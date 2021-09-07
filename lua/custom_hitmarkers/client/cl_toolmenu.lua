CustomHitmarkers = CustomHitmarkers or {}
CustomHitmarkers.Colors = CustomHitmarkers.Colors or {}

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

local hitColorPicker
local miniHitColorPicker

hook.Add( "AddToolMenuCategories", "CustomHitmarkers_AddToolMenuCategories", function()
    spawnmenu.AddToolCategory( "Options", "Hitmarkers", "#Hitmarkers" )
end )

hook.Add( "PopulateToolMenu", "CustomHitmarkers_PopulateToolMenu", function()
    spawnmenu.AddToolMenuOption( "Options", "Hitmarkers", "custom_hitmarkers", "#Hitmarkers", "", "", function( panel )
        panel:CheckBox( "Enable hitmarkers", "custom_hitmarkers_enabled" )
        panel:CheckBox( "Enable NPC hitmarkers", "custom_hitmarkers_npc_enabled" )
        panel:CheckBox( "Enable entity hitmarkers", "custom_hitmarkers_ent_enabled" )
        panel:CheckBox( "Enable hitmarker sounds", "custom_hitmarkers_sound_enabled" )

        panel:NumSlider( "Hit duration\n(0 to disable)", "custom_hitmarkers_hit_duration", 0, 10, 1 )
        panel:NumSlider( "Mini hit duration\n(0 to disable)", "custom_hitmarkers_mini_duration", 0, 10, 1 )

        panel:TextEntry( "Hit sound", "custom_hitmarkers_hit_sound" )
        panel:TextEntry( "Headshot sound", "custom_hitmarkers_headshot_sound" )
        panel:TextEntry( "Kill sound", "custom_hitmarkers_kill_sound" )

        panel:NumSlider( "Hit sound volume", "custom_hitmarkers_hit_sound_volume", 0, 4, 1 )
        panel:NumSlider( "Headshot sound volume", "custom_hitmarkers_headshot_sound_volume", 0, 4, 1 )
        panel:NumSlider( "Kill sound volume", "custom_hitmarkers_kill_sound_volume", 0, 4, 1 )

        hitColorPicker = vgui.Create( "DPanel", panel )
        hitColorPicker:SetSize( 200, 185 )
    
        miniHitColorPicker = vgui.Create( "DPanel", panel )
        miniHitColorPicker:SetSize( 200, 185 )
    
        createColorPicker( hitColorPicker, "hit", "Hit color" )
        createColorPicker( miniHitColorPicker, "mini_hit", "Mini hit color" )

        panel:AddItem( hitColorPicker )
        panel:AddItem( miniHitColorPicker )
    end )
end )
