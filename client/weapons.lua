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
local Shipments               = {}
local inInMission             = {}
local CurrentVehicleData      = nil
local RandomDrops             = {}
local Societies               = {}

ESX                           = nil

Citizen.CreateThread(function ()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	Citizen.Wait(10000)

	RandomDrops = Config.RandomDrops

	if Config.EnablePlayerManagement then
		if ESX.PlayerData.job.name == 'mafia' then
    -- should drops be 1 ?

			if ESX.PlayerData.job.grade_name == 'boss' then
				Config.Zones.MobWeaponShop.Type = 1
			end

		else
      print("No access") -- Remove this
      Config.Zones.MobWeaponShop.Type = -1
			for drop = 1, #RandomDrops do
        Config.RandomDrops[drop].Type = -1
		end
	end
end)

--[===[ Is this even needed ?
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
]===]


function WeaponShopMenu ()

  ESX.UI.Menu.CloseAll()

  ESX.UI.Menu.Open(
    'default', GetCurrentResourceName(), 'reseller',
    {
      title    = _U('weapon_smuggling'),
      align    = 'top-left',
      elements = {
        {label = _U('order_weapons'),                  value = 'order_weapons'},
        {label = _U('take_crate'),                     value = 'take_crate'},
        {label = _U('attack_society'),                 value = 'attack_society'},
      }
    },
    function (data, menu)
      local action = data.current.value

      if action == 'order_weapons' then
        OrderWeapons()
      elseif action == 'take_crate' then
        TakeCrate()
      elseif action == 'attack_society' then
        StartAttackSociety()
      end,
      function (data, menu)
        menu.close()

        CurrentAction     = 'reseller_menu'
        CurrentActionMsg  = _U('shop_menu')
        CurrentActionData = {}
      end
    )

end
