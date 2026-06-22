fx_version 'cerulean'
game 'gta5'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

-- ✅ EXPORTS
exports {
    'notify',
    'progress',
    'dialog',
    'menu',
    'slider'
}

dependencies {
    'qb-core'
}