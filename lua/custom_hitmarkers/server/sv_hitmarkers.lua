CustomHitmarkers = CustomHitmarkers or {}
CustomHitmarkers.HitUsers = CustomHitmarkers.HitUsers or {}
CustomHitmarkers.NPCHitUsers = CustomHitmarkers.NPCHitUsers or {}
CustomHitmarkers.EntHitUsers = CustomHitmarkers.EntHitUsers or {}
CustomHitmarkers.HEAD_DIST = 10
CustomHitmarkers.HEAD_DIST_SQUARED = CustomHitmarkers.HEAD_DIST ^ 2

local hitUsers = CustomHitmarkers.HitUsers
local npcHitUsers = CustomHitmarkers.NPCHitUsers
local entHitUsers = CustomHitmarkers.EntHitUsers

util.AddNetworkString( "CustomHitmarkers_Hit" )
util.AddNetworkString( "CustomHitmarkers_Kill" )
util.AddNetworkString( "CustomHitmarkers_EnableChanged" )
util.AddNetworkString( "CustomHitmarkers_NPCEnableChanged" )
util.AddNetworkString( "CustomHitmarkers_EntEnableChanged" )

hook.Add( "EntityTakeDamage", "CustomHitMarkers_TrackDamagePos", function( ent, dmg )
    if not IsValid( ent ) then return end

    local attacker = dmg:GetAttacker()

    if ent == attacker or not hitUsers[attacker] then return end

    local isNPC = ent:IsNPC()
    local isPlayer = ent:IsPlayer()

    if isNPC then
        if not npcHitUsers[attacker] then return end
    elseif not isPlayer and not entHitUsers[attacker] then
        return
    end

    local damage = dmg:GetDamage()
    local pos = dmg:GetDamagePosition()

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
    if not hitUsers[attacker] then return end

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
