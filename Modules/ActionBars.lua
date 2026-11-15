local _, ReforgedUI = ...
local ActionBarsModule = {}
ReforgedUI.Modules.ActionBars = ActionBarsModule

-- Base de temas (pronta para expansão futura por Raça via UnitRace("player"))
ReforgedUI.ActionBarThemes = {
    NeutralMatte = {
        border = { 0.16, 0.18, 0.21, 0.55 },
        hover  = { 0.78, 0.80, 0.84, 0.85 },
        bg     = { 0.05, 0.05, 0.06, 0.45 },
    },
}

local ACTION_BARS = {
    { bar = _G["MainActionBar"],        prefix = "ActionButton" },
    { bar = _G["MultiBarBottomLeft"],   prefix = "MultiBarBottomLeftButton" },
    { bar = _G["MultiBarBottomRight"],  prefix = "MultiBarBottomRightButton" },
    { bar = _G["MultiBarRight"],        prefix = "MultiBarRightButton" },
    { bar = _G["MultiBarLeft"],         prefix = "MultiBarLeftButton" },
    { bar = _G["MultiBar5"],            prefix = "MultiBar5Button" },
    { bar = _G["MultiBar6"],            prefix = "MultiBar6Button" },
    { bar = _G["MultiBar7"],            prefix = "MultiBar7Button" },
}

local function NukeArt(obj)
    if not obj then return end
    if obj.SetTexture then obj:SetTexture(nil) end
    obj:SetAlpha(0)
end

-- Skin Neutra em Ardósia Fosca (confortável para a vista, sem adornos pesados)
function ReforgedUI:ApplyNeutralMatteSkin(btn, isCooldownViewer)
    if not btn or btn._rfMatteSkinned then return end
    btn._rfMatteSkinned = true

    local theme = ReforgedUI.ActionBarThemes.NeutralMatte
    local name = btn:GetName()

    if name then
        NukeArt(_G[name .. "Border"])
        NukeArt(_G[name .. "FloatingBG"])
        NukeArt(_G[name .. "NormalTexture"])
        NukeArt(_G[name .. "NormalTexture2"])

        local macroName = _G[name .. "Name"]
        if macroName then
            macroName:SetAlpha(0)
            macroName:Hide()
        end

        local hotkey = _G[name .. "HotKey"]
        if hotkey then
            hotkey:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            hotkey:SetTextColor(0.75, 0.78, 0.82, 0.65)
            hotkey:ClearAllPoints()
            hotkey:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -2, -2)
        end

        local count = _G[name .. "Count"]
        if count then
            count:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            count:SetTextColor(0.95, 0.96, 0.98, 1.0)
            count:ClearAllPoints()
            count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
        end
    end

    if btn.NormalTexture then NukeArt(btn.NormalTexture) end
    if btn.SlotArt then NukeArt(btn.SlotArt) end
    if btn.SlotBackground then NukeArt(btn.SlotBackground) end
    if btn.RightDivider then NukeArt(btn.RightDivider) end
    if btn.NewActionTexture then NukeArt(btn.NewActionTexture) end

    local icon = btn.icon or btn.Icon or (name and _G[name .. "Icon"])
    if icon and icon.SetTexCoord then
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
        icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    end

    local frame = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    frame:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    frame:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    frame:SetFrameLevel(math.max(1, btn:GetFrameLevel() + 1))

    if not frame.SetBackdrop and BackdropTemplateMixin then
        Mixin(frame, BackdropTemplateMixin)
    end
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = ReforgedUI.FlatTexture,
            edgeFile = ReforgedUI.FlatTexture,
            tile = false,
            edgeSize = 1,
        })
        frame:SetBackdropColor(0, 0, 0, 0)
        local c = theme.border
        frame:SetBackdropBorderColor(c[1], c[2], c[3], c[4])
    end

    if not isCooldownViewer then
        btn:HookScript("OnEnter", function()
            if frame.SetBackdropBorderColor then
                local h = theme.hover
                frame:SetBackdropBorderColor(h[1], h[2], h[3], h[4])
            end
        end)
        btn:HookScript("OnLeave", function()
            if frame.SetBackdropBorderColor then
                local c = theme.border
                frame:SetBackdropBorderColor(c[1], c[2], c[3], c[4])
            end
        end)
    end

    btn._rfIcon = icon
    btn._rfBorderFrame = frame
end

-- Divide o Gerenciador de Recargas em 2 asas simétricas nas laterais do PlayerFrame
function ActionBarsModule:SplitCooldownViewersAroundPlayer()
    local mainViewer = _G["EssentialCooldownViewer"]
    if mainViewer and PlayerFrame then
        local activeIcons = {}
        for _, child in ipairs({ mainViewer:GetChildren() }) do
            if child:IsShown() and (child.icon or child.Icon) then
                ReforgedUI:ApplyNeutralMatteSkin(child, true)
                table.insert(activeIcons, child)
            end
        end

        local total = #activeIcons
        if total > 0 then
            local half = math.ceil(total / 2)
            local iconSize = 26
            local gap = 4

            -- Asa Esquerda (à esquerda do losango do PlayerFrame)
            for i = half, 1, -1 do
                local btn = activeIcons[i]
                btn:SetSize(iconSize, iconSize)
                btn:ClearAllPoints()
                if i == half then
                    btn:SetPoint("RIGHT", PlayerFrame, "LEFT", -14, -2)
                else
                    btn:SetPoint("RIGHT", activeIcons[i + 1], "LEFT", -gap, 0)
                end
            end

            -- Asa Direita (à direita da barra de vida do PlayerFrame)
            for i = half + 1, total do
                local btn = activeIcons[i]
                btn:SetSize(iconSize, iconSize)
                btn:ClearAllPoints()
                if i == half + 1 then
                    btn:SetPoint("LEFT", PlayerFrame, "RIGHT", 6, -2)
                else
                    btn:SetPoint("LEFT", activeIcons[i - 1], "RIGHT", gap, 0)
                end
            end
        end
    end

    -- Demais viewers secundários apenas recebem a skin limpa
    for _, vName in ipairs({ "UtilityCooldownViewer", "BuffIconCooldownViewer", "BuffBarCooldownViewer" }) do
        local v = _G[vName]
        if v then
            for _, child in ipairs({ v:GetChildren() }) do
                if child.icon or child.Icon then
                    ReforgedUI:ApplyNeutralMatteSkin(child, true)
                end
            end
        end
    end
end

function ActionBarsModule:UpdateCooldownDesaturation()
    for _, entry in ipairs(ACTION_BARS) do
        local prefix = entry.prefix
        for i = 1, 12 do
            local btn = _G[prefix .. i]
            if btn and btn._rfIcon and btn.action then
                local start, duration = GetActionCooldown(btn.action)
                local onCooldown = start and duration and duration > 1.5
                btn._rfIcon:SetDesaturated(onCooldown and true or false)
                btn._rfIcon:SetAlpha(onCooldown and 0.45 or 0.92)
            end
        end
    end
end

-- Opacidade suave fora de combate (0.25) para descanso visual, e 0.95 em combate ou hover
function ActionBarsModule:UpdateContextualFade()
    local inCombat = UnitAffectingCombat("player")
    local hasTarget = UnitExists("target")
    local hoveringAny = false

    for _, entry in ipairs(ACTION_BARS) do
        local bar = entry.bar
        if bar and bar:IsShown() and bar:IsMouseOver() then
            hoveringAny = true
            break
        end
    end

    local targetAlpha = (inCombat or hasTarget or hoveringAny) and 0.95 or 0.25

    for _, entry in ipairs(ACTION_BARS) do
        local bar = entry.bar
        if bar and bar:IsShown() then
            bar:SetAlpha(targetAlpha)
        end
    end
end

function ActionBarsModule:RefreshBars()
    NukeArt(MainMenuBarArtFrameBackground)
    NukeArt(MainMenuBarLeftEndCap)
    NukeArt(MainMenuBarRightEndCap)
    NukeArt(MainMenuBarPageNumber)
    NukeArt(ActionBarUpButton)
    NukeArt(ActionBarDownButton)
    if MainMenuBarArtFrame then
        NukeArt(MainMenuBarArtFrame.LeftEndCap)
        NukeArt(MainMenuBarArtFrame.RightEndCap)
        NukeArt(MainMenuBarArtFrame.PageNumber)
    end
    if MainActionBar and MainActionBar.ActionBarPageNumber then
        NukeArt(MainActionBar.ActionBarPageNumber)
    end

    for _, entry in ipairs(ACTION_BARS) do
        local bar = entry.bar
        local prefix = entry.prefix
        local numVisible = (bar and bar.numButtonsShowable) or 12

        if bar and bar._rfLotrBackdrop then bar._rfLotrBackdrop:Hide() end
        if bar and bar._sfBaseAnchor then bar._sfBaseAnchor:Hide() end

        for i = 1, 12 do
            local btn = _G[prefix .. i]
            if btn then
                if i <= numVisible then
                    ReforgedUI:ApplyNeutralMatteSkin(btn, false)
                else
                    btn:Hide()
                end
            end
        end

        if bar and not bar._rfMatteHoverHooked then
            bar._rfMatteHoverHooked = true
            bar:HookScript("OnEnter", function() self:UpdateContextualFade() end)
            bar:HookScript("OnLeave", function()
                C_Timer.After(0.08, function() self:UpdateContextualFade() end)
            end)
        end
    end

    self:SplitCooldownViewersAroundPlayer()
    self:UpdateCooldownDesaturation()
    self:UpdateContextualFade()
end

function ActionBarsModule:Init()
    if _G["ReforgedUIActionBarBackdrop"] then
        _G["ReforgedUIActionBarBackdrop"]:Hide()
    end

    self:RefreshBars()

    if EditModeManagerFrame then
        EditModeManagerFrame:HookScript("OnHide", function()
            C_Timer.After(0.1, function() self:RefreshBars() end)
        end)
    end

    for _, entry in ipairs(ACTION_BARS) do
        if entry.bar and entry.bar.UpdateShownButtons then
            hooksecurefunc(entry.bar, "UpdateShownButtons", function()
                self:RefreshBars()
            end)
        end
    end

    C_Timer.After(0.35, function()
        self:RefreshBars()
    end)

    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    watcher:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:RegisterEvent("PLAYER_TARGET_CHANGED")
    watcher:SetScript("OnEvent", function(_, ev)
        if ev == "PLAYER_ENTERING_WORLD" then
            self:RefreshBars()
        elseif ev == "SPELL_UPDATE_COOLDOWN" or ev == "ACTIONBAR_SLOT_CHANGED" then
            self:SplitCooldownViewersAroundPlayer()
            self:UpdateCooldownDesaturation()
        else
            self:UpdateContextualFade()
        end
    end)
end