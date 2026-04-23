local TMGCore = exports['tmg-core']:GetCoreObject()

local NoClipState = {
    active = false,
    ped = nil,
    entity = nil,
    camera = nil,
    alpha = 51,
    inVehicle = false,
    speed = 1.0,
    maxSpeed = 16.0,
    lastCoords = nil
}

local BINDINGS = {
    FORWARD = 32, BACK = 33, LEFT = 34, RIGHT = 35, UP = 44, DOWN = 46,
    DEC_SPEED = 14, INC_SPEED = 15, RESET = 348,
    SLOW = 36, FAST = 21, FASTER = 19
}


local function GetGroundCoords(coords)
    local ray = StartShapeTestRay(coords.x, coords.y, coords.z, coords.x, coords.y, -1000.0, 1, 0)
    local _, hit, hitCoords = GetShapeTestResult(ray)
    return (hit == 1) and hitCoords or coords
end

local function SetupNoClipCamera()
    local rot = GetEntityRotation(NoClipState.entity)
    NoClipState.camera = CreateCameraWithParams('DEFAULT_SCRIPTED_CAMERA', GetEntityCoords(NoClipState.entity), vector3(0.0, 0.0, rot.z), 75.0)
    SetCamActive(NoClipState.camera, true)
    RenderScriptCams(true, true, 700, false, false) -- Faster transition (700ms)

    local offset = NoClipState.inVehicle and vector3(0.0, -4.5, 2.0) or vector3(0.0, -2.0, 0.5)
    AttachCamToEntity(NoClipState.camera, NoClipState.entity, offset.x, offset.y, offset.z, true)
end

local function DestroyNoClipCamera()
    SetGameplayCamRelativeHeading(0)
    RenderScriptCams(false, true, 700, true, true)
    DetachEntity(NoClipState.entity, true, true)
    if DoesCamExist(NoClipState.camera) then
        SetCamActive(NoClipState.camera, false)
        DestroyCam(NoClipState.camera, true)
    end
end

-- [[ 3. KINETIC CORE THREAD ]]

local function RunKineticNoClip()
    CreateThread(function()
        print("^3[TMG System]^7 Kinetic NoClip: ENGAGED")
        while NoClipState.active do
            Wait(0)
            
            local ped = PlayerPedId()
            local currentCoords = GetEntityCoords(NoClipState.entity)

            -- 1. INPUT SIEVE (TMG Optimization)
            HudWeaponWheelIgnoreSelection()
            DisableAllControlActions(0) -- Block standard game actions
            
            -- Enable essential UI/Looking controls
            EnableControlAction(0, 220, true) -- Look LR
            EnableControlAction(0, 221, true) -- Look UD
            EnableControlAction(0, 245, true) -- Chat
            
            -- 2. CAMERA & HEADING MATRIX
            local camRot = GetCamRot(NoClipState.camera, 2)
            local rightX, rightY = GetControlNormal(0, 220), GetControlNormal(0, 221)
            
            local newX = math.max(-89.0, math.min(89.0, camRot.x + (rightY * -5.0)))
            local newZ = camRot.z + (rightX * -10.0)
            
            SetCamRot(NoClipState.camera, vector3(newX, camRot.y, newZ), 2)
            SetEntityHeading(NoClipState.entity, newZ)

            -- 3. SPEED PROCESSING
            if IsDisabledControlPressed(2, BINDINGS.DEC_SPEED) then 
                NoClipState.speed = math.max(0.1, NoClipState.speed - 0.1)
            elseif IsDisabledControlPressed(2, BINDINGS.INC_SPEED) then 
                NoClipState.speed = math.min(NoClipState.maxSpeed, NoClipState.speed + 0.1)
            elseif IsDisabledControlJustReleased(0, BINDINGS.RESET) then 
                NoClipState.speed = 1.0 
            end

            local multiplier = 1.0
            if IsDisabledControlPressed(0, BINDINGS.FAST) then multiplier = 2.5
            elseif IsDisabledControlPressed(0, BINDINGS.FASTER) then multiplier = 5.0
            elseif IsDisabledControlPressed(0, BINDINGS.SLOW) then multiplier = 0.3 end

            local moveSpeed = NoClipState.speed * multiplier
            
            -- 4. KINETIC MOVEMENT (Using Disabled Checks)
            -- We use GetCamMatrix/EntityMatrix to calculate the vectors
            local forward, right, up, _ = GetEntityMatrix(NoClipState.entity)
            local nextPos = currentCoords

            -- Y-Axis (Forward/Back)
            if IsDisabledControlPressed(0, BINDINGS.FORWARD) then nextPos = nextPos + (forward * moveSpeed)
            elseif IsDisabledControlPressed(0, BINDINGS.BACK) then nextPos = nextPos - (forward * moveSpeed) end
            
            -- X-Axis (Left/Right)
            if IsDisabledControlPressed(0, BINDINGS.LEFT) then nextPos = nextPos - (right * moveSpeed)
            elseif IsDisabledControlPressed(0, BINDINGS.RIGHT) then nextPos = nextPos + (right * moveSpeed) end
            
            -- Z-Axis (Up/Down)
            if IsDisabledControlPressed(0, BINDINGS.UP) then nextPos = nextPos + (vector3(0,0,1) * moveSpeed)
            elseif IsDisabledControlPressed(0, BINDINGS.DOWN) then nextPos = nextPos - (vector3(0,0,1) * moveSpeed) end

            -- 5. ENTITY PHASING
            SetEntityCoordsNoOffset(NoClipState.entity, nextPos.x, nextPos.y, nextPos.z, true, true, true)

            -- Persistence Guards
            FreezeEntityPosition(NoClipState.entity, true)
            SetEntityCollision(NoClipState.entity, false, false)
            SetEntityVisible(NoClipState.entity, false, false)
            SetEntityInvincible(NoClipState.entity, true)
            SetPoliceIgnorePlayer(NoClipState.ped, true)
        end
        
        -- CLEANUP SEQUENCE
        local finalPed = PlayerPedId()
        FreezeEntityPosition(NoClipState.entity, false)
        SetEntityCollision(NoClipState.entity, true, true)
        SetEntityVisible(NoClipState.entity, true, false)
        SetEntityInvincible(NoClipState.entity, false)
        SetPoliceIgnorePlayer(finalPed, false)
        print("^3[TMG System]^7 Kinetic NoClip: DISCONNECTED")
    end)
end


ToggleNoClip = function(state)
    NoClipState.active = (state ~= nil) and state or not NoClipState.active
    NoClipState.ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(NoClipState.ped, false)
    
    NoClipState.inVehicle = (veh ~= 0)
    NoClipState.entity = NoClipState.inVehicle and veh or NoClipState.ped

    if NoClipState.active then
        SetupNoClipCamera()
        RunKineticNoClip()
        PlaySoundFromEntity(-1, 'SELECT', NoClipState.ped, 'HUD_LIQUOR_STORE_SOUNDSET', 0, 0)
    else
        local ground = GetGroundCoords(GetEntityCoords(NoClipState.entity))
        SetEntityCoords(NoClipState.entity, ground.x, ground.y, ground.z)
        DestroyNoClipCamera()
        PlaySoundFromEntity(-1, 'CANCEL', NoClipState.ped, 'HUD_LIQUOR_STORE_SOUNDSET', 0, 0)
    end

    TMGCore.Functions.Notify(NoClipState.active and "Kinetic NoClip Engaged" or "Kinetic NoClip Disengaged")
end

RegisterNetEvent('tmg-admin:client:ToggleNoClip', function()
    ToggleNoClip()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if NoClipState.active then ToggleNoClip(false) end
    end
end)