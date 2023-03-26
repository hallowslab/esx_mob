ESX               		= nil
local Categories  		= {}
local Vehicles    		= {}
local hasSqlRun   		= false
local hasSecurity     = false


-- This has to be kept on server side to keep it synced with all clients
local vehiclesForSale	= {}
local SecurityGuards  = {}

-- Clear sell zones on start/restart
function LoadSellZones()

	local sellZones = Config.SellZones

	for _,v in pairs(sellZones) do
		table.insert(vehiclesForSale, 
		{
			label = v.Name,
			value = nil,
			id    = nil
		})
	end
	--print(debug.traceback())
end

-------------------------->>>> Net Events <<<<---------------------------------------------------

-- Event for loading sellZones and vehiclesForSale **only for start or restart**
-- The client must trigger server callbacks to get or change vehiclesForSale
RegisterNetEvent('esx_mob:loadSellZones')
AddEventHandler('esx_mob:loadSellZones', function()
	LoadSellZones()
	Citizen.Trace('Loaded sell zones\n')
end)

-- Register events for reseting vehicle states in database on start or restart
RegisterNetEvent('esx_mob:resetDisplayVehicles')
AddEventHandler('esx_mob:resetDisplayVehicles', function()
	MySQL.Async.execute('UPDATE `mobdealer_vehicles` SET `display` = 0')
	Citizen.Trace('Sucessfully reset display vehicles state\n')
end)

RegisterNetEvent('esx_mob:resetSocietyVehicles')
AddEventHandler('esx_mob:resetSocietyVehicles', function()
	MySQL.Async.execute('UPDATE `owned_vehicles` SET `stored` = 1 AND `state` = 1 WHERE `owner` = "society:mafia"')
	Citizen.Trace('Sucessfully reset vehicle values stored and state in DB\n')
end)


-- Get ESX, register society number, register society
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
TriggerEvent('esx_phone:registerNumber', 'mafia', _U('mafia'), true, true)
TriggerEvent('esx_society:registerSociety', 'mafia', _U('mafia'), 'society_mafia', 'society_mafia', 'society_mafia', {type = 'private'})



function RemoveOwnedVehicle (plate)
	MySQL.Async.execute('DELETE FROM owned_vehicles WHERE plate = @plate',
	{
		['@plate'] = plate
	})
end

-- Trigger reset events only when mysql has loaded
AddEventHandler('onMySQLReady', function()
  LoadVehicles()
  -- Trigger reset events
  TriggerEvent('esx_mob:resetDisplayVehicles')
  TriggerEvent('esx_mob:resetSocietyVehicles')
  TriggerEvent('esx_mob:loadSellZones')
end)


function LoadVehicles()
  hasSqlRun = true

  Categories      = MySQL.Sync.fetchAll('SELECT * FROM vehicle_categories WHERE (name = "mafia_leaders" or name = "mafia_initiates") ')
  local vehicles  = MySQL.Sync.fetchAll('SELECT * FROM vehicles WHERE (category = "mafia_leaders" or category = "mafia_initiates") ')

  for i=1, #vehicles, 1 do
    local vehicle = vehicles[i]

    for j=1, #Categories, 1 do
      if Categories[j].name == vehicle.category then
        vehicle.categoryLabel = Categories[j].label
        break
      end
    end

    table.insert(Vehicles, vehicle)
  end

  -- send information after db has loaded, making sure everyone gets vehicle information
  TriggerClientEvent('esx_mob:sendCategories', -1, Categories)
  TriggerClientEvent('esx_mob:sendVehicles', -1, Vehicles)
end

-- extremely useful when restarting script mid-game
Citizen.CreateThread(function()
	Citizen.Wait(10000) -- hopefully enough for connection to the SQL server

	if not hasSqlRun then
		LoadVehicles()
	end
end)


-- Register Server Events


RegisterServerEvent('esx_mob:setVehicleOwned')
AddEventHandler('esx_mob:setVehicleOwned', function (vehicleProps)
  local _source = source
  local xPlayer = ESX.GetPlayerFromId(_source)

  MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)',
  {
    ['@owner']    = xPlayer.identifier,
    ['@plate']    = vehicleProps.plate,
    ['@vehicle']  = json.encode(vehicleProps)
  },
  function (rowsChanged)
    TriggerClientEvent('esx:showNotification', _source, _U('vehicle_belongs', vehicle.vehicleProps.plate))
  end)
end)

RegisterServerEvent('esx_mob:setVehicleOwnedPlayerId')
AddEventHandler('esx_mob:setVehicleOwnedPlayerId', function (playerId, vehicleProps)
	local xPlayer = ESX.GetPlayerFromId(playerId)

	MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)',
	{
		['@owner']   = xPlayer.identifier,
		['@plate']   = vehicleProps.plate,
		['@vehicle'] = json.encode(vehicleProps)
	},
	function (rowsChanged)
		TriggerClientEvent('esx:showNotification', playerId, _U('vehicle_belongs', vehicleProps.plate))
	end)
end)

-- Sets Vehicle owned to a society passed in the parameters
RegisterServerEvent('esx_mob:setVehicleOwnedSociety')
AddEventHandler('esx_mob:setVehicleOwnedSociety', function (society, vehicleProps)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)',
	{
		['@owner']   = 'society:' .. society,
		['@plate']   = vehicleProps.plate,
		['@vehicle'] = json.encode(vehicleProps),
	},
	function (rowsChanged)
		TriggerClientEvent('esx:showNotification', _source, _U('vehicle_belongs', vehicleProps.plate))
	end)
end)

RegisterServerEvent('esx_mob:sellVehicle')
AddEventHandler('esx_mob:sellVehicle', function (vehicle)
	MySQL.Async.fetchAll('SELECT * FROM mobdealer_vehicles WHERE vehicle = @vehicle LIMIT 1', {
		['@vehicle'] = vehicle
	}, function (result)
		local id = result[1].id

		MySQL.Async.execute('DELETE FROM mobdealer_vehicles WHERE id = @id', {
			['@id'] = id
		})
	end)
end)

RegisterServerEvent('esx_mob:returnProvider')
AddEventHandler('esx_mob:returnProvider', function(vehicleModel)
	local _source = source

	MySQL.Async.fetchAll('SELECT * FROM mobdealer_vehicles WHERE vehicle = @vehicle LIMIT 1', {
		['@vehicle'] = vehicleModel
	}, function (result)

		if result[1] then
			local id    = result[1].id
			local price = ESX.Round(result[1].price * 0.75)

			TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mafia', function(account)
				account.addMoney(price)
			end)

			MySQL.Async.execute('DELETE FROM mobdealer_vehicles WHERE id = @id', {
				['@id'] = id
			})

			TriggerClientEvent('esx:showNotification', _source, _U('vehicle_sold_for', vehicleModel, price))
		else
			print('esx_mob: ' .. GetPlayerIdentifiers(_source)[1] .. ' attempted selling an invalid vehicle!')
		end

	end)
end)

RegisterServerEvent('esx_mob:putStockItems')
AddEventHandler('esx_mob:putStockItems', function (itemName, count)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_mafia', function (inventory)
		local item = inventory.getItem(itemName)

		if item.count >= 0 then
			xPlayer.removeInventoryItem(itemName, count)
			inventory.addItem(itemName, count)
			TriggerClientEvent('esx:showNotification', _source, _U('have_deposited', count, item.label))
		else
			TriggerClientEvent('esx:showNotification', _source, _U('invalid_amount'))
		end
	end)
end)

-- unused?
RegisterServerEvent('esx_mob:setVehicleForAllPlayers')
AddEventHandler('esx_mob:setVehicleForAllPlayers', function (props, x, y, z, radius)
	TriggerClientEvent('esx_mob:setVehicle', -1, props, x, y, z, radius)
end)

RegisterServerEvent('esx_mob:getStockItem')
AddEventHandler('esx_mob:getStockItem', function (itemName, count)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	local sourceItem = xPlayer.getInventoryItem(itemName)

	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_mafia', function (inventory)
		local item = inventory.getItem(itemName)

		-- is there enough in the society?
		if count > 0 and item.count >= count then

			-- can the player carry the said amount of x item?
			if sourceItem.limit ~= -1 and (sourceItem.count + count) > sourceItem.limit then
				TriggerClientEvent('esx:showNotification', _source, _U('player_cannot_hold'))
			else
				inventory.removeItem(itemName, count)
				xPlayer.addInventoryItem(itemName, count)
				TriggerClientEvent('esx:showNotification', _source, _U('have_withdrawn', count, item.label))
			end
		else
			TriggerClientEvent('esx:showNotification', _source, _U('not_enough_in_society'))
		end
	end)
end)

RegisterServerEvent('esx_mob:setVehicleDisplay')
AddEventHandler('esx_mob:setVehicleDisplay', function(display, id, label, vehicle)

	for i=1, #vehiclesForSale, 1 do
		if vehiclesForSale[i].label == label then
		  vehiclesForSale[i].value = vehicle
		  vehiclesForSale[i].id = id
		end
	  end

	MySQL.Async.execute('UPDATE `mobdealer_vehicles` SET `display` = @display WHERE `id` = @id', {
		['@display']	= display,
		['@id']			= id
	})
end)

-- For setting stored state in db
RegisterServerEvent('esx_mob:removeVehicleFromGarage')
AddEventHandler('esx_mob:removeVehicleFromGarage', function(vehicleProps)
	-- probably won't need this
	local _source = source

	MySQL.Async.execute('UPDATE `owned_vehicles` SET `state` = 0 WHERE (`owner` = "society:mafia" AND `plate` = @vehiclePlate)',
	{
		['@vehiclePlate']		=	vehicleProps.plate,
	})
end)

RegisterServerEvent('esx_mob:setSecurity')
AddEventHandler('esx_mob:setSecurity', function(value)
  SecurityGuards = value
  hasSecurity    = true
end)

--[[-------------------
    ESX Server Callbacks
  -----------------------]]

----------> Vehicle callbacks <-----------------------

ESX.RegisterServerCallback('esx_mob:getCategories', function (source, cb)
	cb(Categories)
end)

ESX.RegisterServerCallback('esx_mob:getVehicles', function (source, cb)
	cb(Vehicles)
end)

ESX.RegisterServerCallback('esx_mob:buyVehicle', function (source, cb, vehicleModel)
	local xPlayer     = ESX.GetPlayerFromId(source)
	local vehicleData = nil

	for i=1, #Vehicles, 1 do
		if Vehicles[i].model == vehicleModel then
			vehicleData = Vehicles[i]
			break
		end
	end

	if xPlayer.getMoney() >= vehicleData.price then
		xPlayer.removeMoney(vehicleData.price)
		cb(true)
	else
		cb(false)
	end
end)

ESX.RegisterServerCallback('esx_mob:buyVehicleSociety', function (source, cb, society, vehicleModel)
	local vehicleData = nil

	for i=1, #Vehicles, 1 do
		if Vehicles[i].model == vehicleModel then
			vehicleData = Vehicles[i]
			break
		end
	end

	TriggerEvent('esx_addonaccount:getSharedAccount', 'society_' .. society, function (account)
		if account.money >= vehicleData.price then

			account.removeMoney(vehicleData.price)
			MySQL.Async.execute('INSERT INTO mobdealer_vehicles (vehicle, price) VALUES (@vehicle, @price)',
			{
				['@vehicle'] = vehicleData.model,
				['@price']   = vehicleData.price,
			})

			cb(true)
		else
			cb(false)
		end
	end)
end)

ESX.RegisterServerCallback('esx_mob:getPersonnalVehicles', function (source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner', {
		['@owner'] = xPlayer.identifier
	}, function (result)
		local vehicles = {}

		for i=1, #result, 1 do
			local vehicleData = json.decode(result[i].vehicle)
			table.insert(vehicles, vehicleData)
		end

		cb(vehicles)
	end)
end)

ESX.RegisterServerCallback('esx_mob:getCommercialVehicles', function (source, cb)
	MySQL.Async.fetchAll('SELECT * FROM mobdealer_vehicles ORDER BY vehicle ASC', {}, function (result)
		local vehicles = {}

		for i=1, #result, 1 do
			table.insert(vehicles, {
				id		= result[i].id,
				name  	= result[i].vehicle,
				price 	= result[i].price,
				stored	= result[i].display
			})
		end

		cb(vehicles)
	end)
end)

-- Only fetches vehicles from hard coded society
ESX.RegisterServerCallback('esx_mob:getSocietyVehicles', function(source, cb)
	local vehicles = {}

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = "society:mafia"', {},
		function (result)


			for _,v in pairs(result) do
				local vehicle = json.decode(v.vehicle)
				table.insert(vehicles, {vehicle = vehicle, state = v.state, plate = v.plate, stored = v.stored})
			end

			cb(vehicles)
	end)
end)

ESX.RegisterServerCallback('esx_mob:retrieveFromImpound', function(source, cb, price)
  local xPlayer     = ESX.GetPlayerFromId(source)

  if xPlayer.getMoney() >= price then
    xPlayer.removeMoney(price)
    cb(true)
  else
    cb(false)
  end

end)

ESX.RegisterServerCallback('esx_mob:giveBackVehicle', function (source, cb, plate)
	MySQL.Async.fetchAll('SELECT * FROM rented_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function (result)
		if result[1] ~= nil then
			local vehicle   = result[1].vehicle
			local basePrice = result[1].base_price

			MySQL.Async.execute('INSERT INTO mobdealer_vehicles (vehicle, price) VALUES (@vehicle, @price)',
			{
				['@vehicle'] = vehicle,
				['@price']   = basePrice
			})

			MySQL.Async.execute('DELETE FROM rented_vehicles WHERE plate = @plate',{
				['@plate'] = plate
			})

			RemoveOwnedVehicle(plate)
			cb(true)
		else
			cb(false)
		end
	end)
end)

ESX.RegisterServerCallback('esx_mob:storeVehicle', function (source, cb, plate, owner)
	local isOwned = false
	local plates  = {}
	MySQL.Async.fetchAll('SELECT * FROM `owned_vehicles` WHERE (`owner` = @owner AND `plate` = @plate)', {
		['@owner']	= 'society:' .. owner,
		['@plate']	= plate
	}, 
	function(results)
		local veh_plate = plate
		for i=1, #results, 1 do
			if results[i].plate == plate then
				MySQL.Async.execute('UPDATE owned_vehicles SET `state` = 1 AND `stored` = 1 WHERE (`plate` = @plate AND `owner` = @owner)', {
					['@plate'] = plate,
					['@owner'] = 'society:' .. owner
				})
				Citizen.Trace('Found Plate')
				cb(true)
			else
				Citizen.Trace('Din\'t find plate')
				cb(false)
			end
		end
	end)
end)

ESX.RegisterServerCallback('esx_mob:getForSale', function(source, cb)
	cb(vehiclesForSale)
end)

--[[
		Modified resel server callback so that the vehicle value always gets added to society account
		The owner will still be able to sell the vehicle in esx_vehicleshop,
		and receive the money to their wallets/inventory
]]

ESX.RegisterServerCallback('esx_mob:resellVehicle', function (source, cb, plate, price)
	MySQL.Async.fetchAll('SELECT * FROM rented_vehicles WHERE plate = @plate', {
		['@plate'] = plate
	}, function (result)
		if result[1] ~= nil then -- is it a rented vehicle?
			cb(false) -- it is, don't let the player sell it since he doesn't own it
		else
			local xPlayer = ESX.GetPlayerFromId(source)

			TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mafia', function(account)
				MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND @plate = plate',
				{
					['@owner'] = xPlayer.identifier,
					['@plate'] = plate
				}, function (result)

					-- does the owner match?
					if xPlayer.job.grade_name == 'boss' then
						MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND @plate = plate',
						{
							['@owner'] = 'society:' .. xPlayer.job.name,
							['@plate'] = plate
						}, function (result)
							if result[1] ~= nil then
								account.addMoney(price)
								RemoveOwnedVehicle(plate)
								cb(true)
							else
								cb(false)
							end
						end)
					else
						cb(false)
					end
				end)
			end)
		end
	end)
end)

----------> Security callbacks <-----------------------

ESX.RegisterServerCallback('esx_mob:hasSecurity', function(source, cb)
  cb(hasSecurity)
end)

ESX.RegisterServerCallback('esx_mob:getSecurity', function(source, cb)
  if hasSecurity then
    cb(SecurityGuards)
  else
    cb(nil)
  end
end)

ESX.RegisterServerCallback('esx_mob:getStockItems', function (source, cb)
	TriggerEvent('esx_addoninventory:getSharedInventory', 'society_mafia', function(inventory)
		cb(inventory.items)
	end)
end)

ESX.RegisterServerCallback('esx_mob:getPlayerInventory', function (source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local items   = xPlayer.inventory

	cb({ items = items })
end)




-- This is not being used it should !!

-- TODO: use this callback everytime GeneratePlate or GenerateSocPlate is being called
ESX.RegisterServerCallback('esx_mob:isPlateTaken', function (source, cb, plate)
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE @plate = plate', {
		['@plate'] = plate
	}, function (result)
		cb(result[1] ~= nil)
	end)
end)
