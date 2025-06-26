CustomHitmarkers = CustomHitmarkers or {}
CustomHitmarkers.Colors = CustomHitmarkers.Colors or {}
CustomHitmarkers.WeaponSounds = CustomHitmarkers.WeaponSounds or {}
CustomHitmarkers.ClientConVars = CustomHitmarkers.ClientConVars or {}
CustomHitmarkers.ClientConVarOverrides = CustomHitmarkers.ClientConVarOverrides or {}

local hitmarkerColors = CustomHitmarkers.Colors
local weaponSounds = CustomHitmarkers.WeaponSounds
local hitDuration
local miniHitDuration
local roundEnabled
local blockZeros
local combineMulti
local useEffectiveHealth
local dpsEnabled
local damageAccum = 0
local damageAccumPrev = 0
local damagePasses = 0
local damagePassesSinceHit = 0
local damageLastTime = RealTime()
local curDPS = 0
local curDPSstr = ""
local dpsPosX
local dpsPosY

local UPDATE_INTERVAL = 0.01
local ROUND_DECIMALS = 1
local MINI_SPEED_MIN = 1.5
local MINI_SPEED_MAX = 3
local MINI_INERTIA = 0.93
local MINI_GRAVITY = 0.03
local DPS_PASS_CUTOFF = 80
local DPS_INTERVAL = 0.05
local DPS_SIZE = 30
local DPS_COLOR = Color( 255, 255, 255, 255 )

local FONT_DATA = {
    font = "Roboto Mono",
    extended = false,
    size = DPS_SIZE,
    weight = 500,
    blursize = 0,
    scanlines = 0,
    antialias = true,
    underline = false,
    italic = false,
    strikeout = false,
    symbol = false,
    rotary = false,
    shadow = false,
    Additive = false,
    outline = false,
}

local convarFlags = { FCVAR_ARCHIVE, FCVAR_REPLICATED }
local clConVars = CustomHitmarkers.ClientConVars
local clConVarOverrides = CustomHitmarkers.ClientConVarOverrides

local function createHitmarkerClientConVar( name, default, save, userinfo, text, min, max )
    local convar = CreateClientConVar( name, default, save, userinfo, text, min, max )
    clConVars[name] = convar

    return convar
end

local HITMARKERS_ENABLED = createHitmarkerClientConVar( "custom_hitmarkers_enabled", 1, true, false, "Enables hitmarkers.", 0, 1 )
local HITMARKERS_NPC_ENABLED = createHitmarkerClientConVar( "custom_hitmarkers_npc_enabled", 1, true, false, "Enables hitmarkers for NPCs.", 0, 1 )
local HITMARKERS_ENT_ENABLED = createHitmarkerClientConVar( "custom_hitmarkers_ent_enabled", 0, true, false, "Enables hitmarkers for other entities.", 0, 1 )
local HITMARKERS_SOUND_ENABLED = createHitmarkerClientConVar( "custom_hitmarkers_sound_enabled", 1, true, false, "Enables hitmarker sounds.", 0, 1 )
local HITMARKERS_DPS_ENABLED = createHitmarkerClientConVar( "custom_hitmarkers_dps_enabled", 0, true, false, "Enables a DPS tracker.", 0, 1 )
local HITMARKERS_ROUND_ENABLED = createHitmarkerClientConVar( "custom_hitmarkers_round_enabled", 1, true, false, "Rounds damage numbers.", 0, 1 )
local HITMARKERS_BLOCK_ZEROS = createHitmarkerClientConVar( "custom_hitmarkers_block_zeros", 1, true, false, "Don't display hits with a damage value of 0.", 0, 1 )
local HITMARKERS_COMBINE_MULTI_SHOT = createHitmarkerClientConVar( "custom_hitmarkers_combine_multi_shot", 1, true, false, "Combine multi-shot hits (e.g. a shotgun blast) into one damage number.", 0, 1 )
local HITMARKERS_USE_EFFECTIVE_HEALTH = createHitmarkerClientConVar( "custom_hitmarkers_use_effective_health", 0, true, false, "Display player hit numbers by how much health damage they took (after armor, etc).", 0, 1 )

local HIT_DURATION = createHitmarkerClientConVar( "custom_hitmarkers_hit_duration", -1, true, false, "How long burst hit numbers will linger for. 0 to disable. -1 to use server default.", -1, 10 )
local MINI_DURATION = createHitmarkerClientConVar( "custom_hitmarkers_mini_duration", -1, true, false, "How long mini hit numbers will linger for. 0 to disable. -1 to use server default.", -1, 10 )
local HIT_DURATION_DEFAULT = CreateConVar( "custom_hitmarkers_hit_duration_default", 3, convarFlags, "How long burst hit numbers will linger for. 0 to disable. Default value used for players.", 0, 10 )
local MINI_DURATION_DEFAULT = CreateConVar( "custom_hitmarkers_mini_duration_default", 2.5, convarFlags, "How long mini hit numbers will linger for. 0 to disable. Default value used for players.", 0, 10 )

local HIT_SOUND = createHitmarkerClientConVar( "custom_hitmarkers_hit_sound", "buttons/lightswitch2.wav", true, false, "Sound used for regular hits." )
local HEADSHOT_SOUND = createHitmarkerClientConVar( "custom_hitmarkers_headshot_sound", "buttons/button16.wav", true, false, "Sound used for headshots." )
local KILL_SOUND = createHitmarkerClientConVar( "custom_hitmarkers_kill_sound", "buttons/combine_button1.wav", true, false, "Sound used for kills." )

local HIT_SOUND_VOLUME = createHitmarkerClientConVar( "custom_hitmarkers_hit_sound_volume", 1.5, true, false, "Volume for hit sounds.", 0, 4 )
local HEADSHOT_SOUND_VOLUME = createHitmarkerClientConVar( "custom_hitmarkers_headshot_sound_volume", 1, true, false, "Volume for headshot sounds.", 0, 4 )
local KILL_SOUND_VOLUME = createHitmarkerClientConVar( "custom_hitmarkers_kill_sound_volume", 1.5, true, false, "Volume for kill sounds.", 0, 4 )

local HIT_SOUND_PITCH_MIN = createHitmarkerClientConVar( "custom_hitmarkers_hit_sound_pitch_min", 90, true, false, "Minimum pitch for hit sounds. 100 is 'normal' pitch.", 0, 255 )
local HIT_SOUND_PITCH_MAX = createHitmarkerClientConVar( "custom_hitmarkers_hit_sound_pitch_max", 110, true, false, "Maximum pitch for hit sounds. 100 is 'normal' pitch.", 0, 255 )
local HEADSHOT_SOUND_PITCH_MIN = createHitmarkerClientConVar( "custom_hitmarkers_headshot_sound_pitch_min", 90, true, false, "Minimum pitch for headshot sounds. 100 is 'normal' pitch.", 0, 255 )
local HEADSHOT_SOUND_PITCH_MAX = createHitmarkerClientConVar( "custom_hitmarkers_headshot_sound_pitch_max", 110, true, false, "Maximum pitch for headshot sounds. 100 is 'normal' pitch.", 0, 255 )
local KILL_SOUND_PITCH_MIN = createHitmarkerClientConVar( "custom_hitmarkers_kill_sound_pitch_min", 100, true, false, "Minimum pitch for kill sounds. 100 is 'normal' pitch.", 0, 255 )
local KILL_SOUND_PITCH_MAX = createHitmarkerClientConVar( "custom_hitmarkers_kill_sound_pitch_max", 100, true, false, "Maximum pitch for kill sounds. 100 is 'normal' pitch.", 0, 255 )

createHitmarkerClientConVar( "custom_hitmarkers_hit_color", "255 0 0", true, false, "Color for burst hit numbers." )
createHitmarkerClientConVar( "custom_hitmarkers_mini_hit_color", "255 100 0", true, false, "Color for mini hit numbers." )

local HIT_SIZE = createHitmarkerClientConVar( "custom_hitmarkers_hit_size", 30, true, false, "The font size for burst hit numbers.", 1, 200 )
local MINI_SIZE = createHitmarkerClientConVar( "custom_hitmarkers_mini_size", 30, true, false, "The font size for mini hit numbers.", 1, 200 )

local DPS_POS_X = createHitmarkerClientConVar( "custom_hitmarkers_dps_pos_x", 0.02083, true, false, "The horizontal position for the DPS tracker.", 0, 1 )
local DPS_POS_Y = createHitmarkerClientConVar( "custom_hitmarkers_dps_pos_y", 0.861, true, false, "The vertical position for the DPS tracker.", 0, 1 )

clConVarOverrides.custom_hitmarkers_hit_duration = HIT_DURATION_DEFAULT
clConVarOverrides.custom_hitmarkers_mini_duration = MINI_DURATION_DEFAULT

do
    if not file.Exists( "resource/fonts/RobotoMono.ttf", "MOD" ) then
        local files = file.Find( "resource/fonts/*", "THIRDPARTY" )
        local robotoExists = false

        for _, v in ipairs( files ) do
            if v == "RobotoMono.ttf" then
                robotoExists = true

                break
            end
        end

        if not robotoExists then
            FONT_DATA.font = "Verdana"
        end
    end
end

surface.CreateFont( "CustomHitmarkers_DPSFont", FONT_DATA )
FONT_DATA.size = HIT_SIZE:GetInt()
surface.CreateFont( "CustomHitmarkers_HitFont", FONT_DATA )
FONT_DATA.size = MINI_SIZE:GetInt()
surface.CreateFont( "CustomHitmarkers_MiniFont", FONT_DATA )

local function resetDPS()
    damageAccum = 0
    damageAccumPrev = 0
    damagePasses = 0
    damagePassesSinceHit = 0
    damageLastTime = RealTime()
    curDPS = 0
    curDPSstr = "DPS: " .. tostring( math.Round( curDPS ) )
end

function CustomHitmarkers.GetColorFromConvar( colorName, fallbackColor )
    local convarName = "custom_hitmarkers_" .. colorName .. "_color"
    local col
    local result = ProtectedCall( function()
        local colTbl = string.Explode( " ", GetConVar( convarName ):GetString() )
        col = Color( tonumber( colTbl[1] ), tonumber( colTbl[2] ), tonumber( colTbl[3] ), 255 )
    end )

    return result and col or fallbackColor or Color( 255, 255, 255, 255 ), result
end

function CustomHitmarkers.SetColorFromConvar( colorName, fallbackStr, fallbackColor )
    local convarName = "custom_hitmarkers_" .. colorName .. "_color"
    local col, result = CustomHitmarkers.GetColorFromConvar( colorName, fallbackColor )

    if result then
        hitmarkerColors[colorName] = col

        hook.Run( "CustomHitmarkers_SetColor", colorName, col )
    else
        hitmarkerColors[colorName] = fallbackColor or Color( 255, 255, 255, 255 )
        LocalPlayer():ConCommand( convarName .. " " .. ( fallbackStr or "255 255 255" ) )
    end
end

if not hitmarkerColors.hit then
    CustomHitmarkers.SetColorFromConvar( "hit", "255 0 0", Color( 255, 0, 0, 255 ) )
end

if not hitmarkerColors.mini_hit then
    CustomHitmarkers.SetColorFromConvar( "mini_hit", "255 100 0", Color( 255, 100, 0, 255 ) )
end

cvars.AddChangeCallback( "custom_hitmarkers_hit_color", function()
    CustomHitmarkers.SetColorFromConvar( "hit", "255 0 0", Color( 255, 0, 0, 255 ) )
end )

cvars.AddChangeCallback( "custom_hitmarkers_mini_hit_color", function()
    CustomHitmarkers.SetColorFromConvar( "mini_hit", "255 0 0", Color( 255, 0, 0, 255 ) )
end )

cvars.AddChangeCallback( "custom_hitmarkers_hit_duration", function( _, _, new )
    local newVal = tonumber( new ) or -1

    if newVal < 0 then
        newVal = HIT_DURATION_DEFAULT:GetFloat()
    end

    hitDuration = newVal
end )

cvars.AddChangeCallback( "custom_hitmarkers_mini_duration", function( _, _, new )
    local newVal = tonumber( new ) or -1

    if newVal < 0 then
        newVal = MINI_DURATION_DEFAULT:GetFloat()
    end

    miniHitDuration = newVal
end )

cvars.AddChangeCallback( "custom_hitmarkers_enabled", function( _, _, new )
    net.Start( "CustomHitmarkers_EnableChanged" )
    net.WriteBool( new ~= "0" )
    net.SendToServer()
end )

cvars.AddChangeCallback( "custom_hitmarkers_npc_enabled", function( _, _, new )
    net.Start( "CustomHitmarkers_NPCEnableChanged" )
    net.WriteBool( new ~= "0" )
    net.SendToServer()
end )

cvars.AddChangeCallback( "custom_hitmarkers_ent_enabled", function( _, _, new )
    net.Start( "CustomHitmarkers_EntEnableChanged" )
    net.WriteBool( new ~= "0" )
    net.SendToServer()
end )

cvars.AddChangeCallback( "custom_hitmarkers_dps_enabled", function( _, _, new )
    dpsEnabled = new ~= "0"

    if dpsEnabled then
        resetDPS()
    end
end )

cvars.AddChangeCallback( "custom_hitmarkers_round_enabled", function( _, _, new )
    roundEnabled = new ~= "0"
end )

cvars.AddChangeCallback( "custom_hitmarkers_block_zeros", function( _, _, new )
    blockZeros = new ~= "0"
end )

cvars.AddChangeCallback( "custom_hitmarkers_combine_multi_shot", function( _, _, new )
    combineMulti = new ~= "0"
end )

cvars.AddChangeCallback( "custom_hitmarkers_use_effective_health", function( _, _, new )
    useEffectiveHealth = new ~= "0"
end )

cvars.AddChangeCallback( "custom_hitmarkers_dps_pos_x", function( _, _, new )
    local frac = math.Clamp( tonumber( new ) or 0.02083, 0, 1 )

    dpsPosX = ScrW() * frac
end )

cvars.AddChangeCallback( "custom_hitmarkers_dps_pos_y", function( _, _, new )
    local frac = math.Clamp( tonumber( new ) or 0.02083, 0, 1 )

    dpsPosY = ScrH() * frac
end )

cvars.AddChangeCallback( "custom_hitmarkers_hit_size", function( _, old, new )
    local oldVal = tonumber( old ) or 30
    local newVal = tonumber( new )

    if not newVal then
        LocalPlayer():ConCommand( "custom_hitmarkers_hit_size " .. oldVal )

        return
    end

    FONT_DATA.size = newVal
    surface.CreateFont( "CustomHitmarkers_HitFont", FONT_DATA )
end )

cvars.AddChangeCallback( "custom_hitmarkers_mini_size", function( _, old, new )
    local oldVal = tonumber( old ) or 30
    local newVal = tonumber( new )

    if not newVal then
        LocalPlayer():ConCommand( "custom_hitmarkers_mini_size " .. oldVal )

        return
    end

    FONT_DATA.size = newVal
    surface.CreateFont( "CustomHitmarkers_MiniFont", FONT_DATA )
end )

CustomHitmarkers.MiniHitCount = 0
CustomHitmarkers.HitScores = {}
CustomHitmarkers.HitColors = {}
CustomHitmarkers.HitTimes = {}
CustomHitmarkers.HitPoints = {}
CustomHitmarkers.MiniHits = {}

hitDuration = HIT_DURATION:GetFloat() or -1
miniHitDuration = MINI_DURATION:GetFloat() or -1
hitDuration = hitDuration < 0 and HIT_DURATION_DEFAULT:GetFloat() or hitDuration
miniHitDuration = miniHitDuration < 0 and MINI_DURATION_DEFAULT:GetFloat() or miniHitDuration

roundEnabled = HITMARKERS_ROUND_ENABLED:GetBool()
blockZeros = HITMARKERS_BLOCK_ZEROS:GetBool()
combineMulti = HITMARKERS_COMBINE_MULTI_SHOT:GetBool()
useEffectiveHealth = HITMARKERS_USE_EFFECTIVE_HEALTH:GetBool()

dpsEnabled = HITMARKERS_DPS_ENABLED:GetBool()
dpsPosX = ScrW() * DPS_POS_X:GetFloat()
dpsPosY = ScrH() * DPS_POS_Y:GetFloat()

local hitScores = CustomHitmarkers.HitScores
local miniHitCounts = {}
local hitColors = {}
local hitTimes = {}
local hitPoints = {}
local miniHits = {}

CustomHitmarkers.SoundTbl = CustomHitmarkers.SoundTbl or {}
CustomHitmarkers.SoundTbl.Hit = {
    Path = HIT_SOUND,
    Volume = HIT_SOUND_VOLUME,
    Pitch = function() return math.Rand( HIT_SOUND_PITCH_MIN:GetFloat(), HIT_SOUND_PITCH_MAX:GetFloat() ) / 100 end
}
CustomHitmarkers.SoundTbl.Headshot = {
    Path = HEADSHOT_SOUND,
    Volume = HEADSHOT_SOUND_VOLUME,
    Pitch = function() return math.Rand( HEADSHOT_SOUND_PITCH_MIN:GetFloat(), HEADSHOT_SOUND_PITCH_MAX:GetFloat() ) / 100 end
}
CustomHitmarkers.SoundTbl.Kill = {
    Path = KILL_SOUND,
    Volume = KILL_SOUND_VOLUME,
    Pitch = function() return math.Rand( KILL_SOUND_PITCH_MIN:GetFloat(), KILL_SOUND_PITCH_MAX:GetFloat() ) / 100 end
}

function CustomHitmarkers.DoSound( soundType, overrides )
    if not HITMARKERS_SOUND_ENABLED:GetBool() then return end

    local snd = CustomHitmarkers.SoundTbl[soundType]
    if not snd then return end

    overrides = overrides or {}

    local path = overrides.Path or snd.Path
    local volume = overrides.Volume or snd.Volume
    local pitch = overrides.Pitch or snd.Pitch

    if type( path ) == "ConVar" then
        path = path:GetString()
    elseif type( path ) == "function" then
        path = path()
    end

    if path == "" then return end

    if type( volume ) == "ConVar" then
        volume = volume:GetFloat()
    elseif type( volume ) == "function" then
        volume = volume()
    end

    if type( pitch ) == "ConVar" then
        pitch = pitch:GetFloat()
    elseif type( pitch ) == "function" then
        pitch = pitch()
    end

    sound.PlayFile( "sound/" .. path, "noplay", function( station )
        if not IsValid( station ) then return end

        station:Play()
        station:SetVolume( volume )
        station:SetPlaybackRate( pitch )
    end )
end

hook.Add( "InitPostEntity", "CustomHitmarkers_DoIUseHitmarkers", function()
    timer.Simple( 10, function()
        net.Start( "CustomHitmarkers_EnableChanged" )
        net.WriteBool( HITMARKERS_ENABLED:GetBool() )
        net.SendToServer()

        net.Start( "CustomHitmarkers_NPCEnableChanged" )
        net.WriteBool( HITMARKERS_NPC_ENABLED:GetBool() )
        net.SendToServer()

        net.Start( "CustomHitmarkers_EntEnableChanged" )
        net.WriteBool( HITMARKERS_ENT_ENABLED:GetBool() )
        net.SendToServer()
    end )
end )

hook.Add( "HUDPaint", "CustomHitmarkers_DrawHits", function()
    for i = 1, CustomHitmarkers.MiniHitCount do
        local miniHit = miniHits[i]
        local screenPos = miniHit.Pos:ToScreen()
        local xPos = screenPos.x
        local yPos = screenPos.y

        draw.SimpleText( miniHit.Text, "CustomHitmarkers_MiniFont", xPos, yPos, miniHit.Color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end

    for ply, score in pairs( hitScores ) do
        if miniHitDuration == 0 or miniHitCounts[ply] ~= 1 then
            local screenPos = hitPoints[ply]:ToScreen()
            local xPos = screenPos.x
            local yPos = screenPos.y

            draw.SimpleText( tostring( score ), "CustomHitmarkers_HitFont", xPos, yPos, hitColors[ply], TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
        end
    end

    if not dpsEnabled then return end

    draw.SimpleText( curDPSstr, "CustomHitmarkers_DPSFont", dpsPosX, dpsPosY, DPS_COLOR, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
end )

timer.Create( "CustomHitmarkers_TrackDPS", DPS_INTERVAL, 0, function()
    if not dpsEnabled then return end

    if damagePassesSinceHit >= DPS_PASS_CUTOFF then
        resetDPS()

        return
    end

    if damageAccum == 0 then return end

    local damageChunk = damageAccum - damageAccumPrev

    damagePasses = damagePasses + 1

    if damageChunk == 0 then
        damagePassesSinceHit = damagePassesSinceHit + 1
    else
        damagePassesSinceHit = damagePassesSinceHit / 2
    end

    local passRatio = 1 / damagePasses
    local curTime = RealTime()

    if curTime ~= damageLastTime then
        curDPS = curDPS * ( 1 - passRatio ) + damageChunk * passRatio / ( curTime - damageLastTime )
        curDPSstr = "DPS: " .. tostring( math.Round( curDPS ) )
    end

    damageAccumPrev = damageAccum
    damageLastTime = curTime
end )

local function doHitSound( soundType, inflictorClass )
    local weaponSettings = weaponSounds[inflictorClass]
    weaponSettings = weaponSettings and weaponSettings[soundType]
    local overrides = {}

    if weaponSettings and weaponSettings.Path ~= "default" then
        overrides.Path = weaponSettings.Path
        overrides.Volume = weaponSettings.Volume
        overrides.Pitch = weaponSettings.Pitch / 100
    end

    CustomHitmarkers.DoSound( soundType, overrides )
end

local function trackHit( ply, pos, dmg, inflictorClass, headShot, hitColor, miniHitColor, dontAccum )
    if roundEnabled then
        dmg = math.Round( dmg )
    end

    if blockZeros and dmg == 0 then return end

    if not IsValid( ply ) then
        ply = LocalPlayer() -- Only use ply for tracking groups of hits, so it's fine to use the client as a fallback
    end

    if dontAccum then
        hitScores[ply] = hitScores[ply] or 0
    else
        damageAccum = damageAccum + dmg
        hitScores[ply] = ( hitScores[ply] or 0 ) + dmg
    end

    miniHitCounts[ply] = ( miniHitCounts[ply] or 0 ) + 1
    hitColors[ply] = Color( hitColor.r, hitColor.g, hitColor.b )
    hitTimes[ply] = RealTime()
    hitPoints[ply] = pos

    local miniHitVel = Vector( math.Rand( -1, 1 ), math.Rand( -1, 1 ), math.Rand( -1, 1 ) )
    miniHitVel:Normalize()

    local miniHitCount = CustomHitmarkers.MiniHitCount + 1
    CustomHitmarkers.MiniHitCount = miniHitCount

    miniHits[miniHitCount] = {
        Pos = pos,
        Text = headShot and ">" .. dmg .. "<" or dmg .. "",
        Vel = miniHitVel * math.Rand( MINI_SPEED_MIN, MINI_SPEED_MAX ),
        Color = Color( miniHitColor.r, miniHitColor.g, miniHitColor.b ),
        Time = RealTime(),
        Ply = ply,
    }

    doHitSound( headShot and "Headshot" or "Hit", inflictorClass )
end

net.Receive( "CustomHitmarkers_Hit", function()
    local ply = net.ReadEntity()
    local pos = net.ReadVector()
    local trueDmg = net.ReadFloat()
    local hpDmg = net.ReadFloat()
    trueDmg = useEffectiveHealth and hpDmg or trueDmg
    local dmg = math.Round( trueDmg, ROUND_DECIMALS )
    local headShot = net.ReadBool()
    local numHits = net.ReadUInt( 9 )
    local inflictorClass = net.ReadString()
    local hitColor = hitmarkerColors.hit
    local miniHitColor = hitmarkerColors.mini_hit

    if not IsValid( ply ) then
        ply = LocalPlayer()
    end

    if combineMulti or numHits <= 1 then
        trackHit( ply, pos, dmg, inflictorClass, headShot, hitColor, miniHitColor )
    else
        local perHitDmg = math.Round( trueDmg / numHits, ROUND_DECIMALS )
        local radius = ( ply:BoundingRadius() or 20 ) / 3

        if roundEnabled then
            perHitDmg = math.Round( perHitDmg )
        end

        -- Splitting up the damage and sending it straight to trackHit() will cause a lot of rounding (espcially with custom_hitmarkers_round_enabled 1) before everything sums back up,
        --  which causes a ton of imprecision in the final 'burst hit' number. This section finds the discrepancy, tweaks per-hit damage, and overrides the final total to fix things up.

        local roughDmg = perHitDmg * numHits -- What the player would (erroneously) see as their hit total without correcting for truncation
        local truncatedDmg = trueDmg - roughDmg -- Amount of damage under/over represented by rounding, splitting, and optionally re-rounding the original total
        local truncationIsSignificant = math.abs( truncatedDmg ) >= 1
        local singleCorrection = false
        local singleCorrCount = 1

        if truncationIsSignificant then
            if roundEnabled then
                dmg = math.Round( dmg )
            end

            damageAccum = damageAccum + trueDmg
            hitScores[ply] = ( hitScores[ply] or 0 ) + dmg

            -- Have to define these to avoid nil errors during the few frames of rendering between now and the upcoming trackHit() calls
            hitColors[ply] = Color( hitColor.r, hitColor.g, hitColor.b )
            hitPoints[ply] = pos

            -- By now, the burst damage number will be quite accurate (off by at most +- 1)
            -- However, the mini hits wouldn't add up correctly if the player bothers to tally them all, which gets handled below
            local perHitCorrection = math.Round( truncatedDmg / numHits )
            perHitDmg = perHitDmg + perHitCorrection -- Add/subtract whole number values to each mini hit to get close to proper values
            singleCorrection = math.Round( trueDmg - perHitDmg * ( numHits - 1 ), ROUND_DECIMALS ) -- Tweak the first hit to account for whatever couldn't be divided into/out from numHits

            -- In case the numbers are real scuffed, with the remainder being negative and overshadowing the new perHitDmg, we have to override more than just the first number
            if singleCorrection <= 0 then
                truncatedDmg = singleCorrection - perHitDmg -- The remainder truncation, which always satisfies 0 <= |truncatedDmg| < numHits, so we can split these into -1's safely
                singleCorrCount = -truncatedDmg
                singleCorrection = perHitDmg - 1

                -- If you somehow are using a shotgun which does about 0.5 < x < 1 damage and a gajillion bullets per shot to the point where even this extra step yields hit numbers < 1, the fuck are you doing?
            end

            -- Side note: Rarely, some M9K shotguns (such as the m9k_m3) seem to trigger two dmg events simultaneously, one with multiple bullets, and an additional single-bullet shot,
            --  which can create a max burst discrepancy of +- 2 and up to three different mini hit numbers.
            -- This only occasionally happens when shooting players with certain M9K shotguns, seemingly at random.
        end

        for i = 1, numHits do
            local theta = math.Rand( 0, 2 * math.pi )
            local phi = math.Rand( 0, 2 * math.pi )
            local dist = math.Rand( 0, radius )
            local offset = Vector( math.sin( theta ) * math.sin( phi ), math.cos( theta ), math.sin( theta ) * math.cos( phi ) ) * dist

            trackHit( ply, pos + offset, i <= singleCorrCount and singleCorrection or perHitDmg, inflictorClass, headShot, hitColor, miniHitColor, truncationIsSignificant )
        end
    end
end )

net.Receive( "CustomHitmarkers_Kill", function()
    local inflictorClass = net.ReadString()

    doHitSound( "Kill", inflictorClass )
end )

timer.Create( "CustomHitmarkers_UpdatePoints", UPDATE_INTERVAL, 0, function()
    local curTime = RealTime()

    for ply, time in pairs( hitTimes ) do
        local alpha = 255 * ( 1 - ( curTime - time ) / hitDuration )

        if alpha < 0 then
            hitScores[ply] = nil
            hitColors[ply] = nil
            hitTimes[ply] = nil
            hitPoints[ply] = nil
        else
            hitColors[ply].a = alpha
        end
    end

    local miniHitCount = CustomHitmarkers.MiniHitCount

    for i = miniHitCount, 1, -1 do
        local miniHit = miniHits[i]
        local alpha = 255 * ( 1 - ( curTime - miniHit.Time ) / miniHitDuration )

        if alpha < 0 then
            local miniHitCountPly = miniHitCounts[miniHit.Ply]

            if miniHitCountPly then
                miniHitCountPly = miniHitCountPly - 1

                if miniHitCountPly < 1 then
                    miniHitCounts[miniHit.Ply] = nil
                else
                    miniHitCounts[miniHit.Ply] = miniHitCountPly
                end
            end

            table.remove( miniHits, i )
            miniHitCount = miniHitCount - 1
        else
            miniHit.Color.a = alpha
            miniHit.Pos = miniHit.Pos + miniHit.Vel
            miniHit.Vel = miniHit.Vel * MINI_INERTIA + Vector( 0, 0, - MINI_GRAVITY )
        end
    end

    CustomHitmarkers.MiniHitCount = miniHitCount
end )
