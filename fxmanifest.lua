fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cad-email'
author 'Cadburry'
description 'Send mail from FiveM straight to a player Discord DM'
version '2.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}

shared_scripts {
    '@ox_lib/init.lua',
}

client_scripts {
    'config/client.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/server.lua',
    'server/logs.lua',
    'server/bridge.lua',
    'server/database.lua',
    'server/discord.lua',
    'server/main.lua',
}

dependencies {
    'ox_lib',
    'oxmysql',
}
