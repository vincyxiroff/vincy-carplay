local isMusicPlaying = false
local musicPlayingVehicles = {}
local musicOwner = nil
local currentVehicle = nil
ESX = exports["es_extended"]:getSharedObject()

lib.registerContext({
    id = 'car_music_menu',
    title = 'Car Music Menu',
    options = {
        {
            title = 'Play Music',
            icon = 'play',
            onSelect = function()
                OpenMusicInput()
            end
        },
        {
            title = 'Stop Music',
            icon = 'stop',
            onSelect = function()
                StopMusic()
            end,
        },
        {
            title = 'Adjust Volume',
            icon = 'volume-up',
            onSelect = function()
                AdjustVolume()
            end,
        }
    }
})

RegisterCommand(Config.CommandName, function()
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        lib.showContext('car_music_menu')
    end
end, false)

function OpenMusicInput()
    if isMusicPlaying and musicOwner ~= GetPlayerServerId(PlayerId()) then
        return
    end

    local input = lib.inputDialog('Play Music', {
        {type = 'input', label = 'Song (YouTube Link)', required = true},
        {type = 'number', label = 'Volume (0-100)', default = 50, min = 0, max = 100},
        {type = 'number', label = 'Radius (Max 20)', default = 10, min = 1, max = 20}
    })

    if input then
        local url, volume, radius = input[1], input[2], input[3]
        PlayMusic(url, volume, radius)
    end
end

function PlayMusic(url, volume, radius)
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    
    local timestamp = GetGameTimer()
    TriggerServerEvent('vincy-carplay:playMusic', vehicleNetId, url, volume, radius, timestamp)
end

function StopMusic()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    
    if not musicPlayingVehicles[vehicleNetId] then return end
    
    TriggerServerEvent('vincy-carplay:stopMusic', vehicleNetId)
end

function AdjustVolume()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    local vehicleNetId = NetworkGetNetworkIdFromEntity(vehicle)
    
    if not musicPlayingVehicles[vehicleNetId] or 
       musicPlayingVehicles[vehicleNetId].owner ~= GetPlayerServerId(PlayerId()) then
        return
    end

    local input = lib.inputDialog('Adjust Volume', {
        {type = 'number', label = 'Volume (0-100)', default = 50, min = 0, max = 100},
    })

    if input then
        local newVolume = input[1]
        TriggerServerEvent('vincy-carplay:adjustVolume', vehicleNetId, newVolume)
    end
end

RegisterNetEvent('vincy-carplay:syncExistingMusic', function(vehicleData)
    for vehicleNetId, data in pairs(vehicleData) do
        local vehicle = NetToVeh(vehicleNetId)
        if DoesEntityExist(vehicle) then
            local soundId = 'car_music_' .. vehicleNetId
            local vehicleCoords = GetEntityCoords(vehicle)
            
            local currentServerTime = GetGameTimer()
            local elapsedTime = (currentServerTime - data.timestamp) / 1000 
            
            exports.xsound:PlayUrlPos(soundId, data.url, data.volume / 100, vehicleCoords, false, {
                startTime = elapsedTime
            })
            exports.xsound:Distance(soundId, data.radius)
            
            musicPlayingVehicles[vehicleNetId] = {
                owner = data.owner,
                soundId = soundId,
                url = data.url,
                timestamp = data.timestamp
            }
            
            CreateThread(function()
                while musicPlayingVehicles[vehicleNetId] do
                    if DoesEntityExist(vehicle) then
                        local vehicleCoords = GetEntityCoords(vehicle)
                        exports.xsound:Position(soundId, vehicleCoords)
                    else
                        TriggerServerEvent('vincy-carplay:stopMusic', vehicleNetId)
                        break
                    end
                    Wait(100)
                end
            end)
        end
    end
end)

RegisterNetEvent('vincy-carplay:updateVolume', function(vehicleNetId, newVolume)
    local soundId = 'car_music_' .. vehicleNetId
    
    if musicPlayingVehicles[vehicleNetId] then
        exports.xsound:setVolume(soundId, newVolume / 100)
    end
end)

RegisterNetEvent('vincy-carplay:startMusic', function(vehicleNetId, url, volume, radius, owner, serverTimestamp, clientTimestamp)
    local vehicle = NetToVeh(vehicleNetId)
    if DoesEntityExist(vehicle) then
        local soundId = 'car_music_' .. vehicleNetId
        local vehicleCoords = GetEntityCoords(vehicle)
        
        local currentTime = GetGameTimer()
        local timeDifference = currentTime - clientTimestamp
        local startTime = (timeDifference / 1000) 
        
        exports.xsound:PlayUrlPos(soundId, url, volume / 100, vehicleCoords, false, {
            startTime = startTime 
        })
        exports.xsound:Distance(soundId, radius)

        musicPlayingVehicles[vehicleNetId] = {
            owner = owner,
            soundId = soundId,
            url = url,
            timestamp = serverTimestamp
        }

        CreateThread(function()
            while musicPlayingVehicles[vehicleNetId] do
                if DoesEntityExist(vehicle) then
                    local vehicleCoords = GetEntityCoords(vehicle)
                    exports.xsound:Position(soundId, vehicleCoords)
                else
                    TriggerServerEvent('vincy-carplay:stopMusic', vehicleNetId)
                    break
                end
                Wait(100)
            end
        end)
    end
end)

RegisterNetEvent('vincy-carplay:stopMusic', function(vehicleNetId)
    if musicPlayingVehicles[vehicleNetId] then
        local soundId = musicPlayingVehicles[vehicleNetId].soundId
        exports.xsound:Destroy(soundId)
        musicPlayingVehicles[vehicleNetId] = nil
    end
end)

RegisterNetEvent('vincy-carplay:cleanup', function()
    for vehicleNetId, data in pairs(musicPlayingVehicles) do
        exports.xsound:Destroy(data.soundId)
    end
    musicPlayingVehicles = {}
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    TriggerServerEvent('vincy-carplay:requestSync')
end)