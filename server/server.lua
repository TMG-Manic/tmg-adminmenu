local TMGCore = exports['tmg-core']:GetCoreObject()
local frozen = false

local permissions = {
    ['kill'] = 'admin', ['ban'] = 'admin', ['noclip'] = 'admin', 
    ['kickall'] = 'admin', ['kick'] = 'admin', ['revive'] = 'admin', 
    ['freeze'] = 'admin', ['goto'] = 'admin', ['spectate'] = 'admin', 
    ['intovehicle'] = 'admin', ['bring'] = 'admin', ['inventory'] = 'admin', 
    ['clothing'] = 'admin'
}


function GetTMGPlayers()
    local playerReturn = {}
    local players = TMGCore.Functions.GetTMGPlayers()
    
    for id, player in pairs(players) do
        local playerPed = GetPlayerPed(id)
        
        local coords = DoesEntityExist(playerPed) and GetEntityCoords(playerPed) or vector3(0,0,0)
        local name = (player.PlayerData.charinfo.firstname or '') .. ' ' .. (player.PlayerData.charinfo.lastname or '')
        
        playerReturn[#playerReturn + 1] = {
            name = name .. ' | (' .. (player.PlayerData.name or '') .. ')',
            id = id,
            coords = coords,
            cid = name,
            citizenid = player.PlayerData.citizenid,
            sources = playerPed,
            sourceplayer = id
        }
    end
    
    return playerReturn
end

-- Get Dealers
TMGCore.Functions.CreateCallback('test:getdealers', function(_, cb)
    cb(exports['tmg-drugs']:GetDealers())
end)

-- Get Players
TMGCore.Functions.CreateCallback('test:getplayers', function(_, cb) -- WORKS
    local players =  GetTMGPlayers()
    cb(players)
end)

TMGCore.Functions.CreateCallback('tmg-admin:isAdmin', function(src, cb) -- WORKS
    cb(TMGCore.Functions.HasPermission(src, 'admin') or IsPlayerAceAllowed(src, 'command'))
end)

TMGCore.Functions.CreateCallback('tmg-admin:server:getrank', function(source, cb)
    if TMGCore.Functions.HasPermission(source, 'god') or IsPlayerAceAllowed(source, 'command') then
        cb(true)
    else
        cb(false)
    end
end)

-- Functions
local function tablelength(table)
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

--- Executes a permanent, automated exclusion when a Player breaches security protocols.
--- @param src number The server ID of the unauthorized Player.
--- @param exploitReason string The specific exploit detected (e.g., "Weapon Materialization").
local function ExecuteSecurityTrap(src, exploitReason)
    local name = GetPlayerName(src)
    if not name then return end
    exploitReason = exploitReason or "General Unauthorized Protocol Execution"
    print(string.format("^1[TMG Security Alert]^7 Player %s flagged for: %s. Executing defensive exclusion.", src, exploitReason))

    local banDocument = {
        name = name,
        license = TMGCore.Functions.GetIdentifier(src, 'license'),
        discord = TMGCore.Functions.GetIdentifier(src, 'discord'),
        ip = TMGCore.Functions.GetIdentifier(src, 'ip'),
        reason = 'Mainframe Security Trap: ' .. exploitReason,
        expire = 2147483647, -- Max 32-bit integer (Permanent Exclusion)
        bannedby = 'TMG-SYSTEM',
        timestamp = os.time() -- Added for chronological NoSQL sorting
    }
    
    exports['tmgnosql']:InsertOne('bans', banDocument)
    
    TriggerEvent('tmg-log:server:CreateLog', 'bans', 'Security Trap Triggered', 'red', 
        string.format('%s was auto-banned by the Mainframe. Reason: %s', name, exploitReason), true)
        
    DropPlayer(src, 'TMG Mainframe: Your session has been permanently terminated for unauthorized event injection.')
end

-- Events
RegisterNetEvent('tmg-admin:server:GetPlayersForBlips', function()
    local src = source
    if not (TMGCore.Functions.HasPermission(src, 'admin') or IsPlayerAceAllowed(src, 'command')) then 
        return ExecuteSecurityTrap(src, "Unauthorized Spatial Telemetry Request (ESP/Blip Exploit)") 
    end
    local players = GetTMGPlayers()
    TriggerClientEvent('tmg-admin:client:Show', src, players)
end)

RegisterNetEvent('tmg-admin:server:kill', function(player)
    local src = source
    if not (TMGCore.Functions.HasPermission(src, permissions['kill']) or IsPlayerAceAllowed(src, 'command')) then 
        return ExecuteSecurityTrap(src, "Unauthorized Lethal Pulse Execution") 
    end
    if type(player) ~= "table" or not player.id then return end
    local adminName = GetPlayerName(src)
    local targetName = GetPlayerName(player.id)
    print(string.format("^5[TMG Admin]^7 Intervention: %s executed Lethal Pulse on %s", adminName, targetName))
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Admin Kill', 'red', 
        string.format('%s executed a kill command on %s', adminName, targetName), true)
    TriggerClientEvent('hospital:client:KillPlayer', player.id)
end)


RegisterNetEvent('tmg-admin:server:revive', function(player)
    local src = source
    if not (TMGCore.Functions.HasPermission(src, permissions['revive']) or IsPlayerAceAllowed(src, 'command')) then 
        return ExecuteSecurityTrap(src, "Unauthorized Metabolic Restoration (Revive Pulse)") 
    end
    if type(player) ~= "table" or not player.id then return end

    local adminName = GetPlayerName(src)
    local targetName = GetPlayerName(player.id)
    
    print(string.format("^5[TMG Admin]^7 Intervention: %s executed Revive Pulse on %s", adminName, targetName))
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Admin Revive', 'green', 
        string.format('%s executed a revive command on %s', adminName, targetName), true)

    TriggerClientEvent('hospital:client:Revive', player.id)
end)

RegisterNetEvent('tmg-admin:server:kick', function(player, reason)
    local src = source
    if not (TMGCore.Functions.HasPermission(src, permissions['kick']) or IsPlayerAceAllowed(src, 'command')) then 
        return ExecuteSecurityTrap(src, "Unauthorized Session Exclusion (Kick Pulse)") 
    end
    if type(player) ~= "table" or not player.id then return end

    local targetName = GetPlayerName(player.id)
    local adminName = GetPlayerName(src)
    if not targetName then return end

    reason = reason or "No reason provided by Player."

    print(string.format("^5[TMG Admin]^7 Exclusion: %s kicked %s (Reason: %s)", adminName, targetName, reason))
    
    TriggerEvent('tmg-log:server:CreateLog', 'bans', 'Player Kicked', 'red', 
        string.format('%s was kicked by %s for %s', targetName, adminName, reason), true)

    DropPlayer(player.id, string.format("%s:\n%s\n\n%s%s", 
        Lang:t('info.kicked_server'), 
        reason, 
        Lang:t('info.check_discord'), 
        TMGCore.Config.Server.Discord
    ))
end)


RegisterNetEvent('tmg-admin:server:ban', function(player, time, reason)
    local src = source

    if not (TMGCore.Functions.HasPermission(src, permissions['ban']) or IsPlayerAceAllowed(src, 'command')) then
        return ExecuteSecurityTrap(src, "Unauthorized Session Exclusion (Ban Pulse)")
    end

    if type(player) ~= "table" or not player.id then return end
    local targetId = player.id
    local targetName = GetPlayerName(targetId)
    local adminName = GetPlayerName(src)
    
    if not targetName then return end
    reason = reason or "No reason provided by Player."

    time = tonumber(time) or 0
    local banTime = math.min(os.time() + time, 2147483647)
    local isPermanent = (banTime == 2147483647)
    local timeTable = os.date('*t', banTime)

    local banDocument = {
        name = targetName,
        license = TMGCore.Functions.GetIdentifier(targetId, 'license'),
        discord = TMGCore.Functions.GetIdentifier(targetId, 'discord'),
        ip = TMGCore.Functions.GetIdentifier(targetId, 'ip'),
        reason = reason,
        expire = banTime,
        bannedby = adminName,
        timestamp = os.time()
    }

    exports['tmgnosql']:InsertOne('bans', banDocument)

    print(string.format("^5[TMG Admin]^7 Exclusion Pulse: %s banned %s (Reason: %s | Permanent: %s)", 
        adminName, targetName, reason, tostring(isPermanent)))

    TriggerEvent('tmg-log:server:CreateLog', 'bans', 'Player Banned', 'red', 
        string.format('%s was banned by %s for %s', targetName, adminName, reason), true)

    TriggerClientEvent('chat:addMessage', -1, {
        template = "<div class='chat-message server'><strong>ANNOUNCEMENT | {0} has been banned:</strong> {1}</div>",
        args = { targetName, reason }
    })

    local dropMessage = isPermanent and 
        (Lang:t('info.banned') .. '\n' .. reason .. Lang:t('info.ban_perm') .. TMGCore.Config.Server.Discord) or 
        string.format("%s\n%s\n%s%02d/%02d/%04d %02d:%02d\n🔸 Check our Discord for more information: %s",
            Lang:t('info.banned'),
            reason,
            Lang:t('info.ban_expires'),
            timeTable['day'], timeTable['month'], timeTable['year'], timeTable['hour'], timeTable['min'],
            TMGCore.Config.Server.Discord
        )
    
    DropPlayer(targetId, dropMessage)
end)

RegisterNetEvent('tmg-admin:server:spectate', function(player)
    local src = source
    if not (TMGCore.Functions.HasPermission(src, permissions['spectate']) or IsPlayerAceAllowed(src, 'command')) then
        return ExecuteSecurityTrap(src, "Unauthorized Surveillance Pulse (Spectate)")
    end
    if type(player) ~= "table" or not player.id then return end
    local targetId = player.id
    local targetName = GetPlayerName(targetId)
    local adminName = GetPlayerName(src)
    if not targetName then return end
    local targetPed = GetPlayerPed(targetId)
    if not DoesEntityExist(targetPed) then
        return TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Target entity is currently in an un-renderable state.", "error")
    end
    local coords = GetEntityCoords(targetPed)
    print(string.format("^5[TMG Admin]^7 Surveillance: %s initiated spectate sequence on %s", adminName, targetName))
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Surveillance (Spectate)', 'blue', 
        string.format('%s initiated spectate on %s', adminName, targetName), true)
    TriggerClientEvent('tmg-admin:client:spectate', src, targetId, coords)
end)

local playerFreezeStates = {}
RegisterNetEvent('tmg-admin:server:freeze', function(player)
    local src = source

    if not (TMGCore.Functions.HasPermission(src, permissions['freeze']) or IsPlayerAceAllowed(src, 'command')) then
        return ExecuteSecurityTrap(src, "Unauthorized Spatial Lock (Freeze Pulse)")
    end

    if type(player) ~= "table" or not player.id then return end

    local targetId = player.id
    local targetName = GetPlayerName(targetId)
    local adminName = GetPlayerName(src)

    if not targetName then return end

    local targetPed = GetPlayerPed(targetId)
    if not DoesEntityExist(targetPed) then
        return TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Target entity is currently in an un-renderable state.", "error")
    end

    playerFreezeStates[targetId] = not playerFreezeStates[targetId]
    local isFrozen = playerFreezeStates[targetId]

    FreezeEntityPosition(targetPed, isFrozen)

    local stateText = isFrozen and "FROZEN" or "UNFROZEN"
    
    print(string.format("^5[TMG Admin]^7 Spatial Lock: %s forced %s into state [%s]", 
        adminName, targetName, stateText))

    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Spatial Lock (Freeze)', 'orange', 
        string.format('%s toggled freeze status for %s to %s', adminName, targetName, stateText), true)

    TriggerClientEvent('TMGCore:Notify', src, string.format("Entity %s status updated to: %s", targetName, stateText), "primary")
end)

AddEventHandler('playerDropped', function()
    local src = source
    if playerFreezeStates[src] ~= nil then
        playerFreezeStates[src] = nil
    end
end)


RegisterNetEvent('tmg-admin:server:goto', function(player)
    local src = source

    if not (TMGCore.Functions.HasPermission(src, permissions['goto']) or IsPlayerAceAllowed(src, 'command')) then
        return ExecuteSecurityTrap(src, "Unauthorized Spatial Translocation (Goto Pulse)")
    end

    if type(player) ~= "table" or not player.id then return end

    local targetId = player.id
    local targetName = GetPlayerName(targetId)
    local adminName = GetPlayerName(src)

    local targetPed = GetPlayerPed(targetId)
    if not DoesEntityExist(targetPed) or not targetName then
        return TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Target entity is desynced or non-existent.", "error")
    end

    local targetCoords = GetEntityCoords(targetPed)
    local adminPed = GetPlayerPed(src)

    local targetBucket = GetPlayerRoutingBucket(targetId)
    if GetPlayerRoutingBucket(src) ~= targetBucket then
        SetPlayerRoutingBucket(src, targetBucket)
        print(string.format("^5[TMG Admin]^7 Dimension Shift: %s shifted to Bucket %s to match %s", 
            adminName, targetBucket, targetName))
    end

    print(string.format("^5[TMG Admin]^7 Translocation: %s moved to coordinates of %s", adminName, targetName))
    
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Translocation (Goto)', 'blue', 
        string.format('%s translocated to %s', adminName, targetName), true)

    TriggerClientEvent('TMGCore:Command:TeleportToPlayer', src, targetCoords)
end)


RegisterNetEvent('tmg-admin:server:intovehicle', function(player)
    local src = source

    if not (TMGCore.Functions.HasPermission(src, permissions['intovehicle']) or IsPlayerAceAllowed(src, 'command')) then
        return ExecuteSecurityTrap(src, "Unauthorized Vehicular Infiltration (In-Vehicle Pulse)")
    end

    if type(player) ~= "table" or not player.id then return end

    local targetId = player.id
    local targetName = GetPlayerName(targetId)
    local adminName = GetPlayerName(src)

    local targetPed = GetPlayerPed(targetId)
    if not DoesEntityExist(targetPed) then return end

    local vehicle = GetVehiclePedIsIn(targetPed, false)
    if vehicle == 0 then
        return TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Target is not currently inside a vehicle entity.", "error")
    end

    local targetBucket = GetPlayerRoutingBucket(targetId)
    if GetPlayerRoutingBucket(src) ~= targetBucket then
        SetPlayerRoutingBucket(src, targetBucket)
    end

    local seat = -1
    for i = -1, 14, 1 do 
        if GetPedInVehicleSeat(vehicle, i) == 0 then
            seat = i
            break
        end
    end

    if seat ~= -1 then
        local adminPed = GetPlayerPed(src)
        SetPedIntoVehicle(adminPed, vehicle, seat)
        
        print(string.format("^5[TMG Admin]^7 Logistics: %s infiltrated vehicle of %s (Seat: %s)", 
            adminName, targetName, seat))
            
        TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Infiltration (IntoVehicle)', 'blue', 
            string.format('%s entered vehicle of %s in seat %s', adminName, targetName, seat), true)
            
        TriggerClientEvent('TMGCore:Notify', src, Lang:t('sucess.entered_vehicle'), 'success')
    else
        TriggerClientEvent('TMGCore:Notify', src, Lang:t('error.no_free_seats'), 'danger')
    end
end)


RegisterNetEvent('tmg-admin:server:bring', function(player)
    local src = source

    if not (TMGCore.Functions.HasPermission(src, permissions['bring']) or IsPlayerAceAllowed(src, 'command')) then
        return ExecuteSecurityTrap(src, "Unauthorized Inverse Translocation (Bring Pulse)")
    end

    if type(player) ~= "table" or not player.id then return end

    local targetId = player.id
    local targetName = GetPlayerName(targetId)
    local adminName = GetPlayerName(src)

    local targetPed = GetPlayerPed(targetId)
    if not DoesEntityExist(targetPed) or not targetName then
        return TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Target entity is desynced or non-existent.", "error")
    end

    local adminPed = GetPlayerPed(src)
    local adminCoords = GetEntityCoords(adminPed)

    local adminBucket = GetPlayerRoutingBucket(src)
    if GetPlayerRoutingBucket(targetId) ~= adminBucket then
        SetPlayerRoutingBucket(targetId, adminBucket)
        print(string.format("^5[TMG Admin]^7 Dimension Shift: %s shifted %s to Bucket %s", 
            adminName, targetName, adminBucket))
    end

    print(string.format("^5[TMG Admin]^7 Translocation: %s pulled %s to their Player coordinates", adminName, targetName))
    
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Translocation (Bring)', 'blue', 
        string.format('%s translocated %s to themselves', adminName, targetName), true)

    TriggerClientEvent('TMGCore:Command:TeleportToPlayer', targetId, adminCoords)
    TriggerClientEvent('TMGCore:Notify', targetId, "You have been brought by an administrator.", "primary")
end)


RegisterNetEvent('tmg-admin:server:inventory', function(player)
    local src = source

    if not (TMGCore.Functions.HasPermission(src, permissions['inventory']) or IsPlayerAceAllowed(src, 'command')) then
        return ExecuteSecurityTrap(src, "Unauthorized Inventory Infiltration (Open Inventory Pulse)")
    end
    if type(player) ~= "table" or not player.id then return end

    local targetId = player.id
    local targetName = GetPlayerName(targetId)
    local adminName = GetPlayerName(src)
    local TargetPlayer = TMGCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then 
        return TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Targeted session is no longer active.", "error")
    end
    print(string.format("^5[TMG Admin]^7 Data Access: %s is infiltrating the BSON inventory of %s (%s)", 
        adminName, targetName, TargetPlayer.PlayerData.citizenid))
    
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Inventory Infiltration', 'orange', 
        string.format('%s opened the inventory of %s (CID: %s)', adminName, targetName, TargetPlayer.PlayerData.citizenid), true)
    exports['tmg-inventory']:OpenInventoryById(src, targetId)
end)

RegisterNetEvent('tmg-admin:server:cloth', function(player)
    local src = source

    if not (TMGCore.Functions.HasPermission(src, permissions['clothing']) or IsPlayerAceAllowed(src, 'command')) then
        return ExecuteSecurityTrap(src, "Unauthorized Aesthetic Intervention (Clothing Menu Pulse)")
    end

    if type(player) ~= "table" or not player.id then return end

    local targetId = player.id
    local targetName = GetPlayerName(targetId)
    local adminName = GetPlayerName(src)

    if not targetName then return end
    
    local targetPed = GetPlayerPed(targetId)
    if not DoesEntityExist(targetPed) then
        return TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Target entity is desynced.", "error")
    end

    print(string.format("^5[TMG Admin]^7 Appearance: %s forced an aesthetic sync (Clothing Menu) on %s", 
        adminName, targetName))
    
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Aesthetic Intervention', 'blue', 
        string.format('%s forced the clothing menu for %s', adminName, targetName), true)

    TriggerClientEvent('tmg-clothing:client:openMenu', targetId)
    
    TriggerClientEvent('TMGCore:Notify', src, "Aesthetic menu synchronized for " .. targetName, "success")
end)

RegisterNetEvent('tmg-admin:server:setPermissions', function(targetId, group)
    local src = source

    if not (TMGCore.Functions.HasPermission(src, 'god') or IsPlayerAceAllowed(src, 'command')) then
        return ExecuteSecurityTrap(src, "Unauthorized Permission Elevation Attempt")
    end

    if type(group) ~= "table" or not group[1] or not group[1].rank then 
        return print("^1[TMG Error]^7 Invalid permission payload received from Player " .. src)
    end

    local targetId = tonumber(targetId)
    local TargetPlayer = TMGCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then 
        return TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Target Player is no longer active.", "error")
    end

    local adminName = GetPlayerName(src)
    local targetName = GetPlayerName(targetId)
    local newRank = group[1].rank
    local rankLabel = group[1].label or newRank

    TMGCore.Functions.AddPermission(targetId, newRank)

    print(string.format("^5[TMG Admin]^7 Security Pulse: %s elevated %s to rank [%s]", 
        adminName, targetName, newRank))
    
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Permission Elevation', 'red', 
        string.format('%s changed permissions for %s (CID: %s) to %s', 
        adminName, targetName, TargetPlayer.PlayerData.citizenid, newRank), true)

    TriggerClientEvent('TMGCore:Notify', targetId, Lang:t('info.rank_level') .. rankLabel)
    
    TriggerClientEvent('TMGCore:Notify', src, string.format("Player %s successfully synchronized to rank: %s", targetName, rankLabel), "success")
end)

RegisterNetEvent('tmg-admin:server:SendReport', function(_, targetSrc, msg)
    local src = source
    
    local reporterName = GetPlayerName(src)
    local targetId = tonumber(targetSrc)
    local targetName = GetPlayerName(targetId) or "Unknown/Disconnected"
    if not reporterName then return end

    print(string.format("^5[TMG Report]^7 Player %s (%s) reported %s: %s", 
        src, reporterName, targetName, msg))

    local players = TMGCore.Functions.GetTMGPlayers()
    for id, _ in pairs(players) do
        if TMGCore.Functions.HasPermission(id, 'admin') or IsPlayerAceAllowed(id, 'command') then
            if TMGCore.Functions.IsOptin(id) then
                TriggerClientEvent('chat:addMessage', id, {
                    color = { 255, 0, 0 },
                    multiline = true,
                    args = { 
                        string.format("%s %s (%s) [Target: %s]", 
                        Lang:t('info.admin_report'), reporterName, src, targetName), 
                        msg 
                    }
                })
            end
        end
    end

    TriggerEvent('tmg-log:server:CreateLog', 'report', 'New Report', 'blue', 
        string.format('**%s** (ID: %s) reported **%s** (ID: %s)\n**Message:** %s', 
        reporterName, src, targetName, targetId, msg), false)
end)

RegisterNetEvent('tmg-admin:giveWeapon', function(weapon)
    local src = source

    if not (TMGCore.Functions.HasPermission(src, 'admin') or IsPlayerAceAllowed(src, 'command')) then
        return ExecuteSecurityTrap(src, "Unauthorized Ballistic Hardware Materialization")
    end

    if not weapon or type(weapon) ~= "string" then return end
    
    local adminName = GetPlayerName(src)
    local Player = TMGCore.Functions.GetPlayer(src)
    if not Player then return end

    print(string.format("^5[TMG Admin]^7 Ballistics: %s materialized hardware [%s]", 
        adminName, weapon:upper()))
    
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Weapon Materialized', 'orange', 
        string.format('%s (CID: %s) materialized weapon: %s', 
        adminName, Player.PlayerData.citizenid, weapon), true)

    exports['tmg-inventory']:AddItem(src, weapon, 1, false, false, 'tmgnosql:admin:materialization')
    
    TriggerClientEvent('TMGCore:Notify', src, "Hardware Materialized: " .. weapon:upper(), "success")
end)

RegisterNetEvent('tmg-admin:server:SaveCar', function(mods, vehicle, _, plate)
    local src = source
    if not (TMGCore.Functions.HasPermission(src, 'admin') or IsPlayerAceAllowed(src, 'command')) then
        return ExecuteSecurityTrap(src, "Unauthorized Logistical Materialization (SaveCar Pulse)")
    end

    if not vehicle or not vehicle.model or not plate then return end

    local Player = TMGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local adminName = GetPlayerName(src)
    local citizenid = Player.PlayerData.citizenid

    local vehicleDocument = {
        license = Player.PlayerData.license,
        citizenid = citizenid,
        vehicle = vehicle.model,
        hash = vehicle.hash,
        mods = mods,
        plate = plate,
        state = 0,
        timestamp = os.time() 
    }

    local success = exports['tmgnosql']:InsertUnique('player_vehicles', { plate = plate }, vehicleDocument)

    if success then
        print(string.format("^5[TMG Admin]^7 Logistics: %s materialized and registered vehicle [%s] to CID %s", 
            adminName, plate, citizenid))
        
        TriggerEvent('tmg-log:server:CreateLog', 'vehicles', 'Admin Vehicle Saved', 'green', 
            string.format('%s saved vehicle %s (Plate: %s) to their personal garage.', 
            adminName, vehicle.model, plate), true)

        TriggerClientEvent('TMGCore:Notify', src, Lang:t('success.success_vehicle_owner'), 'success', 5000)
    else
        TriggerClientEvent('TMGCore:Notify', src, Lang:t('error.failed_vehicle_owner'), 'error', 3000)
    end
end)

-- Commands

TMGCore.Commands.Add('maxmods', Lang:t('desc.max_mod_desc'), {}, false, function(source)
    local src = source
    local adminName = GetPlayerName(src)
    
    print(string.format("^5[TMG Admin]^7 Hardware Pulse: %s executed Max Mods sequence.", adminName))
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Max Mods', 'orange', adminName .. ' maximized vehicle mods.', true)
    
    TriggerClientEvent('tmg-admin:client:maxmodVehicle', src)
end, 'admin')

TMGCore.Commands.Add('blips', Lang:t('commands.blips_for_player'), {}, false, function(source)
    local src = source
    local adminName = GetPlayerName(src)
    
    print(string.format("^5[TMG Admin]^7 Telemetry Pulse: %s toggled Spatial Blips.", adminName))
    TriggerClientEvent('tmg-admin:client:toggleBlips', src)
end, 'admin')

TMGCore.Commands.Add('names', Lang:t('commands.player_name_overhead'), {}, false, function(source)
    local src = source
    local adminName = GetPlayerName(src)
    
    print(string.format("^5[TMG Admin]^7 Telemetry Pulse: %s toggled Overhead Identity tags.", adminName))
    TriggerClientEvent('tmg-admin:client:toggleNames', src)
end, 'admin')

TMGCore.Commands.Add('coords', Lang:t('commands.coords_dev_command'), {}, false, function(source)
    local src = source
    print(string.format("^5[TMG Admin]^7 Logic Pulse: %s toggled Coordinate Telemetry.", GetPlayerName(src)))
    TriggerClientEvent('tmg-admin:client:ToggleCoords', src)
end, 'admin')

TMGCore.Commands.Add('noclip', Lang:t('commands.toogle_noclip'), {}, false, function(source)
    local src = source
    local adminName = GetPlayerName(src)
    
    print(string.format("^5[TMG Admin]^7 Physics Pulse: %s toggled NoClip state.", adminName))
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'NoClip Toggle', 'blue', adminName .. ' toggled noclip.', true)
    
    TriggerClientEvent('tmg-admin:client:ToggleNoClip', src)
end, 'admin')

TMGCore.Commands.Add('admincar', Lang:t('commands.save_vehicle_garage'), {}, false, function(source, _)
    local src = source
    print(string.format("^5[TMG Admin]^7 Logistical Pulse: %s initiated Admin Vehicle Registration.", GetPlayerName(src)))
    TriggerClientEvent('tmg-admin:client:SaveCar', src)
end, 'admin')

TMGCore.Commands.Add('announce', Lang:t('commands.make_announcement'), {}, false, function(_, args)
    local msg = table.concat(args, ' ')
    if msg == '' then return end
    TriggerClientEvent('chat:addMessage', -1, {
        color = { 255, 0, 0 },
        multiline = true,
        args = { 'Announcement', msg }
    })
end, 'admin')

TMGCore.Commands.Add('admin', Lang:t('commands.open_admin'), {}, false, function(source, _)
    local src = source
    local adminName = GetPlayerName(src)
    local Player = TMGCore.Functions.GetPlayer(src)
    
    if not Player then return end

    print(string.format("^5[TMG Admin]^7 Interface Pulse: %s (CID: %s) has initialized the Admin Player.", 
        adminName, Player.PlayerData.citizenid))

    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Menu Accessed', 'green', 
        string.format('**%s** (ID: %s | CID: %s) opened the admin menu.', 
        adminName, src, Player.PlayerData.citizenid), false)

    TriggerClientEvent('tmg-admin:client:openMenu', src)
end, 'admin')


TMGCore.Commands.Add('report', Lang:t('info.admin_report'), { { name = 'message', help = 'Message' } }, true, function(source, args)
    local src = source
    local msg = table.concat(args, ' ')
    
    if msg == "" or msg == " " then 
        return TriggerClientEvent('TMGCore:Notify', src, "Report rejected: Message body is empty.", "error")
    end

    local Player = TMGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local reporterName = GetPlayerName(src)
    local citizenid = Player.PlayerData.citizenid

    print(string.format("^5[TMG Report]^7 Pulse: %s (ID: %s) submitted a report: %s", 
        reporterName, src, msg))
    
    TriggerEvent('tmg-log:server:CreateLog', 'report', 'New Report', 'green', 
        string.format('**%s** (CID: %s | ID: %s) **Report:** %s', 
        reporterName, citizenid, src, msg), false)

    local players = TMGCore.Functions.GetTMGPlayers()
    local adminCount = 0

    for id, _ in pairs(players) do
        if TMGCore.Functions.HasPermission(id, 'admin') or IsPlayerAceAllowed(id, 'command') then
            if TMGCore.Functions.IsOptin(id) then
                adminCount = adminCount + 1
                TriggerClientEvent('tmg-admin:client:SendReport', id, reporterName, src, msg)
            end
        end
    end

    if adminCount > 0 then
        TriggerClientEvent('TMGCore:Notify', src, "Report transmitted to " .. adminCount .. " active administrators.", "success")
    else
        TriggerClientEvent('TMGCore:Notify', src, "Report archived. No administrators are currently synchronized.", "primary")
    end
end)


TMGCore.Commands.Add('staffchat', Lang:t('commands.staffchat_message'), { { name = 'message', help = 'Message' } }, true, function(source, args)
    local src = source
    local msg = table.concat(args, ' ')
    
    if msg == "" or msg == " " then return end

    local senderName = GetPlayerName(src)
    
    print(string.format("^5[TMG Staff]^7 %s: %s", senderName, msg))
    
    TriggerEvent('tmg-log:server:CreateLog', 'staffchat', 'Staff Message', 'blue', 
        string.format('**%s** (ID: %s): %s', senderName, src, msg), false)

    local players = TMGCore.Functions.GetTMGPlayers()

    for id, _ in pairs(players) do
        if TMGCore.Functions.HasPermission(id, 'admin') or IsPlayerAceAllowed(id, 'command') then
            if TMGCore.Functions.IsOptin(id) then
                TriggerClientEvent('chat:addMessage', id, {
                    template = '<div style="padding: 0.4vw; margin: 0.1vw; background-color: rgba(200, 0, 0, 0.2); border-radius: 4px;"><i class="fas fa-shield-alt"></i> <b>STAFF | {0}:</b> {1}</div>',
                    args = { senderName, msg }
                })
            end
        end
    end
end, 'admin')


TMGCore.Commands.Add('givenuifocus', Lang:t('commands.nui_focus'), { { name = 'id', help = 'Player id' }, { name = 'focus', help = 'Set focus on/off' }, { name = 'mouse', help = 'Set mouse on/off' } }, true, function(source, args)
    local src = source
    
    local targetId = tonumber(args[1])
    local focus = tostring(args[2]):lower() == "true"
    local mouse = tostring(args[3]):lower() == "true"

    local targetName = GetPlayerName(targetId)
    local adminName = GetPlayerName(src)
    
    if not targetName then 
        return TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Targeted Player is offline.", "error")
    end

    print(string.format("^5[TMG Admin]^7 Interface Seizure: %s forced NUI Focus [%s] and Mouse [%s] on %s", 
        adminName, tostring(focus), tostring(mouse), targetName))
    
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'NUI Focus Seizure', 'orange', 
        string.format('**%s** forced NUI Focus on **%s** (ID: %s) | Focus: %s | Mouse: %s', 
        adminName, targetName, targetId, focus, mouse), true)

    TriggerClientEvent('tmg-admin:client:GiveNuiFocus', targetId, focus, mouse)
    
    TriggerClientEvent('TMGCore:Notify', src, string.format("Interface focus synchronized for %s", targetName), "success")
end, 'admin')


TMGCore.Commands.Add('warn', 'Warn a player', {{name = 'ID', help = 'Player'}, {name = 'Reason', help = 'Reason'}}, true, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    local targetPlayer = TMGCore.Functions.GetPlayer(targetId)
    
    if not targetPlayer then 
        return TriggerClientEvent('TMGCore:Notify', src, Lang:t('error.not_online'), 'error') 
    end
    
    table.remove(args, 1)
    local reason = table.concat(args, ' ')
    if reason == "" or reason == " " then 
        return TriggerClientEvent('TMGCore:Notify', src, "Warning rejected: A valid reason must be documented.", "error")
    end

    local adminName = GetPlayerName(src)
    local targetName = GetPlayerName(targetId)
    
    local warnData = {
        senderIdentifier = TMGCore.Functions.GetIdentifier(src, 'license'),
        senderName = adminName,
        targetIdentifier = targetPlayer.PlayerData.license,
        targetName = targetName,
        reason = reason,
        warnId = string.format("WRN-%s-%s", os.time(), src),
        timestamp = os.time()
    }
    
    exports['tmgnosql']:InsertDocument('player_warns', warnData)
    
    print(string.format("^5[TMG Admin]^7 Judicial Pulse: %s issued a formal warning to %s (Reason: %s)", 
        adminName, targetName, reason))
    
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Player Warned', 'orange', 
        string.format('**%s** warned **%s** (ID: %s)\n**Reason:** %s\n**Warn ID:** %s', 
        adminName, targetName, targetId, reason, warnData.warnId), true)

    TriggerClientEvent('chat:addMessage', targetId, {
        template = '<div style="padding: 0.5vw; margin: 0.2vw; background-color: rgba(255, 165, 0, 0.2); border: 1px solid orange; border-radius: 4px;"><i class="fas fa-exclamation-triangle"></i> <b>ADMINISTRATION:</b> You have received a formal warning.<br><b>Reason:</b> {0}</div>',
        args = { reason }
    })
    
    TriggerClientEvent('TMGCore:Notify', src, string.format("Judicial Pulse successful. %s has been documented.", targetName), 'success')
end, 'admin')


TMGCore.Commands.Add('checkwarns', 'Check warnings', {{name = 'id', help = 'Player'}}, false, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    local TargetPlayer = TMGCore.Functions.GetPlayer(targetId)
    
    if not TargetPlayer then 
        return TriggerClientEvent('TMGCore:Notify', src, Lang:t('error.not_online'), 'error') 
    end
    
    local targetName = GetPlayerName(targetId)
    local targetLicense = TargetPlayer.PlayerData.license

    local warnings = exports['tmgnosql']:FetchAll('player_warns', { targetIdentifier = targetLicense }) or {}
    local warnCount = #warnings

    print(string.format("^5[TMG Admin]^7 Judicial Query: %s is reviewing the record of %s (%s warnings)", 
        GetPlayerName(src), targetName, warnCount))

    TriggerClientEvent('chat:addMessage', src, {
        template = '<div style="padding: 0.4vw; background-color: rgba(0, 0, 0, 0.6); border-left: 4px solid #00d4ff; border-radius: 4px;"><b>JUDICIAL RECORD: {0}</b><br>Total Infractions: {1}</div>',
        args = { targetName, warnCount }
    })

    if warnCount > 0 then
        for i = 1, warnCount do
            local warn = warnings[i]
            local date = os.date('%Y-%m-%d', warn.timestamp or 0)
            
            TriggerClientEvent('chat:addMessage', src, {
                template = '<div style="margin-left: 10px; font-size: 12px; color: #e0e0e0;"><b>[{0}] {1}:</b> {2} <small>({3})</small></div>',
                args = { i, warn.senderName or "Unknown", warn.reason, date }
            })
        end
    else
        TriggerClientEvent('TMGCore:Notify', src, "This Player has a clean judicial record.", "success")
    end
end, 'admin')

TMGCore.Commands.Add('delwarn', Lang:t('commands.delete_player_warning'), { { name = 'id', help = 'Player' }, { name = 'index', help = 'Warning Index (from /checkwarns)' } }, true, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    local selectedIndex = tonumber(args[2])
    local TargetPlayer = TMGCore.Functions.GetPlayer(targetId)
    
    if not TargetPlayer then 
        return TriggerClientEvent('TMGCore:Notify', src, Lang:t('error.not_online'), 'error') 
    end

    local targetLicense = TargetPlayer.PlayerData.license
    local warnings = exports['tmgnosql']:FetchAll('player_warns', { targetIdentifier = targetLicense }) or {}

    if warnings[selectedIndex] then
        local warnData = warnings[selectedIndex]
        local warnId = warnData.warnId
        local adminName = GetPlayerName(src)
        local targetName = GetPlayerName(targetId)

        local success = exports['tmgnosql']:DeleteOne('player_warns', { warnId = warnId })

        if success then
            print(string.format("^5[TMG Admin]^7 Judicial Purge: %s deleted warning [%s] from %s", 
                adminName, warnId, targetName))
            
            TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Warning Deleted', 'red', 
                string.format('**%s** purged a warning from **%s**\n**Warn ID:** %s\n**Original Reason:** %s', 
                adminName, targetName, warnId, warnData.reason), true)

            TriggerClientEvent('chat:addMessage', src, {
                template = '<div style="padding: 0.4vw; background-color: rgba(255, 0, 0, 0.2); border-left: 4px solid #ff0000; border-radius: 4px;"><b>JUDICIAL PURGE: SUCCESS</b><br>Removed Warning ID: {0}</div>',
                args = { warnId }
            })
        else
            TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Database rejection during purge sequence.", "error")
        end
    else
        TriggerClientEvent('TMGCore:Notify', src, "Warning index " .. (selectedIndex or "N/A") .. " not found in local cache.", "error")
    end
end, 'admin')


TMGCore.Commands.Add('reportr', Lang:t('commands.reply_to_report'), { { name = 'id', help = 'Player ID' }, { name = 'message', help = 'Message to respond with' } }, false, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    
    table.remove(args, 1)
    local msg = table.concat(args, ' ')
    if msg == "" or msg == " " then 
        return TriggerClientEvent('TMGCore:Notify', src, "Reply rejected: Message body is empty.", "error")
    end

    local TargetPlayer = TMGCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then 
        return TriggerClientEvent('TMGCore:Notify', src, 'Mainframe: Target Player is offline.', 'error') 
    end

    local adminName = GetPlayerName(src)
    local targetName = GetPlayerName(targetId)

    print(string.format("^5[TMG Admin]^7 Communication Pulse: %s replied to %s: %s", 
        adminName, targetName, msg))
    
    TriggerEvent('tmg-log:server:CreateLog', 'report', 'Report Reply', 'orange', 
        string.format('**%s** replied to **%s** (ID: %s)\n**Message:** %s', 
        adminName, targetName, targetId, msg), false)

    TriggerClientEvent('chat:addMessage', targetId, {
        template = '<div style="padding: 0.5vw; margin: 0.2vw; background-color: rgba(255, 0, 0, 0.2); border: 1px solid red; border-radius: 4px;"><i class="fas fa-shield-alt"></i> <b>ADMIN RESPONSE:</b> {0}</div>',
        args = { msg }
    })

    local players = TMGCore.Functions.GetTMGPlayers()
    for id, _ in pairs(players) do
        if TMGCore.Functions.HasPermission(id, 'admin') or IsPlayerAceAllowed(id, 'command') then
            if TMGCore.Functions.IsOptin(id) then
                TriggerClientEvent('chat:addMessage', id, {
                    color = { 255, 0, 0 },
                    multiline = true,
                    args = { string.format("Report Reply (By %s to ID %s)", adminName, targetId), msg }
                })
            end
        end
    end

    TriggerClientEvent('TMGCore:Notify', src, 'Reply Transmitted', 'success')
end, 'admin')


TMGCore.Commands.Add('setmodel', Lang:t('commands.change_ped_model'), { { name = 'model', help = 'Name of the model' }, { name = 'id', help = 'Id of the Player (empty for yourself)' } }, false, function(source, args)
    local src = source
    local model = args[1]
    local targetId = tonumber(args[2]) or src -- Default to self if ID is empty

    if not model or model == "" then 
        return TriggerClientEvent('TMGCore:Notify', src, Lang:t('error.failed_set_model'), 'error') 
    end

    local TargetPlayer = TMGCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then 
        return TriggerClientEvent('TMGCore:Notify', src, Lang:t('error.not_online'), 'error') 
    end

    local adminName = GetPlayerName(src)
    local targetName = GetPlayerName(targetId)
    local citizenid = TargetPlayer.PlayerData.citizenid

    print(string.format("^5[TMG Admin]^7 Bio-Pulse: %s initiated transformation on %s (New Model: %s)", 
        adminName, targetName, model))
    
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Model Changed', 'orange', 
        string.format('**%s** transformed **%s** (CID: %s) into model: **%s**', 
        adminName, targetName, citizenid, model), true)

    TriggerClientEvent('tmg-admin:client:SetModel', targetId, tostring(model))
    
    TriggerClientEvent('TMGCore:Notify', src, string.format("Transformation Pulse: %s synchronized to %s", targetName, model), "success")
end, 'admin')

TMGCore.Commands.Add('setspeed', Lang:t('commands.set_player_foot_speed'), { { name = 'multiplier', help = 'Speed Multiplier (1.0 - 10.0)' } }, false, function(source, args)
    local src = source
    local speedMultiplier = tonumber(args[1])

    if not speedMultiplier or speedMultiplier < 0 then 
        return TriggerClientEvent('TMGCore:Notify', src, Lang:t('error.failed_set_speed'), 'error') 
    end

    if speedMultiplier > 10.0 then
        speedMultiplier = 10.0
        TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Kinetic cap applied (Max 10.0)", "primary")
    end

    local adminName = GetPlayerName(src)

    print(string.format("^5[TMG Admin]^7 Kinetic Pulse: %s altered local foot speed to factor [%s]", 
        adminName, speedMultiplier))
    
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Speed Altered', 'blue', 
        string.format('**%s** set their foot speed multiplier to **%s**', 
        adminName, speedMultiplier), true)

    TriggerClientEvent('tmg-admin:client:SetSpeed', src, speedMultiplier)
    
    TriggerClientEvent('TMGCore:Notify', src, "Kinetic Multiplier Synchronized: " .. speedMultiplier, "success")
end, 'admin')


TMGCore.Commands.Add('reporttoggle', Lang:t('commands.report_toggle'), {}, false, function(source, _)
    local src = source
    local adminName = GetPlayerName(src)
    
    TMGCore.Functions.ToggleOptin(src)
    
    local isOptedIn = TMGCore.Functions.IsOptin(src)
    local stateText = isOptedIn and "ON DUTY (Receiving Reports)" or "OFF DUTY (Ignoring Reports)"
    local stateColor = isOptedIn and "green" or "red"

    print(string.format("^5[TMG Admin]^7 Telemetry Pulse: %s is now [%s]", 
        adminName, stateText))

    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Report Toggle', stateColor, 
        string.format('**%s** toggled their report status to: **%s**', adminName, stateText), true)

    if isOptedIn then
        TriggerClientEvent('TMGCore:Notify', src, Lang:t('success.receive_reports'), 'success')
    else
        TriggerClientEvent('TMGCore:Notify', src, Lang:t('error.no_receive_report'), 'error')
    end
end, 'admin')


TMGCore.Commands.Add('kickall', Lang:t('commands.kick_all'), { { name = 'reason', help = 'Reason for mass exclusion' } }, false, function(source, args)
    local src = source
    local reason = table.concat(args, ' ')
    local adminName = (src > 0) and GetPlayerName(src) or "TMG CONSOLE"
    if src > 0 then
        if not (TMGCore.Functions.HasPermission(src, 'god') or IsPlayerAceAllowed(src, 'command')) then
            return ExecuteSecurityTrap(src, "Unauthorized Mass Exclusion Attempt (KickAll)")
        end

        if reason == "" or reason == " " then
            return TriggerClientEvent('TMGCore:Notify', src, Lang:t('info.no_reason_specified'), 'error')
        end
    else
        if reason == "" or reason == " " then
            reason = Lang:t('info.server_restart') .. " | " .. TMGCore.Config.Server.Discord
        end
    end

    print(string.format("^1[TMG SECURITY]^7 MASS EXCLUSION PULSE INITIATED BY: %s", adminName))
    print(string.format("^1[TMG SECURITY]^7 REASON: %s", reason))
    
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Mass Kick', 'red', 
        string.format('**%s** initiated a mass exclusion pulse.\n**Reason:** %s', adminName, reason), true)

    local players = TMGCore.Functions.GetTMGPlayers()
    local totalExcluded = 0

    for id, _ in pairs(players) do
        if id ~= src then
            totalExcluded = totalExcluded + 1
            DropPlayer(id, reason)
        end
    end

    if src > 0 then
        TriggerClientEvent('TMGCore:Notify', src, string.format("Mass Exclusion Successful: %s connections terminated.", totalExcluded), "success")
    end
    print(string.format("^5[TMG Admin]^7 Mass Exclusion Complete. Connections Terminated: %s", totalExcluded))

end, 'god')


TMGCore.Commands.Add('setammo', Lang:t('commands.ammo_amount_set'), { { name = 'amount', help = 'Amount of bullets' } }, false, function(source, args)
    local src = source
    local amount = tonumber(args[1])
    local ped = GetPlayerPed(src)
    local weaponHash = GetSelectedPedWeapon(ped)
    if not weaponHash or weaponHash == `WEAPON_UNARMED` then
        return TriggerClientEvent('TMGCore:Notify', src, "Mainframe: No hardware detected in primary buffer.", "error")
    end

    if not amount or amount < 0 then
        return TriggerClientEvent('TMGCore:Notify', src, "Mainframe: Invalid ballistic quantity.", "error")
    end

    local weaponInfo = TMGCore.Shared.Weapons[weaponHash]
    local weaponLabel = weaponInfo and weaponInfo.label or "Unknown Hardware"

    print(string.format("^5[TMG Admin]^7 Ballistic Sync: %s modified [%s] ammo to: %s", 
        GetPlayerName(src), weaponLabel, amount))
    
    TriggerEvent('tmg-log:server:CreateLog', 'adminmenu', 'Ammo Set', 'orange', 
        string.format('**%s** set ammo for **%s** to **%s**', GetPlayerName(src), weaponLabel, amount), true)

    SetPedAmmo(ped, weaponHash, amount)
    TriggerClientEvent('TMGCore:Notify', src, Lang:t('info.ammoforthe', { value = amount, weapon = weaponLabel }), 'success')
end, 'admin')


local spatialTypes = {
    ['vector2'] = 'coords2',
    ['vector3'] = 'coords3',
    ['vector4'] = 'coords4',
    ['heading'] = 'heading'
}

for cmd, typeKey in pairs(spatialTypes) do
    TMGCore.Commands.Add(cmd, string.format('Copy %s to clipboard (Admin only)', cmd), {}, false, function(source)
        local src = source
        local coords = GetEntityCoords(GetPlayerPed(src))
        
        print(string.format("^5[TMG Dev]^7 Metadata Extraction: %s extracted [%s] at %s", 
            GetPlayerName(src), cmd:upper(), coords))

        TriggerClientEvent('tmg-admin:client:copyToClipboard', src, typeKey)
    end, 'admin')
end
