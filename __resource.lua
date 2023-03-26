resource_manifest_version '44febabe-d386-4d18-afbe-5e627f4af937'

description 'ESX Mob Society'

version '0.0.1'

server_scripts {
	'@mysql-async/lib/MySQL.lua',
  '@es_extended/locale.lua',
	'locales/en.lua',
	'config.lua',
  'server/main.lua',
  'server/server_utils.lua'
}

client_scripts {
  '@es_extended/locale.lua',
	'locales/en.lua',
	'config.lua',
	'client/utils.lua',
	'client/main.lua'
}
