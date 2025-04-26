fx_version 'cerulean'
game 'gta5'


lua54 'yes'
author '.vincyxir'
description 'carplay'
version '1.0.0'

shared_script {
 'config.lua',
 '@ox_lib/init.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}


dependencies { 
    'ox_lib',      
    'xsound',      
    'oxmysql'      
}
