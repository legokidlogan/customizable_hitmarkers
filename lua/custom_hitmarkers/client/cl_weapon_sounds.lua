CustomHitmarkers = CustomHitmarkers or {}
CustomHitmarkers.Colors = CustomHitmarkers.Colors or {}
CustomHitmarkers.WeaponSounds = CustomHitmarkers.WeaponSounds or {}
CustomHitmarkers.ClientConVars = CustomHitmarkers.ClientConVars or {}
CustomHitmarkers.ClientConVarOverrides = CustomHitmarkers.ClientConVarOverrides or {}

local weaponSounds = CustomHitmarkers.WeaponSounds
local weaponOrder = {}
local settingsListPanel = nil

local saveSettings
local loadSettings
local rebuildListPanels
local makeWeaponPanel
local resetTextColor

local SETTINGS_FILE_PATH = "weapon_sounds.txt"
local TEXT_COLOR = Color( 0, 0, 0, 255 )
local TEXT_COLOR_BAD_INPUT = Color( 200, 0, 0, 255 )
local TEXT_COLOR_UNUSABLE = Color( 128, 128, 128, 255 )
local DIVIDER_COLOR = Color( 128, 128, 128, 255 )


function CustomHitmarkers.CreateWeaponSoundPanel( basePanel )
    local collapse = vgui.Create( "DForm", basePanel )
    collapse:SetLabel( "Per-Weapon Sounds" )
    collapse:SetSpacing( 5 )
    collapse:SetHeight( 500 )
    collapse:SetExpanded( false )

    local infoLabel = vgui.Create( "DLabel", collapse )
    resetTextColor( infoLabel ) -- DLabels show up with pale grey text initially, hard to see
    infoLabel:SetWrap( true )
    infoLabel:SetAutoStretchVertical( true )
    infoLabel:SetText(
        "Add sound overrides per each weapon." .. "\n" ..
        "'default' to use your global settings." .. "\n" ..
        "Leave a sound blank to play nothing." .. "\n\n" ..

        "These are NOT saved into presets (bar at the very top)." .. "\n" ..
        "They are saved to a file under data/" .. CustomHitmarkers.SETTINGS_PATH .. "."
    )
    collapse:AddItem( infoLabel )

    settingsListPanel = vgui.Create( "DScrollPanel", collapse )
    collapse:AddItem( settingsListPanel )
    settingsListPanel:SetHeight( 300 )

    local postListPaddingPanel = vgui.Create( "Panel", collapse )
    postListPaddingPanel:SetSize( 0, 10 )
    collapse:AddItem( postListPaddingPanel )

    local addTextEntry = vgui.Create( "DTextEntry", collapse )
    addTextEntry:SetPlaceholderText( "Weapon Class (e.g. weapon_357)" )
    addTextEntry:SetUpdateOnType( true )

    local addButton = vgui.Create( "DButton", collapse )
    addButton:SetText( "Add" )

    local function validateWeaponToAdd( class )
        class = class or addTextEntry:GetValue()
        if class == "" then return end
        if weaponSounds[class] then return end

        return class
    end

    function addTextEntry:OnValueChange( class )
        if validateWeaponToAdd( class ) then
            self:SetTextColor()
            addButton:SetTextColor()
        else
            self:SetTextColor( TEXT_COLOR_BAD_INPUT )

            local btnSkin = addButton:GetSkin() or SKIN or {}
            addButton:SetTextColor( btnSkin.colTextEntryTextPlaceholder or TEXT_COLOR_UNUSABLE )
        end
    end

    function addButton:DoClick()
        local class = validateWeaponToAdd()
        if not class then return end

        table.insert( weaponOrder, class )
        weaponSounds[class] = {
            Hit = {
                Path = "default",
                Volume = 1,
                Pitch = 100,
            },
            Headshot = {
                Path = "default",
                Volume = 1,
                Pitch = 100,
            },
            Kill = {
                Path = "default",
                Volume = 1,
                Pitch = 100,
            },
        }

        local weaponPanel = makeWeaponPanel( class )
        weaponPanel:SetExpanded( true )

        addTextEntry:SetValue( "" )

        settingsListPanel:AddItem( weaponPanel )
        weaponPanel:Dock( TOP )
        settingsListPanel:ScrollToChild( weaponPanel )

        saveSettings()
    end

    collapse:AddItem( addTextEntry, addButton )
    addTextEntry:GetParent():DockPadding( 10, 0, 10, 0 )
    addTextEntry:SetSize( 200, 35 )
    addButton:Dock( RIGHT )

    local reloadButton = vgui.Create( "DButton", collapse )
    reloadButton:SetText( "Reload Settings From File" )
    collapse:AddItem( reloadButton )

    function reloadButton:DoClick()
        loadSettings()
    end

    local bottomLine = vgui.Create( "DFrame", collapse )
    local collapseSkin = collapse:GetSkin() or SKIN or {}
    local lineColor = collapseSkin.bg_color_bright or DIVIDER_COLOR
    local lineHeight = 1
    local lineMargin = 8

    bottomLine:SetSize( collapse:GetWide(), lineHeight )
    collapse:AddItem( bottomLine )
    bottomLine.Paint = function( _, w, h )
        draw.RoundedBox( 1, lineMargin / 2, 0, w - lineMargin, h, lineColor )
    end

    loadSettings()

    return collapse
end


saveSettings = function( delay )
    local function func()
        if not file.Exists( CustomHitmarkers.SETTINGS_PATH, "DATA" ) then
            file.CreateDir( CustomHitmarkers.SETTINGS_PATH )
        end

        local data = {}

        for i, class in ipairs( weaponOrder ) do
            local weaponSettings = weaponSounds[class]
            data[i] = {
                class = class,
                Hit = weaponSettings.Hit,
                Headshot = weaponSettings.Headshot,
                Kill = weaponSettings.Kill,
            }
        end

        local dataStr = util.TableToJSON( data )
        file.Write( CustomHitmarkers.SETTINGS_PATH .. "/" .. SETTINGS_FILE_PATH, dataStr )
    end

    -- Put delays on things like sliders to avoid file I/O spam
    if delay and delay > 0 then
        timer.Create( "CustomHitmarkers_SaveSettings", delay, 1, func )
    else
        func()
    end
end

loadSettings = function()
    local dataStr = file.Read( CustomHitmarkers.SETTINGS_PATH .. "/" .. SETTINGS_FILE_PATH, "DATA" )
    if not dataStr then return end

    local data = util.JSONToTable( dataStr )
    if not data then return end

    table.Empty( weaponSounds )
    table.Empty( weaponOrder )

    for _, entry in ipairs( data ) do
        local class = entry.class

        if class and class ~= "" and not weaponSounds[class] then
            table.insert( weaponOrder, class )
            weaponSounds[class] = {
                Hit = entry.Hit,
                Headshot = entry.Headshot,
                Kill = entry.Kill,
            }
        end
    end

    rebuildListPanels()
end

rebuildListPanels = function()
    if not settingsListPanel then return end

    settingsListPanel:Clear()

    for _, class in ipairs( weaponOrder ) do
        local weaponPanel = makeWeaponPanel( class )
        settingsListPanel:AddItem( weaponPanel )
        weaponPanel:Dock( TOP )
    end
end

makeWeaponPanel = function( class )
    local weaponPanel = vgui.Create( "DForm", settingsListPanel )
    weaponPanel:SetLabel( class )
    weaponPanel:SetSpacing( 1 )
    weaponPanel:SetExpanded( false )

    local function addSoundType( soundType )
        local curSettings = weaponSounds[class][soundType]
        local wasDefaulted = curSettings.Path == "default"

        local pathLabel = vgui.Create( "DLabel", weaponPanel )
        resetTextColor( pathLabel )
        pathLabel:SetText( soundType )

        local pathEntry = vgui.Create( "DTextEntry", weaponPanel )
        pathEntry:SetPlaceholderText( "(no sound)" )
        pathEntry:SetValue( curSettings.Path )

        weaponPanel:AddItem( pathLabel, pathEntry )
        pathLabel:SetWidth( 60 )
        pathEntry:Dock( FILL )

        local volumeLabel = vgui.Create( "DLabel", weaponPanel )
        resetTextColor( volumeLabel )
        volumeLabel:SetText( "    volume" )

        local volumeSlider = vgui.Create( "DNumSlider", weaponPanel )
        volumeSlider:SetMin( 0 )
        volumeSlider:SetMax( 4 )
        volumeSlider:SetDecimals( 1 )
        volumeSlider:SetValue( curSettings.Volume )
        volumeSlider:SetEnabled( not wasDefaulted )
        resetTextColor( volumeSlider:GetChildren()[3] )

        weaponPanel:AddItem( volumeLabel, volumeSlider )
        volumeLabel:SetSize( 100, 30 )
        volumeSlider:GetParent():DockPadding( 10, 0, 10, 0 )
        volumeSlider:SetWidth( 300 )
        volumeSlider:Dock( RIGHT )

        function volumeSlider:OnValueChanged( val )
            weaponSounds[class][soundType].Volume = val
            saveSettings( 2 )
        end

        local pitchLabel = vgui.Create( "DLabel", weaponPanel )
        resetTextColor( pitchLabel )
        pitchLabel:SetText( "    pitch" )

        local pitchSlider = vgui.Create( "DNumSlider", weaponPanel )
        pitchSlider:SetMin( 0 )
        pitchSlider:SetMax( 255 )
        pitchSlider:SetDecimals( 0 )
        pitchSlider:SetValue( curSettings.Pitch )
        pitchSlider:SetEnabled( not wasDefaulted )
        resetTextColor( pitchSlider:GetChildren()[3] )

        weaponPanel:AddItem( pitchLabel, pitchSlider )
        pitchLabel:SetSize( 100, 30 )
        pitchSlider:GetParent():DockPadding( 10, 0, 10, 0 )
        pitchSlider:SetWidth( 300 )
        pitchSlider:Dock( RIGHT )

        function pitchSlider:OnValueChanged( val )
            weaponSounds[class][soundType].Pitch = val
            saveSettings( 2 )
        end

        function pathEntry:OnLoseFocus()
            local path = self:GetText()
            local isDefaulted = path == "default"

            weaponSounds[class][soundType].Path = path
            saveSettings( 0.5 )

            if wasDefaulted ~= isDefaulted then
                wasDefaulted = isDefaulted
                volumeSlider:SetEnabled( not isDefaulted )
                pitchSlider:SetEnabled( not isDefaulted )
            end
        end
    end

    addSoundType( "Hit" )
    addSoundType( "Headshot" )
    addSoundType( "Kill" )

    local removeButton = vgui.Create( "DButton", weaponPanel )
    removeButton:SetText( "Remove " .. class )
    weaponPanel:AddItem( removeButton )

    function removeButton:DoClick()
        table.RemoveByValue( weaponOrder, class )

        weaponSounds[class] = nil
        weaponPanel:Remove()

        saveSettings()
    end

    return weaponPanel
end

resetTextColor = function( panel )
    local skin = panel:GetSkin() or SKIN or {}
    panel:SetTextColor( skin.colTextEntryText or TEXT_COLOR )
end


hook.Add( "InitPostEntity", "CustomHitmarkers_LoadWeaponSounds", function()
    loadSettings()
end )
