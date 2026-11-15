local _, ReforgedUI = ...
local ExpModule = {}
ReforgedUI.Modules.ExperienceBar = ExpModule

local BAR_WIDTH = 440
local BAR_HEIGHT = 10

local function HideNativeVisuals(frame)
    if not frame then return end
    if frame.GetRegions then
        for _, reg in ipairs({ frame:GetRegions() }) do
            local rType = reg:GetObjectType()
            if rType == "Texture" then
                reg:SetTexture(nil)
                reg:SetAlpha(0)
            elseif rType == "FontString" then
                reg:SetAlpha(0)
                reg:Hide()
            end
        end
    end
    if frame.GetChildren then
        for _, child in ipairs({ frame:GetChildren() }) do
            -- Não mexe na nossa barra customizada
            if not child._rfCustomExp then
                if child.SetStatusBarTexture then
                    child:SetStatusBarTexture(nil)
                    child:SetAlpha(0)
                end
                HideNativeVisuals(child)
            end
        end
    end
end

function ExpModule:Init()
    -- 1. Cria a nossa própria barra de XP minimalista (100% controlada pelo ReforgedUI)
    local customFrame = CreateFrame("Frame", "ReforgedUI_ExpBar", UIParent, "BackdropTemplate")
    customFrame._rfCustomExp = true
    customFrame:SetSize(BAR_WIDTH, BAR_HEIGHT)
    customFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 4)
    customFrame:SetFrameStrata("LOW")
    customFrame:SetFrameLevel(10)
    ReforgedUI:ApplyMinimalBackdrop(customFrame, 0.88)

    local fill = CreateFrame("StatusBar", nil, customFrame)
    fill:SetPoint("TOPLEFT", customFrame, "TOPLEFT", 1, -1)
    fill:SetPoint("BOTTOMRIGHT", customFrame, "BOTTOMRIGHT", -1, 1)
    fill:SetStatusBarTexture(ReforgedUI.FlatTexture)
    fill:SetMinMaxValues(0, 1)
    fill:SetValue(0)

    -- Barra secundária sutil para mostrar o limite do bônus de descanso (Rested XP)
    local restedFill = CreateFrame("StatusBar", nil, customFrame)
    restedFill:SetAllPoints(fill)
    restedFill:SetFrameLevel(fill:GetFrameLevel() - 1)
    restedFill:SetStatusBarTexture(ReforgedUI.FlatTexture)
    restedFill:SetStatusBarColor(0.83, 0.69, 0.22, 0.22)
    restedFill:SetMinMaxValues(0, 1)
    restedFill:SetValue(0)

    local textOverlay = CreateFrame("Frame", nil, customFrame)
    textOverlay:SetAllPoints(customFrame)
    textOverlay:SetFrameLevel(fill:GetFrameLevel() + 5)

    local xpText = textOverlay:CreateFontString(nil, "OVERLAY")
    xpText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    xpText:SetPoint("CENTER", customFrame, "CENTER", 0, 0)
    xpText:SetTextColor(0.96, 0.94, 0.88, 1.0)

    -- Tooltip nativo ao passar o mouse
    customFrame:EnableMouse(true)
    customFrame:SetScript("OnEnter", function(self)
        local cur = UnitXP("player") or 0
        local max = UnitXPMax("player") or 1
        local rest = GetXPExhaustion() or 0
        local pct = (max > 0) and (cur / max * 100) or 0

        GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 4)
        GameTooltip:ClearLines()
        GameTooltip:AddLine(string.format("Experiência: %d / %d (%.1f%%)", cur, max, pct), 0.96, 0.94, 0.88)
        if rest > 0 then
            GameTooltip:AddLine(string.format("Descansado: +%d XP (%.0f%%)", rest, (rest / max) * 100), 0.83, 0.69, 0.22)
        end
        GameTooltip:Show()
    end)
    customFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- 2. Atualiza os valores reais de XP do jogador
    local function UpdateCustomXP()
        local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel() or 60
        if UnitLevel("player") >= maxLevel then
            customFrame:Hide()
            return
        end

        customFrame:Show()
        local cur = UnitXP("player") or 0
        local max = UnitXPMax("player") or 1
        if max <= 0 then max = 1 end

        local rest = GetXPExhaustion() or 0
        local pct = (cur / max) * 100

        fill:SetMinMaxValues(0, max)
        fill:SetValue(cur)

        if rest > 0 then
            fill:SetStatusBarColor(0.83, 0.69, 0.22, 0.92) -- Dourado Soulframe quando descansado
            restedFill:SetMinMaxValues(0, max)
            restedFill:SetValue(math.min(max, cur + rest))
            restedFill:Show()
        else
            fill:SetStatusBarColor(0.56, 0.36, 0.84, 0.92) -- Roxo imperial fosco
            restedFill:Hide()
        end

        xpText:SetFormattedText("%d / %d (%.0f%%)", cur, max, pct)
    end

    -- 3. Silencia completamente a barra nativa da Blizzard para não duplicar nem vazar bordas
    local function SuppressNativeBars()
        local nativeContainers = {
            _G["MainStatusTrackingBarContainer"],
            _G["SecondaryStatusTrackingBarContainer"],
            StatusTrackingBarManager,
            MainMenuExpBar
        }
        for _, bar in ipairs(nativeContainers) do
            if bar then
                HideNativeVisuals(bar)
                bar:SetAlpha(0)
                bar:Hide()
            end
        end
    end

    UpdateCustomXP()
    SuppressNativeBars()

    C_Timer.After(0.3, function()
        UpdateCustomXP()
        SuppressNativeBars()
    end)

    if StatusTrackingBarManager and StatusTrackingBarManager.UpdateBarsShown then
        hooksecurefunc(StatusTrackingBarManager, "UpdateBarsShown", SuppressNativeBars)
    end

    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("PLAYER_XP_UPDATE")
    watcher:RegisterEvent("PLAYER_LEVEL_UP")
    watcher:RegisterEvent("UPDATE_EXHAUSTION")
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function()
        UpdateCustomXP()
        SuppressNativeBars()
    end)
end