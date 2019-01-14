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
local gtable  = require("gears.table"  )
local gstring = require("gears.string" )
local wibox   = require("wibox"        )
local awful   = require("awful"        )
local serpent = require("serpent"      )
local gears   = require("gears"        )
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
   return true
end
-- }}}

--- ad:parseLsBlk -- {{{
-- Parse the output from lsblk
-- The format should be lines of kv pairs
function ad:parseLsBlk (stdout, stderr, exitreason, exitcode)
   local bt = {}
   
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

         if block.name == self._displayName then
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
      if v.children ~= nil and table.getn(v.children) > 0 then
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
   self._block_table = bt

   self:updateDisplayBlock()  
end
-- }}}

--- ad:updateDisplayBlock -- {{{
-- 
function ad:updateDisplayBlock ()   
   print(serpent.block(self._displayBlock))

   if self._displayBlock ~= nil then
      local perc = tonumber(self._displayBlock.fsused) /
         tonumber(self._displayBlock.fssize)
      self.children[1]:set_value(perc)
      self.children[2].text = self._displayBlock.mountpoint ..
         " (" .. math.floor(perc * 100) .. "%" .. ")"
   end
end
-- }}}

--- new -- {{{
-- Awesome Disk constructor
function new (args)
   local args = args or {}
   
   local obj = wibox.widget {
      { max_value = 1, forced_width = 100, forced_height = 10,
        widget = wibox.container.radialprogressbar },
      { text = "", align = "center", widget = wibox.widget.textbox },
      layout = wibox.layout.stack
   }
   
   gtable.crush(obj, ad, true)

   obj._timeout        = args.timeout or 15
   obj._lsblk_cmd      = [[/bin/lsblk -Pbno 'NAME,KNAME,FSTYPE,MOUNTPOINT,LABEL,HOTPLUG,PKNAME,TRAN,FSSIZE,FSUSED']]
   obj._block_table    = {}
   obj._displayName    = args.displayDisk or "vg1-home"
   obj._displayBlock   = {}
   
   -- Start the widget
   -- gears.timer {
   --    timeout   = obj._timeout,
   --    autostart = true,
   --    callback  = obj.update
   -- }

   obj:update()
   gears.timer.start_new(obj._timeout, function () obj:update() return false end)

   return obj
end
-- }}}

return setmetatable(ad, {__call = function(_, ...) return new(...) end})
-- }}}
