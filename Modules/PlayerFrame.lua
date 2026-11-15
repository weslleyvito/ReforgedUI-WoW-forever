local _, ReforgedUI = ...
local PlayerModule = {}
ReforgedUI.Modules.PlayerFrame = PlayerModule

local function NukeObject(obj)
    if not obj then return end
    if obj.SetTexture then obj:SetTexture(nil) end
    if obj.SetText then obj:SetText("") end
    obj:SetAlpha(0)
    obj:Hide()
    if not obj._rfHooked then
        obj._rfHooked = true
        hooksecurefunc(obj, "Show", function(self)
            self:SetAlpha(0)
            self:Hide()
        end)
    end
end

local function NukeAllChildrenAndRegions(frame, keepSet)
    if not frame then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        if not (keepSet and keepSet[region]) then
            NukeObject(region)
        end
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        if not (keepSet and keepSet[child]) then
            NukeAllChildrenAndRegions(child, keepSet)
            NukeObject(child)
        end
    end
end

local function StripStatusBarMasks(statusBar)
    if not statusBar then return end
    local tex = statusBar:GetStatusBarTexture()
    if tex and tex.GetNumMaskTextures and tex.GetMaskTexture and tex.RemoveMaskTexture then
        for i = tex:GetNumMaskTextures(), 1, -1 do
            local mask = tex:GetMaskTexture(i)
            if mask then
                tex:RemoveMaskTexture(mask)
            end
        end
    end
    for _, region in ipairs({ statusBar:GetRegions() }) do
        if region:GetObjectType() == "FontString" and not region._rfCustom then
            NukeObject(region)
        end
    end
end

local function GetPowerBarColor(unit)
    local powerType, powerToken = UnitPowerType(unit)
    if powerToken == "MANA" or powerType == 0 then
        return 0.18, 0.52, 0.94
    elseif powerToken == "RAGE" or powerType == 1 then
        return 0.88, 0.20, 0.20
    elseif powerToken == "FOCUS" or powerType == 2 then
        return 0.95, 0.55, 0.18
    elseif powerToken == "ENERGY" or powerType == 3 then
        return 0.94, 0.80, 0.18
    end
    return 0.22, 0.52, 0.92
end

local function CreatePortraitDiamond(parent, hpBar, size)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(size, size)
    holder:SetPoint("LEFT", hpBar, "TOPLEFT", -math.floor(size * 0.42), -math.floor(size * 0.5))
    holder:SetFrameLevel(parent:GetFrameLevel() + 12)

    local outer = holder:CreateTexture(nil, "BORDER")
    outer:SetSize(size, size)
    outer:SetPoint("CENTER")
    outer:SetTexture(ReforgedUI.FlatTexture)
    outer:SetRotation(math.rad(45))
    outer:SetVertexColor(0.85, 0.82, 0.75, 0.95)

    local inner = holder:CreateTexture(nil, "ARTWORK", nil, 0)
    inner:SetSize(size - 3, size - 3)
    inner:SetPoint("CENTER")
    inner:SetTexture(ReforgedUI.FlatTexture)
    inner:SetRotation(math.rad(45))
    inner:SetVertexColor(0.06, 0.06, 0.08, 0.98)

    local mask = holder:CreateMaskTexture()
    mask:SetSize(size - 4, size - 4)
    mask:SetPoint("CENTER")
    mask:SetTexture(ReforgedUI.FlatTexture, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetRotation(math.rad(45))

    local portrait = holder:CreateTexture(nil, "ARTWORK", nil, 1)
    portrait:SetSize(size * 0.90, size * 0.90)
    portrait:SetPoint("CENTER")
    portrait:AddMaskTexture(mask)

    return holder, portrait, outer
end

function PlayerModule:ApplyLayout()
    local content = PlayerFrame.PlayerFrameContent
    local main = content and content.PlayerFrameContentMain

    local hp = (main and main.HealthBarsContainer and main.HealthBarsContainer.HealthBar) or PlayerFrameHealthBar
    local mana = (main and main.ManaBarArea and main.ManaBarArea.ManaBar) or PlayerFrameManaBar

    local keep = {
        [hp] = true,
        [mana] = true,
    }
    if main then
        keep[main] = true
        if main.HealthBarsContainer then keep[main.HealthBarsContainer] = true end
        if main.ManaBarArea then keep[main.ManaBarArea] = true end
    end

    if PlayerFrame.PlayerFrameContainer then
        NukeAllChildrenAndRegions(PlayerFrame.PlayerFrameContainer)
    end
    if content and content.PlayerFrameContentContextual then
        NukeAllChildrenAndRegions(content.PlayerFrameContentContextual)
    end
    if main then
        NukeAllChildrenAndRegions(main, keep)
        if main.HealthBarsContainer then
            NukeAllChildrenAndRegions(main.HealthBarsContainer, keep)
        end
        if main.ManaBarArea then
            NukeAllChildrenAndRegions(main.ManaBarArea, keep)
        end
    end

    local width = 280
    local hpHeight = 22
    local manaHeight = 13

    PlayerFrame:SetSize(width + 36, hpHeight + manaHeight + 28)

    hp:ClearAllPoints()
    hp:SetPoint("TOP", PlayerFrame, "TOP", 0, -16)
    hp:SetSize(width, hpHeight)
    if not hp._rfWidthLocked then
        hp._rfWidthLocked = true
        hooksecurefunc(hp, "SetWidth", function(self, w)
            if math.abs(w - 280) > 1 then self:SetWidth(280) end
        end)
        hooksecurefunc(hp, "SetSize", function(self, w, h)
            if math.abs(w - 280) > 1 or math.abs(h - 22) > 1 then self:SetSize(280, 22) end
        end)
    end

    if not mana._rfWidthLocked then
        mana._rfWidthLocked = true
        hooksecurefunc(mana, "SetWidth", function(self, w)
            if math.abs(w - 268) > 1 then self:SetWidth(268) end
        end)
        hooksecurefunc(mana, "SetSize", function(self, w, h)
            if math.abs(w - 268) > 1 or math.abs(h - 13) > 1 then self:SetSize(268, 13) end
        end)
    end
    StripStatusBarMasks(hp)

    local r, g, b = ReforgedUI:GetClassColor("player")
    ReforgedUI:ApplyUntarnishedTexture(hp, r, g, b)

    mana:ClearAllPoints()
    mana:SetPoint("TOPLEFT", hp, "BOTTOMLEFT", 0, -3)
    mana:SetSize(width - 12, manaHeight)
    StripStatusBarMasks(mana)

    local pr, pg, pb = GetPowerBarColor("player")
    ReforgedUI:ApplyUntarnishedTexture(mana, pr, pg, pb)

    return hp, mana
end

function PlayerModule:Init()
    local hp, mana = self:ApplyLayout()
    local r, g, b = ReforgedUI:GetClassColor("player")

    local diamondHolder, portraitTex, portraitBorder = CreatePortraitDiamond(PlayerFrame, hp, 38)
    portraitBorder:SetVertexColor(r, g, b, 0.95)
    local _, UpdatePlayerCrest = ReforgedUI:CreateFactionCrest(diamondHolder, "LEFT")

    ReforgedUI:RegisterMovableFrame(PlayerFrame, "PlayerFrame", { "CENTER", "CENTER", -310, -140 })

    hooksecurefunc(hp, "SetStatusBarColor", function(self)
        local tr, tg, tb = ReforgedUI:GetClassColor("player")
        ReforgedUI:ApplyUntarnishedTexture(self, tr, tg, tb)
    end)

    hooksecurefunc(mana, "SetStatusBarColor", function(self)
        local tr, tg, tb = GetPowerBarColor("player")
        ReforgedUI:ApplyUntarnishedTexture(self, tr, tg, tb)
    end)

    local hpBg = CreateFrame("Frame", nil, hp, "BackdropTemplate")
    hpBg:SetPoint("TOPLEFT", hp, "TOPLEFT", -1, 1)
    hpBg:SetPoint("BOTTOMRIGHT", hp, "BOTTOMRIGHT", 1, -1)
    hpBg:SetFrameLevel(hp:GetFrameLevel() - 1)
    ReforgedUI:ApplyMinimalBackdrop(hpBg, 0.72)

    local manaBg = CreateFrame("Frame", nil, mana, "BackdropTemplate")
    manaBg:SetPoint("TOPLEFT", mana, "TOPLEFT", -1, 1)
    manaBg:SetPoint("BOTTOMRIGHT", mana, "BOTTOMRIGHT", 1, -1)
    manaBg:SetFrameLevel(mana:GetFrameLevel() - 1)
    ReforgedUI:ApplyMinimalBackdrop(manaBg, 0.68)

    local _, portraitTex, portraitBorder = CreatePortraitDiamond(PlayerFrame, hp, 38)
    portraitBorder:SetVertexColor(r, g, b, 0.95)

    local function UpdatePortrait()
        SetPortraitTexture(portraitTex, "player")
        UpdatePlayerCrest("player")
    end

    local textOverlay = CreateFrame("Frame", nil, UIParent)
    textOverlay:SetAllPoints(hp)
    textOverlay:SetFrameStrata("HIGH")
    textOverlay:SetFrameLevel(20)

    local nameText = ReforgedUI:CreateCleanText(textOverlay, 11, "LEFT")
    nameText:SetPoint("BOTTOMLEFT", hp, "TOPLEFT", 18, 4)
    nameText:SetTextColor(0.95, 0.92, 0.85, 1.0)

    local hpText = ReforgedUI:CreateCleanText(textOverlay, 11, "CENTER")
    hpText:SetWidth(240)
    hpText:SetPoint("CENTER", hp, "CENTER", 0, 0)
    hpText:SetTextColor(1.0, 1.0, 1.0, 1.0)

    local manaText = ReforgedUI:CreateCleanText(textOverlay, 9, "CENTER")
    manaText:SetWidth(228)
    manaText:SetPoint("CENTER", mana, "CENTER", 0, 0)
    manaText:SetTextColor(0.96, 0.98, 1.0, 1.0)

local function UpdateTexts()
        local level = UnitLevel("player") or ""
        local pname = string.upper(ReforgedUI:GetFullUnitName("player") or "JOGADOR")
        nameText:SetText("|cffd4af37" .. level .. "|r  " .. pname)

        local curHP = UnitHealth("player")
        if curHP then
            hpText:SetFormattedText("%d", curHP)
        end

        local pType = UnitPowerType("player")
        local curMP = UnitPower("player", pType)
        if curMP then
            manaText:SetFormattedText("%d", curMP)
        end
    end

    local function UpdateAlpha()
        local inCombat = UnitAffectingCombat("player")
        local hasTarget = UnitExists("target")
        local a = (inCombat or hasTarget) and 1.0 or 0.75
        PlayerFrame:SetAlpha(a)
        textOverlay:SetAlpha(a)

        -- Borda do losango vermelha em combate, cor da classe fora de combate
        if inCombat then
            portraitBorder:SetVertexColor(0.95, 0.14, 0.14, 1.0)
        else
            local cr, cg, cb = ReforgedUI:GetClassColor("player")
            portraitBorder:SetVertexColor(cr, cg, cb, 0.95)
        end
    end

    if PetFrame then
        NukeObject(PetFrameTexture)
        NukeObject(PetPortrait)
        NukeObject(PetName)
        NukeObject(PetFrameHealthBarText)
        NukeObject(PetFrameHealthBarTextLeft)
        NukeObject(PetFrameHealthBarTextRight)
        NukeObject(PetFrameManaBarText)
        NukeObject(PetFrameManaBarTextLeft)
        NukeObject(PetFrameManaBarTextRight)
        NukeObject(PetAttackModeTexture)
        if PetFrameHappiness then NukeObject(PetFrameHappiness) end

        local petWidth = 115
        local function PositionPet()
            if PetFrame._rfMoving then return end
            PetFrame._rfMoving = true
            PetFrame:ClearAllPoints()
            PetFrame:SetPoint("TOPLEFT", mana, "BOTTOMLEFT", 0, -16)
            PetFrame:SetSize(petWidth, 18)
            PetFrame._rfMoving = false
        end

        PositionPet()
        hooksecurefunc(PetFrame, "SetPoint", PositionPet)

        PetFrameHealthBar:ClearAllPoints()
        PetFrameHealthBar:SetPoint("TOPLEFT", PetFrame, "TOPLEFT", 0, -2)
        PetFrameHealthBar:SetSize(petWidth, 7)
        StripStatusBarMasks(PetFrameHealthBar)
        ReforgedUI:ApplyUntarnishedTexture(PetFrameHealthBar, 0.55, 0.82, 0.45)

        local phpBg = CreateFrame("Frame", nil, PetFrameHealthBar, "BackdropTemplate")
        phpBg:SetPoint("TOPLEFT", PetFrameHealthBar, "TOPLEFT", -1, 1)
        phpBg:SetPoint("BOTTOMRIGHT", PetFrameHealthBar, "BOTTOMRIGHT", 1, -1)
        phpBg:SetFrameLevel(PetFrameHealthBar:GetFrameLevel() - 1)
        ReforgedUI:ApplyMinimalBackdrop(phpBg, 0.65)

        PetFrameManaBar:ClearAllPoints()
        PetFrameManaBar:SetPoint("TOP", PetFrameHealthBar, "BOTTOM", 0, -2)
        PetFrameManaBar:SetSize(petWidth, 3)
        StripStatusBarMasks(PetFrameManaBar)
        ReforgedUI:ApplyUntarnishedTexture(PetFrameManaBar, 0.95, 0.70, 0.25)

        local petLabel = ReforgedUI:CreateCleanText(PetFrameHealthBar, 9, "LEFT")
        petLabel._rfCustom = true
        petLabel:SetPoint("BOTTOMLEFT", PetFrameHealthBar, "TOPLEFT", 0, 2)
        petLabel:SetTextColor(0.85, 0.85, 0.80, 0.90)

        local function UpdatePetText()
            local petName = UnitName("pet")
            petLabel:SetText(petName and string.upper(petName) or "PET")
        end
        UpdatePetText()
        PetFrame:HookScript("OnEvent", UpdatePetText)
    end

    C_Timer.After(0.15, function()
        self:ApplyLayout()
        UpdatePortrait()
        UpdateTexts()
        UpdateAlpha()
    end)

    local updater = CreateFrame("Frame")
    updater:RegisterEvent("PLAYER_ENTERING_WORLD")
    updater:RegisterEvent("UNIT_HEALTH")
    updater:RegisterEvent("UNIT_MAXHEALTH")
    updater:RegisterEvent("UNIT_POWER_UPDATE")
    updater:RegisterEvent("UNIT_MAXPOWER")
    updater:RegisterEvent("UNIT_DISPLAYPOWER")
    updater:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    updater:RegisterEvent("PLAYER_REGEN_DISABLED")
    updater:RegisterEvent("PLAYER_REGEN_ENABLED")
    updater:RegisterEvent("PLAYER_TARGET_CHANGED")
    updater:SetScript("OnEvent", function(_, ev)
        if ev == "PLAYER_ENTERING_WORLD" then
            self:ApplyLayout()
            StripStatusBarMasks(PetFrameHealthBar)
            StripStatusBarMasks(PetFrameManaBar)
        end
        local pr, pg, pb = GetPowerBarColor("player")
        ReforgedUI:ApplyUntarnishedTexture(mana, pr, pg, pb)
        UpdatePortrait()
        UpdateTexts()
        UpdateAlpha()
    end)
end