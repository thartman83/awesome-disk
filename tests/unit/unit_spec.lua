-------------------------------------------------------------------------------
-- unit_spec.lua for awesome-disk                                            --
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
-- Unit tests for awesome-disk
-- }}}

--- awesome-disk unit tests -- {{{

--- libraries and mocks -- {{{
package.path = "./tests/mocks/?.lua;./tests/mocks/?/init.lua;../?/init.lua;" ..
               package.path

local disk  = require("awesome-disk")
local awful = require("awful")
local dbg   = require("debugger")
-- }}}

--- awesome-pass unit tests -- {{{
describe("awesome-pass unit tests",
  function ()
     
end)
-- }}}


-- }}}
