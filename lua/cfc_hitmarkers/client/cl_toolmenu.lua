CFC_Hitmarkers = CFC_Hitmarkers or {}
CFC_Hitmarkers.Colors = CFC_Hitmarkers.Colors or {}

local function createColorPicker( background, colorName, colorNameFancy )
    local storedColor = CFC_Hitmarkers.GetColorFromConvar( colorName )

    local label = vgui.Create( "DLabel", background )
    label:SetPos( 5, 5 )
    label:SetSize( 155, 20 )
    label:SetText( colorNameFancy or colorName )
    label:SetTextColor( Color( 0, 0, 0, 255 ) )

    local colorCube = vgui.Create( "DColorCube", background )
    colorCube:SetPos( 5, 5 + 20 )
    colorCube:SetSize( 155, 155 )

    local colorPicker = vgui.Create( "DRGBPicker", background )
    colorPicker:SetPos( 165, 5 + 20 )
    colorPicker:SetSize( 30, 155 )

    local colorR = vgui.Create( "DNumberWang", background )
    colorR:SetPos( 200, 5 + 20 )
    colorR:SetSize( 50, 20 )
    colorR:SetTextColor( Color( 255, 0, 0, 255 ) )
    colorR:SetMin( 0 )
    colorR:SetMax( 255 )
    colorR:SetDecimals( 0 )

    local colorG = vgui.Create( "DNumberWang", background )
    colorG:SetPos( 200, 30 + 20 )
    colorG:SetSize( 50, 20 )
    colorG:SetTextColor( Color( 0, 255, 0, 255 ) )
    colorG:SetMin( 0 )
    colorG:SetMax( 255 )
    colorG:SetDecimals( 0 )

    local colorB = vgui.Create( "DNumberWang", background )
    colorB:SetPos( 200, 55 + 20 )
    colorB:SetSize( 50, 20 )
    colorB:SetTextColor( Color( 0, 0, 255, 255 ) )
    colorB:SetMin( 0 )
    colorB:SetMax( 255 )
    colorB:SetDecimals( 0 )

    local function updateColors( col, ignore )
        if ignore ~= "r" then
            colorR:SetValue( col.r )
        end

        if ignore ~= "g" then
            colorG:SetValue( col.g )
        end

        if ignore ~= "b" then
            colorB:SetValue( col.b )
        end

        if ignore ~= "picker" then
            colorPicker:SetRGB( col )
        end

        colorCube:SetColor( col )
        storedColor = col

        if ignore ~= "concmd" then
            LocalPlayer():ConCommand( "cfc_hitmarkers_" .. colorName .. "_color " .. col.r .. " " .. col.g .. " " .. col.b )
        end
    end

    background:SetBackgroundColor( Color( 255, 255, 255, 0 ) )
    updateColors( storedColor, "concmd" )

    function colorPicker:OnChange( col )
        local h = ColorToHSV( col )
        local _, s, v = ColorToHSV( colorCube:GetRGB() )

        col = HSVToColor( h, s, v )

        updateColors( col, "picker" )
    end

    function colorCube:OnUserChanged( col )
        local h = ColorToHSV( colorPicker:GetRGB() )
        local _, s, v = ColorToHSV( col )

        col = HSVToColor( h, s, v )

        updateColors( col )
    end

    function colorR:OnValueChanged( val )
        local col = storedColor

        col.r = val
        updateColors( col, "r" )
    end

    function colorG:OnValueChanged( val )
        local col = storedColor

        col.g = val
        updateColors( col, "g" )
    end

    function colorB:OnValueChanged( val )
        local col = storedColor

        col.b = val
        updateColors( col, "b" )
    end
end

local hitColorPicker
local miniHitColorPicker

hook.Add( "AddToolMenuCategories", "CFC_Hitmarkers_AddToolMenuCategories", function()
    spawnmenu.AddToolCategory( "Options", "CFC", "#CFC" )
end )

hook.Add( "PopulateToolMenu", "CFC_Hitmarkers_PopulateToolMenu", function()
    spawnmenu.AddToolMenuOption( "Options", "CFC", "cfc_hitmarkers", "#Hitmarkers", "", "", function( panel )
        panel:CheckBox( "Enable hitmarkers", "cfc_hitmarkers_enabled" )
        panel:CheckBox( "Enable NPC hitmarkers", "cfc_hitmarkers_npc_enabled" )
        panel:CheckBox( "Enable entity hitmarkers", "cfc_hitmarkers_ent_enabled" )
        panel:CheckBox( "Enable hitmarker sounds", "cfc_hitmarkers_sound_enabled" )

        panel:NumSlider( "Hit duration (0 to disable)", "cfc_hitmarkers_hit_duration", 0, 10, 1 )
        panel:NumSlider( "Mini hit duration (0 to disable)", "cfc_hitmarkers_mini_duration", 0, 10, 1 )

        panel:TextEntry( "Hit sound", "cfc_hitmarkers_hit_sound" )
        panel:TextEntry( "Headshot sound", "cfc_hitmarkers_headshot_sound" )
        panel:TextEntry( "Kill sound", "cfc_hitmarkers_kill_sound" )

        panel:NumSlider( "Hit sound volume", "cfc_hitmarkers_hit_sound_volume", 0, 4, 1 )
        panel:NumSlider( "Headshot sound volume", "cfc_hitmarkers_headshot_sound_volume", 0, 4, 1 )
        panel:NumSlider( "Kill sound volume", "cfc_hitmarkers_kill_sound_volume", 0, 4, 1 )

        hitColorPicker = vgui.Create( "DPanel", panel )
        hitColorPicker:SetSize( 200, 165 + 20 )
    
        miniHitColorPicker = vgui.Create( "DPanel", panel )
        miniHitColorPicker:SetSize( 200, 165 + 20 )
    
        createColorPicker( hitColorPicker, "hit", "Hit color" )
        createColorPicker( miniHitColorPicker, "mini_hit", "Mini hit color" )

        panel:AddItem( hitColorPicker )
        panel:AddItem( miniHitColorPicker )
    end )
end )
