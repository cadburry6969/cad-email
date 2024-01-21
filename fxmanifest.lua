fx_version 'cerulean'
game 'gta5'

author "Cadburry"
description "This is a fivem script where you can send a message to a person discord dm from server"

ui_page "index.html"
files {
    "index.html",
}

client_script 'client/client.js'
server_script 'server/server.js'

dependencies {
    '/server:7290',
    'yarn'
}