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

--- awesome_disk:find_block_parent tests
-- {{{
describe("find_block_parent #unit tests", function ()
  -- Setup the package environment so that it can find awful
  package.path = '/usr/share/awesome/lib/?.lua;' .. package.path
  local ad = require 'awesome-disk'()
  
  it("Empty block table", function()
        local block_table = {}
        local retval = ad:find_block_parent(block_table, "foobar")
        assert.are.same(retval, {})
  end)

  it("Block table doesn't have the parent", function ()
        local block_table = { { name = "sda" } }
        local retval = ad:find_block_parent(block_table, "sdb")
        assert.are.same(retval, block_table)
  end)

  it("Block table has root parent", function ()
        local block_table = { { name = "sda" } }
        local retval = ad:find_block_parent(block_table, "sda")
        assert.are.same(retval, { name = "sda"})
  end)

  it("Block table has nested parent", function ()
        local block_table = { { name = "sda",
                                children = { { name = "sda1" } },
                              }
                            }
        
        local retval = ad:find_block_parent(block_table, "sda1")
        assert.are.same(retval, { name = "sda1" })           
  end)
  
end)

-- }}}

-- awesome_disk:update_block_table tests
-- {{{

describe("update_block_table #unit tests", function ()
  package.path = '/usr/share/awesome/lib/?.lua;' .. package.path
  local ad = require 'awesome-disk'()

  it("block table 1", function ()
        ad.lsblk_info = function ()
           return {'KNAME=sda FSTYPE= MOUNTPOINT= LABEL= HOTPLUG=0 PKNAME= TRAN=sata'}
        end

        ad:update_block_table()
        assert.are.same({ { name = 'sda',
                            fstype = '',
                            mountpoint = '',
                            label = '',
                            hotplug = '0',
                            pkname = '',
                            tran = 'sata',
                            children = {} } },
           ad._block_table)
  end)
  
  it("block table 2", function ()
    ad.lsblk_info = function ()
       return { 'KNAME=sda FSTYPE= MOUNTPOINT= LABEL= HOTPLUG=0 PKNAME= TRAN=sata',
                'KNAME=sda1 FSTYPE=ext3 MOUNTPOINT= LABEL= HOTPLUG=0 PKNAME=sda TRAN='
       }       
    end
        
    ad:update_block_table()
    assert.are.same({ { name = "sda",
                        fstype = "",
                        mountpoint = "",
                        label = "",
                        hotplug = "0",
                        pkname = "",
                        tran = "sata",
                        children = { 
                           { name = "sda1",
                             fstype = "ext3",
                             mountpoint = "",
                             label = "",
                             hotplug = "0",
                             pkname = "sda",
                             tran = "",
                             children = {} } } } },
       ad._block_table)        
  end)

  it("block table 3", function ()
    ad.lsblk_info = function ()
       return { 'KNAME=sda FSTYPE= MOUNTPOINT= LABEL= HOTPLUG=0 PKNAME= TRAN=sata',
                'KNAME=sda1 FSTYPE=ext3 MOUNTPOINT= LABEL= HOTPLUG=0 PKNAME=sda TRAN=',
                'KNAME=sda2 FSTYPE=crypto_LUKS MOUNTPOINT= LABEL= HOTPLUG=0 PKNAME=sda TRAN=' }
    end

    ad:update_block_table()
    assert.are.same({ { name = "sda",
                        fstype = '',
                        mountpoint = '',
                        label = '',
                        hotplug = '0',
                        pkname = '',
                        tran = 'sata',
                        children = {
                           {
                              name = 'sda1',
                              fstype = 'ext3',
                              mountpoint = '',
                              label = '',
                              hotplug = '0',
                              pkname = 'sda',
                              tran = '',
                              children = { }
                           },
                           {
                              name = 'sda2',
                              fstype = 'crypto_LUKS',
                              mountpoint = '',
                              label = '',
                              hotplug = '0',
                              pkname = 'sda',
                              tran = '',
                              children = {}
                           }                                                        
                        }
                      }
                    },
       ad._block_table)
  end)
end)
-- }}}

-- }}}
