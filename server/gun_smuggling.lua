ESX               = nil
local Societys    = {}
local hasSqlRun   = false

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function LoadSocieties()
  hasSqlRun = true

  Societies      = MySQL.Sync.fetchAll('SELECT * FROM vehicle_categories WHERE (name = "mafia_leaders" or name = "mafia_initiates") ')

  -- send information after db has loaded, making sure everyone gets vehicle information
  TriggerClientEvent('esx_mob:sendSocieties', -1, Societies)
end


AddEventHandler('onMySQLReady', function()
	LoadSocieties()
end)
