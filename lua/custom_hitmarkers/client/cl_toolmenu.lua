CustomHitmarkers = CustomHitmarkers or {}
CustomHitmarkers.Colors = CustomHitmarkers.Colors or {}
CustomHitmarkers.ClientConVars = CustomHitmarkers.ClientConVars or {}
CustomHitmarkers.ClientConVarOverrides = CustomHitmarkers.ClientConVarOverrides or {}

local convarFlags = { FCVAR_ARCHIVE, FCVAR_REPLICATED }
local clConVars = CustomHitmarkers.ClientConVars
local clConVarOverrides = CustomHitmarkers.ClientConVarOverrides

local NPC_ALLOWED = CreateConVar( "custom_hitmarkers_npc_allowed", 1, convarFlags, "Allows players to opt in to NPC hitmarkers.", 0, 1 )
local ENT_ALLOWED = CreateConVar( "custom_hitmarkers_ent_allowed", 1, convarFlags, "Allows players to opt in to entity hitmarkers.", 0, 1 )

local TEXT_COLOR = Color( 0, 0, 0, 255 )
local TEXT_COLOR_UNUSABLE = Color( 128, 128, 128, 255 )
local DIVIDER_COLOR = Color( 128, 128, 128, 255 )

local function createColorPicker( background, colorName, colorNameFancy )
    local storedColor = CustomHitmarkers.GetColorFromConvar( colorName )

    local label = vgui.Create( "DLabel", background )
    label:SetPos( 5, 5 )
    label:SetSize( 155, 20 )
    label:SetText( colorNameFancy or colorName )
    label:SetTextColor( Color( 0, 0, 0, 255 ) )

    local colorCube = vgui.Create( "DColorCube", background )
    colorCube:SetPos( 5, 25 )
    colorCube:SetSize( 155, 155 )

    local colorPicker = vgui.Create( "DRGBPicker", background )
    colorPicker:SetPos( 165, 25 )
    colorPicker:SetSize( 30, 155 )

    local colorR = vgui.Create( "DNumberWang", background )
    colorR:SetPos( 200, 25 )
    colorR:SetSize( 50, 20 )
    colorR:SetTextColor( Color( 255, 0, 0, 255 ) )
    colorR:SetMin( 0 )
    colorR:SetMax( 255 )
    colorR:SetDecimals( 0 )

    local colorG = vgui.Create( "DNumberWang", background )
    colorG:SetPos( 200, 50 )
    colorG:SetSize( 50, 20 )
    colorG:SetTextColor( Color( 0, 255, 0, 255 ) )
    colorG:SetMin( 0 )
    colorG:SetMax( 255 )
    colorG:SetDecimals( 0 )

    local colorB = vgui.Create( "DNumberWang", background )
    colorB:SetPos( 200, 75 )
    colorB:SetSize( 50, 20 )
    colorB:SetTextColor( Color( 0, 0, 255, 255 ) )
    colorB:SetMin( 0 )
    colorB:SetMax( 255 )
    colorB:SetDecimals( 0 )

    local function updateColors( col, ignore, hue )
        if ignore ~= "r" then
            colorR:SetText( tostring( col.r ) ) -- Sets the number's value without triggering :OnValueChanged()
        end

        if ignore ~= "g" then
            colorG:SetText( tostring( col.g ) )
        end

        if ignore ~= "b" then
            colorB:SetText( tostring( col.b ) )
        end

        if ignore ~= "picker" and ignore ~= "cube" then
            hue = hue or ColorToHSV( col )
            colorPicker.LastY = 155 * ( 1 - hue / 360 )
        end

        colorCube:SetColor( col )
        storedColor = col

        if ignore ~= "concmd" then
            LocalPlayer():ConCommand( "custom_hitmarkers_" .. colorName .. "_color " .. col.r .. " " .. col.g .. " " .. col.b )
        end
    end

    hook.Add( "CustomHitmarkers_SetColor", "CustomHitmarkers_UpdateColorPicker_" .. colorName, function( colName, col )
        if colName ~= colorName or col == storedColor then return end

        updateColors( col, "concmd" )
    end )

    background:SetBackgroundColor( Color( 255, 255, 255, 0 ) )
    updateColors( storedColor, "concmd" )

    function colorPicker:OnChange( col )
        local h = ColorToHSV( col )
        local _, s, v = ColorToHSV( storedColor )

        col = HSVToColor( h, s, v )

        updateColors( col, "picker", h )
    end

    function colorCube:OnUserChanged( col )
        local h = ColorToHSV( storedColor )
        local _, s, v = ColorToHSV( col )

        col = HSVToColor( h, s, v )

        updateColors( col, "cube", h )
    end

    function colorR:OnValueChanged( val )
        local col = storedColor

        col.r = tonumber( val ) -- Clicking the up/down arrows yields a string instead of a number
        updateColors( col, "r" )
    end

    function colorG:OnValueChanged( val )
        local col = storedColor

        col.g = tonumber( val )
        updateColors( col, "g" )
    end

    function colorB:OnValueChanged( val )
        local col = storedColor

        col.b = tonumber( val )
        updateColors( col, "b" )
    end
end

local function updateUsabilityColor( panel, state )
    if not panel then return end

    local skin = panel:GetSkin() or SKIN or {}
    local newCol = state and ( skin.colTextEntryText or TEXT_COLOR ) or skin.colTextEntryTextPlaceholder or TEXT_COLOR_UNUSABLE

    panel:SetTextColor( newCol )
end

local hitColorPicker
local miniHitColorPicker
local npcCB
local entCB

local function createCollapsibleSliders( panel, collapseText, settings )
    local collapse = vgui.Create( "DCollapsibleCategory", panel )
    local list = vgui.Create( "DPanelList", collapse )
    local bottomLine = vgui.Create( "DFrame", list )
    local skin = panel:GetSkin() or SKIN or {}
    local lineColor = skin.bg_color_bright or DIVIDER_COLOR
    local lineHeight = 1
    local lineMargin = 8

    collapse:SetLabel( collapseText )
    collapse:SetExpanded( false )

    list:SetSpacing( 5 )
    list:EnableHorizontal( false )
    list:EnableVerticalScrollbar( true )
    collapse:SetContents( list )

    for _, setting in ipairs( settings ) do
        local slider = vgui.Create( "DNumSlider" )

        slider:SetText( setting.Text )
        slider:SetMin( setting.Min )
        slider:SetMax( setting.Max )
        slider:SetDecimals( setting.Decimals )
        slider:SetConVar( setting.ConVar )
        slider:SizeToContents()
        slider:GetChildren()[3]:SetTextColor( skin.colTextEntryText or TEXT_COLOR )
        list:AddItem( slider )
    end

    local listW = list:GetSize()

    bottomLine:SetSize( listW, lineHeight )
    list:AddItem( bottomLine )
    bottomLine.Paint = function( _, w, h )
        draw.RoundedBox( 1, lineMargin / 2, 0, w - lineMargin, h, lineColor )
    end

    return collapse
end

hook.Add( "AddToolMenuCategories", "CustomHitmarkers_AddToolMenuCategories", function()
    spawnmenu.AddToolCategory( "Options", "CustomTools", "#CustomTools" )
end )

hook.Add( "PopulateToolMenu", "CustomHitmarkers_PopulateToolMenu", function()
    spawnmenu.AddToolMenuOption( "Options", "CustomTools", "custom_hitmarkers", "#Hitmarkers", "", "", function( panel )
        pcall( function() -- ControlPresets only exists in certain gamemodes
            local presetControl = vgui.Create( "ControlPresets", panel )
            local defaults = {}

            for cvName, cv in pairs( clConVars ) do
                presetControl:AddConVar( cvName )
                defaults[cvName] = ( clConVarOverrides[cvName] or cv ):GetDefault()
            end

            presets.Add( "custom_hitmarkers", "Default", defaults )
            presetControl:SetPreset( "custom_hitmarkers" )

            panel:AddItem( presetControl )
        end )

        panel:CheckBox( "Enable hitmarkers", "custom_hitmarkers_enabled" )
        npcCB = panel:CheckBox( "Enable NPC hitmarkers", "custom_hitmarkers_npc_enabled" )
        entCB = panel:CheckBox( "Enable entity hitmarkers", "custom_hitmarkers_ent_enabled" )
        panel:CheckBox( "Enable hitmarker sounds", "custom_hitmarkers_sound_enabled" )
        panel:CheckBox( "Enable DPS tracker", "custom_hitmarkers_dps_enabled" )
        panel:CheckBox( "Round damage numbers", "custom_hitmarkers_round_enabled" )
        panel:CheckBox( "Block zero-damage hits", "custom_hitmarkers_block_zeros" )
        panel:CheckBox( "Combine shotgun blasts into one number\n(doesn't work with some custom weapons)", "custom_hitmarkers_combine_multi_shot" )
        panel:CheckBox( "Show final HP loss instead of raw damage", "custom_hitmarkers_effective_health" )

        local infoPanel = vgui.Create( "DLabel" )

        updateUsabilityColor( infoPanel, true )
        infoPanel:SetText(
            "'Burst hits' show total recent damage to a target.\n" ..
            "'Mini hits' show individual hit numbers."
        )

        local _, infoY = infoPanel:GetTextSize()

        infoPanel:SetHeight( infoY + 5 )
        panel:AddItem( infoPanel )

        panel:NumSlider( "Burst hit duration\n(0 to disable)", "custom_hitmarkers_hit_duration", 0, 10, 1 )
        panel:NumSlider( "Mini hit duration\n(0 to disable)", "custom_hitmarkers_mini_duration", 0, 10, 1 )

        panel:NumSlider( "Burst hit font size", "custom_hitmarkers_hit_size", 1, 200, 0 )
        panel:NumSlider( "Mini hit font size", "custom_hitmarkers_mini_size", 1, 200, 0 )

        panel:TextEntry( "Hit sound", "custom_hitmarkers_hit_sound" )
        panel:TextEntry( "Headshot sound", "custom_hitmarkers_headshot_sound" )
        panel:TextEntry( "Kill sound", "custom_hitmarkers_kill_sound" )

        if WireLib then
            panel:Button( "Sound Browser", "wire_sound_browser_open" )
        end

        panel:AddItem( createCollapsibleSliders( panel, "Sound Volume Settings", {
            {
                Text = "Hit sound volume",
                Min = 0,
                Max = 4,
                Decimals = 1,
                ConVar = "custom_hitmarkers_hit_sound_volume",
            },
            {
                Text = "Headshot sound volume",
                Min = 0,
                Max = 4,
                Decimals = 1,
                ConVar = "custom_hitmarkers_headshot_sound_volume",
            },
            {
                Text = "Kill sound volume",
                Min = 0,
                Max = 4,
                Decimals = 1,
                ConVar = "custom_hitmarkers_kill_sound_volume",
            },
        } ) )
        panel:AddItem( createCollapsibleSliders( panel, "Sound Pitch Settings", {
            {
                Text = "Hit sound pitch min",
                Min = 0,
                Max = 255,
                Decimals = 0,
                ConVar = "custom_hitmarkers_hit_sound_pitch_min",
            },
            {
                Text = "Hit sound pitch max",
                Min = 0,
                Max = 255,
                Decimals = 0,
                ConVar = "custom_hitmarkers_hit_sound_pitch_max",
            },
            {
                Text = "Headshot sound pitch min",
                Min = 0,
                Max = 255,
                Decimals = 0,
                ConVar = "custom_hitmarkers_headshot_sound_pitch_min",
            },
            {
                Text = "Headshot sound pitch max",
                Min = 0,
                Max = 255,
                Decimals = 0,
                ConVar = "custom_hitmarkers_headshot_sound_pitch_max",
            },
            {
                Text = "Kill sound pitch min",
                Min = 0,
                Max = 255,
                Decimals = 0,
                ConVar = "custom_hitmarkers_kill_sound_pitch_min",
            },
            {
                Text = "Kill sound pitch max",
                Min = 0,
                Max = 255,
                Decimals = 0,
                ConVar = "custom_hitmarkers_kill_sound_pitch_max",
            },
        } ) )

        panel:NumSlider( "DPS pos x", "custom_hitmarkers_dps_pos_x", 0, 1, 4 )
        panel:NumSlider( "DPS pos y", "custom_hitmarkers_dps_pos_y", 0, 1, 4 )

        hitColorPicker = vgui.Create( "DPanel", panel )
        hitColorPicker:SetSize( 200, 185 )

        miniHitColorPicker = vgui.Create( "DPanel", panel )
        miniHitColorPicker:SetSize( 200, 185 )

        createColorPicker( hitColorPicker, "hit", "Burst hit color" )
        createColorPicker( miniHitColorPicker, "mini_hit", "Mini hit color" )

        panel:AddItem( hitColorPicker )
        panel:AddItem( miniHitColorPicker )

        updateUsabilityColor( npcCB, NPC_ALLOWED:GetBool() )
        updateUsabilityColor( entCB, ENT_ALLOWED:GetBool() )
    end )
end )

net.Receive( "CustomHitmarkers_NPCAllowedChanged", function()
    updateUsabilityColor( npcCB, net.ReadBool() )
end )

net.Receive( "CustomHitmarkers_ENTAllowedChanged", function()
    updateUsabilityColor( entCB, net.ReadBool() )
end )
