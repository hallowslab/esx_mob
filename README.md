# ESX_MOB configurable mob society

## Installing esx_mob

### Using git

You will need the git command line tool for this

```
git clone thisrepository [esx]/esx_mob
```

### Manually

Download the [zip file](), copy the contents of the folder inside the zip file into a folder in your resources, you should name it esx_mob, after that go into your **server.cfg** file and do start esx_mob after all the requirements listed [here](#requirements)


## Features

It contains all of the base feature of the [resources](#credits) it derived from
plus the features listed below

### Vehicle Shop
1. Vehicle shop with "mafia like" vehicles -- Can be turned off in config --> **(turning on off in config not implemented)**
2. Ability to purchase cars for your own society or sell them to others
3. Custom plates for society -->  **Plate should be checked before trying to create one to avoid conflicts in database, should also be configurable**

### Weapon Shop
**Not Implemented**


### Society Garage
1. A garage available to all members of the society if their rank matches the one in the config --> **Not implemented**

### Mission

**Not implemented**

### Security Personnel
1. Npcs provide security to compound
2. If all security is eliminated from a certain zone more will come to provide backup **Not implemented**
3. All Zones, Weapons and Personell are configurable in the .config file --> **Semi-finished**

## Requirements
**Please make sure you also meet all the requirements of the requirements listed below**

1. [ESX](https://forum.fivem.net/t/release-esx-base/39881) **Important**
2. [esx_society](https://github.com/ESX-Org/esx_society) **Important**
3. [esx_billing](https://github.com/ESX-Org/esx_billing) **Important - if using the society shops**
4. [esx_jobs](https://github.com/ESX-Org/esx_jobs) **Probably not required but it does require the jobs and job grades tables in database**
5. [esx_addonaccount](https://github.com/ESX-Org/esx_addonaccount) **Important**
6. [esx_addoninventory](https://github.com/ESX-Org/esx_addoninventory) **Important**
7. [esx_eden_garage](https://github.com/HumanTree92/esx_eden_garage) **Not actually required but you do need the state and stored columns in the owned_vehicles table**
10. [esx_vehicleshop](https://github.com/ESX-Org/esx_vehicleshop) **Not actualy required but you do need the owned_vehicles, vehicles and vehicle_categories tables in the database**


## **For Dev:**

#### Possible Tasks for defense/guarding

```
void TASK_STAND_GUARD(Ped ped, float x, float y, float z, float heading, char* scenarioName)
 x,y,z,heading = Pos
scenarioName example: "WORLD_HUMAN_GUARD_STAND"

void TASK_GUARD_CURRENT_POSITION(Ped p0, float p1, float p2, BOOL p3)
From re_prisonvanbreak:  
AI::TASK_GUARD_CURRENT_POSITION(l_DD, 35.0, 35.0, 1)

void TASK_GUARD_SPHERE_DEFENSIVE_AREA(Ped p0, float p1, float p2, float p3, float p4, float p5, Any p6, float p7, float p8, float p9, float p10)
p0 - Guessing PedID  
p1, p2, p3 - XYZ?  
p4 - ???  
p5 - Maybe the size of sphere from XYZ?  
p6 - ???  
p7, p8, p9 - XYZ again?  
p10 - Maybe the size of sphere from second XYZ?

void TASK_PATROL(Ped ped, char* p1, Any p2, BOOL p3, BOOL p4)

https://runtime.fivem.net/doc/natives/#_0xBDA5DF49D080FE4E

TASK_GUARD_ASSIGNED_DEFENSIVE_AREA(Any p0, float p1, float p2, float p3, float p4, float p5, Any p6)
```

#### Traveling to waypoints

- [Vehicle path nodes](https://forum.fivem.net/t/vehicles-path-nodes/50958)

```
http://gtaforums.com/topic/822314-guide-driving-styles/

void TASK_VEHICLE_DRIVE_TO_COORD(Ped ped, Vehicle vehicle, float x, float y, float z, float speed, Any p6, Hash vehicleModel, int drivingMode, float stopRange, float p10)
Passing P6 value as floating value didn't throw any errors, though unsure what is it exactly, looks like radius or something.  
P10 though, it is mentioned as float, however, I used bool and set it to true, that too worked.  
Here the e.g. code I used  
Function.Call(Hash.TASK_VEHICLE_DRIVE_TO_COORD, Ped, Vehicle, Cor X, Cor Y, Cor Z, 30f, 1f, Vehicle.GetHashCode(), 16777216, 1f, true)

-- Possible driving modes
-- 16777216 Seems the same as 5 , 5 No Clue, 2883621 ??fast/normal/offroad/insideBuildings ??, 786603 this is normal,

```

#### Changing appearence

**Good Matches**

1. **Goon**
  - Body SetPedComponentVariation(ped, 3, 4, 0, 2)
  - inner shirt SetPedComponentVariation(ped, 8, 10, 0, 2) or SetPedComponentVariation(ped, 8, 12, 0, 2)
  - Jacket SetPedComponentVariation(ped, 11, 4, 0, 2) or SetPedComponentVariation(ped, 11, 23, 0, 2)

or

  - Body SetPedComponentVariation(ped, 3, 4, 0, 2)
  - inner shirt SetPedComponentVariation(ped, 8, 31, 0, 2)
  - Jacket SetPedComponentVariation(ped, 11, 29, 0, 2)

2. **Leaders**
  - Body SetPedComponentVariation(ped, 3, 4, 0, 2)
  - inner shirt SetPedComponentVariation(ped, 8, 12, 0, 2)
  - Jacket SetPedComponentVariation(ped, 11, 10, 0, 2) or SetPedComponentVariation(ped, 11, 27, 0, 2) or SetPedComponentVariation(ped, 11, 28, 0, 2)

  or

  - Body SetPedComponentVariation(ped, 3, 4, 0, 2)
  - inner shirt SetPedComponentVariation(ped, 8, 32, 0, 2)
  - Jacket SetPedComponentVariation(ped, 11, 30, 0, 2)


```
void SET_PED_COMPONENT_VARIATION(Ped ped, int componentId, int drawableId, int textureId, int paletteId)

0 FACE
1 BEARD
2 HAIRCUT
3 SHIRT
4 PANTS
5 Hands / Gloves
6 SHOES
7 Eyes
8 Accessories
9 Mission Items/Tasks
10 Decals
11 Collars and Inner Shirts

Ped - is the ped you want to set the outfit.

ComponentId - Is the ID of the part of the body.

DrawableID - Is the ID of the cloth you want to set.

TextureID - Is the ID of the variation of the cloth. (Variation in the sense of color)

PalleteID - Can be set as 2 or you use (int GET_PED_PALETTE_VARIATION(Ped ped, int componentId))

```

#### Following/Protecting:

```

model = GetEntityModel(btype.entity)
## 117401876 ???
BTYPE    0x06FF6914    117401876    117401876    SportsClassic    (Roosevelt)    ValDayMassacre    06FF6914    BTYPE              0x06FF6914        117401876          117401876          SportsClassic      (Roosevelt)                      ValDayMassacre     " 750,000 "    " 1,150,000 "    " 1,150,000 "

```

#### Flying:

```

-- Checking if ped is in runway to start taking off might be hard due to localization
local strtName,_ = GetStreetNameAtCoord(pos.x,pos.y,pos.z,0,0)
print(GetStreetNameFromHashKey(strtName)) <-- Pista de pouso1

-- Just taxies trough runway
TaskVehicleDriveWander(ped, vehicle, 25.0, 8388614)

-- Flies directly to target does not taxi trough runway
TaskPlaneMission(ped, vehicle, 0, 0 ,x,y,z, 4, 100.0, 0, 90.0, 0, 200.0)

```

#### Array related stuff:

https://stackoverflow.com/questions/12394841/safely-remove-items-from-an-array-table-while-iterating

#### Lua list comprehension

[**Requires Penlight**](http://lua-users.org/wiki/ListComprehensions)

[**Chained Coroutines**](https://rosettacode.org/wiki/List_comprehensions#Lua)

#### Debugging

https://stackoverflow.com/questions/10838961/lua-find-out-calling-function

#### About the code
**Notes**

- **"SecurityGuards"** table - contains all the groups with npcs configured in Config.SecurityGuards each group being a table with a table for each npc so many tables
- **"SecurityGroups"** table - contains booleans for groups being called if true group is being called
- **"InUseVehicles"** table - contains all vehicles veing used by the society **This should be restricted to some value to avoid many vehicles outside**
- **"isSpawningBackup"**, **"isLoadingSecurity"**, **"isCallingBackup"** ,isEtc... booleans- represent booleans for those actions
- **"Travelling"** table - Contains tables with entities travelling
- Can't check security group while creating new ones to avoid errors while iterating trough the table
- ^^This is probably the same for driving and bodyguards


## TODO:

- Verify all the registered events and callbacks and check which ones are being used and which ones are unused
- Clean the code: check for unused vars, functions, etc...
- Check for performance issues
- Redo the pop vehicle function so it can have multiple "sell" locations for multiple vehicles on display
- Review permissions of the other members of society below boss
- Make sure that all functions event or callbacks that try to spawn a vehicle check if the spawning zone is clear before actually spawning the vehicle
- Call IsPlateTaken before trying to generate plates especially for custom plates

## Credits

This was based of [ESX-Org´s esx_vehicleshop](https://github.com/ESX-Org/esx_vehicleshop) and [HumanTree92's esx_eden_garage](https://github.com/HumanTree92/esx_eden_garage)
Some of the original functions where modified CONTINUE=====================>
