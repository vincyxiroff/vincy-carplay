local playingMusic = {}

RegisterServerEvent('vincy-carplay:playMusic')
AddEventHandler('vincy-carplay:playMusic', function(vehicleNetId, url, volume, radius, clientTimestamp)
    local owner = source
    local serverTimestamp = os.time() * 1000
    
    playingMusic[vehicleNetId] = {
        url = url,
        volume = volume,
        radius = radius,
        owner = owner,
        timestamp = serverTimestamp
    }
    
    TriggerClientEvent('vincy-carplay:startMusic', -1, vehicleNetId, url, volume, radius, owner, serverTimestamp, clientTimestamp)
end)

RegisterServerEvent('vincy-carplay:stopMusic')
AddEventHandler('vincy-carplay:stopMusic', function(vehicleNetId)
    playingMusic[vehicleNetId] = nil
    TriggerClientEvent('vincy-carplay:stopMusic', -1, vehicleNetId)
end)

RegisterServerEvent('vincy-carplay:adjustVolume')
AddEventHandler('vincy-carplay:adjustVolume', function(vehicleNetId, newVolume)
    if playingMusic[vehicleNetId] then
        playingMusic[vehicleNetId].volume = newVolume
    end
    
    TriggerClientEvent('vincy-carplay:updateVolume', -1, vehicleNetId, newVolume)
end)

RegisterServerEvent('vincy-carplay:requestSync')
AddEventHandler('vincy-carplay:requestSync', function()
    local source = source
    if next(playingMusic) then
        TriggerClientEvent('vincy-carplay:syncExistingMusic', source, playingMusic)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    TriggerClientEvent('vincy-carplay:cleanup', -1)
end)