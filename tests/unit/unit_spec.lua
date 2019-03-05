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

local awesomeDisk  = require("awesome-disk")
local awful = require("awful")
local dbg   = require("debugger")
-- }}}

--- awesome-pass unit tests -- {{{
describe("awesome-pass unit tests",
  function ()     

     --- ad:parseLsBlk Tests -- {{{
     describe("ad:parseLsBlk tests",
       function ()
          local d = awesomeDisk()
          -- updateBlockTable is called as a side effect of parseLsBlk
          -- completing so noop the function while testing
          d["updateBlockTable"] = function (self, bt) self._blockTable = bt end

          --- A good test -- {{{
          it("should parse well formed output from lsblk successfully",
             function()
                local lsblkOutput = [[NAME="sda" KNAME="sda" FSTYPE="" MOUNTPOINT="" LABEL="" HOTPLUG="0" PKNAME="" TRAN="sata" FSSIZE="" FSUSED=""
NAME="sda1" KNAME="sda1" FSTYPE="" MOUNTPOINT="" LABEL="" HOTPLUG="0" PKNAME="sda" TRAN="" FSSIZE="" FSUSED=""
NAME="sda2" KNAME="sda2" FSTYPE="ext2" MOUNTPOINT="" LABEL="" HOTPLUG="0" PKNAME="sda" TRAN="" FSSIZE="" FSUSED=""
NAME="sda3" KNAME="sda3" FSTYPE="swap" MOUNTPOINT="[SWAP]" LABEL="" HOTPLUG="0" PKNAME="sda" TRAN="" FSSIZE="" FSUSED=""
NAME="sda4" KNAME="sda4" FSTYPE="ext4" MOUNTPOINT="/" LABEL="" HOTPLUG="0" PKNAME="sda" TRAN="" FSSIZE="48347668480" FSUSED="37202923520"
NAME="sr0" KNAME="sr0" FSTYPE="" MOUNTPOINT="" LABEL="" HOTPLUG="1" PKNAME="" TRAN="ata" FSSIZE="" FSUSED=""]]
                d:parseLsBlk(lsblkOutput,"",0,0)
                assert.is_equal(2,table.getn(d._blockTable))
                assert.is_equal(4,table.getn(d._blockTable[1].children))
          end)
          -- }}}
     end)
     -- }}}
end)
-- }}}


-- }}}
