CFC_Hitmarkers = CFC_Hitmarkers or {}
CFC_Hitmarkers.HitUsers = CFC_Hitmarkers.HitUsers or {}
CFC_Hitmarkers.NPCHitUsers = CFC_Hitmarkers.NPCHitUsers or {}
CFC_Hitmarkers.EntHitUsers = CFC_Hitmarkers.EntHitUsers or {}
CFC_Hitmarkers.HEAD_DIST = 10
CFC_Hitmarkers.HEAD_DIST_SQUARED = CFC_Hitmarkers.HEAD_DIST ^ 2

local hitUsers = CFC_Hitmarkers.HitUsers
local npcHitUsers = CFC_Hitmarkers.NPCHitUsers
local entHitUsers = CFC_Hitmarkers.EntHitUsers

util.AddNetworkString( "CFC_Hitmarkers_Hit" )
util.AddNetworkString( "CFC_Hitmarkers_Kill" )
util.AddNetworkString( "CFC_Hitmarkers_EnableChanged" )
util.AddNetworkString( "CFC_Hitmarkers_NPCEnableChanged" )
util.AddNetworkString( "CFC_Hitmarkers_EntEnableChanged" )

hook.Add( "EntityTakeDamage", "CFC_HitMarkers_TrackDamagePos", function( ent, dmg )
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
                headShot = headBone.Pos:DistToSqr( pos ) <= CFC_Hitmarkers.HEAD_DIST_SQUARED
            end
        end

        net.Start( "CFC_Hitmarkers_Hit" )
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

hook.Add( "PlayerHurt", "CFC_Hitmarkers_HitNotify", function( ply, attacker, newHealth, damage )
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
        headShot = headBone.Pos:DistToSqr( pos ) <= CFC_Hitmarkers.HEAD_DIST_SQUARED
    end

    net.Start( "CFC_Hitmarkers_Hit" )
    net.WriteEntity( ply )
    net.WriteVector( pos )
    net.WriteFloat( damage )
    net.WriteBool( headShot )
    net.Send( attacker )

    attacker.hitmarkerPoints[ply] = nil
end )

hook.Add( "PlayerDeath", "CFC_Hitmarkers_KillNotify", function( ply, _, attacker )
    if not hitUsers[attacker] then return end

    net.Start( "CFC_Hitmarkers_Kill" )
    net.WriteEntity( ply )
    net.Send( attacker )
end )

hook.Add( "OnNPCKilled", "CFC_Hitmarkers_KillNotify", function( npc, attacker )
    if not hitUsers[attacker] or not npcHitUsers[attacker] then return end

    net.Start( "CFC_Hitmarkers_Kill" )
    net.WriteEntity( npc )
    net.Send( attacker )
end )

net.Receive( "CFC_Hitmarkers_EnableChanged", function( _, ply )
    local status = net.ReadBool()

    hitUsers[ply] = status and ply or nil
end )

net.Receive( "CFC_Hitmarkers_NPCEnableChanged", function( _, ply )
    local status = net.ReadBool()

    npcHitUsers[ply] = status and ply or nil
end )

net.Receive( "CFC_Hitmarkers_EntEnableChanged", function( _, ply )
    local status = net.ReadBool()

    entHitUsers[ply] = status and ply or nil
end )
