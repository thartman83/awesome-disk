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
local lsblk_cmd_opts = "-Pno 'KNAME,FSTYPE,MOUNTPOINT,LABEL,HOTPLUG,PKNAME,TRAN'"

local disk = { mt = {} }
-- }}}

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

--- lsblk_info
-- Call lsblk and return the output as a array of lines
-- {{{
function disk:lsblk_info ()
   return remove_blanks(lines(string.gsub(util.pread(lsblk_cmd .. " " .. lsblk_cmd_opts), '"','')))
end
-- }}}

--- find_block_parent(block_table, block_name)
-- Find `block_name' in the table where each entry in the table has a
-- key `name'.
-- {{{
function disk:find_block_parent(block_table, block_name)
   for __,v in ipairs(block_table) do
      if v.name == block_name then
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
                                   

--- build_block_table()
-- {{{
function disk:build_block_table()
   local lsblk_lines = self:lsblk_info()
   local block_table = {}

   for i,v in ipairs(lsblk_lines) do
      local parts = split(v, ' ', true)
      local block = {}
      block.name = split(parts[1], '=')[2]
      block.fstype = split(parts[2], '=')[2]
      block.mountpoint = split(parts[3], '=')[2]
      block.label = split(parts[4], '=')[2]
      block.hotplug = split(parts[5], '=')[2]
      block.pkname = split(parts[6], '=')[2]
      block.tran = split(parts[7], '=')[2]
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

   return block_table
end
-- }}}


--- Constructor
-- {{{
function disk.new(args)
end

function disk.mt:__call(...)
   return disk.new{...}
end
--}}}

return setmetatable(disk, disk.mt)

-- }}}
