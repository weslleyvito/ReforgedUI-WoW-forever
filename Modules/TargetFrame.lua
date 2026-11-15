local _, ReforgedUI = ...
local TargetModule = {}
ReforgedUI.Modules.TargetFrame = TargetModule

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
        if obj.SetAlpha then
            hooksecurefunc(obj, "SetAlpha", function(self, a)
                if a > 0 then self:SetAlpha(0) end
            end)
        end
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

local function GetTargetHealthColor(unit)
    if not UnitExists(unit) then return 0.85, 0.82, 0.75 end
    if UnitIsPlayer(unit) then
        return ReforgedUI:GetClassColor(unit)
    end
    if UnitIsTapDenied and UnitIsTapDenied(unit) then
        return 0.50, 0.50, 0.50
    end
    local reaction = UnitReaction(unit, "player")
    if reaction then
        if reaction <= 2 then
            return 0.85, 0.22, 0.22
        elseif reaction == 3 or reaction == 4 then
            return 0.90, 0.72, 0.20
        else
            return 0.25, 0.78, 0.35
        end
    end
    return 0.85, 0.22, 0.22
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

local function CreateTargetPortraitDiamond(parent, hpBar, size)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(size, size)
    holder:SetPoint("RIGHT", hpBar, "TOPRIGHT", math.floor(size * 0.42), -math.floor(size * 0.5))
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

function TargetModule:ApplyLayout()
    local hp = TargetFrame.healthbar
    local mana = TargetFrame.manabar
    if not hp or not mana then return end

    local tot = TargetFrame.totFrame

    if hp.SetReverseFill then hp:SetReverseFill(true) end
    if mana.SetReverseFill then mana:SetReverseFill(true) end

    local keep = {
        [hp] = true,
        [mana] = true,
    }
    if tot then keep[tot] = true end

    -- Limpa todas as artes do TargetFrameContainer (Portrait, FrameTexture, BossPortraitFrameTexture, Flash)
    local tfc = TargetFrame.TargetFrameContainer
    if tfc then
        NukeObject(tfc.Portrait)
        NukeObject(tfc.PortraitMask)
        NukeObject(tfc.BossPortraitFrameTexture)
        NukeObject(tfc.FrameTexture)
        NukeObject(tfc.Flash)
        NukeAllChildrenAndRegions(tfc)
    end

    -- Limpa TargetFrameContent preservando as barras e o totFrame
    local content = TargetFrame.TargetFrameContent
    if content then
        if content.TargetFrameContentContextual then
            NukeAllChildrenAndRegions(content.TargetFrameContentContextual, keep)
        end
        if content.TargetFrameContentMain then
            local main = content.TargetFrameContentMain
            keep[main] = true
            if main.HealthBarsContainer then
                keep[main.HealthBarsContainer] = true
                NukeAllChildrenAndRegions(main.HealthBarsContainer, keep)
            end
            if main.ManaBarArea then
                keep[main.ManaBarArea] = true
                NukeAllChildrenAndRegions(main.ManaBarArea, keep)
            end
            NukeAllChildrenAndRegions(main, keep)
        end
    end

    NukeObject(TargetFrame.portrait)
    NukeObject(TargetFrame.name)
    NukeObject(TargetFrame.threatIndicator)
    NukeObject(TargetFrame.threatNumericIndicator)

    local width = 280
    local hpHeight = 22
    local manaHeight = 13

    TargetFrame:SetSize(width + 36, hpHeight + manaHeight + 28)

    hp:ClearAllPoints()
    hp:SetPoint("TOP", TargetFrame, "TOP", 0, -16)
    hp:SetSize(width, hpHeight)
    if not hp._rfWidthLocked then
        hp._rfWidthLocked = true
        hooksecurefunc(hp, "SetWidth", function(self, w)
            if math.abs(w - 280) > 1 then self:SetWidth(280) end
        end)
       hooksecurefunc(hp, "SetSize", function(self, w, h)
    if self._rfSizing then return end

    if math.abs(w - 280) > 1 or math.abs(h - 22) > 1 then
        self._rfSizing = true
        self:SetSize(280, 22)
        self._rfSizing = nil
    end
end)
    end

   
    StripStatusBarMasks(hp)

    mana:ClearAllPoints()
    mana:SetPoint("TOPRIGHT", hp, "BOTTOMRIGHT", 0, -3)
    mana:SetSize(width - 12, manaHeight)
    if not mana._rfWidthLocked then
       mana._rfWidthLocked = true
       hooksecurefunc(mana, "SetWidth", function(self, w)
           if math.abs(w - 268) > 1 then self:SetWidth(268) end
       end)
       hooksecurefunc(mana, "SetSize", function(self, w, h)
           if self._rfSizing then return end

           if math.abs(w - 268) > 1 or math.abs(h - 13) > 1 then
               self._rfSizing = true
               self:SetSize(268, 13)
               self._rfSizing = nil
           end
       end)
   end
    StripStatusBarMasks(mana)


    return hp, mana
end

function TargetModule:Init()
    local hp, mana = self:ApplyLayout()
    if not hp or not mana then return end

    -- Cria o losango APENAS UMA VEZ e anexa o brasão de facção no topo
    local diamondHolder, portraitTex, portraitBorder = CreateTargetPortraitDiamond(TargetFrame, hp, 38)
    local _, UpdateTargetCrest = ReforgedUI:CreateFactionCrest(diamondHolder, "RIGHT")

    ReforgedUI:RegisterMovableFrame(TargetFrame, "TargetFrame", { "CENTER", "CENTER", 310, -140 })

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

    local textOverlay = CreateFrame("Frame", nil, TargetFrame)
    textOverlay:SetAllPoints(hp)
    textOverlay:SetFrameStrata("HIGH")
    textOverlay:SetFrameLevel(20)

    local nameText = ReforgedUI:CreateCleanText(textOverlay, 11, "RIGHT")
    nameText:SetPoint("BOTTOMRIGHT", hp, "TOPRIGHT", -18, 4)
    nameText:SetTextColor(0.95, 0.92, 0.85, 1.0)

    local hpText = ReforgedUI:CreateCleanText(textOverlay, 11, "CENTER")
    hpText:SetPoint("CENTER", hp, "CENTER", 0, 0)
    hpText:SetTextColor(1.0, 1.0, 1.0, 1.0)

    local manaText = ReforgedUI:CreateCleanText(textOverlay, 9, "CENTER")
    manaText:SetPoint("CENTER", mana, "CENTER", 0, 0)
    manaText:SetTextColor(0.96, 0.98, 1.0, 1.0)

    local function UpdateTargetVisuals()
        if not UnitExists("target") then return end

        local r, g, b = GetTargetHealthColor("target")
        ReforgedUI:ApplyUntarnishedTexture(hp, r, g, b)
        portraitBorder:SetVertexColor(r, g, b, 0.95)

        SetPortraitTexture(portraitTex, "target")
        UpdateTargetCrest("target")

        local pType = UnitPowerType("target")
        local pr, pg, pb = GetPowerBarColor("target")
        ReforgedUI:ApplyUntarnishedTexture(mana, pr, pg, pb)

        local classif = UnitClassification("target")
        local tag = ""
        if classif == "worldboss" then
            tag = "|cffff4444[CHEFE]|r "
        elseif classif == "rareelite" then
            tag = "|cffffd700[RARO+]|r "
        elseif classif == "elite" then
            tag = "|cffffd700[ELITE]|r "
        elseif classif == "rare" then
            tag = "|cffcccccc[RARO]|r "
        end

        local level = UnitLevel("target")
        local pLevel = UnitLevel("player") or 1
        local lvlStr = (level and level > 0) and tostring(level) or "??"
        local hexColor

        if not level or level <= 0 then
            hexColor = "|cffff1a1a" -- Caveira / Chefe (Vermelho)
        else
            local diff = level - pLevel
            -- Limite de nível cinza no Vanilla/Classic
            local grayDiff = (pLevel <= 5 and 5)
                or (pLevel <= 39 and (math.floor(pLevel / 10) + 5))
                or (pLevel <= 59 and (math.floor(pLevel / 5) + 1))
                or 9

            if diff >= 5 then
                hexColor = "|cffff2020" -- Vermelho
            elseif diff >= 3 then
                hexColor = "|cffff8040" -- Laranja
            elseif diff >= -2 then
                hexColor = "|cffffff00" -- Amarelo (-2 a +2)
            elseif -diff < grayDiff then
                hexColor = "|cff40c040" -- Verde (-3 até antes de ficar cinza)
            else
                hexColor = "|cff808080" -- Cinza
            end
        end
        
        local tname = string.upper(ReforgedUI:GetFullUnitName("target") or "")
        nameText:SetText(tag .. tname .. "  " .. hexColor .. lvlStr .. "|r")

        local curHP = UnitHealth("target")
        if curHP then
            hpText:SetFormattedText("%d", curHP)
        end

        local curMP = UnitPower("target", pType)
        local maxMP = UnitPowerMax("target", pType)
        if curMP and maxMP and maxMP > 0 then
            manaText:SetFormattedText("%d", curMP)
        else
            manaText:SetText("")
        end
    end

    hooksecurefunc(hp, "SetStatusBarColor", function()
        if UnitExists("target") then
            local r, g, b = GetTargetHealthColor("target")
            ReforgedUI:ApplyUntarnishedTexture(hp, r, g, b)
        end
    end)

    hooksecurefunc(mana, "SetStatusBarColor", function()
        if UnitExists("target") then
            local pr, pg, pb = GetPowerBarColor("target")
            ReforgedUI:ApplyUntarnishedTexture(mana, pr, pg, pb)
        end
    end)

    if TargetFrame.Update then
        hooksecurefunc(TargetFrame, "Update", function()
            self:ApplyLayout()
            UpdateTargetVisuals()
        end)
    end

    -- Alvo do Alvo (TargetFrame.totFrame)
    local tot = TargetFrame.totFrame
    if tot then
        local totHp = tot.healthbar or TargetFrameToTHealthBar
        if totHp then
            NukeAllChildrenAndRegions(tot, { [totHp] = true })
            if tot.portrait then NukeObject(tot.portrait) end
            if tot.name then NukeObject(tot.name) end

            local totWidth = 115
            local function PositionToT()
                if tot._rfMoving then return end
                tot._rfMoving = true
                tot:ClearAllPoints()
                tot:SetPoint("TOPRIGHT", mana, "BOTTOMRIGHT", 0, -14)
                tot:SetSize(totWidth, 16)
                tot._rfMoving = false
            end

            PositionToT()
            hooksecurefunc(tot, "SetPoint", PositionToT)

            totHp:ClearAllPoints()
            totHp:SetPoint("TOPLEFT", tot, "TOPLEFT", 0, -2)
            totHp:SetSize(totWidth, 7)
            StripStatusBarMasks(totHp)

            local totBg = CreateFrame("Frame", nil, totHp, "BackdropTemplate")
            totBg:SetPoint("TOPLEFT", totHp, "TOPLEFT", -1, 1)
            totBg:SetPoint("BOTTOMRIGHT", totHp, "BOTTOMRIGHT", 1, -1)
            totBg:SetFrameLevel(totHp:GetFrameLevel() - 1)
            ReforgedUI:ApplyMinimalBackdrop(totBg, 0.65)

            local totOverlay = CreateFrame("Frame", nil, tot)
            totOverlay:SetAllPoints(totHp)
            totOverlay:SetFrameStrata("HIGH")
            totOverlay:SetFrameLevel(20)

            local totName = ReforgedUI:CreateCleanText(totOverlay, 9, "RIGHT")
            totName:SetPoint("BOTTOMRIGHT", totHp, "TOPRIGHT", 0, 2)

            local function UpdateToT()
                if UnitExists("targettarget") then
                    local tr, tg, tb = GetTargetHealthColor("targettarget")
                    ReforgedUI:ApplyUntarnishedTexture(totHp, tr, tg, tb)
                    totName:SetTextColor(tr, tg, tb, 1.0)
                    totName:SetText(string.upper(UnitName("targettarget") or ""))
                end
            end

            tot:HookScript("OnUpdate", UpdateToT)
        end
    end

    C_Timer.After(0.15, function()
        self:ApplyLayout()
        UpdateTargetVisuals()
    end)

    local updater = CreateFrame("Frame")
    updater:RegisterEvent("PLAYER_ENTERING_WORLD")
    updater:RegisterEvent("PLAYER_TARGET_CHANGED")
    updater:RegisterEvent("UNIT_HEALTH")
    updater:RegisterEvent("UNIT_MAXHEALTH")
    updater:RegisterEvent("UNIT_POWER_UPDATE")
    updater:RegisterEvent("UNIT_MAXPOWER")
    updater:RegisterEvent("UNIT_DISPLAYPOWER")
    updater:RegisterEvent("UNIT_PORTRAIT_UPDATE")
    updater:RegisterEvent("UNIT_FACTION")
    updater:SetScript("OnEvent", function(_, ev, unit)
        if ev == "PLAYER_ENTERING_WORLD" or ev == "PLAYER_TARGET_CHANGED" then
            self:ApplyLayout()
        end
        if not unit or unit == "target" then
            UpdateTargetVisuals()
        end
    end)
end