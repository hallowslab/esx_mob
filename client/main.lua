local Keys = {
  ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
  ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
  ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
  ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
  ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
  ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
  ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
  ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
  ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local HasAlreadyEnteredMarker = false
local LastZone                = nil
local CurrentAction           = nil
local CurrentActionMsg        = ''
local CurrentActionData       = {}
local IsInShopMenu            = false
local Categories              = {}
local Vehicles                = {}
local LastVehicles            = {}
local InUseVehicles           = {}
local SecurityGuards          = {}
local SecurityGroup           = nil -- GetHashKey(Config.Group)
local SecurityGroups          = nil
local BodyGuards              = {}
local BodyGuardsGroups        = {}
local CurrentVehicleData      = nil
local isSpawningBackup        = false
local isLoadingSecurity       = false
local isSpawningSecurity      = false
local isCallingBackup         = false
local isCallingBodyguards     = false
local onSale                  = {}
local Travelling              = {}
local defaultNPC              = Config.NPC
local HQArrival               = Config.Zones.MobHeadquartersArrival
local SecuritySpawnPoints     = Config.SPLS
local vehicleExit             = Config.Zones.MobVehicleOutside
local impoundSpawn            = Config.Zones.MobImpoundSpawn
local SocNic                  = Config.SocNic

ESX                           = nil


--Load ESX and set zones
Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	Citizen.Wait(10000)

	ESX.TriggerServerCallback('esx_mob:getCategories', function (categories)
		Categories = categories
	end)

	ESX.TriggerServerCallback('esx_mob:getVehicles', function (vehicles)
		Vehicles = vehicles
	end)

  CreateRelationGroup()
  Citizen.Trace('esx_mob: Loading vehicles for sale\n')
  LoadVehiclesForSale()
  if Config.EnableSecurity then
    Citizen.Trace('esx_mob: Loading Security Guards\n')
    LoadSecurity()
  end
  CheckDebugging()
  -- To Remove
  --CallSecurity()
  -- This resets the sell zones
  TriggerServerEvent('esx_mob:loadSellZones')

	if Config.EnablePlayerManagement then
		if ESX.PlayerData.job.name == 'mafia' then
      Config.Zones.MobVehicleShop.Type = 1
      CheckAndSetRelationship('PLAYER', 0)

			if ESX.PlayerData.job.grade_name == 'boss' then
				Config.Zones.MobHeadquarters.Type = 1
			end

    else
      CheckAndSetRelationship('PLAYER', 4)
			Config.Zones.MobVehicleShop.Type = -1
			Config.Zones.MobHeadquarters.Type  = -1
		end
	end
end)


-- Net Events
-- Also configures the zones based on player job
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	ESX.PlayerData = xPlayer

	if Config.EnablePlayerManagement then
		if ESX.PlayerData.job.name == 'mafia' then
			Config.Zones.MobVehicleShop.Type = 1

			if ESX.PlayerData.job.grade_name == 'boss' then
				Config.Zones.MobHeadquarters.Type = 1
			end

		else
			Config.Zones.MobVehicleShop.Type = -1
			Config.Zones.MobHeadquarters.Type  = -1
		end
	end
end)

RegisterNetEvent('esx_mob:sendCategories')
AddEventHandler('esx_mob:sendCategories', function (categories)
	Categories = categories
end)

RegisterNetEvent('esx_mob:sendVehicles')
AddEventHandler('esx_mob:sendVehicles', function (vehicles)
	Vehicles = vehicles
end)

-- Delete vehicle and clear last vehicle data,
-- this will be removed after zone system is implemented
function DeleteShopInsideVehicles()
  while #LastVehicles > 0 do
    local vehicle = LastVehicles[1]
    ESX.Game.DeleteVehicle(vehicle)
    table.remove(LastVehicles, 1)
  end
end

--Load vehicles for sale
function LoadVehiclesForSale()
  ESX.TriggerServerCallback('esx_mob:getForSale', function(saleVehicles)
    if not (table.empty(saleVehicles)) then
      local zones = Config.SellZones
      for i,v in pairs(saleVehicles) do
        for name,z in pairs(zones) do
          print("name and zone:",name,z)
          if v.label == zones[name] then
            if v.value ~= nil then
              print('Spawning')
            end
          end
        end
      end
    else
      print("no vehicles for sale")
    end
  end)
end

function CreateRelationGroup()
  AddRelationshipGroup(Config.Group)
  local security = GetHashKey(Config.Group)
  LogAndTrace("Creating", {group = security}, "info")
  SecurityGroup = security
  local secGroups = {}
  for i,_ in pairs(Config.SecurityGuards) do
    secGroups[i] = false
  end
  SecurityGroups = secGroups
end

-- Loads npc security
function LoadSecurity()
  local isSecure = nil
  while isLoadingSecurity do
    Citizen.Wait(1000)
  end
  -- check with server if npcs spawned
  ESX.TriggerServerCallback('esx_mob:hasSecurity', function(hasSecurity)
    if not hasSecurity then
      isSecure = false
    else
      isSecure = true
      ESX.TriggerServerCallback('esx_mob:getSecurity', function(security)
        if (security ~= nil) then
          SecurityGuards = security
          -- check entity status after 15 secs
          Citizen.Wait(15000)
          for _,v in pairs(security) do
            local ent = v.ent
            LogAndTrace('Checking spawned security', {
              entityExist = DoesEntityExist(ent),
              hasDrawable = DoesEntityHaveDrawable(ent),
              hasPhysics = DoesEntityHavePhysics(ent)
            }, 'tables')
          end
          -- check if spawned
        else
          print("No security on server")
        end
      end)
    end
  end)
  if not isSecure then
    isLoadingSecurity = true

    print("No security")

    -- loop trough the config and spawn accordingly
    for i,_ in pairs(Config.SecurityGuards) do
      if not isSpawningSecurity then
        SpawnSecurity(i)
      end
    end
    isLoadingSecurity = false
  end
end

-- TODO: FINISH this
local function GuardHQ(ped, isLeader)
end

local function DressAsMob(ped, isLeader)
  -- SetPedComponentVariation(Ped ped, int componentId, int drawableId, int textureId, int paletteId)
  --[[----------------------------
          **Drawables**
    1 head        -- masks ?,
    2 hair        -- hair,
    3 torso       -- body,
    4 legs        -- pants,
    5 hands?      -- seems to be parachute,
    6 feet        -- feet,
    7 eyes        -- ?? ,
    8 accessories?  -- seems inner shirt
    9 tasks?      -- seems body armours,
    10 textures?  -- does nothing?,
    11 inner shirt? -- seems jacket
  ---------------------------------------------]]
  -- SetPedPropIndex(Ped ped, int componentId, int drawableId, int TextureId, BOOL attach)
  --[[---------
        **Props**
    PED_PROP_HATS = 0,
    PED_PROP_GLASSES = 1,
    PED_PROP_EARS = 2,
    PED_PROP_WATCHES = 3,
  ------------------------]]
  if isLeader then
    SetPedComponentVariation(ped, 2, 2, 1, 2)
    SetPedComponentVariation(ped, 3, 4, 0, 2)
    SetPedComponentVariation(ped, 4, 35, 0, 2)
    SetPedComponentVariation(ped, 6, 10, 0, 2)
    SetPedComponentVariation(ped, 8, 10, 0, 2)
    SetPedComponentVariation(ped, 11, 28, 0, 2)
    SetPedPropIndex(ped, 0, 12, 1, 2)
  else
    SetPedComponentVariation(ped, 2, 2, 2, 2)
    SetPedComponentVariation(ped, 3, 4, 0, 2)
    SetPedComponentVariation(ped, 4, 35, 0, 2)
    SetPedComponentVariation(ped, 6, 10, 0, 2)
    SetPedComponentVariation(ped, 8, 10, 0, 2)
    SetPedComponentVariation(ped, 11, 4, 0, 2)
    SetPedPropIndex(ped, 0, 12, 0, 2)
  end
end

function CreateBackups(index, sp, heading, dest, caller)
  if (dest == HQArrival.Pos) then
    SpawnBackupVehicleCrew(index, sp, heading, dest, caller)
  else
    CallBodyGuards(index)
  end
end

function CallBodyGuards(index)
  local ped = GetPlayerPed(-1)
  local coords = GetEntityCoords(ped, 0)
  local x,y,z = table.unpack(coords)
  local a,b,c = table.unpack(Config.BodyGuardsSpawnDistance)
  local roadType = 1
  local roadFound = false
  local sp = nil
  local heading = nil
  while not roadFound do
    roadFound, sp, heading = GetClosestVehicleNodeWithHeading(x+a, y+b, z+c, 1,3,0)
    roadType = roadType + 1
  end
  while isSpawningBackup do
    Citizen.Wait(2000)
  end
  BodyGuardsGroups[index] = true
  SpawnBackupVehicleCrew(index, sp, heading, coords, ped)
end

-- args: index of npcs to spawn, spawn point, heading for vehicle, destination, caller is for following player or vehicle
function SpawnBackupVehicleCrew(index, sp, heading, dest, caller)
  isSpawningBackup = true
  local vehHash = WaitForHash('btype')
  local vehicle = CreateVehicle(vehHash, sp.x, sp.y, sp.z, heading, 1, 0)
  local group   = SecurityGroup
  local weapon  = GetHashKey('WEAPON_GUSENBERG')
  local sidearm = GetHashKey('WEAPON_PISTOL')
  print("npcs:", index)
  local toTable = {}

  local isDriver = false

  for _,v in pairs(Config.SecurityGuards[index]) do
    local postHeading = v.Heading
    local pos = v.Pos
    local hash = WaitForHash(defaultNPC)
    local ped = CreatePed(10, hash, sp.x+1.0, sp.y+1.0, sp.z, 0.0, true, true)

    SetVehicleOnGroundProperly(vehicle)

    -- -2 should be any available seat but does not seem to work with TaskWarpPedIntoVehicle
    -- maybe it's because it's a btype, or maybe it's because the driver immediately drives off
    if not (isDriver) then
      DressAsMob(ped, true)
      SetPedIntoVehicle(ped, vehicle, -1)
      GiveWeaponToPed(ped, weapon, 0, 1)
      -- This might cause issues when guarding or following ??
      SetBlockingOfNonTemporaryEvents(ped, true)
      isDriver = true
      -- Call function to travel
      TravelToPos(ped, index, vehicle, dest, caller)
    else
      DressAsMob(ped, false)
      SetPedIntoVehicle(ped, vehicle, -2)
      GiveWeaponToPed(ped, sidearm, 0, 1)
      SetPedCombatAttributes(ped, 46, true)
    end
    SetPedRelationshipGroupHash(ped, group)
    SetPedCombatAttributes(ped, 2, true)
    SetEntityAsMissionEntity(ped, true, true)
    -- Don't allow ped to leave vehicle
    SetPedCombatAttributes(ped, 3, false)
    SetPedFleeAttributes(ped, 0, true)

    if (dest == HQArrival.Pos) then
      table.insert(toTable, {ent = ped, group = index, post = pos, heading = postHeading})
    else
      table.insert(toTable, {ent = ped, group = index, post = pos, heading = postHeading, caller = caller})
    end

  end

  if (dest == HQArrival.Pos) then
    SecurityGuards[index] = toTable
    TriggerServerEvent('esx_mob:setSecurity', SecurityGuards)
    SecurityGroups[index] = false
  else
    BodyGuards[index] = toTable
    BodyGuardsGroups[index] = false
    -- TODO: add this event and finish this
    --TriggerServerEvent('esx_mob:setBodyguards', BodyGuards)
  end
  isSpawningBackup = false
end

-- Check if anyone is alive
-- should this be server side?
function CheckSecurity()
  print('esx_mob: checking security')

  -- I can't check security while calling security or the tables won't be correct
  -- I could implement a function to check if a current group was already being called
  -- but for now....
  -- while isCallingSecurity do
  --   Citizen.Wait(5000)
  -- end
  -- Iterate trough security table
  for i,t in pairs(SecurityGuards) do
    if (SecurityGroups[i] == false) then
      if (table.empty(t)) then
        print('There is no one alive in:', i)
        if not isCallingSecurity then
          print("Calling security")
          isCallingSecurity = true
          SecurityGroups[i] = true
          CallSecurityToHQ(i)
        end
      else
        print('There are npcs in:', i)
        for a,v in pairs(t) do
          local ped = v.ent
          local isDead = IsPedDeadOrDying(ped, 1)
          -- check if dead, remove and set as no longer needed
          if isDead then
            print(ped)
            print('is dead')
            ClearPedTasksImmediately(ped)
            SetEntityAsNoLongerNeeded(ped)
            RemovePedElegantly(ped)
            table.remove(t, a)
            for n,e in pairs(Travelling) do
              if (ped == e.ent) then
                table.remove(Travelling, n)
              end
            end
          end
        end
      end
    end
  end
  -- Wait 5 seconds and recurse
  Citizen.Wait(10000)
  CheckSecurity()
end

-- Spawn at configured pos and travel to HQ
function CallSecurityToHQ(index)
  local sp      = SecuritySpawnPoints.Docks1.Pos
  local heading = SecuritySpawnPoints.Docks1.Heading
  local dest    = HQArrival.Pos

  SpawnBackupVehicleCrew(index, sp, heading, dest, "HQ")

  isCallingSecurity = false
end

-- Function for spawing security at defined hq
function SpawnSecurity(index)
  LogAndTrace('Spawning security', {group = index}, 'info')
  isSpawningSecurity = true
  for i,t in pairs(Config.SecurityGuards) do
    local toTable = {}
    if (index == i) then
      local isLeader = false
      for _,v in pairs(t) do
        local hash = WaitForHash(defaultNPC)
        local group = SecurityGroup
        local pos       = v.Pos
        local heading   = v.Heading
        local ped       = CreatePed(v.PedType, hash, pos.x, pos.y, pos.z, heading, true, true)
        local weapon = GetHashKey('WEAPON_GUSENBERG')
        local sidearm = GetHashKey('WEAPON_PISTOL')

        Citizen.Wait(200)

        if not (isLeader) then
          DressAsMob(ped, true)
          GiveWeaponToPed(ped, weapon, 0, 1)
          TaskStartScenarioInPlace(ped, "WORLD_HUMAN_SMOKING", 0, true)
          -- Set firing to full auto
          SetPedFiringPattern(ped, -957453492)
          SetPedChanceOfFiringBlanks(ped, 1.0, 1.0)
          isLeader = true
        else
          DressAsMob(ped, false)
          GiveWeaponToPed(ped, sidearm, 0, 1)
          SetPedChanceOfFiringBlanks(ped, 10.0, 10.0)
          TaskStandGuard(ped, pos.x, pos.y, pos.z, heading, 'WORLD_HUMAN_MOB_GUARDS')
        end
        SetPedRelationshipGroupHash(ped, group)
        SetPedNeverLeavesGroup(ped, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetPedCombatAttributes(ped, 46, true)
        SetPedFleeAttributes(ped, 0, 0)
        SetPedDropsWeaponsWhenDead(ped, false)
        table.insert(toTable, {ent = ped, group = index, post = pos, heading = heading})
      end
      print('esx_mob_SpawnSecurity: index is:', index)
      SecurityGuards[index] = toTable
    end
  end
  TriggerServerEvent('esx_mob:setSecurity', SecurityGuards)
  isSpawningSecurity = false
end

-- args: ped, group defined in config, vehicle, destination
function TravelToPos(ped, group, vehicle, dest, caller)
  -- Wait for everyone to enter vehicle
  -- Possible driving modes, best seem to be 1074528293 doesn't overpass, 8388614 rams gate doesn't take shortest path, 786603 normal
  -- 16777216 Seems the same as 5 , 5 No Clue, 2883621 ??fast/normal/offroad/inside buildings??, 786603 this is normal,
  -- 262144 - Take shortest path (Removes most pathing limits) also rams cars, 524288 stays on same lane but tries to overpass,
  -- 536870912 - Rush b cyka, 64 - seems as bad or worst as the one before
  TaskVehicleDriveToCoordLongrange(ped, vehicle, dest.x, dest.y, dest.z, 25.0, 8388614, 10.0)
  if (dest == HQArrival.Pos) then
    table.insert(Travelling, {ent = ped, group = group, vehicle = vehicle, dest = dest})
  else
    table.insert(Travelling, {ent = ped, group = group, vehicle = vehicle, caller = caller, dest = dest})
  end
end

-- check if npc has arrived at location
function CheckHasArrived()
  local isLeader = false
  if not (isSpawningBackup) then
    if not (table.empty(Travelling)) then
      local toCheck = nil
      for i,v in pairs(Travelling) do
        if not (BodyGuardsGroups[v.group]) or not (SecurityGroups[v.group]) then
          local wasCalled = false
          if (v.caller ~= nil) then
            wasCalled = true
            toCheck = BodyGuards
          else
            toCheck = SecurityGuards
          end
          local group = v.group
          local vCoord = GetEntityCoords(v.vehicle)
          local dest = v.dest
          -- IsVehicleStopped might be a problem if the vehicle gets stuck but might also help unstuck it
          if (GetDistanceBetweenCoords(vCoord.x, vCoord.y, vCoord.z, dest.x, dest.y , dest.z, true) <= 20.0) then
            print("Emptying vehicle")
            -- TaskEveryoneLeaveVehicle does not seem to work
            for _,e in pairs(toCheck[group]) do
              local ped = e.ent
              local pos = e.post
              local heading = e.heading
              TaskLeaveVehicle(ped, v.vehicle, 0)
              if not isLeader then
                if wasCalled then
                  TaskGoToEntity(ped, v.caller, -1, 4.0, 10.0, 0,0)
                else
                  TaskStandGuard(ped, pos.x, pos.y, pos.z, heading, 'WORLD_HUMAN_MOB_GUARDS')
                  --TaskStartScenarioInPlace(v.ent, 'WORLD_HUMAN_SMOKING', 0, true)
                  isLeader = true
                end
              else
                if wasCalled then
                  TaskGoToEntity(ped, v.caller, -1, 4.0, 10.0, 0,0)
                else
                  TaskStandGuard(ped, pos.x, pos.y, pos.z, heading, 'WORLD_HUMAN_MOB_GUARDS')
                end
              end
              -- The vehicle does not seem to despawn
              SetVehicleAsNoLongerNeeded(v.vehicle)
            end
            print("Done")
            table.remove(Travelling, i)
          end
        else
          print("Group is being called:", v.group)
        end
      end
    end
  else
    LogAndTrace("npcs spawning or being called waiting...", {}, "info")
  end
  Citizen.Wait(2000)
  CheckHasArrived()
end

-- Checks for bodyguards
function FollowAndProtect()
  if not isCallingBodyguards then

    for i,v in pairs(BodyGuards) do
      if not BodyGuardsGroups[i] and not table.empty(v) then
        local seat = 0
        local model = nil
        local seats = nil
        for n,e in pairs(v) do
          local leader = e.caller
          local ped = e.ent
          local isDead = IsPedDeadOrDying(ped, 1)
          local leaderVehicle = GetVehiclePedIsIn(leader,false)
          local followerVehicle = GetVehiclePedIsIn(ped,false)
          if isDead then
            SetEntityAsNoLongerNeeded(ped)
            table.remove(v, n)
          else
            while (GetIsTaskActive(leader, 160) == 1) do
              Citizen.Wait(1000)
            end
            if (leaderVehicle == 0) then
              model = nil
              seats = nil
              seat = 0
              if (followerVehicle ~= 0) then
                TaskLeaveVehicle(ped, e.vehicle, 0)
              else
                -- Just goes to entity disregarding world events
                --TaskGoToEntity(ped, leader, -1, 4.0, 10.0, 0,0)
                local x,y,z = table.unpack(GetEntityCoords(leader))
                TaskGoToCoordAndAimAtHatedEntitiesNearCoord(ped, x,y,z,x,y,z, 2.0,true, 3.0,0.0, true, 1,1,3337513804)
              end
            elseif (leaderVehicle ~= 0) then
              if not model or not seats then
                model = GetEntityModel(leaderVehicle)
                seats = GetVehicleModelNumberOfSeats(model)
              end
              if (leaderVehicle ~= followerVehicle) then
                if (followerVehicle ~= 0) then
                  TaskLeaveVehicle(ped, followerVehicle, 0)
                else
                  TaskEnterVehicle(ped, leaderVehicle, 5000,seat, 2.0, 1, 0)
                  if (seat < seats) then
                    seat = seat + 1
                  else
                    print("no seats available resetting...")
                    seat = 0
                  end
                  Citizen.Wait(1000)
                  e["vehicle"] = leaderVehicle
                end
              end
            end
          end
        end
      else
        LogAndTrace(string.format("%s is spawning, or table is empty", i), {}, "info")
      end
    end
  else
    LogAndTrace("Bodyguards being called, waiting...", {}, "info")
  end
  Citizen.Wait(1000)
  FollowAndProtect()
end


-- Opens impounded vehicles menu, Location = City impound
function OpenImpoundMenu()

  ESX.UI.Menu.CloseAll()

  local elements = {}

  ESX.TriggerServerCallback('esx_mob:getSocietyVehicles', function(vehicles)

    for _,v in pairs(vehicles) do
      local vehicleHash = v.vehicle.model
      local vehicleName = GetDisplayNameFromVehicleModel(vehicleHash)
      local labelvehicle
      local plate = v.plate

      -- If vehicle is not stored v.state = 0
      if not (v.state) then
        labelvehicle = vehicleName.. ' (' .. plate .. ') ' .._U('impound')
        table.insert(elements, {label =labelvehicle , value = v})
      end
    end

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'society_vehicles',
      {
        title    = _U('society_vehicles'),
        align    = 'top-left',
        elements = elements,
      },
      function (data, menu)
        local playerPed     = PlayerPedId()
        local coords        = impoundSpawn
        local vehicleData   = data.current.value
        local vehicle       = vehicleData.vehicle
        local vehEnt        = nil
        local vehiclePrice  = nil

        if not (data.current.value.state) then
          menu.close()

          -- Charge Player for vehicle retrieval

          for i=1, #Vehicles, 1 do
            if GetHashKey(Vehicles[i].model) == vehicle.model then
              print("Found Vehicle")
              vehiclePrice = Vehicles[i].price
              break
            end
          end

          print("Price is: ")
          print(vehiclePrice)

          local impoundPrice = math.floor(vehiclePrice / 100 * Config.ResellPercentage)

          ESX.TriggerServerCallback('esx_mob:retrieveFromImpound', function(hasEnoughMoney)
            if hasEnoughMoney then
              -- check if vehicle is out and delete it from game and InUseVehicles
              for i,v in pairs(InUseVehicles) do
                if(vehicleData.plate == v.plate) then
                  print("Deleting vehicle: " .. v.vehicle)
                  vehiclePrice = vehicleData.price
                  SetEntityAsNoLongerNeeded(v.vehicle)
                  ESX.Game.DeleteVehicle(v.vehicle)
                  table.remove(InUseVehicles, i)
                  break
                end
              end
              -- Add vehicle to InUseVehicles spawn it and set as mission entity
              SpawnVehicle(coords, playerPed, vehicle, vehicleData.plate)
              -- 500 Should be enough to spawn vehicle to obtain entity
              Citizen.Wait(500)
              vehEnt = GetVehiclePedIsIn(playerPed)
              print("Vehicle entity: " .. vehEnt)
              table.insert(InUseVehicles, {plate = vehicleData.plate, vehicle = vehEnt})
              -- TO REMOVE -->
              for _,v in  pairs(InUseVehicles) do
                print("Id in table is: " .. v.vehicle)
              end
              SetEntityAsMissionEntity(vehEnt, true, true)
            else
              TriggerEvent('esx:showNotification', _U('not_enough_money'))
            end
          end, impoundPrice)
        else
          TriggerEvent('esx:showNotification', _U('vehicle_is_out'))
        end
      end,
      function (data, menu)
        menu.close()
      end
    )

  end)
end

-- Return dealership vehicle to provider
function ReturnVehicleProvider()
	ESX.TriggerServerCallback('esx_mob:getCommercialVehicles', function (vehicles)
		local elements = {}
		local returnPrice
		for i=1, #vehicles, 1 do
			returnPrice = ESX.Round(vehicles[i].price * 0.75)

			table.insert(elements, {
				label = vehicles[i].name .. ' [<span style="color: orange;">$' .. returnPrice .. '</span>]',
				value = vehicles[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'return_provider_menu',
		{
			title    = _U('return_provider_menu'),
			align    = 'top-left',
			elements = elements
		}, function (data, menu)
			TriggerServerEvent('esx_mob:returnProvider', data.current.value)

			Citizen.Wait(300)
			menu.close()

			ReturnVehicleProvider()
		end, function (data, menu)
			menu.close()
		end)
	end)
end

-- Open vehicleshop menu
function OpenShopMenu ()
  IsInShopMenu = true

  ESX.UI.Menu.CloseAll()

  local playerPed = PlayerPedId()

  FreezeEntityPosition(playerPed, true)
  SetEntityVisible(playerPed, false)
  SetEntityCoords(playerPed, Config.Zones.MobVehicleInside.Pos.x, Config.Zones.MobVehicleInside.Pos.y, Config.Zones.MobVehicleInside.Pos.z)

  local vehiclesByCategory = {}
  local elements           = {}
  local firstVehicleData   = nil

  for i=1, #Categories, 1 do
    vehiclesByCategory[Categories[i].name] = {}
  end

  for i=1, #Vehicles, 1 do
    table.insert(vehiclesByCategory[Vehicles[i].category], Vehicles[i])
  end

  for i=1, #Categories, 1 do
    local category         = Categories[i]
    local categoryVehicles = vehiclesByCategory[category.name]
    local options          = {}

    for j=1, #categoryVehicles, 1 do
      local vehicle = categoryVehicles[j]

      if i == 1 and j == 1 then
        firstVehicleData = vehicle
      end

      table.insert(options, vehicle.name .. ' <span style="color: green;">$' .. vehicle.price .. '</span>')
    end

    table.insert(elements, {
      name    = category.name,
      label   = category.label,
      value   = 0,
      type    = 'slider',
      max     = #Categories[i],
      options = options
    })
  end


  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'vehicle_shop',
    {
      title    = _U('mafia'),
      align    = 'top-left',
      elements = elements
    },
    function (data, menu)
      local vehicleData = vehiclesByCategory[data.current.name][data.current.value + 1]

      ESX.UI.Menu.Open(
        'default', GetCurrentResourceName(), 'shop_confirm',
        {
          title = _U('buy_vehicle_shop', vehicleData.name, vehicleData.price),
          align = 'top-left',
          elements = {
            {label = _U('yes'), value = 'yes'},
            {label = _U('no'),  value = 'no'},
          },
        },
        function (data2, menu2)
          if data2.current.value == 'yes' then
            if Config.EnablePlayerManagement then
              ESX.TriggerServerCallback('esx_mob:buyVehicleSociety', function (hasEnoughMoney)
                if hasEnoughMoney then
                  IsInShopMenu = false

                  DeleteShopInsideVehicles()

                  local playerPed = PlayerPedId()

                  CurrentAction     = 'shop_menu'
                  CurrentActionMsg  = _U('shop_menu')
                  CurrentActionData = {}

                  FreezeEntityPosition(playerPed, false)
                  SetEntityVisible(playerPed, true)
                  SetEntityCoords(playerPed, Config.Zones.MobVehicleShop.Pos.x, Config.Zones.MobVehicleShop.Pos.y, Config.Zones.MobVehicleShop.Pos.z)

                  menu2.close()
                  menu.close()

                  ESX.ShowNotification(_U('vehicle_purchased'))
                else
                  ESX.ShowNotification(_U('broke_company'))
                end

              end, 'mafia', vehicleData.model)
            else
              local playerData = ESX.GetPlayerData()

              if Config.EnableSocietyOwnedVehicles and playerData.job.grade_name == 'boss' then
                ESX.UI.Menu.Open(
                  'default', GetCurrentResourceName(), 'shop_confirm_buy_type',
                  {
                    title = _U('purchase_type'),
                    align = 'top-left',
                    elements = {
                      {label = _U('staff_type'),   value = 'personnal'},
                      {label = _U('society_type'), value = 'society'},
                    },
                  },
                  function (data3, menu3)

                    if data3.current.value == 'personnal' then
                      ESX.TriggerServerCallback('esx_mob:buyVehicle', function (hasEnoughMoney)
                        if hasEnoughMoney then
                          IsInShopMenu = false

                          menu3.close()
                          menu2.close()
                          menu.close()

                          DeleteShopInsideVehicles()

                          -- Replace with SpawnVehicle
                          ESX.Game.SpawnVehicle(vehicleData.model, vehicleExit.Pos, vehicleExit.Heading, function (vehicle)

                            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

                            local newPlate     = GeneratePlate()
                            local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
                            vehicleProps.plate = newPlate
                            SetVehicleNumberPlateText(vehicle, newPlate)

                            if Config.EnableOwnedVehicles then
                              TriggerServerEvent('esx_mob:setVehicleOwned', vehicleProps)
                            end

                            ESX.ShowNotification(_U('vehicle_purchased'))
                          end)

                          FreezeEntityPosition(playerPed, false)
                          SetEntityVisible(playerPed, true)
                        else
                          ESX.ShowNotification(_U('not_enough_money'))
                        end
                      end, vehicleData.model)
                    end

                    if data3.current.value == 'society' then
                      ESX.TriggerServerCallback('esx_mob:buyVehicleSociety', function (hasEnoughMoney)
                        if hasEnoughMoney then

                          IsInShopMenu = false

                          menu3.close()
                          menu2.close()
                          menu.close()

                          DeleteShopInsideVehicles()

                          -- Replace with SpawnVehicle
                          ESX.Game.SpawnVehicle(vehicleData.model, vehicleExit.Pos, vehicleExit.Heading, function (vehicle)

                            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

                            local newPlate     = GeneratePlate()
                            local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
                            vehicleProps.plate = newPlate
                            SetVehicleNumberPlateText(vehicle, newPlate)

                            TriggerServerEvent('esx_mob:setVehicleOwnedSociety', playerData.job.name, vehicleProps)

                            ESX.ShowNotification(_U('vehicle_purchased'))

                          end)

                          FreezeEntityPosition(playerPed, false)
                          SetEntityVisible(playerPed, true)
                        else
                          ESX.ShowNotification(_U('broke_company'))
                        end
                      end, playerData.job.name, vehicleData.model)
                    end
                  end,
                  function (data3, menu3)
                    menu3.close()
                  end
                )
              else
                ESX.TriggerServerCallback('esx_mob:buyVehicle', function (hasEnoughMoney)
                  if hasEnoughMoney then

                    IsInShopMenu = false

                    menu2.close()
                    menu.close()

                    DeleteShopInsideVehicles()

                    -- Replace with SpawnVehicle
                    ESX.Game.SpawnVehicle(vehicleData.model, vehicleExit.Pos, vehicleExit.Heading, function (vehicle)

                      TaskWarpPedIntoVehicle(playerPed, vehicle, -1)

                      local newPlate     = GeneratePlate()
                      local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
                      vehicleProps.plate = newPlate
                      SetVehicleNumberPlateText(vehicle, newPlate)

                      if Config.EnableOwnedVehicles then
                        TriggerServerEvent('esx_mob:setVehicleOwned', vehicleProps)
                      end

                      ESX.ShowNotification(_U('vehicle_purchased'))
                    end)

                    FreezeEntityPosition(playerPed, false)
                    SetEntityVisible(playerPed, true)
                  else
                    ESX.ShowNotification(_U('not_enough_money'))
                  end
                end, vehicleData.model)
              end
            end
          end

          if data2.current.value == 'no' then

          end

        end,
        function (data2, menu2)
          menu2.close()
        end
      )

    end,
    function (data, menu)

      menu.close()

      DeleteShopInsideVehicles()

      local playerPed = PlayerPedId()

      CurrentAction     = 'shop_menu'
      CurrentActionMsg  = _U('shop_menu')
      CurrentActionData = {}

      FreezeEntityPosition(playerPed, false)
      SetEntityVisible(playerPed, true)
      SetEntityCoords(playerPed, Config.Zones.MobVehicleShop.Pos.x, Config.Zones.MobVehicleShop.Pos.y, Config.Zones.MobVehicleShop.Pos.z)

      IsInShopMenu = false

    end,
    function (data, menu)
      local vehicleData = vehiclesByCategory[data.current.name][data.current.value + 1]
      local playerPed   = PlayerPedId()

      DeleteShopInsideVehicles()

      ESX.Game.SpawnLocalVehicle(vehicleData.model, Config.Zones.MobVehicleInside.Pos, Config.Zones.MobVehicleInside.Heading, function (vehicle)
        table.insert(LastVehicles, vehicle)
        TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
        FreezeEntityPosition(vehicle, true)
      end)
    end
  )

  DeleteShopInsideVehicles()

  ESX.Game.SpawnLocalVehicle(firstVehicleData.model, Config.Zones.MobVehicleInside.Pos, Config.Zones.MobVehicleInside.Heading, function (vehicle)
    table.insert(LastVehicles, vehicle)
    TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
    FreezeEntityPosition(vehicle, true)
  end)
end

-- Puts a vehicle on display in the selected available zone
function PutOutForSale()
	-- Close all menus
  ESX.UI.Menu.CloseAll()
  -- local sellZones and vehiclesForSale
  local spots   = {}
  local forSale = {}
  print("Put For sale")
  -- Callback to get vehicles for sale
  ESX.TriggerServerCallback('esx_mob:getForSale', function(vehiclesForSale)
    onSale = vehiclesForSale
    -- Check if there are vehicles for sale or not
    print('esx_mob:getForSale', vehiclesForSale)
    for _,v in pairs(vehiclesForSale) do
      -- If vehicle is not nill add it to value
      if v.value ~= nil then
        table.insert(spots, {
          name  = tostring(v.label),
          label = tostring(v.label) .. ' <span style="color: red;">' .. _U('occupied'),
          value	= tostring(v.value),
        })
      -- If vehicle is nill value is nil
      else
        table.insert(spots, {
          name  = tostring(v.label),
          label = tostring(v.label) .. ' <span style="color: green;">' .. _U('empty'),
          value	= 'nil',
        })
      end
    end

    ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'vehicles_out',
		{
			title    = _U('vehicles_for_sale'),
			align    = 'top-left',
			elements = spots
    },
    function (data, menu)
		  -- If there is no vehicle continue
      if string.find(data.current.label, 'Empty') then

			  -- Get commercial vehicles
				ESX.TriggerServerCallback('esx_mob:getCommercialVehicles', function (vehicles)

				  -- Create local elements
					local elements	=	{}

          -- Add commercial vehicles to local elements
          -- contains stored value on database
          -- Do not forget to change it after spawning
          for i=1, #vehicles, 1 do
            if vehicles[i].stored == false then
              table.insert(elements, {
                id      = vehicles[i].id,
                label   = vehicles[i].name .. ' [MSRP <span style="color: green;">$' .. vehicles[i].price .. '</span>]',
                value   = vehicles[i].name
              })
            end
					end

				  -- Open commercial vehicles menu
          ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'commercial_vehicles',
            {
              title    = _U('mafia'),
              align    = 'top-left',
              elements = elements
            },
            function (data2, menu2)
              local model = data2.current.value
              local zone	=	Config.SellZones[data.current.name]

              -- Replace with SpawnVehicle
              ESX.Game.SpawnVehicle(model, zone.Pos, zone.Heading, function (vehicle)
                SetEntityAsMissionEntity(vehicle, true, true)
                SetVehicleDoorsLocked(vehicle, 2)
                TriggerServerEvent('esx_mob:setVehicleDisplay', 1, data2.current.id, data.current.name, vehicle)
              end)

              -- close menu manually
              menu2.close()
            end,
            -- Why is this not called? or when is this called
            function (data2, menu2)
              Citizen.Trace('function (data2, menu2)')
              menu2.close()
            end)
        end)
		  -- If there is a vehicle trigger notification
			else
				TriggerEvent('esx:showNotification', _U('zone_occupied'))
      end
      -- close menu manually and open reseller
      menu.close()
      OpenResellerMenu()
    end,
    -- Why is this only called when it succeeds
    function (data, menu)
      print('function (data, menu)')
      menu.close()
    end
    )
  end)
end

function StoreOnSale()
  -- Close all menus
  ESX.UI.Menu.CloseAll()

  local spots = {}

  -- Check if there are vehicles for sale or not
  for _,v in pairs(onSale) do
		-- If vehicle is not nill add it to value
		if v.value ~= nil then
			table.insert(spots, {
        name  = v.label,
				label = tostring(v.label) .. ' <span style="color: red;">' .. _U('occupied'),
				value	= v.value,
			})
		-- If vehicle is nill replace value with nil
		else
			table.insert(spots, {
        name  = v.label,
				label = tostring(v.label) .. ' <span style="color: green;">' .. _U('empty'),
				value	= 'nil',
			})
		end
  end

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'vehicles_out',
		{
			title    = _U('vehicles_for_sale'),
			align    = 'top-left',
			elements = spots
    },
    function (data, menu)
      -- If there is no vehicle trigger notification else continue
      -- maybe just check if value is nil
      if string.find(data.current.label, 'Empty') then
        TriggerEvent('esx:showNotification', _U('zone_clear'))
      else
        local veh_to_del = data.current.value
        local id_to_del = nil

        SetEntityAsNoLongerNeeded(veh_to_del)
        ESX.Game.DeleteVehicle(veh_to_del)

        for _,v in pairs(vehiclesForSale) do
          if v.label == data.current.name then
            v.value   = nil
            id_to_del = v.id
            v.id      = nil
          end
        end

        TriggerServerEvent('esx_mob:setVehicleDisplay', 0, id_to_del)

      end
      -- close menu
      menu.close()
    end,
    -- Why is this also not called
    function (data, menu)
      Citizen.Trace('hey3')
      menu.close()
    end
  )
end

-- Opens vehicle dealer menu
function OpenResellerMenu ()

  -- Close all menus
  ESX.UI.Menu.CloseAll()

  -- Open resseller menu and create labels with values
  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'reseller',
    {
      title    = _U('mafia'),
      align    = 'top-left',
      elements = {
        {label = _U('buy_vehicle'),                    value = 'buy_vehicle'},
        {label = _U('buy_society'),                    value = 'buy_society'},
        {label = _U('put_for_sale'),                   value = 'put_for_sale'},
        {label = _U('store_on_sale'),                  value = 'store_on_sale'},
        {label = _U('pop_vehicle'),                    value = 'pop_vehicle'},
        {label = _U('depop_vehicle'),                  value = 'depop_vehicle'},
        {label = _U('return_provider'),                value = 'return_provider'},
        {label = _U('create_bill'),                    value = 'create_bill'},
        {label = _U('set_vehicle_owner_sell'),         value = 'set_vehicle_owner_sell'},
        {label = _U('set_vehicle_owner_sell_society'), value = 'set_vehicle_owner_sell_society'},
      }
    },
    function (data, menu)

      -- Check which label was selected by value and execute corresponding functions
      local action = data.current.value

      if action == 'buy_vehicle' then
        OpenShopMenu()
      elseif action == 'put_stock' then
        OpenPutStocksMenu()
      elseif action == 'get_stock' then
        OpenGetStocksMenu()
      elseif action == 'pop_vehicle' then
        OpenPopVehicleMenu()
      elseif action == 'depop_vehicle' then
        DeleteShopInsideVehicles()
      elseif action == 'return_provider' then
        ReturnVehicleProvider()
      elseif action == 'create_bill' then
        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
        if closestPlayer == -1 or closestDistance > 3.0 then
          ESX.ShowNotification(_U('no_players'))
          return
        end
        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'set_vehicle_owner_sell_amount',
          {
            title = _U('invoice_amount'),
          },
          function (data2, menu)

            local amount = tonumber(data2.value)

            if amount == nil then
              ESX.ShowNotification(_U('invoice_amount'))
            else
              menu.close()

              local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

              if closestPlayer == -1 or closestDistance > 3.0 then
                ESX.ShowNotification(_U('no_players'))
              else
                TriggerServerEvent('esx_billing:sendBill', GetPlayerServerId(closestPlayer), 'society_mafia', _U('mafia'), tonumber(data2.value))
              end
            end
          end,
          function (data2, menu)
            menu.close()
          end
        )

      elseif action == 'set_vehicle_owner_sell' then
        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

        if closestPlayer == -1 or closestDistance > 3.0 then
          ESX.ShowNotification(_U('no_players'))
        else

          local newPlate     = GeneratePlate()
          local vehicleProps = ESX.Game.GetVehicleProperties(LastVehicles[#LastVehicles])
          local model        = CurrentVehicleData.model
          vehicleProps.plate = newPlate
          SetVehicleNumberPlateText(LastVehicles[#LastVehicles], newPlate)


          TriggerServerEvent('esx_mob:sellVehicle', model)

          if Config.EnableOwnedVehicles then
            TriggerServerEvent('esx_mob:setVehicleOwnedPlayerId', GetPlayerServerId(closestPlayer), vehicleProps)
            ESX.ShowNotification(_U('vehicle_set_owned', vehicleProps.plate, GetPlayerName(closestPlayer)))
          else
            ESX.ShowNotification(_U('vehicle_sold_to', vehicleProps.plate, GetPlayerName(closestPlayer)))
          end
        end
      elseif action == 'set_vehicle_owner_sell_society' then
        local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

        if closestPlayer == -1 or closestDistance > 3.0 then
          ESX.ShowNotification(_U('no_players'))
        else
          ESX.TriggerServerCallback('esx:getOtherPlayerData', function (xPlayer)
            local newPlate     = GeneratePlate()
            local vehicleProps = ESX.Game.GetVehicleProperties(LastVehicles[#LastVehicles])
            local model        = CurrentVehicleData.model
            vehicleProps.plate = newPlate
            SetVehicleNumberPlateText(LastVehicles[#LastVehicles], newPlate)

            TriggerServerEvent('esx_mob:sellVehicle', model)

            if Config.EnableSocietyOwnedVehicles then
              TriggerServerEvent('esx_mob:setVehicleOwnedSociety', xPlayer.job.name, vehicleProps)
              ESX.ShowNotification(_U('vehicle_set_owned', vehicleProps.plate, GetPlayerName(closestPlayer)))
            else
              ESX.ShowNotification(_U('vehicle_sold_to', vehicleProps.plate, GetPlayerName(closestPlayer)))
            end

            DeleteShopInsideVehicles()

          end, GetPlayerServerId(closestPlayer))
        end
      elseif action == 'set_vehicle_owner_rent' then
        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'set_vehicle_owner_rent_amount',
          {
            title = _U('rental_amount'),
          },
          function (data2, menu)
            local amount = tonumber(data2.value)

            if amount == nil then
              ESX.ShowNotification(_U('invalid_amount'))
            else
              menu.close()

              local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()

              if closestPlayer == -1 or closestDistance > 5.0 then
                ESX.ShowNotification(_U('no_players'))
              else

                local newPlate     = 'RENT' .. string.upper(ESX.GetRandomString(4))
                local vehicleProps = ESX.Game.GetVehicleProperties(LastVehicles[#LastVehicles])
                local model        = CurrentVehicleData.model
                vehicleProps.plate = newPlate
                SetVehicleNumberPlateText(LastVehicles[#LastVehicles], newPlate)

                TriggerServerEvent('esx_mob:rentVehicle', model, vehicleProps.plate, GetPlayerName(closestPlayer), CurrentVehicleData.price, amount, GetPlayerServerId(closestPlayer))

                if Config.EnableOwnedVehicles then
                  TriggerServerEvent('esx_mob:setVehicleOwnedPlayerId', GetPlayerServerId(closestPlayer), vehicleProps)
                end

                ESX.ShowNotification(_U('vehicle_set_rented', vehicleProps.plate, GetPlayerName(closestPlayer)))

                TriggerServerEvent('esx_mob:setVehicleForAllPlayers', vehicleProps, Config.Zones.MobVehicleInside.Pos.x, Config.Zones.MobVehicleInside.Pos.y, Config.Zones.MobVehicleInside.Pos.z, 5.0)
              end
            end
          end,
          function (data2, menu)
            menu.close()
          end
        )
      -- Purchase a vehicle for own society from society
      elseif action == 'buy_society' then
        BuyVehicleForSociety()
      elseif action == 'put_for_sale' then
        PutOutForSale()
      elseif  action == 'store_on_sale' then
        StoreOnSale()
      end
    end,
    function (data, menu)
      menu.close()

      CurrentAction     = 'reseller_menu'
      CurrentActionMsg  = _U('shop_menu')
      CurrentActionData = {}
    end
  )
end

-- Purchase a vehicle for your own society
function BuyVehicleForSociety ()
  -- get player source what is this??? what source
  local player = source

  -- check if no player selected useless since player is self TODO: remove
  if player == -1 then
    ESX.ShowNotification(_U('no_players'))
  else
    -- TriggerServerCallback to obtain other player data as job.name
    ESX.TriggerServerCallback('esx:getOtherPlayerData', function (xPlayer)

      -- Check if there is a vehicle in shop outside
      if CurrentVehicleData ~= nil then

        -- Get vehicle props create new plate and set it GenerateSocPlate takes a string of 3 letters to assign it to first letter of plate
        local newPlate     = GenerateSocPlate(SocNic)
        local vehicleProps = ESX.Game.GetVehicleProperties(LastVehicles[#LastVehicles])
        local model        = CurrentVehicleData.model
        vehicleProps.plate = newPlate
        SetVehicleNumberPlateText(LastVehicles[#LastVehicles], newPlate)

        -- Remove the vehicle from the mob database
        TriggerServerEvent('esx_mob:sellVehicle', model)

        -- Set vehicle owned to society and notify seller
        TriggerServerEvent('esx_mob:setVehicleOwnedSociety', xPlayer.job.name, vehicleProps)
        ESX.ShowNotification(_U('vehicle_set_owned', vehicleProps.plate, xPlayer.job.label))

        -- Delete the spawned vehicle outside shop
        DeleteShopInsideVehicles()

        -- Clean CurrentVehicleData DeleteShopInsideVehicles should do this however it is not working
        CurrentVehicleData = nil

      -- If there isn't a vehicle outside warn player
      else
        ESX.ShowNotification(_U('take_out_vehicle'))
      end

    end, GetPlayerServerId(player))
  end
end

-- Puts vehicle on display old To be removed...
function OpenPopVehicleMenu ()
	ESX.TriggerServerCallback('esx_mob:getCommercialVehicles', function (vehicles)
		local elements	=	{}

		for i=1, #vehicles, 1 do
			table.insert(elements, {
				label = vehicles[i].name .. ' [MSRP <span style="color: green;">$' .. vehicles[i].price .. '</span>]',
				value = vehicles[i].name
			})
		end

		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'commercial_vehicles',
		{
			title    = _U('mafia'),
			align    = 'top-left',
			elements = elements
		}, function (data, menu)
			local model = data.current.value

			DeleteShopInsideVehicles()

      -- Replace with SpawnVehicle
			ESX.Game.SpawnVehicle(model, vehicleExit.Pos, vehicleExit.Heading, function (vehicle)
				table.insert(LastVehicles, vehicle)

        SetVehicleDoorsLocked(vehicle, 2)

				for i=1, #Vehicles, 1 do
					if model == Vehicles[i].model then
						CurrentVehicleData = Vehicles[i]
					end
				end
			end)

		end, function (data, menu)
			menu.close()
		end)
	end)
end

-- Opens the society purchased vehicles menu
function OpenSocietyVehicleMenu ()

  ESX.UI.Menu.CloseAll()

  local elements = {}

  ESX.TriggerServerCallback('esx_mob:getSocietyVehicles', function (vehicles)


    for _,v in pairs(vehicles) do

			local vehicleModel = v.vehicle.model
    	local vehicleName = GetDisplayNameFromVehicleModel(vehicleModel)
    	local labelvehicle
			local plate = v.plate

    		if (v.state) and (v.stored) then
    		  labelvehicle = vehicleName.. ' (' .. plate .. ') ' .._U('garage')
    		else
    		  labelvehicle = vehicleName.. ' (' .. plate .. ') ' .._U('impound')
    		end
			table.insert(elements, {label =labelvehicle , value = v})
    end


    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'society_vehicles',
      {
        title    = _U('society_vehicles'),
        align    = 'top-left',
        elements = elements,
      },
      function (data, menu)
        local playerPed   = PlayerPedId()
        local coords      = vehicleExit
        local vehicleData = data.current.value
        local vehEnt     = nil

        if(data.current.value.state) then
          menu.close()
          SpawnVehicle(coords, playerPed, vehicleData.vehicle, vehicleData.plate)
          -- Should be enough to spawn vehicle and get the entity
          Citizen.Wait(500)
          vehEnt = GetVehiclePedIsIn(playerPed)
          print("Vehicle entity: " .. vehEnt)
          table.insert(InUseVehicles, {plate = vehicleData.plate, vehicle = vehEnt})
          TriggerServerEvent('esx_mob:removeVehicleFromGarage', vehicleData)
          TriggerEvent('esx:showNotification', 'c was greater')
          -- TriggerEvent('esx:showNotification', _U('vehicle_is_out'))
        else
          TriggerEvent('esx:showNotification', _U('vehicle_is_impound'))
        end
      end,
      function (data, menu)
        menu.close()
      end)
  end)
end

-- Opens boss actions menu
function OpenBossActionsMenu ()
  ESX.UI.Menu.CloseAll()

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'reseller',
    {
      title    = _U('mafia_boss'),
      align    = 'top-left',
      elements = {
        {label = _U('boss_actions'),   value = 'boss_actions'},
      },
    },
    function (data, menu)
      if data.current.value == 'boss_actions' then
        TriggerEvent('esx_society:openBossMenu', 'mafia', function(data, menu)
          menu.close()
        end)
      end
    end,
    function (data, menu)
      menu.close()

      CurrentAction     = 'boss_actions_menu'
      CurrentActionMsg  = _U('shop_menu')
      CurrentActionData = {}
    end
  )
end

-- Menu for fetching inventory items
function OpenGetStocksMenu ()
  ESX.TriggerServerCallback('esx_mob:getStockItems', function (items)
    local elements = {}

    for i=1, #items, 1 do
      table.insert(elements, {label = 'x' .. items[i].count .. ' ' .. items[i].label, value = items[i].name})
    end

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'stocks_menu',
      {
        title    = _U('mafia_stock'),
        align    = 'top-left',
        elements = elements
      },
      function (data, menu)
        local itemName = data.current.value

        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'stocks_menu_get_item_count',
          {
            title = _U('amount'),
          },
          function (data2, menu2)
            local count = tonumber(data2.value)

            if count == nil then
              ESX.ShowNotification(_U('quantity_invalid'))
            else
              TriggerServerEvent('esx_mob:getStockItem', itemName, count)
              menu2.close()
              menu.close()
              OpenGetStocksMenu()


            end
          end,
          function (data2, menu2)
            menu2.close()
          end
        )
      end,
      function (data, menu)
        menu.close()
      end
    )
  end)
end

-- Menu for storing in inventory
function OpenPutStocksMenu ()
  ESX.TriggerServerCallback('esx_mob:getPlayerInventory', function (inventory)
    local elements = {}

    for i=1, #inventory.items, 1 do
      local item = inventory.items[i]

      if item.count > 0 then
        table.insert(elements, {label = item.label .. ' x' .. item.count, type = 'item_standard', value = item.name})
      end
    end

    ESX.UI.Menu.Open(
      'default', GetCurrentResourceName(), 'stocks_menu',
      {
        title    = _U('inventory'),
        align    = 'top-left',
        elements = elements
      },
      function (data, menu)
        local itemName = data.current.value

        ESX.UI.Menu.Open(
          'dialog', GetCurrentResourceName(), 'stocks_menu_put_item_count',
          {
            title = _U('amount'),
          },
          function (data2, menu2)
            local count = tonumber(data2.value)

            if count == nil then
              ESX.ShowNotification(_U('quantity_invalid'))
            else
              TriggerServerEvent('esx_mob:putStockItems', itemName, count)
              menu2.close()
              menu.close()
              OpenPutStocksMenu()
            end

          end,
          function (data2, menu2)
            menu2.close()
          end
        )
      end,
      function (data, menu)
        menu.close()
      end
    )
  end)
end

-- This triggers when job is changed
-- Enable set blip Type based on player society
-- Take the chance to set group relationship based on player job
RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function (job)
	ESX.PlayerData.job = job

	if Config.EnablePlayerManagement then
    if ESX.PlayerData.job.name == 'mafia' and tonumber(ESX.PlayerData.job.grade) >= 3 then
      CheckAndSetRelationship('PLAYER', 0)
			Config.Zones.MobVehicleShop.Type 	 = 1
			Config.Zones.MobSocietyGarage.Type = 1

			if ESX.PlayerData.job.grade_name == 'boss' then
				Config.Zones.MobHeadquarters.Type = 1
			end

    else
      CheckAndSetRelationship('PLAYER', 4)
      Config.Zones.MobVehicleImpound.Type = -1
			Config.Zones.MobVehicleShop.Type 		= -1
			Config.Zones.MobHeadquarters.Type  	= -1
			Config.Zones.MobSocietyGarage.Type 	= -1
		end
	end
end)

-- Configure all menus based on marker entry
AddEventHandler('esx_mob:hasEnteredMarker', function (zone)
  if zone == 'MobVehicleShop' then
    if Config.EnablePlayerManagement then
      if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name == 'mafia' then
        CurrentAction     = 'reseller_menu'
        CurrentActionMsg  = _U('shop_menu')
        CurrentActionData = {}
      end
    else
      CurrentAction     = 'shop_menu'
      CurrentActionMsg  = _U('shop_menu')
      CurrentActionData = {}
    end
  end

  if zone == 'MobResellVehicle' then
    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) then
      local vehicle     = GetVehiclePedIsIn(playerPed, false)
      local vehicleData = nil

      for i=1, #Vehicles, 1 do
        if GetHashKey(Vehicles[i].model) == GetEntityModel(vehicle) then
          vehicleData = Vehicles[i]
          break
        end
      end

      local resellPrice = math.floor(vehicleData.price / 100 * Config.ResellPercentage)

      CurrentAction     = 'resell_vehicle'
      CurrentActionMsg  = _U('sell_menu', vehicleData.name, resellPrice)

      CurrentActionData = {
        vehicle = vehicle,
        price   = resellPrice
      }
    end
  end

  if zone == 'MobHeadquarters' and Config.EnablePlayerManagement and ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name == 'mafia' and ESX.PlayerData.job.grade_name == 'boss' then
    CurrentAction     = 'boss_actions_menu'
    CurrentActionMsg  = _U('boss_actions')
    CurrentActionData = {}
	end

	if zone == 'MobSocietyGarage' then
		CurrentAction			=	'society_vehicles'
		CurrentActionMsg	= _U('society_vehicles_menu')
		CurrentActionData	=	{}
  end

  if zone == 'MobSocietyGarageEntry' then
    local playerPed = PlayerPedId()

    if IsPedInAnyVehicle(playerPed, false) then
      local vehicle     = GetVehiclePedIsIn(playerPed, false)
      CurrentAction			=	'store_vehicle'
      CurrentActionMsg	= _U('store_vehicle')
      CurrentActionData	=	{
        vehicle = vehicle
      }
    else
      TriggerEvent('esx:showNotification', _U('no_vehicle'))
    end
  end

  if zone == 'MobVehicleImpound' then
    CurrentAction     = 'mob_vehicle_impound'
    CurrentActionMsg  = _U('impound')
    CurrentActionData = {}
  end
end)

-- Close all menus on marker exit
AddEventHandler('esx_mob:hasExitedMarker', function (zone)
	if not IsInShopMenu then
		ESX.UI.Menu.CloseAll()
	end

	CurrentAction = nil
end)

-- Load society contact for all players
if Config.EnablePlayerManagement then
	RegisterNetEvent('esx_phone:loaded')
	AddEventHandler('esx_phone:loaded', function (phoneNumber, contacts)
		local specialContact = {
			name       = _U('mafia'),
			number     = 'mafia',
			base64Icon = ' data:image/png;base64,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',
		}

    TriggerEvent('esx_phone:addSpecialContact', specialContact.name, specialContact.number, specialContact.base64Icon)
	end)
end

-- Create Blip
Citizen.CreateThread(function ()
	local blip = AddBlipForCoord(Config.Zones.MobVehicleShop.Pos.x, Config.Zones.MobVehicleShop.Pos.y, Config.Zones.MobVehicleShop.Pos.z)

	SetBlipSprite (blip, 477)
  SetBlipColour(blip, 40)
	SetBlipDisplay(blip, 4)
	SetBlipScale  (blip, 1.0)
	SetBlipAsShortRange(blip, true)

	BeginTextCommandSetBlipName("STRING")
	AddTextComponentString(_U('mafia'))
	EndTextCommandSetBlipName(blip)
end)

-- Display markers
Citizen.CreateThread(function ()
	while true do
		Citizen.Wait(0)

		local coords = GetEntityCoords(PlayerPedId())

		for k,v in pairs(Config.Zones) do
			if(v.Type ~= -1 and GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < Config.DrawDistance) then
				DrawMarker(v.Type, v.Pos.x, v.Pos.y, v.Pos.z, 0.0, 0.0, 0.0, 0, 0.0, 0.0, v.Size.x, v.Size.y, v.Size.z, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, false, false, false, false)
			end
		end
	end
end)

if Config.CheckSecurity then
  -- Check security after 20 seconds
  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(20000)
      CheckSecurity()
    end
  end)
end

Citizen.CreateThread(function()
  while true do
    Citizen.Wait(20000)
    FollowAndProtect()
  end
end)

-- check if npcs have arrived after 5 secs
Citizen.CreateThread(function()
  while true do
    Citizen.Wait(5000)
    CheckHasArrived()
  end
end)

-- Enter / Exit marker events
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		local coords      = GetEntityCoords(PlayerPedId())
		local isInMarker  = false
		local currentZone = nil

		for k,v in pairs(Config.Zones) do
			if(GetDistanceBetweenCoords(coords, v.Pos.x, v.Pos.y, v.Pos.z, true) < v.Size.x) then
				isInMarker  = true
				currentZone = k
			end
		end

		if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
			HasAlreadyEnteredMarker = true
			LastZone                = currentZone
			TriggerEvent('esx_mob:hasEnteredMarker', currentZone)
		end

		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('esx_mob:hasExitedMarker', LastZone)
		end
	end
end)

-- Key controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)

		if CurrentAction == nil then
			Citizen.Wait(200)
		else

			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, Keys['E']) then
				if CurrentAction == 'shop_menu' then
					OpenShopMenu()
				elseif CurrentAction == 'reseller_menu' then
					OpenResellerMenu()
				elseif CurrentAction == 'give_back_vehicle' then
					ESX.TriggerServerCallback('esx_mob:giveBackVehicle', function (isRentedVehicle)
						if isRentedVehicle then
							ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
							ESX.ShowNotification(_U('delivered'))
						else
							ESX.ShowNotification(_U('not_rental'))
						end
					end, GetVehicleNumberPlateText(CurrentActionData.vehicle))
				elseif CurrentAction == 'resell_vehicle' then
					ESX.TriggerServerCallback('esx_mob:resellVehicle', function (isOwnedVehicle)
						if isOwnedVehicle then
							ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
							ESX.ShowNotification(_U('vehicle_sold'))
						else
							ESX.ShowNotification(_U('not_yours'))
						end
					end, GetVehicleNumberPlateText(CurrentActionData.vehicle), CurrentActionData.price)
				elseif CurrentAction == 'boss_actions_menu' then
					OpenBossActionsMenu()
        elseif CurrentAction == 'mob_vehicle_impound' then
					OpenImpoundMenu()
				elseif CurrentAction == 'society_vehicles' then
          OpenSocietyVehicleMenu()
        elseif CurrentAction == 'store_vehicle' then
          local vehicle = CurrentActionData.vehicle
          local PlayerData = ESX.GetPlayerData()
          local plate = string.gsub(GetVehicleNumberPlateText(vehicle), '^%s*(.-)%s*$', '%1')

          ESX.TriggerServerCallback('esx_mob:storeVehicle', function(isOwnedVehicle)
            if isOwnedVehicle then
              for i,v in pairs(InUseVehicles) do
                print("Vehicle: " .. vehicle)
                print("v: " .. v.vehicle)
                if (vehicle == v.vehicle) then
                  table.remove(InUseVehicles, i)
                  break
                end
              end
              ESX.Game.DeleteVehicle(vehicle)
              CurrentActionData = {}
            else
              TriggerEvent('esx:showNotification', _U('not_yours'))
            end
          end, plate, PlayerData.job.name)

				end

				CurrentAction = nil
			end
		end
	end
end)
