-------------------------------------------------------------------------------
-- init.lua for awesome-disk                                                 --
-- Copyright (c) 2019 Tom Hartman (thomas.lees.hartman@gmail.com)            --
--                                                                           --
-- This program is free software; you can redistribute it and/or             --
-- modify it under the terms of the GNU General Public License               --
-- as published by the Free Software Foundation; either version 2            --
-- of the License, or the License, or (at your option) any later             --
-- version.                                                                  --
--                                                                           --
-- This program is distributed in the hope that it will be useful,           --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of            --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             --
-- GNU General Public License for more details.                              --
-------------------------------------------------------------------------------

--- Commentary -- {{{
-- 
-- }}}

--- awesome-disk -- {{{
local ad = {}

--- Libraries -- {{{
local gtable    = require("gears.table"  )
local gstring   = require("gears.string" )
local wibox     = require("wibox"        )
local awful     = require("awful"        )
local serpent   = require("serpent"      )
local gears     = require("gears"        )
local beautiful = require("beautiful"    )
local dbg       = require("debugger"     )
-- }}}

--- Helper Functions -- {{{
--- lines(str)
-- {{{
local function lines(str)
   local t = {}
   local function helper(line) table.insert(t, line) return "" end
   helper((str:gsub("(.-)\r?\n", helper)))
   return t
end
-- }}}

--- remove_blanks(t)
-- {{{
local function remove_blanks(t)
   local retval = {}
   for _, s in ipairs(t) do
      if s ~= "" and s ~= nil then
         table.insert(retval, s)
      end
   end
   return retval
end
-- }}}

--- split(str, delim, noblanks)
-- {{{
local function split(str, delim, noblanks)   
   local t = {}
   if str == nil then
      return t
   end
   
   local function helper(part) table.insert(t, part) return "" end
   helper((str:gsub("(.-)" .. delim, helper)))
   if noblanks then
      return remove_blanks(t)
   else
      return t
   end
end
-- }}}
-- }}}

--- ad:update -- {{{
-- 
function ad:update ()
   awful.spawn.easy_async(self._lsblk_cmd,
                          function(stdout, stderr, exitreason, exitcode)
                             self:parseLsBlk(stdout, stderr, exitreason, exitcode)
   end)
end
-- }}}

--- ad:parseLsBlk -- {{{
-- Parse the output from lsblk
-- The format should be lines of kv pairs
function ad:parseLsBlk (stdout, stderr, exitreason, exitcode)
   local bt = {}
   local displayName = type(self._displayName) == "function" and self:_displayName() or
      self._displayName
   
   local lines = remove_blanks(lines(stdout))
   for _,line in ipairs(lines) do
      local parts = split(line, ' ', true)
      local block = {}
      for _, keypair in ipairs(parts) do
         keypair_parts = split(keypair, '=')
         block[keypair_parts[1]:lower()] = keypair_parts[2]:gsub("\"","")
      end

      block.children = {}
      
      -- if pkname is "" then it is a root block node, otherwise find the parent
      if block.pkname == "" then
         table.insert(bt, block)
      else
         local parent = self:findBlockParent(bt, block.pkname)

         -- this really shouldn't happen to my knowledge but we should trap for it
         assert(parent ~= nil, "Found non-root block node without parent... " ..
                   "that shouldn't happen")
         assert(parent.children ~= nil, "Could not find block parent `" ..
                   block.pkname .. "'")
         
         table.insert(parent.children, block)

         print("Checking " .. block.name .. " = " .. displayName)
         if block.name == displayName then
            self._displayBlock = block
         end
      end
   end

   self:updateBlockTable(bt)
end
-- }}}

--- ad:findBlockParent -- {{{
-- 
function ad:findBlockParent (block_table, block_name)
   for __,v in ipairs(block_table) do
      if v.kname == block_name then
         return v
      end

      -- depth first search
      if v.children ~= nil and #v.children > 0 then
         local retval = self:findBlockParent(v.children, block_name)
         if retval ~= v.children then
            return retval
         end
      end
   end

   -- couldn't find it in `block_table', so return the whole structure
   return block_table
end
-- }}}

--- ad:updateBlockTable -- {{{
-- 
function ad:updateBlockTable (bt)  
   self._blockTable = bt
   
   self:updateDisplayBlock()
   self:updateBlockMenu()
end
-- }}}

--- ad:updateDisplayBlock -- {{{
-- 
function ad:updateDisplayBlock ()
   if self._displayBlock ~= nil then
      print(serpent.block(self._displayBlock))
      
      if self._displayBlock.fsused == nil or self._displayBlock.fssize == nil then
         return
      end         
      
      local perc = tonumber(self._displayBlock.fsused) /
         tonumber(self._displayBlock.fssize)
      self.children[1].text = self._displayBlock.mountpoint .. " "
      self.children[2].children[1]:set_value(perc)
      self.children[2].children[2].text = math.floor(perc * 100)
   end
end
-- }}}

--- ad:updateBlockMenu -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
function ad:updateBlockMenu ()
   local function genBlockEntry(parent, args)            
      local w = wibox.widget {
         {
            max_value = 100,
            value = args.pct,
            widget = wibox.widget.progressbar,
         },
         {
            text = args.name,
            widget = wibox.widget.textbox,
         },         
         
         layout = wibox.layout.stack
      }

      return { widget = w,
               cmd = {},
               akey = args.name .. "_menu_entry"
      }
   end
   
   local function helper(m, tbl, level)
      for i,v in ipairs(tbl) do         
         table.insert(m, { new = function(parent, args)
                                    args.name = v.name
                                    if tonumber(v.fsused) ~= nil and tonumber(v.fssize) ~= nil then
                                       args.pct = tonumber(v.fsused) / tonumber(v.fssize) * 100
                                    end
                                    return genBlockEntry(parent,args)
                                 end})
         
         if v.children ~= nil and #v.children > 0 then
            helper(m, v.children, level + 1)
         end
      end
      return retval
   end
   
   local m = {}
   helper(m, self._blockTable, 0)
   self._menu = awful.menu({ items = m })
end
-- }}}

--- ad:makeSpace -- {{{
----------------------------------------------------------------------
-- 
----------------------------------------------------------------------
function makeSpace (level)
   local retval = ""
   if level == 0 then
      return retval
   end

   for x=1,level do
      retval = retval .. "─"
   end
   
   return retval
end
-- }}}

--- ad:toggle_menu -- {{{
----------------------------------------------------------------------
-- toggle the disk menu
----------------------------------------------------------------------
function ad:toggle_menu ()
   if self._menu == nil then return end
   
   if self._menu.visible then
      self._menu:hide()
   else
      self._menu:show()
   end

   self._menu.visible = not self._menu.visible
end
-- }}}

--- ad:findHomePartition -- {{{
-- Returns the name of the block node that has the home directory mounted on it
-- param: tbl the 
function ad:findHomePartition (tbl)
   local tbl = tbl or self._blockTable
   if tbl == nil then return end
   
   for i,v in ipairs(tbl) do
      if v.mountpoint == "/home" then
         return v.name
      elseif #v.children ~= 0 then
         ad:findHomePartition(v.children)
      end
   end   
end
-- }}}

--- new -- {{{
-- Awesome Disk constructor
function new (args)
   local args = args or {}
   
   local obj = wibox.widget {
      { text = "", widget = wibox.widget.textbox },
      {
         { max_value = 1, -- forced_width = 100, forced_height = 8,
           start_angle = math.pi / 2,
           thickness = 1.5,
           widget = wibox.container.arcchart },
         { text = "", align = "center", widget = wibox.widget.textbox },
         layout = wibox.layout.stack
      },
      layout = wibox.layout.align.horizontal
   }

   gtable.crush(obj, ad, true)

   obj._timeout        = args.timeout or 15
   obj._lsblk_cmd      = [[/bin/lsblk -Pbno 'NAME,KNAME,FSTYPE,MOUNTPOINT,LABEL,HOTPLUG,PKNAME,TRAN,FSSIZE,FSUSED']]
   obj._blockTable     = {}
   obj._displayName    = args.displayDisk or obj.findHomePartition
   obj._displayBlock   = {}
   obj._menu           = nil

   obj._timer = gears.timer {
      timeout   = obj._timeout,
      autostart = true,
      call_now  = true,
      callback  = function () obj:update() end
   }

   obj:buttons(gtable.join(awful.button({},1,
                              function () obj:toggle_menu() end)))

   return obj
end
-- }}}

return setmetatable(ad, {__call = function(_, ...) return new(...) end})
-- }}}
