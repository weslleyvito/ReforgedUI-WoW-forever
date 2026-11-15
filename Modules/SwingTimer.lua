local _, ReforgedUI = ...
local SwingModule = {}
ReforgedUI.Modules.SwingTimer = SwingModule

local RING_SIZE = 38

local function HideAllVisuals(obj)
    if not obj then return end
    if obj.GetRegions then
        for _, reg in ipairs({ obj:GetRegions() }) do
            local rType = reg:GetObjectType()
            if rType == "Texture" then
                reg:SetTexture(nil)
                reg:SetAlpha(0)
            elseif rType == "FontString" then
                reg:SetText("")
                reg:SetAlpha(0)
                reg:Hide()
            end
        end
    end
    if obj.GetChildren then
        for _, child in ipairs({ obj:GetChildren() }) do
            HideAllVisuals(child)
        end
    end
end

local function CreateCircularSwingIndicator(nativeFrame, r, g, b, xOffset)
    if not nativeFrame or nativeFrame._rfRingCreated then return end
    nativeFrame._rfRingCreated = true

    HideAllVisuals(nativeFrame)
    if nativeFrame.Background then nativeFrame.Background:SetAlpha(0); nativeFrame.Background:Hide() end
    if nativeFrame.Border then nativeFrame.Border:SetAlpha(0); nativeFrame.Border:Hide() end
    if nativeFrame.StatusBar then nativeFrame.StatusBar:SetAlpha(0) end

    local holder = CreateFrame("Frame", nil, UIParent)
    holder:SetSize(RING_SIZE, RING_SIZE)
    holder:SetPoint("BOTTOM", PlayerFrame, "TOP", xOffset, 18)
    holder:Hide()

    -- Fundo circular escuro aveludado
    local bgCircle = holder:CreateTexture(nil, "BACKGROUND")
    bgCircle:SetAllPoints(holder)
    bgCircle:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    bgCircle:SetVertexColor(0.04, 0.04, 0.05, 0.88)

    -- Anel de trilha (fundo da barra circular)
    local trackRing = holder:CreateTexture(nil, "BORDER")
    trackRing:SetAllPoints(holder)
    trackRing:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    trackRing:SetVertexColor(0.18, 0.18, 0.20, 0.55)

    -- Anel de progresso radial (CooldownFrameTemplate)
    local radial = CreateFrame("Cooldown", nil, holder, "CooldownFrameTemplate")
    radial:SetAllPoints(holder)
    radial:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    radial:SetSwipeColor(r, g, b, 0.95)
    radial:SetDrawEdge(false)
    radial:SetDrawBling(false)
    radial:SetHideCountdownNumbers(true)
    radial:SetReverse(true)

    -- Miolo recortado para formar o anel fino moderno
    local centerCutout = radial:CreateTexture(nil, "OVERLAY", nil, 2)
    centerCutout:SetSize(RING_SIZE - 9, RING_SIZE - 9)
    centerCutout:SetPoint("CENTER", holder, "CENTER", 0, 0)
    centerCutout:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
    centerCutout:SetVertexColor(0.05, 0.05, 0.06, 1.0)

    -- Borda externa sutil
    local outerStroke = radial:CreateTexture(nil, "OVERLAY", nil, 3)
    outerStroke:SetPoint("TOPLEFT", holder, "TOPLEFT", -1, 1)
    outerStroke:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 1, -1)
    outerStroke:SetTexture("Interface\\Minimap\\UI-Minimap-Border")
    outerStroke:SetTexCoord(0.24, 0.76, 0.24, 0.76)
    outerStroke:SetVertexColor(0.30, 0.30, 0.34, 0.65)

    -- Contador decimal limpo no centro
    local timeText = radial:CreateFontString(nil, "OVERLAY", nil, 4)
    timeText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    timeText:SetPoint("CENTER", holder, "CENTER", 0, 0)
    timeText:SetTextColor(0.96, 0.94, 0.88, 1.0)

    -- Monitora continuamente a StatusBar nativa (mesmo se o frame nativo não disparar OnHide)
    local lastCurVal = -1
    local watcher = CreateFrame("Frame")
    watcher:SetScript("OnUpdate", function()
        local sb = nativeFrame.StatusBar
        if not nativeFrame:IsShown() or not sb then
            if holder:IsShown() then holder:Hide() end
            lastCurVal = -1
            return
        end

        local minVal, maxVal = sb:GetMinMaxValues()
        local curVal = sb:GetValue()

        -- Se a barra não está progredindo ou já finalizou (0.0s), esconde o círculo para não ficar fantasma na tela
        if not maxVal or maxVal <= minVal or curVal <= minVal or curVal >= (maxVal - 0.02) then
            if holder:IsShown() then
                holder:Hide()
                radial:Clear()
            end
            lastCurVal = curVal
            return
        end

        local duration = maxVal - minVal
        local elapsed = curVal - minVal
        local remaining = maxVal - curVal

        if not holder:IsShown() then
            holder:Show()
        end

        -- Detecta início de um novo golpe/tiro (quando curVal cai em relação ao frame anterior) ou mudança de velocidade
        if curVal < lastCurVal or lastCurVal <= minVal then
            radial:Clear()
            radial:SetCooldown(GetTime() - elapsed, duration)
        end
        lastCurVal = curVal

        timeText:SetFormattedText("%.1f", remaining)
    end)
end

function SwingModule:Init()
    local function SetupAllSwingRings()
        CreateCircularSwingIndicator(_G["SwingTimerMainHandFrame"], 0.92, 0.76, 0.32, -24)
        CreateCircularSwingIndicator(_G["SwingTimerOffHandFrame"], 0.65, 0.82, 0.96, 24)
        CreateCircularSwingIndicator(_G["SwingTimerRangedFrame"], 0.45, 0.85, 0.55, 72)
    end

    SetupAllSwingRings()
    C_Timer.After(0.5, SetupAllSwingRings)
    C_Timer.After(1.5, SetupAllSwingRings)

    local loader = CreateFrame("Frame")
    loader:RegisterEvent("ADDON_LOADED")
    loader:RegisterEvent("PLAYER_ENTERING_WORLD")
    loader:SetScript("OnEvent", function(_, event, addonName)
        if event == "ADDON_LOADED" and addonName == "Blizzard_SwingTimer" then
            C_Timer.After(0.1, SetupAllSwingRings)
        else
            C_Timer.After(0.2, SetupAllSwingRings)
        end
    end)
end