local NumberCharset = {}
local Charset = {}
local defaultNPC              = Config.NPC

for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end

for i = 65,  90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

-- Function for generating plates
function GeneratePlate()
	local generatedPlate
	local doBreak = false

	while true do
		Citizen.Wait(2)
		math.randomseed(GetGameTimer())
		if Config.PlateUseSpace then
			generatedPlate = string.upper(GetRandomLetter(Config.PlateLetters) .. ' ' .. GetRandomNumber(Config.PlateNumbers))
		else
			generatedPlate = string.upper(GetRandomLetter(Config.PlateLetters) .. GetRandomNumber(Config.PlateNumbers))
		end

		ESX.TriggerServerCallback('esx_mob:isPlateTaken', function (isPlateTaken)
			if not isPlateTaken then
				doBreak = true
			end
		end, generatedPlate)

		if doBreak then
			break
		end
	end

	return generatedPlate
end

-- Function for generating society plates
function GenerateSocPlate(nick)
	local generatedPlate
	local doBreak = false
	local _nick = tostring(nick)

	if string.len(_nick) > 3 then
		return luaL_error(L, 'nick is too long for plate')
	else
		_nick = tostring(nick)


		while true do
			Citizen.Wait(2)
			math.randomseed(GetGameTimer())
			if Config.PlateUseSpace then
				generatedPlate = string.upper(_nick .. ' ' .. GetRandomNumber(Config.PlateNumbers))
			else
				generatedPlate = string.upper(_nick .. GetRandomNumber(Config.PlateNumbers))
			end

			ESX.TriggerServerCallback('esx_mob:isPlateTaken', function (isPlateTaken)
				if not isPlateTaken then
					doBreak = true
				end
			end, generatedPlate)

			if doBreak then
				break
			end
		end

		return generatedPlate
	end
end

-- Function to check if table empty see https://stackoverflow.com/a/10114940
function table.empty (self)
  for _, _ in pairs(self) do
      return false
  end
  return true
end

-- Function for spawning vehicles
function SpawnVehicle(coords, player, vehicle, plate)

  ESX.Game.SpawnVehicle(vehicle.model,{
    x=coords.Pos.x,
    y=coords.Pos.y,
    z=coords.Pos.z,
    },coords.Heading, function(callback_vehicle)
    ESX.Game.SetVehicleProperties(callback_vehicle, vehicle)
    SetVehRadioStation(callback_vehicle, "OFF")
    TaskWarpPedIntoVehicle(player, callback_vehicle, -1)
    end)
end

-- Is this being called?
-- mixing async with sync tasks
function IsPlateTaken(plate)
	local callback = 'waiting'

	ESX.TriggerServerCallback('esx_mob:isPlateTaken', function (isPlateTaken)
		callback = isPlateTaken
	end, plate)

	while type(callback) == 'string' do
		Citizen.Wait(0)
	end

	return callback
end

-- Function to wait for hash keys to load
function WaitForHash(model)
	if not model then return nil else
	  local hash = GetHashKey(model)
	    -- Make sure to wait before loading the hashes
	    while not HasModelLoaded(hash) do RequestModel(hash) Wait(100) end
	  return hash
	end
end

-- Function to check and set relationship: group must be string like "PLAYER" or "CUSTOM"
function CheckAndSetRelationship(group, val)
  local sec = GetHashKey(Config.Group)
  local other = GetHashKey(group)
	local isRelated = GetRelationshipBetweenGroups(other,sec)
  if (isRelated ~= val) or (isRelated ~= val) then
    SetRelationshipBetweenGroups(val,other,sec)
    SetRelationshipBetweenGroups(val,sec,other)
  else
    LogAndTrace('Relationship already exists between', { group = group, group, sec}, 'info')
  end
end

function GetRandomNumber(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
	else
		return ''
	end
end

function GetRandomLetter(length)
	Citizen.Wait(1)
	math.randomseed(GetGameTimer())
	if length > 0 then
		return GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
	else
		return ''
	end
end



-- Debug stuff

function CheckTypeAndReturn(val)
  local cases = {
    ["true"] = function() return true end,
    ["false"] = function() return false end,
    ["num"] = function(num) return tonumber(num) end
  }
  if tonumber(val) ~= nil then
    return cases['num'](val)
  elseif (val == "true") or (val == "false") then
    return cases[val]()
  else
    return val
  end
end

-- Check if Debugging is enabled and configure values accordingly
function CheckDebugging()
	if Debugging.EnableDebug then
		LogAndTrace('Debugging enabled', {}, 'info')
	else
		SetDebugValues(false)
	end
end

-- Set debug values to passed in boolean
function SetDebugValues(val)
	for _,v in pairs(Debugging) do
		if (type(v) ~= "table") then
			if (type(v) == "boolean") then
				v = val
			end
		else
			for _,n in pairs(v) do
				if (type(v) == "boolean") then
					n = val
				end
			end
		end
	end
	if not val then Debugging = nil end
end


-- text ..., params a table with name and value, type info/params/tables
function LogAndTrace(text, params, level)
	local caller = debug.getinfo(2)
	local c_name = caller.name or "Unknown"
	if Debugging.EnableLogging then
		local paramStr = ""
		if not table.empty(params) then
			for i,v in pairs(params) do
				if (type(v) == "table") then
					paramStr = string.format("%s %s: is table, ", paramStr, tostring(i))
				else
					paramStr = string.format("%s %s: %s, ", paramStr, tostring(i), tostring(v))
				end
			end
		end
		if (caller ~= nil) then
			if Debugging.LogLevels[level] then
				--if (paramStr == "") then Citizen.Trace('esx_mob_LogAndTrace: No parameters passed\n') end
				local finalStr = string.format("esx_mob_%s: %s %s\n", caller.name, text, paramStr)
				Citizen.Trace(finalStr)
			end
		end
	end
end



-- DEV COMMANDS
-- TOREMOVE
-- Make a civilian near player
if Debugging.EnableDevCommands then
	RegisterCommand('MakeCiv', function(source, args)
	  local id       = GetPlayerFromServerId(source)
	  local player   = GetPlayerPed(id)
	  local pos     = GetEntityCoords(player)
	  local heading      = GetEntityHeading(player)
	  local dict        = "amb@world_human_aa_smoke@male@idle_a"
	  local sceneTask   = "WORLD_HUMAN_SMOKING"
	  local hash         = WaitForHash(defaultNPC)
	  local ped          = CreatePed(10, hash, pos.x+1.0, pos.y+1.0, pos.z, heading, true, false)
	  --RequestAnimDict(dict)
	  --while not HasAnimDictLoaded(dict) do
	  --  print("Not loaded waiting")
	  --  Wait(500)
	  --end
	  --TaskPlayAnim(ped, dict, 'idle_c', 1.0, -1.0, -1, 1, 1.0, true, true)
	  -- This seems to work best
	  Citizen.Wait(3000)
	  TaskStartScenarioInPlace(ped, "WORLD_HUMAN_SMOKING", 0, true)
	  Citizen.Wait(3000)
	  TaskStandGuard(ped, pos.x, pos.y, pos.z, heading, 'WORLD_HUMAN_MOB_GUARDS')
	  DressAsMob(ped, false)
	  SetEntityAsNoLongerNeeded(ped)
	end, false)

	RegisterCommand('SpawnEnemy', function(source, args)
		local id      	= GetPlayerFromServerId(source)
		local player  	= GetPlayerPed(id)
		local pos     	= GetEntityCoords(player)
		local heading 	= GetEntityHeading(player)
		local arg     	= nil
		local hash    	= WaitForHash(defaultNPC)
		local isLeader 	= false
		local weapon  	= GetHashKey('WEAPON_GUSENBERG')
		local sidearm 	= GetHashKey('WEAPON_PISTOL')
		AddRelationshipGroup('MOB_E')

		for i,a in pairs(args) do
	    if (i == 1) then arg = a end
	  end

		if not arg then LogAndTrace('Missing argument', {}, 'info') else
			for _,_ in pairs(Config.SecurityGuards[arg]) do
				local ped = CreatePed(10, hash, pos.x+15.0, pos.y+15.0, pos.z, heading, true, false)
				if not isLeader then
		      GiveWeaponToPed(ped, weapon, 0, 1)
		      isLeader = true
		    else
		      GiveWeaponToPed(ped, sidearm, 0, 1)
		    end
				SetPedRelationshipGroupHash(ped, 'MOB_E')
				CheckAndSetRelationship('MOB_E', 5)
				SetPedCombatAttributes(ped, 2, true)
				SetPedCombatAttributes(ped, 46, true)
			end
		end
	end, false)


	-- https://stackoverflow.com/a/1791506
	--[[
	  To call a function in the global namespace (as mentioned by @THC4k)
	  is easily done, and does not require loadstring().
	  x='foo'
	  _G[x]() -- calls foo from the global namespace
	  You would need to use loadstring() (or walk each table)
	  if the function in another table, such as if x='math.sqrt'
	--]]
	RegisterCommand('ExecFunc', function(source, args)
	  local id      = GetPlayerFromServerId(source)
	  local player  = GetPlayerPed(id)
	  local func    = nil
	  local arg     = nil

	  for i,a in pairs(args) do
	    if (i == 1) then
	      func = a
	    else
	      arg = CheckTypeAndReturn(a)
	    end
	  end

	  if _G[func] ~= nil then
	    if (arg) then
	      _G[func](arg)
	    else
	      _G[func]()
	    end
	  else
	    LogAndTrace('Unknown', {func = func, arg = arg}, 'info')
	  end

	end, false)

	-- arg: r for wander, w for waypoint **make sure to call from inside vehicle**
	RegisterCommand('CallPilot', function(source, args)
		local arg = args[1]
		local hash = WaitForHash(defaultNPC)
		local id      	= GetPlayerFromServerId(source)
		local player  	= GetPlayerPed(id)
		local pos     	= GetEntityCoords(player)
		local heading 	= GetEntityHeading(player)
		local weapon  	= GetHashKey('WEAPON_GUSENBERG')
		local group			=	GetHashKey(Config.Group)

		if not arg then LogAndTrace('Missing argument', {}, 'info') else
			local ped = CreatePed(10, hash, pos.x+15.0, pos.y+15.0, pos.z, heading, true, false)
			local vehicle = GetVehiclePedIsIn(player)
			local wp = GetFirstBlipInfoId(8)
			local x,y,z = table.unpack(GetBlipCoords(wp))
			GiveWeaponToPed(ped, weapon, 0, true, false)
			SetPedRelationshipGroupHash(ped, group)
			--TaskEnterVehicle(ped, vehicle, -1, -1, 2.0, 1, 0)
			local strtName,_ = GetStreetNameAtCoord(pos.x,pos.y,pos.z,0,0)
			print(GetStreetNameFromHashKey(strtName))

			if arg == "r" then
				--TaskVehicleDriveWander(ped, vehicle, 25.0, 8388614)
			elseif arg == "w" then
				print("plane mission")
				--TaskPlaneMission(ped, vehicle, 0, 0 ,x,y,z, 4, 100.0, 0, 90.0, 0, 200.0)
			end
		end

	end)

	RegisterCommand('CallBody', function(source, args)
		local arg = args[1]

		if not arg then LogAndTrace('Missing argument', {}, 'info') else CallBodyGuards(arg) end

	end, false)
end
