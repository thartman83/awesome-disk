-------------------------------------------------------------------------------
-- table.lua for awesome-disk gears.table mocks                             --
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
-- Gears.table mock objects for awesome-disk
-- }}}

--- table -- {{{
local gtable = {}
--- All functions here are lifted straight from gears.table

--- Override elements in the first table by the one in the second.
--
-- Note that this method doesn't copy entries found in `__index`.
-- @class function
-- @name crush
-- @tparam table t the table to be overriden
-- @tparam table set the table used to override members of `t`
-- @tparam[opt=false] bool raw Use rawset (avoid the metatable)
-- @treturn table t (for convenience)
function gtable.crush(t, set, raw)
    if raw then
        for k, v in pairs(set) do
            rawset(t, k, v)
        end
    else
        for k, v in pairs(set) do
            t[k] = v
        end
    end

    return t
end

--- Join all tables given as arguments.
-- This will iterate over all tables and insert their entries into a new table.
-- @class function
-- @name join
-- @tparam table ... Tables to join.
-- @treturn table A new table containing all entries from the arguments.
function gtable.join(...)
    local ret = {}
    for i = 1, select("#", ...) do
        local t = select(i, ...)
        if t then
            for k, v in pairs(t) do
                if type(k) == "number" then
                    rtable.insert(ret, v)
                else
                    ret[k] = v
                end
            end
        end
    end
    return ret
end

return gtable
-- }}}
