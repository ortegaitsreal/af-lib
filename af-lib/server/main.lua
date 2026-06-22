-- server/main.lua
print('^2[AF-Lib] Server started^0')

-- Command untuk test dari server
RegisterCommand('afnotifserver', function(source, args, rawCommand)
    TriggerClientEvent('af-lib:notify', source, 'Server', 'Notifikasi dari server!', 'success')
end, true)