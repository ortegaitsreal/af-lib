fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'AF Library - Custom UI Components'
version '1.0.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

client_scripts {
    'config.lua',
    'client/main.lua'
}

server_scripts {
    'config.lua',
    'server/main.lua'
}

dependencies {
    'qb-core'
}