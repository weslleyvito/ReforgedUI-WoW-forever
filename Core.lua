local addonName, ReforgedUI = ...
_G.ReforgedUI = ReforgedUI
ReforgedUI.Modules = {}

ReforgedUI.Colors = {
    Background = { 0.04, 0.04, 0.05, 0.55 },
    Border     = { 0.85, 0.82, 0.75, 0.35 },
    Gold       = { 0.83, 0.69, 0.22, 0.90 },
    Mana       = { 0.22, 0.48, 0.88, 0.90 },
    Energy     = { 0.90, 0.76, 0.22, 0.90 },
    Rage       = { 0.85, 0.20, 0.20, 0.90 },
    Ghost      = { 0.95, 0.90, 0.75, 0.65 },
}

ReforgedUI.BarTexture = "Interface\\Buttons\\WHITE8X8"
ReforgedUI.FlatTexture = "Interface\\Buttons\\WHITE8X8"

function ReforgedUI:ApplyMinimalBackdrop(frame, bgAlpha)
    if not frame then return end
    if not frame.SetBackdrop and BackdropTemplateMixin then
        Mixin(frame, BackdropTemplateMixin)
    end
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = ReforgedUI.FlatTexture,
            edgeFile = ReforgedUI.FlatTexture,
            tile = false,
            tileSize = 0,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        local bg = ReforgedUI.Colors.Background
        local bd = ReforgedUI.Colors.Border
        frame:SetBackdropColor(bg[1], bg[2], bg[3], bgAlpha or bg[4])
        frame:SetBackdropBorderColor(bd[1], bd[2], bd[3], bd[4])
    end
end

function ReforgedUI:GetClassColor(unit)
    local _, classFile = UnitClass(unit)
    if classFile == "SHAMAN" then
        return 0.00, 0.44, 0.87 -- Azul Xamã
    end
    if classFile and RAID_CLASS_COLORS[classFile] then
        local c = RAID_CLASS_COLORS[classFile]
        return c.r, c.g, c.b
    end
    return 0.85, 0.82, 0.75
end

-- Brasão de Facção espelhado ("LEFT" = TOPLEFT no Player | "RIGHT" = TOPRIGHT no Target)
function ReforgedUI:CreateFactionCrest(diamondHolder, side)
    local crest = diamondHolder:CreateTexture(nil, "OVERLAY", nil, 7)
    crest:SetSize(20, 20)
    if side == "RIGHT" then
        crest:SetPoint("TOPRIGHT", diamondHolder, "TOPRIGHT", 3, 3)
    else
        crest:SetPoint("TOPLEFT", diamondHolder, "TOPLEFT", -3, 3)
    end
    crest:Hide()

    local function UpdateCrest(unit)
        if not UnitExists(unit) then
            crest:Hide()
            return
        end
        local faction = UnitFactionGroup(unit)
        if faction == "Alliance" then
            crest:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
            crest:SetTexCoord(0.06, 0.58, 0.04, 0.58)
            crest:Show()
        elseif faction == "Horde" then
            crest:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
            crest:SetTexCoord(0.08, 0.58, 0.06, 0.58)
            crest:Show()
        else
            crest:Hide()
        end
    end

    return crest, UpdateCrest
end

-- Lê o nome completo com sobrenome do jogador (compatível com sobrenomes customizados)
local nameScanner = CreateFrame("GameTooltip", "ReforgedUINameScanner", nil, "GameTooltipTemplate")
nameScanner:SetOwner(WorldFrame, "ANCHOR_NONE")

function ReforgedUI:GetFullUnitName(unit)
    if not UnitExists(unit) then return "" end
    local baseName = UnitName(unit) or ""

    if UnitIsPlayer(unit) then
        nameScanner:ClearLines()
        nameScanner:SetUnit(unit)
        local line1 = _G["ReforgedUINameScannerTextLeft1"]
        local tipText = line1 and line1:GetText()
        if tipText and tipText ~= "" then
            -- Remove títulos comuns se vierem antes/depois, mantendo Nome + Sobrenome
            local clean = tipText:gsub("^%s+", ""):gsub("%s+$", "")
            if #clean >= #baseName then
                return clean
            end
        end
    end

    return (GetUnitName and GetUnitName(unit, false)) or baseName
end

function ReforgedUI:ApplyUntarnishedTexture(statusBar, r, g, b)
    if not statusBar then return end
    statusBar:SetStatusBarTexture(ReforgedUI.BarTexture)
    local tex = statusBar:GetStatusBarTexture()
    if tex then
        tex:SetTexture(ReforgedUI.BarTexture)
        tex:SetHorizTile(false)
        tex:SetVertTile(false)
        if tex.SetGradient and CreateColor then
            local minColor = CreateColor(r * 0.62, g * 0.62, b * 0.62, 1)
            local maxColor = CreateColor(math.min(1, r * 1.05), math.min(1, g * 1.05), math.min(1, b * 1.05), 1)
            tex:SetGradient("VERTICAL", minColor, maxColor)
        else
            statusBar:SetStatusBarColor(r, g, b)
        end
    end
end

function ReforgedUI:CreateCleanText(parent, size, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size or 11, "OUTLINE")
    fs:SetShadowOffset(1, -1)
    fs:SetShadowColor(0, 0, 0, 0.85)
    fs:SetJustifyH(justify or "CENTER")
    return fs
end

-- Integra o frame ao Modo de Edição nativo (16001) e salva a posição escolhida
function ReforgedUI:RegisterMovableFrame(frame, key, defaultPoint)
    if not frame then return end
    ReforgedUIDB = ReforgedUIDB or {}
    ReforgedUIDB.positions = ReforgedUIDB.positions or {}

    local function ApplySavedOrDefault()
        if InCombatLockdown and InCombatLockdown() then return end
        if EditModeManagerFrame and EditModeManagerFrame:IsShown() then return end

        frame._rfMoving = true
        frame:ClearAllPoints()
        local saved = ReforgedUIDB.positions[key]
        if saved then
            frame:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
        else
            frame:SetPoint(defaultPoint[1], UIParent, defaultPoint[2], defaultPoint[3], defaultPoint[4])
        end
        frame._rfMoving = false
    end

    hooksecurefunc(frame, "StopMovingOrSizing", function(self)
        local point, _, relPoint, x, y = self:GetPoint()
        if point and relPoint then
            ReforgedUIDB.positions[key] = { point, relPoint, math.floor(x + 0.5), math.floor(y + 0.5) }
        end
    end)

    hooksecurefunc(frame, "SetPoint", function(self)
        if self._rfMoving then return end
        if EditModeManagerFrame and EditModeManagerFrame:IsShown() then
            local point, _, relPoint, x, y = self:GetPoint()
            if point and relPoint then
                ReforgedUIDB.positions[key] = { point, relPoint, math.floor(x + 0.5), math.floor(y + 0.5) }
            end
            return
        end
        ApplySavedOrDefault()
    end)

    if EditModeManagerFrame and not EditModeManagerFrame._rfHooked then
        EditModeManagerFrame._rfHooked = true
        EditModeManagerFrame:HookScript("OnHide", function()
            for k, f in pairs(ReforgedUI.MovableFrames or {}) do
                local point, _, relPoint, x, y = f:GetPoint()
                if point and relPoint then
                    ReforgedUIDB.positions[k] = { point, relPoint, math.floor(x + 0.5), math.floor(y + 0.5) }
                end
            end
        end)
    end

    ReforgedUI.MovableFrames = ReforgedUI.MovableFrames or {}
    ReforgedUI.MovableFrames[key] = frame
    ApplySavedOrDefault()
end

local CoreFrame = CreateFrame("Frame", "ReforgedUICoreFrame", UIParent)
CoreFrame:RegisterEvent("ADDON_LOADED")
CoreFrame:RegisterEvent("PLAYER_LOGIN")

CoreFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        ReforgedUIDB = ReforgedUIDB or {}
        ReforgedUIDB.scale = ReforgedUIDB.scale or 1.0
        ReforgedUIDB.outOfCombatAlpha = ReforgedUIDB.outOfCombatAlpha or 0.75
        ReforgedUIDB.actionBarMode = ReforgedUIDB.actionBarMode or "reforged"
        ReforgedUIDB.positions = ReforgedUIDB.positions or {}
    elseif event == "PLAYER_LOGIN" then
        for name, module in pairs(ReforgedUI.Modules) do
            if module.Init then
                local ok, err = pcall(module.Init, module)
                if not ok then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[ReforgedUI Erro em " .. name .. "]:|r " .. tostring(err))
                end
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffd4af37Reforged|rUI carregado com sucesso.")
    end
end)