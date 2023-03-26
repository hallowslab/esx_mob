--[[################################
    Main Configuration File

    Please read everything carefully, this has a lot of values to configure it comes
    pre-configured to a "mobster like society" but it can be easily re-configured
    to create simple societies

    #### Config

    This is the main configuration values some are booleans (true or false) others are
    numbers (floats or ints) and tables table = { value = 1 }

    #### Zones

    Main zones used by the resource most names are self-explanatory
    **Important*** DO NOT RENAME THEM
    you can configure (remove, edit) all the zones but leave the names
    EX: **everything is important even the ","**
    MobHeadquarters = { <---- Name
      Pos   = {x = -589.88, y = -1626.71, z = 32.05 }, <- Position you can edit this
      Size  = {x = 1.5, y = 1.5, z = 1.0}, <- Size for the blip to render
      Type  = 1, <- this is for blips if 1 it shows the blip if -1 it never shows it
    },

    #### SellZones

    This is the zones for the vehicle shop that can be disable by setting Config


########################################]]

Config                              = {}
Config.DrawDistance                 = 100.0
Config.MarkerColor                  = {r = 120, g = 120, b = 240}
Config.EnablePlayerManagement       = true -- enables the actual car dealer job. You'll need esx_addonaccount, esx_billing and esx_society
Config.EnableMobCommand             = false -- TODO: command for mob members above caporegime for additional mob controls
Config.EnableMobMissions            = false -- TODO: Mob missions can be started at headquarters or with MobCommand
Config.EnableMobWars                = false -- TODO: use with EnableMobMissions, Allows the mob to attack other factions
Config.EnableVehicleShop            = true -- TODO: enables/disables vehicle shop
Config.EnableOwnedVehicles          = true -- TODO: what is this ........?
Config.EnableSocietyOwnedVehicles   = true -- use with EnablePlayerManagement disabled, or else it wont have any effects
Config.ResellPercentage             = 50 -- vehicle resell percentage
Config.ImpoundPercentage            = 5 -- impound price percentage of the value of the vehicle
Config.Locale                       = 'en'
Config.NPC                          = "mp_m_freemode_01" -- change the model spawned **might break the dress function or just produce glitchy textures**
Config.Group                        = 'MOB' -- Then name of the group to make peds friendly or aggressive to player
Config.SocNic                       = 'MOB' -- Used to create custom plates EX: MOB 123 it has nothing to do with the one above
Config.CheckSecurity                = true -- if true it will check for each security group if the peds are still alive
Config.EnableSecurity               = true -- TODO: enables/disables security at configured zones
-- looks like this: 'LLL NNN'
-- The maximum plate length is 8 chars (including spaces & symbols), don't go past it!
Config.PlateLetters  = 3
Config.PlateNumbers  = 3
Config.PlateUseSpace = true

Config.BodyGuardsSpawnDistance = {
  25.0, -- x
  25.0, -- y
  0.0, -- z
}


Config.Zones = {

  -- For vehicles arriving
  MobHeadquartersArrival = { -- Boss Actions
    Pos   = {x = -529.21, y = -1688.05, z = 18.14 },
    Size  = {x = 1.5, y = 1.5, z = 1.0},
    Type  = 1,
  },

  MobHeadquarters = { -- Boss Actions
    Pos   = {x = -589.88, y = -1626.71, z = 32.05 },
    Size  = {x = 1.5, y = 1.5, z = 1.0},
    Type  = 1,
  },

  MobWeaponShop = { -- Mob Weapon Shop
    Pos   = {x = -573.99, y = -1601.56, z = 25.89 },
    Size  = {x = 1.5, y = 1.5, z = 1.0},
    Type  = 1,
  },

  MobVehicleShop = { -- Marker for accessing shop
    Pos   = {x = -595.30, y = -1647.40, z = 25.17 },
    Size  = {x = 1.5, y = 1.5, z = 1.0},
    Type  = 1,
  },

  MobSocietyGarage = { -- Marker for accessing society garage
    Pos   = {x = -575.75 , y = -1634.34 , z = 18.46 },
    Size  = {x = 1.5, y = 1.5, z = 1.0},
    Type  = 1,
  },

  MobSocietyGarageEntry = {
    Pos   = {x = -572.16 , y = -1633.19 , z = 18.35 },
    Size  = {x = 3.0, y = 3.0, z = 1.0},
    Type  = -1,
  },

  MobVehicleInside = { -- Marker for viewing vehicles
  Pos     = {x = -576.36, y = -1670.34, z = 19.25 },
  Size    = {x = 1.5, y = 1.5, z = 1.0},
  Heading = 297.3,
  Type    = -1,
  },

  MobVehicleOutside = { -- Marker after purchasing vehicle
    Pos     = {x = -570.24, y = -1639.65, z = 19.44},
    Size    = {x = 1.5, y = 1.5, z = 1.0},
    Heading = 145.7,
    Type    = -1,
  },

  GiveBackVehicle = { -- Marker for Player Management
    Pos   = {x = -1040.79, y = -2991.23, z = 14.55},
    Size  = {x = 3.0, y = 3.0, z = 1.0},
    Type  = (Config.EnablePlayerManagement and 1 or -1),
  },

  MobResellVehicle = { -- Marker for selling vehicle
    Pos   = {x = -527.42, y = -1627.79, z = 16.80 },
    Size  = {x = 3.0, y = 3.0, z = 1.0},
    Type  = 1,
  },

  MobVehicleImpound = { -- Marker for retrieving impounded vehicles
    Pos   = {x = 410.44, y = -1623.13, z = 29.29},
    Size  = {x = 1.5, y = 1.5, z= 1.0},
    Type  = 1,
  },

  MobImpoundSpawn = { -- Spawn Point for impounded vehicles
  Pos     = {x=405.64, y=-1643.4, z=27.61},
  Size    = {x = 1.5, y = 1.5, z= 1.0},
  Heading = 229.54,
  Type    = -1,
  },

}

-- This names can be changed, and more can be added,
-- as long as they match the structure of those already created
Config.SellZones = { -- Vehicle sell spots

  Zone1 = {
    Name    = 'Zone1',
    Pos     = {x= -594.60, y= -1659.62, z= 19.56},
    Size    = {x = 3.0, y = 3.0, z = 1.0},
    Heading = 249.65,
    Type    = -1,
  },

  Zone2 = {
    Name    = 'Zone2',
    Pos     = {x= -585.31, y= -1659.24, z= 19.33},
    Size    = {x = 3.0, y = 3.0, z = 1.0},
    Heading = 178.82,
    Type    = -1,
  },

  Zone3 = {
    Name    = 'Zone3',
    Pos     = {x= -607.69, y= -1671.76, z= 19.88},
    Size    = {x = 3.0, y = 3.0, z = 1.0},
    Heading = 279.94,
    Type    = -1,
  },

  Zone4 = {
    Name    = 'Zone4',
    Pos     = {x= -578.26, y= -1674.64, z= 19.23},
    Size    = {x = 3.0, y = 3.0, z = 1.0},
    Heading = 358.51,
    Type    = -1,
  },

}

-- These parameters can be removed/changed as long as the structure remains the same
--  entrys here must contain (no spaces, only word characters, numbers, or underlines, and don't begin with a number)
Config.SecurityGuards = {

  Group1 = {
    FuelTop = {
      PedType = 11,
      Pos     = {x= -563.61, y= -1644.75, z= 23.94},
      Heading = 184.08
    },

    Entry1 = {
      PedType = 11,
      Pos     = {x= -574.78, y= -1648.42, z= 19.40},
      Heading = 62.16
    },

    Entry2 = {
      PedType = 11,
      Pos     = {x= -576.22, y= -1647.63, z= 19.40},
      Heading = 216.10
    },

    StairsBottom = {
      PedType = 11,
      Pos     = {x= -579.82, y= -1630.45, z= 19.40},
      Heading = 215.70
    }
  },

  Group2 = {
    WharehouseBackEntry = {
      PedType = 11,
      Pos     = {x= -607.15, y= -1629.22, z= 26.01},
      Heading = 257.54
    },

    WharehouseScaffold = {
      PedType = 11,
      Pos     = {x= -601.36, y= -1600.46, z= 29.40},
      Heading = 266.34
    },

    Wharehouse1 = {
      PedType = 11,
      Pos     = {x= -583.64, y= -1599.91, z= 26.01},
      Heading = 176.81
    },

    Wharehouse2 = {
      PedType = 11,
      Pos     = {x= -572.97, y= -1610.87, z= 26.01},
      Heading = 57.09
    }
  }
}

Config.Shipments = {

  RPG = {
    name = 'WEAPON_RPG',
    quantity = 0,
  },

  GUS = {
    name = 'WEAPON_GUSENBERG',
    quantity = 0,
  },

}

Config.SPLS = {

  Docks1 = {
    Pos     = {x= -180.24, y= -2254.73, z= 7.25},
    Heading = 355.2
  },

  Docks2 = {
    Pos     = {x= -111.01, y= -2238.42, z= 10.8},
    Heading = 62.16
  }

}

Config.RandomDrops = {

  -- Palomino Highlands
  PH1 = {
    Pos   = {},
    Size  = { x = 3.0, y = 3.0, z = 1.0},
    Type  = -1,
  },


  PH2 = {
    Pos   = {},
    Size  = { x = 3.0, y = 3.0, z = 1.0},
    Type  = -1,
  },

  -- Great Senora
  GS1 = {
    Pos   = {},
    Size  = { x = 3.0, y = 3.0, z = 1.0},
    Type  = -1,
  },

  GS2 = {
    Pos   = {},
    Size  = { x = 3.0, y = 3.0, z = 1.0},
    Type  = -1,
  },

}

--[[###############
      In development....
###################]]

Debugging         = {}
Debugging.EnableDebug = true -- if this is set to false everything else will be also set to false
Debugging.EnableDevCommands = true
Debugging.EnableLogging     = true
Debugging.LogLevels         = {
  info = true, -- Info like running functions
  params = false, -- parameters passed around
  tables = false, -- table values
}
