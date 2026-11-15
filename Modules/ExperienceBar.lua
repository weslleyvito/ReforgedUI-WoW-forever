local _, ReforgedUI = ...
local ExpModule = {}
ReforgedUI.Modules.ExperienceBar = ExpModule

local BAR_WIDTH = 460
local BAR_HEIGHT = 12

local function PermanentlyBanishFrame(frame)
    if not frame or (frame.IsForbidden and frame:IsForbidden()) then return end
    frame:SetAlpha(0)
    frame:SetScale(0.0001)
    frame:Hide()

    if not frame._rfBanished then
        frame._rfBanished = true
        hooksecurefunc(frame, "Show", function(self)
            self:SetAlpha(0)
            self:SetScale(0.0001)
            self:Hide()
        end)
        if frame.SetShown then
            hooksecurefunc(frame, "SetShown", function(self, shown)
                if shown then
                    self:SetAlpha(0)
                    self:SetScale(0.0001)
                    self:Hide()
                end
            end)
        end
        hooksecurefunc(frame, "SetAlpha", function(self, a)
            if a > 0 then
                self:SetAlpha(0)
            end
        end)
    end
end

local function BanishAllNativeExpBars()
    local targets = {
        _G["MainStatusTrackingBarContainer"],
        _G["SecondaryStatusTrackingBarContainer"],
        _G["StatusTrackingBarManager"],
        _G["MainMenuExpBar"],
        _G["ReputationWatchBar"]
    }
    for _, frame in ipairs(targets) do
        PermanentlyBanishFrame(frame)
    end
end

function ExpModule:Init()
    BanishAllNativeExpBars()

    ReforgedUIDB = ReforgedUIDB or {}

    -- 1. Container principal da barra no padrão visual Soulframe / ReforgedUI
    local expFrame = CreateFrame("Frame", "ReforgedUI_CustomExpBar", UIParent, "BackdropTemplate")
    expFrame:SetSize(BAR_WIDTH, BAR_HEIGHT)
    expFrame:SetFrameStrata("MEDIUM")
    expFrame:SetFrameLevel(15)
    ReforgedUI:ApplyMinimalBackdrop(expFrame, 0.90)

    -- Restaura a posição salva ou coloca na base inferior por padrão
    local function RestoreSavedPosition()
        expFrame:ClearAllPoints()
        local pos = ReforgedUIDB.ExpBarPos
        if pos and pos.point and pos.relativePoint and pos.x and pos.y then
            expFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
        else
            expFrame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 4)
        end
    end
    RestoreSavedPosition()

    -- Torna a barra movível com Shift + Arrastar (ou arraste livre enquanto o Modo de Edição estiver aberto)
    expFrame:SetMovable(true)
    expFrame:SetClampedToScreen(true)
    expFrame:EnableMouse(true)
    expFrame:RegisterForDrag("LeftButton")

    expFrame:SetScript("OnDragStart", function(self)
        local inEditMode = EditModeManagerFrame and EditModeManagerFrame:IsShown()
        if IsShiftKeyDown() or inEditMode then
            self:StartMoving()
        end
    end)

    expFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        ReforgedUIDB.ExpBarPos = {
            point = point,
            relativePoint = relativePoint,
            x = math.floor(x + 0.5),
            y = math.floor(y + 0.5)
        }
    end)

    -- Destaca a borda em dourado quando você abrir o Modo de Edição da Blizzard para indicar que pode arrastar
    if EditModeManagerFrame then
        EditModeManagerFrame:HookScript("OnShow", function()
            expFrame:SetBackdropBorderColor(0.83, 0.69, 0.22, 1.0)
        end)
        EditModeManagerFrame:HookScript("OnHide", function()
            ReforgedUI:ApplyMinimalBackdrop(expFrame, 0.90)
        end)
    end

    -- 2. Barra de XP Descansado (Rested) ao fundo em dourado translúcido
    local restedBar = CreateFrame("StatusBar", nil, expFrame)
    restedBar:SetPoint("TOPLEFT", expFrame, "TOPLEFT", 1, -1)
    restedBar:SetPoint("BOTTOMRIGHT", expFrame, "BOTTOMRIGHT", -1, 1)
    restedBar:SetStatusBarTexture(ReforgedUI.FlatTexture)
    restedBar:SetStatusBarColor(0.83, 0.69, 0.22, 0.22)
    restedBar:SetFrameLevel(expFrame:GetFrameLevel() + 1)

    -- 3. Barra principal de progresso (FlatTexture fosca)
    local fillBar = CreateFrame("StatusBar", nil, expFrame)
    fillBar:SetPoint("TOPLEFT", expFrame, "TOPLEFT", 1, -1)
    fillBar:SetPoint("BOTTOMRIGHT", expFrame, "BOTTOMRIGHT", -1, 1)
    fillBar:SetStatusBarTexture(ReforgedUI.FlatTexture)
    fillBar:SetFrameLevel(expFrame:GetFrameLevel() + 2)

    local topHighlight = fillBar:CreateTexture(nil, "OVERLAY")
    topHighlight:SetHeight(1)
    topHighlight:SetPoint("TOPLEFT", fillBar, "TOPLEFT", 0, 0)
    topHighlight:SetPoint("TOPRIGHT", fillBar, "TOPRIGHT", 0, 0)
    topHighlight:SetTexture(ReforgedUI.FlatTexture)
    topHighlight:SetVertexColor(1.0, 0.96, 0.85, 0.14)

    -- 4. Camada de texto nítido centralizado
    local textLayer = CreateFrame("Frame", nil, expFrame)
    textLayer:SetAllPoints(expFrame)
    textLayer:SetFrameLevel(expFrame:GetFrameLevel() + 5)

    local xpText = textLayer:CreateFontString(nil, "OVERLAY")
    xpText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    xpText:SetPoint("CENTER", expFrame, "CENTER", 0, 0)
    xpText:SetTextColor(0.96, 0.94, 0.88, 1.0)

    -- 5. Tooltip informativo ao passar o cursor
    expFrame:SetScript("OnEnter", function(self)
        local cur = UnitXP("player") or 0
        local max = UnitXPMax("player") or 1
        local rest = GetXPExhaustion() or 0
        local pct = (max > 0) and ((cur / max) * 100) or 0

        GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 6)
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Progresso de Nível", 0.83, 0.69, 0.22)
        GameTooltip:AddDoubleLine("Experiência:", string.format("%d / %d (%.1f%%)", cur, max, pct), 0.96, 0.94, 0.88, 1, 1, 1)
        GameTooltip:AddDoubleLine("Restante:", string.format("%d XP", math.max(0, max - cur)), 0.70, 0.70, 0.72, 0.9, 0.9, 0.9)
        if rest > 0 then
            GameTooltip:AddDoubleLine("Bônus Descansado:", string.format("+%d XP (%.0f%%)", rest, (rest / max) * 100), 0.83, 0.69, 0.22, 0.83, 0.69, 0.22)
        end
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("Shift + Arrastar para mover", 0.65, 0.65, 0.68)
        GameTooltip:Show()
    end)
    expFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- 6. Atualização em tempo real dos valores
    local function UpdateExperienceBar()
        BanishAllNativeExpBars()

        local maxLevel = (GetMaxPlayerLevel and GetMaxPlayerLevel()) or 60
        if UnitLevel("player") >= maxLevel then
            expFrame:Hide()
            return
        end

        expFrame:Show()
        local cur = UnitXP("player") or 0
        local max = UnitXPMax("player") or 1
        if max <= 0 then max = 1 end

        local rest = GetXPExhaustion() or 0
        local pct = (cur / max) * 100

        fillBar:SetMinMaxValues(0, max)
        fillBar:SetValue(cur)

        if rest > 0 then
            fillBar:SetStatusBarColor(0.83, 0.69, 0.22, 0.92)
            restedBar:SetMinMaxValues(0, max)
            restedBar:SetValue(math.min(max, cur + rest))
            restedBar:Show()
        else
            fillBar:SetStatusBarColor(0.56, 0.36, 0.84, 0.92)
            restedBar:Hide()
        end

        xpText:SetFormattedText("%d / %d  (%.0f%%)", cur, max, pct)
    end

    UpdateExperienceBar()
    C_Timer.After(0.3, UpdateExperienceBar)
    C_Timer.After(1.2, UpdateExperienceBar)

    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("ADDON_LOADED")
    watcher:RegisterEvent("PLAYER_XP_UPDATE")
    watcher:RegisterEvent("PLAYER_LEVEL_UP")
    watcher:RegisterEvent("UPDATE_EXHAUSTION")
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function()
        UpdateExperienceBar()
    end)
end