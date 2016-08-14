--- awesome-disk.lua --- Disk widget for awesome

-- Copyright (c) 2016 Thomas Hartman (thomas.lees.hartman@gmail.com)

-- This program is free software- you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation- either version 2
-- of the License, or the License, or (at your option) any later
-- version.

-- This program is distributed in the hope that it will be useful
-- but WITHOUT ANY WARRANTY- without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.

--- Awesome Disk
-- {{{

--- locals and requires
-- {{{
local setmetatable = setmetatable
local util = require('awful.util')

local lsblk_cmd = "/bin/lsblk"
local lsblk_cmd_opts = "-Pno 'NAME,KNAME,FSTYPE,MOUNTPOINT,LABEL,HOTPLUG,PKNAME,TRAN'"
-- }}}

--- Utility functions
-- {{{

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

--- awesome_disk
-- {{{

--- Constructor
-- {{{
local awesome_disk = {}
awesome_disk.__index = awesome_disk

setmetatable(awesome_disk, {
                __call = function(ad, ...)
                   return ad.new(...)
                end,
})

function awesome_disk.new()
   local self = setmetatable({}, awesome_disk)
   self:update()
   return self
end

-- }}}

--- awesome_disk:update()
-- {{{
function awesome_disk:update()
   self:update_block_table()
   self:update_menu()
end
-- }}}

--- awesome_disk:lsblk_info
-- Call lsblk and return the output as a array of lines
-- {{{
function awesome_disk:lsblk_info ()
   return remove_blanks(lines(string.gsub(util.pread(lsblk_cmd .. " " .. lsblk_cmd_opts), '"','')))
end
-- }}}

--- awesome_disk:find_block_parent(block_table, block_name)
-- Find `block_name' in the table where each entry in the table has a
-- key `name'.
-- {{{
function awesome_disk:find_block_parent(block_table, block_name)
   for __,v in ipairs(block_table) do
      if v.kname == block_name then
         return v
      end

      -- depth first search
      if v.children ~= nil and table.getn(v.children) > 0 then
         local retval = self:find_block_parent(v.children, block_name)
         if retval ~= v.children then
            return retval
         end
      end
   end

   -- couldn't find it in `block_table', so return the whole structure
   return block_table
end
-- }}}
                                   
--- awesome_disk:update_block_table()
-- {{{
function awesome_disk:update_block_table()
   local lsblk_lines = self:lsblk_info()
   local block_table = {}

   for _, line in ipairs(lsblk_lines) do
      local parts = split(line, ' ', true)
      local block = {}
      for _, keypair in ipairs(parts) do
         keypair_parts = split(keypair, '=')
         block[keypair_parts[1]:lower()] = keypair_parts[2]
      end

      block.children = {}
      
      -- if pkname is "" then it is a root block node, otherwise find the parent
      if block.pkname == "" then
         table.insert(block_table, block)
      else
         local parent = self:find_block_parent(block_table, block.pkname)

         -- this really shouldn't happen to my knowledge but we should trap for it
         assert(parent ~= nil, "Found non-root block node without parent... " ..
                   "that shouldn't happen")
         assert(parent.children ~= nil, "Could not find block parent `" .. block.pkname .. "'")
         
         table.insert(parent.children, block)
      end
   end

   self._block_table = block_table
end
-- }}}

--- awesome_disk:update_menu()
-- {{{
function awesome_disk:update_menu()
   local menu = {}
   local function helper(block, menu)
      
   end

   self._menu = menu
end
-- }}}

-- }}}

return awesome_disk

-- }}}
