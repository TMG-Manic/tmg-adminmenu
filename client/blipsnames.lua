local TMGCore = exports['tmg-core']:GetCoreObject()

local Telemetry = {
    blips = false,
    names = false,
    isPolling = false,
    isAdmin = false
}

local activeTags = {}

local function WipeTelemetry()
    for _, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        
        local blip = GetBlipFromEntity(ped)
        if DoesBlipExist(blip) then RemoveBlip(blip) end
        
        if activeTags[ped] then
            RemoveMpGamerTag(activeTags[ped])
            activeTags[ped] = nil
        end
    end
end

local function ManageTelemetryThread()
    if not Telemetry.blips and not Telemetry.names then 
        Telemetry.isPolling = false
        WipeTelemetry()
        return 
    end
    
    if Telemetry.isPolling then return end
    Telemetry.isPolling = true

    CreateThread(function()
        print("^3[TMG System]^7 Telemetry Polling: ONLINE")
        while Telemetry.isPolling do
            TriggerServerEvent('tmg-admin:server:GetPlayersForBlips')
            Wait(1000)
        end
        print("^3[TMG System]^7 Telemetry Polling: OFFLINE")
    end)
end

RegisterNetEvent('tmg-admin:client:toggleBlips', function()
    TMGCore.Functions.TriggerCallback('tmg-admin:isAdmin', function(isAdmin)
        if not isAdmin then return end
        
        Telemetry.isAdmin = true
        Telemetry.blips = not Telemetry.blips
        
        local msg = Telemetry.blips and Lang:t('success.blips_activated') or Lang:t('error.blips_deactivated')
        local type = Telemetry.blips and 'success' or 'error'
        
        TMGCore.Functions.Notify(msg, type)
        ManageTelemetryThread()
    end)
end)

RegisterNetEvent('tmg-admin:client:toggleNames', function()
    TMGCore.Functions.TriggerCallback('tmg-admin:isAdmin', function(isAdmin)
        if not isAdmin then return end
        
        Telemetry.isAdmin = true
        Telemetry.names = not Telemetry.names
        
        local msg = Telemetry.names and Lang:t('success.names_activated') or Lang:t('error.names_deactivated')
        local type = Telemetry.names and 'success' or 'error'
        
        TMGCore.Functions.Notify(msg, type)
        ManageTelemetryThread()
    end)
end)

RegisterNetEvent('tmg-admin:client:Show', function(players)
    if not Telemetry.isAdmin then return end
    if not Telemetry.blips and not Telemetry.names then return end

    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)

    for _, player in ipairs(players) do
        local playeridx = GetPlayerFromServerId(player.id)
        if playeridx ~= -1 then
            local ped = GetPlayerPed(playeridx)
            
            if Telemetry.names then
                local nameStr = string.format("ID: %s | %s", player.id, player.name)
                
                if not activeTags[ped] then
                    activeTags[ped] = CreateFakeMpGamerTag(ped, nameStr, false, false, '', false)
                end
                
                local tag = activeTags[ped]
                SetMpGamerTagAlpha(tag, 0, 255) 
                SetMpGamerTagAlpha(tag, 2, 255) 
                SetMpGamerTagAlpha(tag, 4, 255) 
                SetMpGamerTagAlpha(tag, 6, 255) 
                SetMpGamerTagHealthBarColour(tag, 25) 

                SetMpGamerTagVisibility(tag, 0, true) 
                SetMpGamerTagVisibility(tag, 2, true) 
                SetMpGamerTagVisibility(tag, 4, NetworkIsPlayerTalking(playeridx))
                SetMpGamerTagVisibility(tag, 6, GetPlayerInvincible(playeridx))
            else
                if activeTags[ped] then
                    RemoveMpGamerTag(activeTags[ped])
                    activeTags[ped] = nil
                end
            end

            if Telemetry.blips then
                local blip = GetBlipFromEntity(ped)
                if not DoesBlipExist(blip) then
                    blip = AddBlipForEntity(ped)
                    SetBlipSprite(blip, 1)
                    ShowHeadingIndicatorOnBlip(blip, true)
                else
                    local veh = GetVehiclePedIsIn(ped, false)
                    local blipSprite = GetBlipSprite(blip)
                    
                    if IsEntityDead(ped) then
                        if blipSprite ~= 274 then
                            SetBlipSprite(blip, 274)
                            ShowHeadingIndicatorOnBlip(blip, false)
                        end
                    elseif veh ~= 0 then
                        local classveh = GetVehicleClass(veh)
                        local modelveh = GetEntityModel(veh)
                        local newSprite = 225
                        local showHeading = true

                        if classveh == 8 or classveh == 13 then newSprite = 226; showHeading = false
                        elseif classveh == 9 then newSprite = 757; showHeading = false
                        elseif classveh == 10 or classveh == 11 or classveh == 20 then newSprite = 477; showHeading = false
                        elseif classveh == 12 then newSprite = 67; showHeading = false
                        elseif classveh == 14 then newSprite = 427; showHeading = false
                        elseif classveh == 15 then newSprite = 422; showHeading = false
                        elseif classveh == 16 then
                            if modelveh == `besra` or modelveh == `hydra` or modelveh == `lazer` then
                                newSprite = 424; showHeading = false
                            else
                                newSprite = 423; showHeading = false
                            end
                        elseif classveh == 17 then newSprite = 198; showHeading = false
                        elseif classveh == 18 then newSprite = 56; showHeading = false
                        elseif classveh == 19 then
                            if modelveh == `rhino` then newSprite = 421; showHeading = false
                            else newSprite = 750; showHeading = false end
                        else
                            if modelveh == `insurgent` or modelveh == `insurgent2` or modelveh == `limo2` then
                                newSprite = 426; showHeading = false
                            else
                                newSprite = 225; showHeading = true
                            end
                        end

                        -- Only send native updates if the sprite actually changed
                        if blipSprite ~= newSprite then
                            SetBlipSprite(blip, newSprite)
                            ShowHeadingIndicatorOnBlip(blip, showHeading)
                        end

                        local passengers = GetVehicleNumberOfPassengers(veh)
                        if passengers and passengers > 0 then
                            if not IsVehicleSeatFree(veh, -1) then passengers = passengers + 1 end
                            ShowNumberOnBlip(blip, passengers)
                        else
                            HideNumberOnBlip(blip)
                        end
                    else
                        HideNumberOnBlip(blip)
                        if blipSprite ~= 1 then
                            SetBlipSprite(blip, 1)
                            ShowHeadingIndicatorOnBlip(blip, true)
                        end
                    end

                    local activeEntity = veh ~= 0 and veh or ped
                    SetBlipRotation(blip, math.ceil(GetEntityHeading(activeEntity)))
                    SetBlipNameToPlayerName(blip, playeridx)
                    SetBlipScale(blip, 0.85)

                    if IsPauseMenuActive() then
                        SetBlipAlpha(blip, 255)
                    else
                        local targetCoords = GetEntityCoords(ped)
                        local distance = #(myCoords - targetCoords)
                        local alpha = math.floor(900 - distance)
                        
                        if alpha < 0 then alpha = 0 elseif alpha > 255 then alpha = 255 end
                        SetBlipAlpha(blip, alpha)
                    end
                end
            else
                local blip = GetBlipFromEntity(ped)
                if DoesBlipExist(blip) then RemoveBlip(blip) end
            end
        end
    end
end)