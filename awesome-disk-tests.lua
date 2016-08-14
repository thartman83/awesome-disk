--- Awesome disk tests

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

--- Awesome disk tests
-- {{{

require 'busted.runner'()

--- find_block_parent_tests
-- {{{
describe("find_block_parent #unit tests", function ()
  -- Setup the package environment so that it can find awful
  package.path = '/usr/share/awesome/lib/?.lua;' .. package.path
  local ad = require 'awesome-disk'
  it("Empty block table", function()
        local block_table = {}
        local retval = ad.find_block_parent(block_table, "foobar")
        assert.are.same(retval, {})
  end)

  it("Block table doesn't have the parent", function ()
        local block_table = { { name = "sda" } }
        local retval = ad.find_block_parent(block_table, "sdb")
        assert.are.same(retval, block_table)
  end)

  it("Block table has root parent", function ()
        local block_table = { { name = "sda" } }
        local retval = ad.find_block_parent(block_table, "sda")
        assert.are.same(retval, { name = "sda"})
  end)

  it("Block table has nested parent", function ()
        local block_table = { { name = "sda",
                                children = { { name = "sda1" } },
                              }
                            }
        
        local retval = ad.find_block_parent(block_table, "sda1")
        assert.are.same(retval, { name = "sda1" })           
  end)
end)

describe("build_block_table #unit tests", function ()
  package.path = '/usr/share/awesome/lib/?.lua;' .. package.path
  local ad = require 'awesome-disk'

  it("block table 1", function ()
        stub(ad, "lsblk_info")
           
        local block_table = ad.build_block_table()
        assert.are.same(block_table, { { name = "sda",
                                         fstype = "",
                                         mountpoint = "",
                                         label = "",
                                         hotplug = "0",
                                         pkname = "",
                                         tran = "sata",
                                         children = {
                                            { name = "sda1",
                                              fstype = "cyrpto_LUKS",
                                              mountpoint = "",
                                              label = "",
                                              hotplug = "0",
                                              pkname = "sda",
                                              tran = "" }
                                         }
        } })
  end)
end)
-- }}}

-- }}}
