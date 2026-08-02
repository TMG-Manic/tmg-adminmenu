local TMGCore = exports['tmg-core']:GetCoreObject()

local activeThreads = {
    godmode = false,
    coords = false,
    vehDev = false,
    invisible = false,
    devMode = false
}

local AdminState = {
    menuBuilt = false,
    authLock = false,
    banLength = nil,
    banReason = 'Unknown',
    kickReason = 'Unknown',
    menuLocation = 'topright',
    menus = {},
    hooks = {}
}

local function Draw2DText(content, font, colour, scale, x, y)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(colour[1], colour[2], colour[3], 255)
    SetTextDropShadow()
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(content)
    EndTextCommandDisplayText(x, y)
end

local function LocalInput(text, number, windows)
    AddTextEntry('FMMC_MPM_NA', text)
    DisplayOnscreenKeyboard(1, 'FMMC_MPM_NA', '', windows or '', '', '', '', number or 30)
    
    local timeout = GetGameTimer() + 60000 
    
    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
        if GetGameTimer() > timeout then 
            print("^3[TMG Security]^7 Keyboard input matrix timed out. Restoring controls.")
            return nil 
        end
    end

    if GetOnscreenKeyboardResult() then
        return GetOnscreenKeyboardResult()
    end
    
    return nil
end

local function LocalInputInt(text, number, windows)
    local result = LocalInput(text, number, windows)
    return tonumber(result)
end

local function ToggleShowCoordinates()
    activeThreads.coords = not activeThreads.coords
    
    if activeThreads.coords then
        CreateThread(function()
            local x, y = 0.4, 0.025
            while activeThreads.coords do
                local ped = PlayerPedId()
                local coords = GetEntityCoords(ped)
                local heading = TMGCore.Shared.Round(GetEntityHeading(ped), 2)
                
                local cx = TMGCore.Shared.Round(coords.x, 2)
                local cy = TMGCore.Shared.Round(coords.y, 2)
                local cz = TMGCore.Shared.Round(coords.z, 2)
                
                local displayString = string.format('~w~%s~b~ vector4(~w~%s~b~, ~w~%s~b~, ~w~%s~b~, ~w~%s~b~)', Lang:t('info.ped_coords'), cx, cy, cz, heading)
                
                Draw2DText(displayString, 4, {66, 182, 245}, 0.4, x, y)
                Wait(0)
            end
        end)
    end
end

local function ToggleVehicleDeveloperMode()
    activeThreads.vehDev = not activeThreads.vehDev
    
    if activeThreads.vehDev then
        CreateThread(function()
            local x, y = 0.4, 0.888
            while activeThreads.vehDev do
                local ped = PlayerPedId()
                
                if IsPedInAnyVehicle(ped, false) then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    local netID = VehToNet(vehicle)
                    local hash = GetEntityModel(vehicle)
                    local modelName = GetLabelText(GetDisplayNameFromVehicleModel(hash))
                    
                    local eHealth = TMGCore.Shared.Round(GetVehicleEngineHealth(vehicle), 2)
                    local bHealth = TMGCore.Shared.Round(GetVehicleBodyHealth(vehicle), 2)
                    
                    Draw2DText(Lang:t('info.vehicle_dev_data'), 4, {66, 182, 245}, 0.4, x, y)
                    Draw2DText(string.format('%s~b~%s~s~ | %s~b~%s~s~', Lang:t('info.ent_id'), vehicle, Lang:t('info.net_id'), netID), 4, {255, 255, 255}, 0.4, x, y + 0.025)
                    Draw2DText(string.format('%s~b~%s~s~ | %s~b~%s~s~', Lang:t('info.model'), modelName, Lang:t('info.hash'), hash), 4, {255, 255, 255}, 0.4, x, y + 0.050)
                    Draw2DText(string.format('%s~b~%s~s~ | %s~b~%s~s~', Lang:t('info.eng_health'), eHealth, Lang:t('info.body_health'), bHealth), 4, {255, 255, 255}, 0.4, x, y + 0.075)
                end
                Wait(0)
            end
        end)
    end
end

local function CopyToClipboard(dataType)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = TMGCore.Shared.Round(GetEntityHeading(ped), 2)
    
    local x = TMGCore.Shared.Round(coords.x, 2)
    local y = TMGCore.Shared.Round(coords.y, 2)
    local z = TMGCore.Shared.Round(coords.z, 2)

    local outputString = ""

    if dataType == 'coords2' then
        outputString = string.format('vector2(%s, %s)', x, y)
    elseif dataType == 'coords3' then
        outputString = string.format('vector3(%s, %s, %s)', x, y, z)
    elseif dataType == 'coords4' then
        outputString = string.format('vector4(%s, %s, %s, %s)', x, y, z, heading)
    elseif dataType == 'heading' then
        outputString = tostring(heading)
    elseif dataType == 'freeaimEntity' then
        local entity = GetFreeAimEntity()
        if entity then
            local eHash = GetEntityModel(entity)
            local eName = Entities[eHash] or 'Unknown'
            local eCoords = GetEntityCoords(entity)
            local eRot = GetEntityRotation(entity)
            
            outputString = string.format(
                'Model Name:\t%s\nModel Hash:\t%s\n\nHeading:\t%s\nCoords:\t\tvector3(%s, %s, %s)\nRotation:\tvector3(%s, %s, %s)', 
                eName, eHash, TMGCore.Shared.Round(GetEntityHeading(entity), 2), 
                TMGCore.Shared.Round(eCoords.x, 2), TMGCore.Shared.Round(eCoords.y, 2), TMGCore.Shared.Round(eCoords.z, 2), 
                TMGCore.Shared.Round(eRot.x, 2), TMGCore.Shared.Round(eRot.y, 2), TMGCore.Shared.Round(eRot.z, 2)
            )
        else
            return TMGCore.Functions.Notify(Lang:t('error.failed_entity_copy'), 'error')
        end
    end

    if outputString ~= "" then
        SendNUIMessage({ string = outputString })
        TMGCore.Functions.Notify(Lang:t('success.coords_copied'), 'success')
    end
end

local function OpenPermsMenu(permsply)
    TMGCore.Functions.TriggerCallback('tmg-admin:server:getrank', function(rank)
        if not rank then
            MenuV:CloseMenu(AdminState.menus.main)
            print("^1[TMG Security]^7 Permissions check failed. Aborting UI generation.")
            return
        end

        local m = AdminState.menus.perms
        MenuV:OpenMenu(m)
        m:ClearItems()

        local groupMatrix = {
            [1] = { { rank = 'user', label = 'User' } },
            [2] = { { rank = 'admin', label = 'Admin' } },
            [3] = { { rank = 'god', label = 'God' } }
        }

        local selectedgroup = 'Unknown'

        m:AddSlider({
            icon = '🎟️',
            label = 'Group',
            value = 'user',
            values = { 
                { label = 'User', value = 'user', description = 'Standard Access' }, 
                { label = 'Admin', value = 'admin', description = 'Elevated Access' }, 
                { label = 'God', value = 'god', description = 'Maximum Access' } 
            },
            change = function(_, newValue, _)
                selectedgroup = groupMatrix[newValue] or 'Unknown'
            end
        })

        m:AddButton({
            icon = '✅',
            label = Lang:t('info.confirm'),
            value = 'giveperms',
            description = 'Finalize permission delegation',
            select = function(_)
                if selectedgroup ~= 'Unknown' then
                    TriggerServerEvent('tmg-admin:server:setPermissions', permsply.id, selectedgroup)
                    TMGCore.Functions.Notify(Lang:t('success.changed_perm'), 'success')
                    selectedgroup = 'Unknown'
                    m:Close() 
                else
                    TMGCore.Functions.Notify(Lang:t('error.changed_perm_failed'), 'error')
                end
            end
        })
    end)
end

local function OpenKickMenu(kickplayer)
    local m = AdminState.menus.kick
    MenuV:OpenMenu(m)
    m:ClearItems()

    AdminState.kickReason = 'Unknown'

    m:AddButton({
        icon = '📝',
        label = Lang:t('info.reason'),
        value = 'reason',
        description = Lang:t('desc.kick_reason'),
        select = function(_)
            local input = LocalInput(Lang:t('desc.kick_reason'), 255)
            if input and input ~= "" then
                AdminState.kickReason = input
                TMGCore.Functions.Notify("Reason logged: " .. input, "success")
            else
                TMGCore.Functions.Notify("Input cancelled.", "error")
            end
        end
    })

    m:AddButton({
        icon = '🥾',
        label = Lang:t('info.confirm'),
        value = 'kick',
        description = Lang:t('desc.confirm_kick'),
        select = function(_)
            if AdminState.kickReason ~= 'Unknown' then
                TriggerServerEvent('tmg-admin:server:kick', kickplayer, AdminState.kickReason)
                AdminState.kickReason = 'Unknown'
                m:Close() 
            else
                TMGCore.Functions.Notify(Lang:t('error.missing_reason'), 'error')
            end
        end
    })
end

local banTimeMatrix = {
    { label = Lang:t('time.onehour'), value = '3600' },
    { label = Lang:t('time.sixhour'), value = '21600' },
    { label = Lang:t('time.twelvehour'), value = '43200' },
    { label = Lang:t('time.oneday'), value = '86400' },
    { label = Lang:t('time.threeday'), value = '259200' },
    { label = Lang:t('time.oneweek'), value = '604800' },
    { label = Lang:t('time.onemonth'), value = '2678400' },
    { label = Lang:t('time.threemonth'), value = '8035200' },
    { label = Lang:t('time.sixmonth'), value = '16070400' },
    { label = Lang:t('time.oneyear'), value = '32140800' },
    { label = Lang:t('time.permanent'), value = '99999999999' },
    { label = Lang:t('time.self'), value = 'self' }
}

local sliderValues = {}
for _, t in ipairs(banTimeMatrix) do
    sliderValues[#sliderValues + 1] = { label = t.label, value = t.value, description = Lang:t('time.ban_length') }
end

local function OpenBanMenu(banplayer)
    local m = AdminState.menus.ban
    MenuV:OpenMenu(m)
    m:ClearItems()

    AdminState.banReason = 'Unknown'
    AdminState.banLength = '3600'
    
    m:AddButton({
        icon = '📝',
        label = Lang:t('info.reason'),
        value = 'reason',
        description = Lang:t('desc.ban_reason'),
        select = function(_)
            local input = LocalInput(Lang:t('desc.ban_reason'), 255)
            if input and input ~= "" then
                AdminState.banReason = input
                TMGCore.Functions.Notify("Reason logged: " .. input, "success")
            else
                TMGCore.Functions.Notify("Input cancelled.", "error")
            end
        end
    })

    m:AddSlider({
        icon = '⏲️',
        label = Lang:t('info.length'),
        value = '3600',
        values = sliderValues,
        select = function(_, newValue, _)
            if newValue == 'self' then
                local input = LocalInputInt('Custom Ban Length (Seconds)', 11)
                if input and input > 0 then
                    AdminState.banLength = input
                    TMGCore.Functions.Notify("Custom duration logged.", "success")
                else
                    TMGCore.Functions.Notify("Invalid or cancelled duration. Reverting to 1 hour.", "error")
                    AdminState.banLength = '3600'
                end
            else
                AdminState.banLength = newValue
            end
        end
    })

    m:AddButton({
        icon = '🔨',
        label = Lang:t('info.confirm'),
        value = 'ban',
        description = Lang:t('desc.confirm_ban'),
        select = function(_)
            if AdminState.banReason ~= 'Unknown' and AdminState.banLength ~= nil then
                TriggerServerEvent('tmg-admin:server:ban', banplayer, AdminState.banLength, AdminState.banReason)
                AdminState.banReason = 'Unknown'
                AdminState.banLength = nil
                m:Close()
            else
                TMGCore.Functions.Notify(Lang:t('error.invalid_reason_length_ban'), 'error')
            end
        end
    })
end

local playerActionMatrix = {
    { icon = '💀', label = Lang:t('menu.kill'), value = 'kill', descPrefix = Lang:t('menu.kill') },
    { icon = '🏥', label = Lang:t('menu.revive'), value = 'revive', descPrefix = Lang:t('menu.revive') },
    { icon = '🥶', label = Lang:t('menu.freeze'), value = 'freeze', descPrefix = Lang:t('menu.freeze') },
    { icon = '👀', label = Lang:t('menu.spectate'), value = 'spectate', descPrefix = Lang:t('menu.spectate') },
    { icon = '➡️', label = Lang:t('info.go_to'), value = 'goto', descPrefix = Lang:t('info.go_to') },
    { icon = '⬅️', label = Lang:t('menu.bring'), value = 'bring', descPrefix = Lang:t('menu.bring') },
    { icon = '🚗', label = Lang:t('menu.sit_in_vehicle'), value = 'intovehicle', descPrefix = Lang:t('desc.sit_in_veh_desc') },
    { icon = '🎒', label = Lang:t('menu.open_inv'), value = 'inventory', descPrefix = Lang:t('info.open') },
    { icon = '👕', label = Lang:t('menu.give_clothing_menu'), value = 'cloth', descPrefix = Lang:t('desc.clothing_menu_desc') },
    { icon = '🥾', label = Lang:t('menu.kick'), value = 'kick', descPrefix = Lang:t('menu.kick'), subMenu = OpenKickMenu },
    { icon = '🚫', label = Lang:t('menu.ban'), value = 'ban', descPrefix = Lang:t('menu.ban'), subMenu = OpenBanMenu },
    { icon = '🎟️', label = Lang:t('menu.permissions'), value = 'perms', descPrefix = Lang:t('info.give'), subMenu = OpenPermsMenu }
}

local function OpenPlayerMenus(player)
    local cid = player.cid or player.citizenid or "Unknown"
    
    local m = MenuV:CreateMenu(false, cid .. ' ' .. Lang:t('info.options'), AdminState.menuLocation, 220, 20, 60, 'size-125', 'none', 'menuv')
    m:ClearItems()
    MenuV:OpenMenu(m)

    for _, action in ipairs(playerActionMatrix) do
        local dynamicDesc = string.format("%s %s", action.descPrefix, cid)

        m:AddButton({
            icon = action.icon,
            label = ' ' .. action.label,
            value = action.value,
            description = dynamicDesc,
            select = function(_)
                if action.subMenu then
                    action.subMenu(player)
                else
                    TriggerServerEvent('tmg-admin:server:' .. action.value, player)
                end
            end
        })
    end
end

local dealerActionMatrix = {
    { icon = '➡️', labelPrefix = Lang:t('info.go_to'), command = 'dealergoto', descPrefix = Lang:t('desc.dealergoto_desc') },
    { icon = '☠', labelPrefix = Lang:t('info.remove'), command = 'deletedealer', descPrefix = Lang:t('desc.dealerremove_desc') }
}

local function OpenDealerMenu(dealer)
    local dealerName = dealer.name or "Unknown"

    local m = MenuV:CreateMenu(false, Lang:t('menu.edit_dealer') .. " " .. dealerName, AdminState.menuLocation, 220, 20, 60, 'size-125', 'none', 'menuv')
    m:ClearItems()
    MenuV:OpenMenu(m)

    for _, action in ipairs(dealerActionMatrix) do
        m:AddButton({
            icon = action.icon,
            label = string.format(" %s %s", action.labelPrefix, dealerName),
            value = action.command,
            description = string.format("%s %s", action.descPrefix, dealerName),
            select = function(btn)
                local execCommand = btn.Value
                TriggerServerEvent('TMGCore:CallCommand', execCommand, { dealerName })

                if execCommand == 'deletedealer' then
                    m:Close()
                    AdminState.menus.dealers:Close()
                    TMGCore.Functions.Notify("Dealer network connection severed.", "success")
                end
            end
        })
    end
end

local function OpenCarModelsMenu(categoryList)
    local mModels = AdminState.menus.vehModels
    mModels:ClearItems()
    MenuV:OpenMenu(mModels)

    for hash, data in pairs(categoryList) do
        mModels:AddButton({
            label = data.name,
            value = hash,
            description = string.format("Spawn %s", data.name),
            select = function(btn)
                local spawnHash = btn.Value
                TriggerServerEvent('TMGCore:CallCommand', 'car', { spawnHash })
            end
        })
    end
end


local function HydrateMenu(targetMenu, matrix)
    for _, item in ipairs(matrix) do
        local element
        if item.type == 'button' then
            element = targetMenu:AddButton({ icon = item.icon, label = item.label, value = item.value, description = item.desc })
        elseif item.type == 'checkbox' then
            element = targetMenu:AddCheckbox({ icon = item.icon, label = item.label, value = item.value, description = item.desc })
        end
        
        if item.id then AdminState.hooks[item.id] = element end
    end
end

local function BuildAdminInterface()
    if AdminState.menuBuilt then return end
    print("^3[TMG System]^7 Authenticated. Hydrating Admin UI Matrix...")

    local loc = AdminState.menuLocation
    local m = AdminState.menus

    m.main = MenuV:CreateMenu(false, Lang:t('menu.admin_menu'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test1')
    m.options = MenuV:CreateMenu(false, Lang:t('menu.admin_options'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test2')
    m.server = MenuV:CreateMenu(false, Lang:t('menu.manage_server'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test3')
    m.players = MenuV:CreateMenu(false, Lang:t('menu.online_players'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test4')
    m.vehicles = MenuV:CreateMenu(false, Lang:t('menu.vehicle_options'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test5')
    m.dealers = MenuV:CreateMenu(false, Lang:t('menu.dealer_list'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test6')
    m.developer = MenuV:CreateMenu(false, Lang:t('menu.developer_options'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test7')

    m.weather = MenuV:CreateMenu(false, Lang:t('menu.weather_conditions'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test8')
    m.ban = MenuV:CreateMenu(false, Lang:t('menu.ban'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test9')
    m.kick = MenuV:CreateMenu(false, Lang:t('menu.kick'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test10')
    m.perms = MenuV:CreateMenu(false, Lang:t('menu.permissions'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test11')
    m.vehCats = MenuV:CreateMenu(false, Lang:t('menu.vehicle_categories'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test12')
    m.vehModels = MenuV:CreateMenu(false, Lang:t('menu.vehicle_models'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test13')
    m.entityOpts = MenuV:CreateMenu(false, Lang:t('menu.entity_view_options'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test14')
    m.weapons = MenuV:CreateMenu(false, Lang:t('menu.spawn_weapons'), loc, 220, 20, 60, 'size-125', 'none', 'menuv', 'test15')

    local mainNavigationMatrix = {
        { type = 'button', id = nil,       icon = '😃', label = Lang:t('menu.admin_options'),    value = m.options,   desc = Lang:t('desc.admin_options_desc') },
        { type = 'button', id = 'players', icon = '🙍‍♂️', label = Lang:t('menu.player_management'), value = m.players,   desc = Lang:t('desc.player_management_desc') },
        { type = 'button', id = nil,       icon = '🎮', label = Lang:t('menu.server_management'),  value = m.server,    desc = Lang:t('desc.server_management_desc') },
        { type = 'button', id = nil,       icon = '🚗', label = Lang:t('menu.vehicles'),           value = m.vehicles,  desc = Lang:t('desc.vehicles_desc') },
        { type = 'button', id = 'dealers', icon = '💊', label = Lang:t('menu.dealer_list'),        value = m.dealers,   desc = Lang:t('desc.dealer_desc') },
        { type = 'button', id = nil,       icon = '🔧', label = Lang:t('menu.developer_options'),  value = m.developer, desc = Lang:t('desc.developer_desc') }
    }
    HydrateMenu(m.main, mainNavigationMatrix)

    local adminOptionsMatrix = {
        { type = 'checkbox', id = 'adminNoclip', icon = '🎥', label = Lang:t('menu.noclip'), value = nil, desc = Lang:t('desc.noclip_desc') },
        { type = 'button',   id = 'adminRevive', icon = '🏥', label = Lang:t('menu.revive'), value = 'revive', desc = Lang:t('desc.revive_desc') },
        { type = 'checkbox', id = 'adminInvisible', icon = '👻', label = Lang:t('menu.invisible'), value = nil, desc = Lang:t('desc.invisible_desc') },
        { type = 'checkbox', id = 'adminGodMode', icon = '⚡', label = Lang:t('menu.god'), value = nil, desc = Lang:t('desc.god_desc') },
        { type = 'checkbox', id = 'adminNames', icon = '📋', label = Lang:t('menu.names'), value = nil, desc = Lang:t('desc.names_desc') },
        { type = 'checkbox', id = 'adminBlips', icon = '📍', label = Lang:t('menu.blips'), value = nil, desc = Lang:t('desc.blips_desc') },
        { type = 'button',   id = nil, icon = '🎁', label = Lang:t('menu.spawn_weapons'), value = m.weapons, desc = Lang:t('desc.spawn_weapons_desc') }
    }
    HydrateMenu(m.options, adminOptionsMatrix)

    AdminState.hooks['serverWeather'] = m.server:AddButton({ icon = '🌡️', label = Lang:t('menu.weather_options'), value = m.weather, description = Lang:t('desc.weather_desc') })

    local serverTimeValues = {}
    for i = 0, 23 do
        local formattedHour = string.format("%02d", i)
        serverTimeValues[#serverTimeValues + 1] = { label = formattedHour, value = formattedHour, description = Lang:t('menu.time') }
    end
    AdminState.hooks['serverTime'] = m.server:AddSlider({ icon = '⏲️', label = Lang:t('menu.server_time'), value = GetClockHours(), values = serverTimeValues })

    local vehicleOptionsMatrix = {
        { type = 'button', id = 'vehSpawn', icon = '🚗', label = Lang:t('menu.spawn_vehicle'), value = m.vehCats, desc = Lang:t('desc.spawn_vehicle_desc') },
        { type = 'button', id = 'vehFix', icon = '🔧', label = Lang:t('menu.fix_vehicle'), value = 'fix', desc = Lang:t('desc.fix_vehicle_desc') },
        { type = 'button', id = 'vehBuy', icon = '💲', label = Lang:t('menu.buy'), value = 'buy', desc = Lang:t('desc.buy_desc') },
        { type = 'button', id = 'vehRemove', icon = '🗑️', label = Lang:t('menu.remove_vehicle'), value = 'remove', desc = Lang:t('desc.remove_vehicle_desc') },
        { type = 'button', id = 'vehMaxUpgrades', icon = '⚡️', label = Lang:t('menu.max_mods'), value = 'maxmods', desc = Lang:t('desc.max_mod_desc') }
    }
    HydrateMenu(m.vehicles, vehicleOptionsMatrix)

    local developerOptionsMatrix = {
        { type = 'button',   id = 'devCopyVec3', icon = '📋', label = Lang:t('menu.copy_vector3'), value = 'coords3', desc = Lang:t('desc.vector3_desc') },
        { type = 'button',   id = 'devCopyVec4', icon = '📋', label = Lang:t('menu.copy_vector4'), value = 'coords4', desc = Lang:t('desc.vector4_desc') },
        { type = 'button',   id = 'devCopyHeading', icon = '📋', label = Lang:t('menu.copy_heading'), value = 'heading', desc = Lang:t('desc.copy_heading_desc') },
        { type = 'checkbox', id = 'devToggleCoords', icon = '📍', label = Lang:t('menu.display_coords'), value = nil, desc = Lang:t('desc.display_coords_desc') },
        { type = 'checkbox', id = 'devVehicleMode', icon = '🚘', label = Lang:t('menu.vehicle_dev_mode'), value = nil, desc = Lang:t('desc.vehicle_dev_mode_desc') },
        { type = 'checkbox', id = 'devInfoMode', icon = '⚫', label = Lang:t('menu.hud_dev_mode'), value = nil, desc = Lang:t('desc.hud_dev_mode_desc') },
        { type = 'checkbox', id = 'devNoclip', icon = '🎥', label = Lang:t('menu.noclip'), value = nil, desc = Lang:t('desc.noclip_desc') },
        { type = 'button',   id = nil, icon = '🔍', label = Lang:t('menu.entity_view_options'), value = m.entityOpts, desc = Lang:t('desc.entity_view_desc') }
    }
    HydrateMenu(m.developer, developerOptionsMatrix)

    local entityDistanceValues = {}
    for i = 5, 50, 5 do
        entityDistanceValues[#entityDistanceValues + 1] = { label = tostring(i), value = i, description = Lang:t('menu.entity_view_distance') }
    end
    AdminState.hooks['entityDistance'] = m.entityOpts:AddSlider({ icon = '📏', label = Lang:t('menu.entity_view_distance'), value = GetCurrentEntityViewDistance(), values = entityDistanceValues })

    local entityViewMatrix = {
        { type = 'button',   id = 'entityCopyInfo', icon = '📋', label = Lang:t('menu.entity_view_freeaim_copy'), value = 'freeaimEntity', desc = Lang:t('desc.entity_view_freeaim_copy_desc') },
        { type = 'checkbox', id = 'entityFreeaim',  icon = '🔫', label = Lang:t('menu.entity_view_freeaim'), value = nil, desc = Lang:t('desc.entity_view_freeaim_desc') },
        { type = 'checkbox', id = 'entityVehicle',  icon = '🚗', label = Lang:t('menu.entity_view_vehicles'), value = nil, desc = Lang:t('desc.entity_view_vehicles_desc') },
        { type = 'checkbox', id = 'entityPed',      icon = '🧍‍♂‍', label = Lang:t('menu.entity_view_peds'), value = nil, desc = Lang:t('desc.entity_view_peds_desc') },
        { type = 'checkbox', id = 'entityObject',   icon = '📦', label = Lang:t('menu.entity_view_objects'), value = nil, desc = Lang:t('desc.entity_view_objects_desc') }
    }
    HydrateMenu(m.entityOpts, entityViewMatrix)

    for _, weapon in pairs(TMGCore.Shared.Weapons) do
        m.weapons:AddButton({
            icon = '🎁',
            label = weapon.label,
            value = weapon.name,
            description = Lang:t('desc.spawn_weapons_desc'),
            select = function(_)
                TriggerServerEvent('tmg-admin:giveWeapon', weapon.name)
                TMGCore.Functions.Notify(Lang:t('success.spawn_weapon'), 'success')
            end
        })
    end

    local vehiclesByCategory = {}
    for hash, data in pairs(TMGCore.Shared.Vehicles) do
        local cat = data.category or "unknown"
        if not vehiclesByCategory[cat] then
            vehiclesByCategory[cat] = {}
        end
        vehiclesByCategory[cat][hash] = data
    end

    for catName, vehList in pairs(vehiclesByCategory) do
        m.vehCats:AddButton({
            label = TMGCore.Shared.FirstToUpper(catName),
            value = vehList,
            description = Lang:t('menu.category_name'),
            select = function(btn) OpenCarModelsMenu(btn.Value) end
        })
    end

    AdminState.menuBuilt = true
end

RegisterNetEvent('tmg-admin:client:openMenu', function()
    if AdminState.authLock then return end
    AdminState.authLock = true

    TMGCore.Functions.TriggerCallback('tmg-admin:isAdmin', function(isAdmin)
        AdminState.authLock = false
        if not isAdmin then return end

        BuildAdminInterface()
        MenuV:OpenMenu(AdminState.menus.main)
    end)
end)

RegisterNetEvent('tmg-admin:client:putIntoVehicle', function(netId)
    local vehicle = NetToVeh(netId)
    if DoesEntityExist(vehicle) then
        local ped = PlayerPedId()
        for seat = -1, GetVehicleMaxNumberOfPassengers(vehicle) - 1 do
            if IsVehicleSeatFree(vehicle, seat) then
                TaskWarpPedIntoVehicle(ped, vehicle, seat)
                TriggerEvent('TMGCore:Notify', Lang:t('success.entered_vehicle'), 'success')
                return
            end
        end
        TriggerEvent('TMGCore:Notify', Lang:t('error.no_free_seats'), 'error')
    end
end)

CreateThread(function()
    while not AdminState.menuBuilt do Wait(100) end

    AdminState.hooks['adminNames']:On('change', function() TriggerEvent('tmg-admin:client:toggleNames') end)
    AdminState.hooks['adminBlips']:On('change', function() TriggerEvent('tmg-admin:client:toggleBlips') end)
    AdminState.hooks['adminNoclip']:On('change', function() ToggleNoClip() end)
    AdminState.hooks['adminRevive']:On('select', function() TriggerEvent('hospital:client:Revive', PlayerPedId()) end)
    AdminState.hooks['adminInvisible']:On('change', function()
        activeThreads.invisible = not activeThreads.invisible
        SetEntityVisible(PlayerPedId(), not activeThreads.invisible, 0)
    end)
    AdminState.hooks['adminGodMode']:On('change', function()
        activeThreads.godmode = not activeThreads.godmode
        local ped = PlayerPedId()
        if activeThreads.godmode then
            CreateThread(function()
                while activeThreads.godmode do
                    Wait(0)
                    SetPlayerInvincible(ped, true)
                end
                SetPlayerInvincible(ped, false)
            end)
        end
    end)

    AdminState.hooks['players']:On('select', function()
        local m = AdminState.menus.players
        m:ClearItems()
        TMGCore.Functions.TriggerCallback('test:getplayers', function(players)
            if type(players) ~= "table" then 
                TMGCore.Functions.Notify("Network error: Failed to fetch player matrix.", "error")
                return 
            end
            if next(players) == nil then
                m:AddButton({ label = "No players online.", disabled = true })
                return
            end
            for _, pData in pairs(players) do
                m:AddButton({
                    label = string.format("%s %s | %s", Lang:t('info.id'), pData.id, pData.name),
                    value = pData,
                    description = Lang:t('info.player_name'),
                    select = function(btn) OpenPlayerMenus(btn.Value) end
                })
            end
        end)
    end)

    AdminState.hooks['dealers']:On('select', function()
        local m = AdminState.menus.dealers
        m:ClearItems()
        TMGCore.Functions.TriggerCallback('test:getdealers', function(dealers)
            if type(dealers) ~= "table" then 
                TMGCore.Functions.Notify("Network error: Failed to fetch dealer matrix.", "error")
                return 
            end
            if next(dealers) == nil then
                m:AddButton({ label = "No active dealers found.", disabled = true })
                return
            end
            for _, dData in pairs(dealers) do
                m:AddButton({
                    label = dData.name,
                    value = dData,
                    description = Lang:t('menu.dealer_name'),
                    select = function(btn) OpenDealerMenu(btn.Value) end
                })
            end
        end)
    end)
    local weatherMatrix = {
        { icon = '☀️', label = Lang:t('weather.extra_sunny'), value = 'EXTRASUNNY', desc = Lang:t('weather.extra_sunny_desc') },
        { icon = '☀️', label = Lang:t('weather.clear'),       value = 'CLEAR',      desc = Lang:t('weather.clear_desc') },
        { icon = '☀️', label = Lang:t('weather.neutral'),     value = 'NEUTRAL',    desc = Lang:t('weather.neutral_desc') },
        { icon = '🌁', label = Lang:t('weather.smog'),        value = 'SMOG',       desc = Lang:t('weather.smog_desc') },
        { icon = '🌫️', label = Lang:t('weather.foggy'),       value = 'FOGGY',      desc = Lang:t('weather.foggy_desc') },
        { icon = '⛅', label = Lang:t('weather.overcast'),    value = 'OVERCAST',   desc = Lang:t('weather.overcast_desc') },
        { icon = '☁️', label = Lang:t('weather.clouds'),      value = 'CLOUDS',     desc = Lang:t('weather.clouds_desc') },
        { icon = '🌤️', label = Lang:t('weather.clearing'),    value = 'CLEARING',   desc = Lang:t('weather.clearing_desc') },
        { icon = '☂️', label = Lang:t('weather.rain'),        value = 'RAIN',       desc = Lang:t('weather.rain_desc') },
        { icon = '⛈️', label = Lang:t('weather.thunder'),     value = 'THUNDER',    desc = Lang:t('weather.thunder_desc') },
        { icon = '❄️', label = Lang:t('weather.snow'),        value = 'SNOW',       desc = Lang:t('weather.snow_desc') },
        { icon = '🌨️', label = Lang:t('weather.blizzard'),    value = 'BLIZZARD',   desc = Lang:t('weather.blizzed_desc') },
        { icon = '❄️', label = Lang:t('weather.light_snow'),  value = 'SNOWLIGHT',  desc = Lang:t('weather.light_snow_desc') },
        { icon = '🌨️', label = Lang:t('weather.heavy_snow'),  value = 'XMAS',       desc = Lang:t('weather.heavy_snow_desc') },
        { icon = '🎃', label = Lang:t('weather.halloween'),   value = 'HALLOWEEN',  desc = Lang:t('weather.halloween_desc') }
    }
    
    AdminState.hooks['serverWeather']:On('select', function()
        local m = AdminState.menus.weather
        m:ClearItems()
        for _, wData in ipairs(weatherMatrix) do
            m:AddButton({
                icon = wData.icon, label = wData.label, value = wData.value, description = wData.desc,
                select = function(btn)
                    TriggerServerEvent('tmg-weathersync:server:setWeather', btn.Value)
                    TMGCore.Functions.Notify(Lang:t('weather.weather_changed', { value = wData.label }), 'success')
                end
            })
        end
    end)
    
    AdminState.hooks['serverTime']:On('select', function(_, value)
        local timeString = tostring(value)
        TriggerServerEvent('tmg-weathersync:server:setTime', timeString, timeString)
        TMGCore.Functions.Notify(Lang:t('time.changed', { time = timeString }), 'success')
    end)

    AdminState.hooks['vehFix']:On('select', function() TriggerServerEvent('TMGCore:CallCommand', 'fix', {}); TMGCore.Functions.Notify("Vehicle structural integrity restored.", "success") end)
    AdminState.hooks['vehBuy']:On('select', function() TriggerServerEvent('TMGCore:CallCommand', 'admincar', {}); TMGCore.Functions.Notify("Admin vehicle authorization granted.", "success") end)
    AdminState.hooks['vehRemove']:On('select', function() TriggerServerEvent('TMGCore:CallCommand', 'dv', {}); TMGCore.Functions.Notify("Entity wiped from local spacetime.", "success") end)
    AdminState.hooks['vehMaxUpgrades']:On('select', function() TriggerServerEvent('TMGCore:CallCommand', 'maxmods', {}); TMGCore.Functions.Notify("Performance augmentations applied.", "success") end)

    AdminState.hooks['devInfoMode']:On('change', function()
        activeThreads.devMode = not activeThreads.devMode
        TriggerEvent('tmg-admin:client:ToggleDevmode')
        SetPlayerInvincible(PlayerId(), activeThreads.devMode)
    end)
    AdminState.hooks['entityDistance']:On('select', function(_, value)
        SetEntityViewDistance(value)
        TMGCore.Functions.Notify(Lang:t('info.entity_view_distance', { distance = value }), 'success')
    end)
    AdminState.hooks['entityCopyInfo']:On('select', function() CopyToClipboard('freeaimEntity') end)
    AdminState.hooks['devCopyVec3']:On('select', function() CopyToClipboard('coords3') end)
    AdminState.hooks['devCopyVec4']:On('select', function() CopyToClipboard('coords4') end)
    AdminState.hooks['devCopyHeading']:On('select', function() CopyToClipboard('heading') end)
    AdminState.hooks['devToggleCoords']:On('change', function() ToggleShowCoordinates() end)
    AdminState.hooks['devVehicleMode']:On('change', function() ToggleVehicleDeveloperMode() end)
    AdminState.hooks['devNoclip']:On('change', function() ToggleNoClip() end)
    AdminState.hooks['entityFreeaim']:On('change', function() ToggleEntityFreeView() end)
    AdminState.hooks['entityVehicle']:On('change', function() ToggleEntityVehicleView() end)
    AdminState.hooks['entityObject']:On('change', function() ToggleEntityObjectView() end)
    AdminState.hooks['entityPed']:On('change', function() ToggleEntityPedView() end)
end)

RegisterNetEvent('tmg-admin:client:ToggleCoords', function() ToggleShowCoordinates() end)
RegisterNetEvent('tmg-admin:client:copyToClipboard', function(dataType) CopyToClipboard(dataType) end)