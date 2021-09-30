CustomHitmarkers = CustomHitmarkers or {}
CustomHitmarkers.HitUsers = CustomHitmarkers.HitUsers or {}
CustomHitmarkers.NPCHitUsers = CustomHitmarkers.NPCHitUsers or {}
CustomHitmarkers.EntHitUsers = CustomHitmarkers.EntHitUsers or {}
CustomHitmarkers.RatelimitCount = CustomHitmarkers.RatelimitCount or {}
CustomHitmarkers.RatelimitBlocked = CustomHitmarkers.RatelimitBlocked or {}
CustomHitmarkers.HEAD_DIST = 10
CustomHitmarkers.HEAD_DIST_SQUARED = CustomHitmarkers.HEAD_DIST ^ 2

local convarFlags = { FCVAR_ARCHIVE, FCVAR_PROTECTED }
local convarFlags2 = { FCVAR_ARCHIVE, FCVAR_REPLICATED }

local RATELIMIT_ENABLED = CreateConVar( "custom_hitmarkers_ratelimit_enabled", 1, convarFlags, "Enables ratelimiting on hitmarkers to prevent net message spam.", 0, 1 )
local RATELIMIT_TRACK_DURATION = CreateConVar( "custom_hitmarkers_ratelimit_track_duration", 0.5, convarFlags, "The window of time (in seconds) for hit counts to be tracked per player before getting reset to 0.", 0, 50000 )
local RATELIMIT_THRESHOLD = CreateConVar( "custom_hitmarkers_ratelimit_threshold", 50, convarFlags, "How many hit events a player must trigger in short succesion to become ratelimited.", 2, 50000 )
local RATELIMIT_COOLDOWN = CreateConVar( "custom_hitmarkers_ratelimit_cooldown", 2, convarFlags, "How long (in seconds) hit events for a player will be ignored after breaching the ratelimit threshold.", 0, 50000 )

local NPC_ALLOWED = CreateConVar( "custom_hitmarkers_npc_allowed", 1, convarFlags2, "Allows players to opt in to NPC hitmarkers.", 0, 1 )
local ENT_ALLOWED = CreateConVar( "custom_hitmarkers_ent_allowed", 1, convarFlags2, "Allows players to opt in to entity hitmarkers.", 0, 1 )

local ZERO_VECTOR = Vector( 0, 0, 0 )

local hitUsers = CustomHitmarkers.HitUsers
local npcHitUsers = CustomHitmarkers.NPCHitUsers
local entHitUsers = CustomHitmarkers.EntHitUsers
local ratelimitCount = CustomHitmarkers.RatelimitCount
local ratelimitBlocked = CustomHitmarkers.RatelimitBlocked

local ratelimitEnabled = RATELIMIT_ENABLED:GetBool()
local ratelimitTrackDuration = RATELIMIT_TRACK_DURATION:GetFloat()
local ratelimitThreshold = RATELIMIT_THRESHOLD:GetInt()
local ratelimitCooldown = RATELIMIT_COOLDOWN:GetFloat()

local npcHitsAllowed = NPC_ALLOWED:GetBool()
local entHitsAllowed = ENT_ALLOWED:GetBool()

util.AddNetworkString( "CustomHitmarkers_Hit" )
util.AddNetworkString( "CustomHitmarkers_Kill" )
util.AddNetworkString( "CustomHitmarkers_EnableChanged" )
util.AddNetworkString( "CustomHitmarkers_NPCEnableChanged" )
util.AddNetworkString( "CustomHitmarkers_EntEnableChanged" )
util.AddNetworkString( "CustomHitmarkers_NPCAllowedChanged" )
util.AddNetworkString( "CustomHitmarkers_EntAllowedChanged" )

cvars.AddChangeCallback( "custom_hitmarkers_ratelimit_enabled", function( _, old, new )
    ratelimitEnabled = tobool( tonumber( new ) or tonumber( old ) )
end )

cvars.AddChangeCallback( "custom_hitmarkers_ratelimit_track_duration", function( _, old, new )
    ratelimitTrackDuration = tonumber( new ) or tonumber( old ) or 0.5
end )

cvars.AddChangeCallback( "custom_hitmarkers_ratelimit_threshold", function( _, old, new )
    ratelimitThreshold = math.floor( tonumber( new ) or tonumber( old ) or 50 )
end )

cvars.AddChangeCallback( "custom_hitmarkers_ratelimit_cooldown", function( _, old, new )
    ratelimitCooldown = tonumber( new ) or tonumber( old ) or 2
end )

cvars.AddChangeCallback( "custom_hitmarkers_npc_allowed", function( _, old, new )
    local state = new ~= "0"

    npcHitsAllowed = state

    net.Start( "CustomHitmarkers_NPCAllowedChanged" )
    net.WriteBool( state )
    net.Broadcast()
end )

cvars.AddChangeCallback( "custom_hitmarkers_ent_allowed", function( _, old, new )
    local state = new ~= "0"

    entHitsAllowed = state

    net.Start( "CustomHitmarkers_ENTAllowedChanged" )
    net.WriteBool( state )
    net.Broadcast()
end )

function CustomHitmarkers.RatelimitCheck( attacker )
    if not ratelimitEnabled then return end
    if ratelimitBlocked[attacker] then return true end

    local hitCount = ( ratelimitCount[attacker] or 0 ) + 1
    ratelimitCount[attacker] = hitCount

    if hitCount == 1 then
        timer.Create( "CustomHitmarkers_RatelimitClear_" .. attacker:SteamID(), ratelimitTrackDuration, 1, function()
            if not IsValid( attacker ) then return end

            ratelimitCount[attacker] = nil
        end )
    elseif hitCount >= ratelimitThreshold then
        ratelimitBlocked[attacker] = true

        timer.Remove( "CustomHitmarkers_RatelimitClear_" .. attacker:SteamID() )

        timer.Simple( ratelimitCooldown, function()
            if not IsValid( attacker ) then return end

            ratelimitCount[attacker] = nil
            ratelimitBlocked[attacker] = nil
        end )

        return true
    end
end

local ratelimitCheck = CustomHitmarkers.RatelimitCheck

hook.Add( "EntityTakeDamage", "CustomHitmarkers_TrackDamagePos", function( ent, dmg )
    if not IsValid( ent ) then return end

    local attacker = dmg:GetAttacker()

    if ent == attacker or not IsValid( attacker ) or not attacker:IsPlayer() or not hitUsers[attacker] then return end

    local isNPC = ent:IsNPC()
    local isPlayer = ent:IsPlayer()

    if isNPC then
        if not npcHitsAllowed or not npcHitUsers[attacker] then return end
    elseif not isPlayer and ( not entHitsAllowed or not entHitUsers[attacker] ) then
        return
    end

    if ratelimitCheck( attacker ) then return end

    local damage = dmg:GetDamage() or 0
    local pos = dmg:GetDamagePosition()

    if not pos or pos == ZERO_VECTOR then
        pos = ent:WorldSpaceCenter()
    end

    if not isPlayer then
        local headShot = false

        if isNPC then
            local headBone = ent:GetAttachment( ent:LookupAttachment( "eyes" ) )

            if headBone then
                headShot = headBone.Pos:DistToSqr( pos ) <= CustomHitmarkers.HEAD_DIST_SQUARED
            end
        end

        net.Start( "CustomHitmarkers_Hit" )
        net.WriteEntity( ent )
        net.WriteVector( pos )
        net.WriteFloat( damage )
        net.WriteBool( headShot )
        net.Send( attacker )

        return
    end

    attacker.hitmarkerPoints = attacker.hitmarkerPoints or {}
    attacker.hitmarkerPoints[ent] = pos
end, HOOK_LOW )

hook.Add( "PlayerHurt", "CustomHitmarkers_HitNotify", function( ply, attacker, newHealth, damage )
    if not IsValid( attacker ) or not attacker:IsPlayer() or not hitUsers[attacker] then return end
    if ratelimitCheck( attacker ) then return end

    attacker.hitmarkerPoints = attacker.hitmarkerPoints or {}
    local pos = attacker.hitmarkerPoints[ply]
    local headShot = false

    if not pos then
        local chestBone = ply:GetAttachment( ply:LookupAttachment( "chest" ) )
        pos = chestBone and chestBone.Pos or ply:GetPos() + Vector( 0, 0, ply:OBBMaxs().z * 2 / 3  )
    end

    local headBone = ply:GetAttachment( ply:LookupAttachment( "eyes" ) )

    if headBone then
        headShot = headBone.Pos:DistToSqr( pos ) <= CustomHitmarkers.HEAD_DIST_SQUARED
    end

    net.Start( "CustomHitmarkers_Hit" )
    net.WriteEntity( ply )
    net.WriteVector( pos )
    net.WriteFloat( damage )
    net.WriteBool( headShot )
    net.Send( attacker )

    attacker.hitmarkerPoints[ply] = nil
end )

hook.Add( "PlayerDeath", "CustomHitmarkers_KillNotify", function( ply, _, attacker )
    if not hitUsers[attacker] then return end

    net.Start( "CustomHitmarkers_Kill" )
    net.WriteEntity( ply )
    net.Send( attacker )
end )

hook.Add( "OnNPCKilled", "CustomHitmarkers_KillNotify", function( npc, attacker )
    if not hitUsers[attacker] or not npcHitUsers[attacker] then return end

    net.Start( "CustomHitmarkers_Kill" )
    net.WriteEntity( npc )
    net.Send( attacker )
end )

net.Receive( "CustomHitmarkers_EnableChanged", function( _, ply )
    local status = net.ReadBool()

    hitUsers[ply] = status and ply or nil
end )

net.Receive( "CustomHitmarkers_NPCEnableChanged", function( _, ply )
    local status = net.ReadBool()

    npcHitUsers[ply] = status and ply or nil
end )

net.Receive( "CustomHitmarkers_EntEnableChanged", function( _, ply )
    local status = net.ReadBool()

    entHitUsers[ply] = status and ply or nil
end )
