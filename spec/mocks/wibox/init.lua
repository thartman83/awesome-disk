-------------------------------------------------------------------------------
-- init.lua for awesome-disk wibox mocks                                     --
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
-- Mocks for wibox for awesome-disk testing
-- }}}

--- init -- {{{
local w = {}
local c = { arcchart = {} }
local l = { align = {} }

function w:buttons(...) end
function l:buttons(...) end

setmetatable(w, {__call = function(_,...) return w end})

return { widget = w,
        container = c,
        layout = l }
-- }}}
