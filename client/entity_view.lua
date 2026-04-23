-- ==============================================================================
-- [[ TMG MAINFRAME: ENTITY INTELLIGENCE MATRIX ]]
-- ==============================================================================
local TMGCore = exports['tmg-core']:GetCoreObject()

local EntityState = {
    viewDistance = 10.0,
    enabled = false,
    freeAim = false,
    peds = false,
    objects = false,
    vehicles = false,
    freeAimEntity = nil,
    frozen = {}
}

-- Configurable settings derived from legacy parameters
local FreeAimInfoBoxX = 0.60 
local FreeAimInfoBoxY = 0.02 
local useKph          = true 

-- [[ 1. GEOMETRY & MATH UTILITIES ]]

local function RoundFloat(number, num)
    return math.floor(number * math.pow(10, num) + 0.5) / math.pow(10, num)
end

local function RoundVector3(vector, num)
    return 'vector3(' .. RoundFloat(vector.x, num) .. ', ' .. RoundFloat(vector.y, num) .. ', ' .. RoundFloat(vector.z, num) .. ')'
end

local function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

local RelationshipTypes = { ['0'] = 'Companion', ['1'] = 'Respect', ['2'] = 'Like', ['3'] = 'Neutral', ['4'] = 'Dislike', ['5'] = 'Hate', ['255'] = 'Pedestrians' }
local function GetPedRelationshipType(value)
    return RelationshipTypes[tostring(value)] or 'Unknown'
end

-- [[ 2. NATIVE RENDERING FUNCTIONS ]]

function RayCastGamePlayCamera(distance)
    local currentRenderingCam = false
    if not IsGameplayCamRendering() then
        currentRenderingCam = GetRenderingCam()
    end

    local cameraRotation = not currentRenderingCam and GetGameplayCamRot() or GetCamRot(currentRenderingCam, 2)
    local cameraCoord = not currentRenderingCam and GetGameplayCamCoord() or GetCamCoord(currentRenderingCam)
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local _, b, c, _, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
    return b, c, e
end

function DrawEntityBoundingBox(entity, color)
    local model = GetEntityModel(entity)
    local min, max = GetModelDimensions(model)
    local rightVector, forwardVector, upVector, position = GetEntityMatrix(entity)

    local dim = { x = 0.5 * (max.x - min.x), y = 0.5 * (max.y - min.y), z = 0.5 * (max.z - min.z) }
    local FUR = { x = position.x + dim.y * rightVector.x + dim.x * forwardVector.x + dim.z * upVector.x, y = position.y + dim.y * rightVector.y + dim.x * forwardVector.y + dim.z * upVector.y, z = 0 }
    local _, FUR_z = GetGroundZFor_3dCoord(FUR.x, FUR.y, 1000.0, 0)
    FUR.z = FUR_z + 2 * dim.z

    local BLL = { x = position.x - dim.y * rightVector.x - dim.x * forwardVector.x - dim.z * upVector.x, y = position.y - dim.y * rightVector.y - dim.x * forwardVector.y - dim.z * upVector.y, z = 0 }
    local _, BLL_z = GetGroundZFor_3dCoord(FUR.x, FUR.y, 1000.0, 0)
    BLL.z = BLL_z

    local edge1, edge5 = BLL, FUR
    local edge2 = { x = edge1.x + 2 * dim.y * rightVector.x, y = edge1.y + 2 * dim.y * rightVector.y, z = edge1.z + 2 * dim.y * rightVector.z }
    local edge3 = { x = edge2.x + 2 * dim.z * upVector.x, y = edge2.y + 2 * dim.z * upVector.y, z = edge2.z + 2 * dim.z * upVector.z }
    local edge4 = { x = edge1.x + 2 * dim.z * upVector.x, y = edge1.y + 2 * dim.z * upVector.y, z = edge1.z + 2 * dim.z * upVector.z }
    local edge6 = { x = edge5.x - 2 * dim.y * rightVector.x, y = edge5.y - 2 * dim.y * rightVector.y, z = edge5.z - 2 * dim.y * rightVector.z }
    local edge7 = { x = edge6.x - 2 * dim.z * upVector.x, y = edge6.y - 2 * dim.z * upVector.y, z = edge6.z - 2 * dim.z * upVector.z }
    local edge8 = { x = edge5.x - 2 * dim.z * upVector.x, y = edge5.y - 2 * dim.z * upVector.y, z = edge5.z - 2 * dim.z * upVector.z }

    color = color or { r = 255, g = 255, b = 255, a = 255 }
    DrawLine(edge1.x, edge1.y, edge1.z, edge2.x, edge2.y, edge2.z, color.r, color.g, color.b, color.a)
    DrawLine(edge1.x, edge1.y, edge1.z, edge4.x, edge4.y, edge4.z, color.r, color.g, color.b, color.a)
    DrawLine(edge2.x, edge2.y, edge2.z, edge3.x, edge3.y, edge3.z, color.r, color.g, color.b, color.a)
    DrawLine(edge3.x, edge3.y, edge3.z, edge4.x, edge4.y, edge4.z, color.r, color.g, color.b, color.a)
    DrawLine(edge5.x, edge5.y, edge5.z, edge6.x, edge6.y, edge6.z, color.r, color.g, color.b, color.a)
    DrawLine(edge5.x, edge5.y, edge5.z, edge8.x, edge8.y, edge8.z, color.r, color.g, color.b, color.a)
    DrawLine(edge6.x, edge6.y, edge6.z, edge7.x, edge7.y, edge7.z, color.r, color.g, color.b, color.a)
    DrawLine(edge7.x, edge7.y, edge7.z, edge8.x, edge8.y, edge8.z, color.r, color.g, color.b, color.a)
    DrawLine(edge1.x, edge1.y, edge1.z, edge7.x, edge7.y, edge7.z, color.r, color.g, color.b, color.a)
    DrawLine(edge2.x, edge2.y, edge2.z, edge8.x, edge8.y, edge8.z, color.r, color.g, color.b, color.a)
    DrawLine(edge3.x, edge3.y, edge3.z, edge5.x, edge5.y, edge5.z, color.r, color.g, color.b, color.a)
    DrawLine(edge4.x, edge4.y, edge4.z, edge6.x, edge6.y, edge6.z, color.r, color.g, color.b, color.a)
end

-- [[ 3. DATA AGGREGATION ]]

function GetEntityInfo(entity)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local entityType   = GetEntityType(entity)
    local entityHash   = GetEntityModel(entity)
    local entityName   = Entities[entityHash] or Lang:t('info.obj_unknown')
    local entityData   = { '~y~' .. Lang:t('info.entity_view_info'), '', Lang:t('info.model_hash') .. ' ~y~' .. entityHash, ' ', Lang:t('info.ent_id') .. ' ~y~' .. entity, Lang:t('info.obj_name') .. ' ~y~' .. entityName, Lang:t('info.net_id') .. ' ~y~' .. (NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or Lang:t('info.net_id_not_registered')), Lang:t('info.ent_owner') .. ' ~y~' .. GetPlayerServerId(NetworkGetEntityOwner(entity)), ' ' }

    if entityType == 1 then
        local pedRelationshipGroup = GetPedRelationshipGroupHash(entity)
        entityData[#entityData + 1] = Lang:t('info.cur_health') .. ' ~y~' .. GetEntityHealth(entity)
        entityData[#entityData + 1] = Lang:t('info.max_health') .. ' ~y~' .. GetPedMaxHealth(entity)
        entityData[#entityData + 1] = Lang:t('info.armour') .. ' ~y~' .. GetPedArmour(entity)
        entityData[#entityData + 1] = Lang:t('info.rel_group') .. ' ~y~' .. (Entities[pedRelationshipGroup] or Lang:t('info.rel_group_custom'))
        entityData[#entityData + 1] = Lang:t('info.rel_to_player') .. ' ~y~' .. GetPedRelationshipType(GetRelationshipBetweenPeds(entity, PlayerPedId()))
    elseif entityType == 2 then
        entityData[#entityData + 1] = Lang:t('info.veh_rpm') .. ' ~y~' .. RoundFloat(GetVehicleCurrentRpm(entity), 2)
        entityData[#entityData + 1] = (useKph and Lang:t('info.veh_speed_kph') or Lang:t('info.veh_speed_mph')) .. ' ~y~' .. RoundFloat((GetEntitySpeed(entity) * (useKph and 3.6 or 2.23694)), 0)
        entityData[#entityData + 1] = Lang:t('info.veh_cur_gear') .. ' ~y~' .. GetVehicleCurrentGear(entity)
        entityData[#entityData + 1] = Lang:t('info.veh_acceleration') .. ' ~y~' .. RoundFloat(GetVehicleAcceleration(entity), 2)
        entityData[#entityData + 1] = Lang:t('info.body_health') .. ' ~y~' .. GetVehicleBodyHealth(entity)
        entityData[#entityData + 1] = Lang:t('info.eng_health') .. ' ~y~' .. GetVehicleEngineHealth(entity)
    elseif entityType == 3 then
        entityData[#entityData + 1] = Lang:t('info.cur_health') .. ' ~y~' .. GetEntityHealth(entity)
    end

    local entityCoords = GetEntityCoords(entity)
    entityData[#entityData + 1] = ' '
    entityData[#entityData + 1] = Lang:t('info.dist_to_obj') .. ' ~y~' .. RoundFloat(#(playerCoords - entityCoords), 2)
    entityData[#entityData + 1] = Lang:t('info.obj_heading') .. ' ~y~' .. RoundFloat(GetEntityHeading(entity), 2)
    entityData[#entityData + 1] = Lang:t('info.obj_coords') .. ' ~y~' .. RoundVector3(entityCoords, 2)
    entityData[#entityData + 1] = Lang:t('info.obj_rot') .. ' ~y~' .. RoundVector3(GetEntityRotation(entity), 2)
    entityData[#entityData + 1] = Lang:t('info.obj_velocity') .. ' ~y~' .. RoundVector3(GetEntityVelocity(entity), 2)

    return entityData
end

function DrawEntityViewText(entity)
    local data = GetEntityInfo(entity)
    local posX, posY = FreeAimInfoBoxX, FreeAimInfoBoxY
    local titleSpacing, textSpacing = 0.03, 0.022
    local rectWidth = 0.18
    local rectHeight = ((#data - 1) * 0.022) + 0.03

    DrawRect(posX + (rectWidth / 2), posY + ((rectHeight / 2) - posY / 2), rectWidth, rectHeight, 11, 11, 11, 200)

    for k, v in ipairs(data) do
        SetTextScale(k == 1 and 0.50 or 0.35, k == 1 and 0.50 or 0.35)
        SetTextFont(4)
        SetTextOutline()
        SetTextColour(255, 255, 255, 215)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(v)
        EndTextCommandDisplayText(posX + (k == 1 and 0.05 or 0.005), posY)
        posY = posY + (k == 1 and titleSpacing or textSpacing)
    end
end

function DrawEntityViewTextInWorld(entity, coords)
    local onScreen, posX, posY = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end
    
    local data = GetEntityInfo(entity)
    local textOffsetY = 0.015
    local rectWidth = 0.12
    local rectHeight = (#data * 0.015) + 0.02

    DrawRect(posX, posY, rectWidth, rectHeight, 11, 11, 11, 200)

    for k, v in ipairs(data) do
        if k > 2 then
            SetTextScale(0.25, 0.25)
            SetTextFont(4)
            SetTextOutline()
            SetTextColour(255, 255, 255, 215)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(v)
            EndTextCommandDisplayText(posX - rectWidth / 2 + 0.005, posY - rectHeight / 2 + 0.01)
            posY = posY + textOffsetY
        end
    end
end

-- [[ 4. POOL PROCESSING & CORE THREAD ]]

local function ProcessEntityPool(poolName, stateKey)
    if not EntityState[stateKey] then return end
    
    local myCoords = GetEntityCoords(PlayerPedId())
    local entities = GetGamePool(poolName) 

    for i = 1, #entities do
        local ent = entities[i]
        if ent ~= EntityState.freeAimEntity then
            local entCoords = GetEntityCoords(ent)
            local dist = #(myCoords - entCoords)

            if dist < EntityState.viewDistance then
                if dist > 5.0 then
                    DrawEntityBoundingBox(ent)
                else
                    DrawEntityViewTextInWorld(ent, entCoords)
                end
            end
        end
    end
end

local function RunEntityIntelligenceThread()
    if EntityState.enabled then return end
    EntityState.enabled = true

    CreateThread(function()
        print("^3[TMG System]^7 Entity Intelligence Matrix: ONLINE")
        while EntityState.enabled do
            local sleep = 500 
            
            if EntityState.freeAim or EntityState.peds or EntityState.objects or EntityState.vehicles then
                sleep = 0
                local myPed = PlayerPedId()
                local myCoords = GetEntityCoords(myPed)

                ProcessEntityPool('CPed', 'peds')
                ProcessEntityPool('CObject', 'objects')
                ProcessEntityPool('CVehicle', 'vehicles')

                if EntityState.freeAim then
                    local hit, coords, entity = RayCastGamePlayCamera(1000.0)
                    local color = { r = 255, g = 255, b = 255, a = 200 }
                    
                    if hit and (IsEntityAVehicle(entity) or IsEntityAPed(entity) or IsEntityAnObject(entity)) then
                        color = { r = 0, g = 255, b = 0, a = 200 }
                        EntityState.freeAimEntity = entity
                        DrawEntityBoundingBox(entity, color)
                        DrawEntityViewText(entity)

                        if IsControlJustReleased(0, 47) then 
                            EntityState.frozen[entity] = not EntityState.frozen[entity]
                            FreezeEntityPosition(entity, EntityState.frozen[entity])
                            TMGCore.Functions.Notify("Entity Status: "..(EntityState.frozen[entity] and "FROZEN" or "UNFROZEN"), "success")
                        end

                        if IsControlJustReleased(0, 38) then 
                            SetEntityAsMissionEntity(entity, true, true)
                            DeleteEntity(entity)
                            TMGCore.Functions.Notify("Entity Expunged", "success")
                        end
                    else
                        EntityState.freeAimEntity = nil
                    end
                    
                    DrawLine(myCoords.x, myCoords.y, myCoords.z, coords.x, coords.y, coords.z, color.r, color.g, color.b, color.a)
                    DrawMarker(28, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.1, 0.1, 0.1, color.r, color.g, color.b, color.a, false, true, 2, nil, nil, false, false)
                end
            end

            if not EntityState.freeAim and not EntityState.peds and not EntityState.objects and not EntityState.vehicles then
                EntityState.enabled = false
            end
            Wait(sleep)
        end
        print("^3[TMG System]^7 Entity Intelligence Matrix: OFFLINE")
    end)
end

-- [[ 5. EXPORTED INTERFACE ]]

ToggleEntityFreeView = function() EntityState.freeAim = not EntityState.freeAim; RunEntityIntelligenceThread() end
ToggleEntityObjectView = function() EntityState.objects = not EntityState.objects; RunEntityIntelligenceThread() end
ToggleEntityVehicleView = function() EntityState.vehicles = not EntityState.vehicles; RunEntityIntelligenceThread() end
ToggleEntityPedView = function() EntityState.peds = not EntityState.peds; RunEntityIntelligenceThread() end
SetEntityViewDistance = function(data) EntityState.viewDistance = tonumber(data) * 5.0 end
GetCurrentEntityViewDistance = function() return EntityState.viewDistance / 5 end
GetFreeAimEntity = function() return EntityState.freeAimEntity end