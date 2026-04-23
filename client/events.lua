local TMGCore = exports['tmg-core']:GetCoreObject()

local Telemetry = {
    isSpectating = false,
    lastCoords = nil,
    isAdmin = false
}


local function LoadPlayerModel(skin)
    RequestModel(skin)
    while not HasModelLoaded(skin) do Wait(0) end
end

local function GetVehicleModelFromHash(hash)
    for model, data in pairs(TMGCore.Shared.Vehicles) do
        if data.hash == hash then return model end
    end
    return nil
end


RegisterNetEvent('tmg-admin:client:spectate', function(targetServerId)
    local myPed = PlayerPedId()
    
    if not Telemetry.isSpectating then
        local targetPlayer = GetPlayerFromServerId(targetServerId)
        local targetPed = GetPlayerPed(targetPlayer)

        if targetPed ~= 0 and targetPed ~= myPed then
            Telemetry.isSpectating = true
            Telemetry.lastCoords = GetEntityCoords(myPed)
            
            SetEntityVisible(myPed, false, false)
            SetEntityCollision(myPed, false, false)
            SetEntityInvincible(myPed, true)
            NetworkSetEntityInvisibleToNetwork(myPed, true)
            
            NetworkSetInSpectatorMode(true, targetPed)
            TMGCore.Functions.Notify("Spectate Matrix: ENGAGED", "success")
        end
    else
        Telemetry.isSpectating = false
        NetworkSetInSpectatorMode(false)
        
        NetworkSetEntityInvisibleToNetwork(myPed, false)
        SetEntityCollision(myPed, true, true)
        SetEntityCoords(myPed, Telemetry.lastCoords)
        SetEntityVisible(myPed, true, false)
        SetEntityInvincible(myPed, false)
        
        Telemetry.lastCoords = nil
        TMGCore.Functions.Notify("Spectate Matrix: DISCONNECTED", "error")
    end
end)


RegisterNetEvent('tmg-admin:client:SaveCar', function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped)

    if veh ~= 0 then
        local plate = TMGCore.Functions.GetPlate(veh)
        local props = TMGCore.Functions.GetVehicleProperties(veh)
        local vehName = GetVehicleModelFromHash(props.model)

        if vehName and TMGCore.Shared.Vehicles[vehName] then
            TriggerServerEvent('tmg-admin:server:SaveCar', props, TMGCore.Shared.Vehicles[vehName], GetHashKey(veh), plate)
        else
            TMGCore.Functions.Notify(Lang:t('error.no_store_vehicle_garage'), 'error')
        end
    else
        TMGCore.Functions.Notify(Lang:t('error.no_vehicle'), 'error')
    end
end)

RegisterNetEvent('tmg-admin:client:maxmodVehicle', function()
    local veh = GetVehiclePedIsIn(PlayerPedId())
    if veh == 0 then return end
    
    local performanceMods = { 11, 12, 13, 15, 16 }
    SetVehicleModKit(veh, 0)
    
    for _, modType in ipairs(performanceMods) do
        local max = GetNumVehicleMods(veh, modType) - 1
        SetVehicleMod(veh, modType, max, false)
    end
    
    ToggleVehicleMod(veh, 18, true) -- Turbo
    SetVehicleFixed(veh)
    TMGCore.Functions.Notify("Vehicle Performance Optimized", "success")
end)

RegisterNetEvent('tmg-admin:client:SetModel', function(skin)
    local model = GetHashKey(skin)
    if IsModelInCdimage(model) and IsModelValid(model) then
        LoadPlayerModel(model)
        SetPlayerModel(PlayerId(), model)
        SetPedRandomComponentVariation(PlayerPedId(), true)
        SetModelAsNoLongerNeeded(model)
    end
end)

RegisterNetEvent('tmg-admin:client:SetSpeed', function(speed)
    local multiplier = (speed == 'fast') and 1.49 or 1.0
    SetRunSprintMultiplierForPlayer(PlayerId(), multiplier)
    SetSwimMultiplierForPlayer(PlayerId(), multiplier)
    TMGCore.Functions.Notify("Movement Speed Adjusted: " .. multiplier, "success")
end)

RegisterNetEvent('tmg-admin:client:GiveNuiFocus', function(focus, mouse)
    SetNuiFocus(focus, mouse)
end)

RegisterNetEvent('tmg-admin:client:SendReport', function(name, src, msg)
    TriggerServerEvent('tmg-admin:server:SendReport', name, src, msg)
end)