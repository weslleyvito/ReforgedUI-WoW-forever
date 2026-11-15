-- local _, ReforgedUI = ...
-- local CastBarModule = {}
-- ReforgedUI.Modules.CastBar = CastBarModule

-- local NON_MAGIC_KEYWORDS = {
--     "fundir", "smelt", "forjar", "forge", "criar", "create", "encantar", "enchant",
--     "tiro", "shot", "disparo", "arremesso", "throw", "investida", "charge",
--     "bandagem", "bandage", "mineração", "mining", "herborismo", "herbalism",
--     "esfolamento", "skinning", "abrir", "open", "pesca", "fishing", "montaria", "mount",
--     "coletar", "gather", "desencantar", "disenchant", "golpe heróico", "heroic strike",
--     "golpe sinistro", "sinister strike", "golpe mortal", "mortal strike"
-- }

-- local SCHOOL_COLORS = {
--     ARCANE = { 0.78, 0.42, 0.98 },
--     FROST  = { 0.30, 0.78, 1.00 },
--     FIRE   = { 1.00, 0.42, 0.16 },
--     NATURE = { 0.32, 0.88, 0.44 },
--     SHADOW = { 0.58, 0.32, 0.88 },
--     HOLY   = { 1.00, 0.84, 0.32 },
-- }

-- local function GetMagicSchoolColor(spellName)
--     local lower = string.lower(tostring(spellName or ""))
--     if string.find(lower, "gelo", 1, true) or string.find(lower, "frost", 1, true) then return SCHOOL_COLORS.FROST end
--     if string.find(lower, "fogo", 1, true) or string.find(lower, "fire", 1, true) then return SCHOOL_COLORS.FIRE end
--     if string.find(lower, "arcano", 1, true) or string.find(lower, "arcane", 1, true) or string.find(lower, "mísseis", 1, true) or string.find(lower, "missile", 1, true) then return SCHOOL_COLORS.ARCANE end
--     if string.find(lower, "sombra", 1, true) or string.find(lower, "shadow", 1, true) then return SCHOOL_COLORS.SHADOW end
--     if string.find(lower, "cura", 1, true) or string.find(lower, "heal", 1, true) or string.find(lower, "sagrado", 1, true) then return SCHOOL_COLORS.HOLY end
--     return SCHOOL_COLORS.NATURE
-- end

-- local function IsMagicCast(spellName)
--     if not spellName then return true end
--     local lower = string.lower(tostring(spellName))
--     for _, word in ipairs(NON_MAGIC_KEYWORDS) do
--         if string.find(lower, word, 1, true) then return false end
--     end
--     return true
-- end

-- local function NukeRegion(obj)
--     if not obj then return end
--     if obj.SetTexture then obj:SetTexture(nil) end
--     if obj.SetText then obj:SetText("") end
--     obj:SetAlpha(0)
--     obj:Hide()
-- end

-- -- ============================================================================
-- -- 1. CÍRCULO DO JOGADOR (LEVE E OTIMIZADO - SEM LAG)
-- -- ============================================================================
-- local function SetupPlayerArcaneCircle(castBar)
--     if not castBar or castBar._rfCircleSetup then return end
--     castBar._rfCircleSetup = true

--     castBar:SetAlpha(0)
--     if castBar.SetScale then castBar:SetScale(0.001) end

--     local magicSize = 66
--     local simpleSize = 42

--     local seal = CreateFrame("Frame", "ReforgedUIArcaneCastCircle", UIParent)
--     seal:SetSize(magicSize, magicSize)
--     seal:SetFrameStrata("HIGH")
--     seal:SetFrameLevel(30)
--     seal:Hide()

--     seal:SetPoint("BOTTOM", PlayerFrame or UIParent, "TOP", 0, 68)

--     local bgMask = seal:CreateMaskTexture()
--     bgMask:SetAllPoints(seal)
--     bgMask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")

--     local bgTex = seal:CreateTexture(nil, "BACKGROUND")
--     bgTex:SetAllPoints(seal)
--     bgTex:SetTexture(ReforgedUI.FlatTexture)
--     bgTex:SetVertexColor(0.03, 0.03, 0.04, 0.75)
--     bgTex:AddMaskTexture(bgMask)

--     local radial = CreateFrame("Cooldown", nil, seal, "CooldownFrameTemplate")
--     radial:SetAllPoints(seal)
--     radial:SetDrawEdge(true)
--     radial:SetDrawBling(false)
--     radial:SetHideCountdownNumbers(true)
--     radial:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask")
--     radial:SetSwipeColor(0.85, 0.82, 0.75, 0.55)

--     local iconMask = seal:CreateMaskTexture()
--     iconMask:SetSize(26, 26)
--     iconMask:SetPoint("CENTER")
--     iconMask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")

--     local spellIcon = seal:CreateTexture(nil, "ARTWORK")
--     spellIcon:SetSize(26, 26)
--     spellIcon:SetPoint("CENTER")
--     spellIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
--     spellIcon:AddMaskTexture(iconMask)

--     local centerRing = seal:CreateTexture(nil, "OVERLAY", nil, 1)
--     centerRing:SetSize(32, 32)
--     centerRing:SetPoint("CENTER")
--     centerRing:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
--     centerRing:SetTexCoord(0.0, 0.6, 0.0, 0.6)
--     centerRing:SetVertexColor(0.83, 0.69, 0.22, 0.65)

--     local arcSegments = {}
--     for i = 1, 24 do
--         local deg = 90 - ((i - 1) * 15)
--         local angle = math.rad(deg)
--         local seg = seal:CreateTexture(nil, "OVERLAY", nil, 3)
--         seg:SetSize(6, 2)
--         seg:SetPoint("CENTER", seal, "CENTER", math.cos(angle) * 23, math.sin(angle) * 23)
--         seg:SetTexture(ReforgedUI.FlatTexture)
--         seg:SetRotation(math.rad(deg - 90))
--         seg:SetVertexColor(0.85, 0.72, 0.30, 0.0)
--         arcSegments[i] = seg
--     end

--     local nameText = ReforgedUI:CreateCleanText(seal, 9, "CENTER")
--     nameText:SetPoint("BOTTOM", seal, "TOP", 0, 3)
--     nameText:SetTextColor(0.88, 0.84, 0.74, 0.90)

--     local timerText = ReforgedUI:CreateCleanText(seal, 10, "CENTER")
--     timerText:SetPoint("CENTER", seal, "CENTER", 0, -14)
--     timerText:SetTextColor(0.98, 0.96, 0.90, 1.0)

--     local activeDuration, activeStart = 0, 0
--     local isMagicSpell, isChanneling = true, false
--     local sR, sG, sB = 1.0, 0.84, 0.32

--     seal:SetScript("OnUpdate", function(self, elapsed)
--         local now = GetTime()
--         local elapsedCast = now - activeStart
--         local rem = activeDuration - elapsedCast

--         if rem <= 0 then
--             self:Hide()
--             return
--         end

--         timerText:SetFormattedText("%.1fs", rem)

--         if isMagicSpell and not isChanneling and activeDuration > 0 then
--             local progress = math.min(1, elapsedCast / activeDuration)
--             local lit = math.floor(progress * 24 + 0.5)
--             for i = 1, 24 do
--                 arcSegments[i]:SetVertexColor(sR, sG, sB, i <= lit and 0.95 or 0.0)
--             end
--         end
--     end)

--     local function StartCast(spellName, texture, duration, startTime, isChan)
--         if not duration or duration <= 0 then return end
--         isMagicSpell = IsMagicCast(spellName)
--         isChanneling = isChan

--         local sc = isMagicSpell and GetMagicSchoolColor(spellName) or { 0.85, 0.82, 0.75 }
--         sR, sG, sB = sc[1], sc[2], sc[3]

--         nameText:SetText(string.upper(tostring(spellName or "")))
--         if texture then spellIcon:SetTexture(texture) end

--         activeDuration = duration
--         activeStart = startTime or GetTime()

--         if isChanneling then
--             radial:SetReverse(false)
--             radial:SetSwipeColor(sR, sG, sB, 0.65)
--             radial:SetCooldown(activeStart, activeDuration)
--             radial:Show()
--             for i = 1, 24 do arcSegments[i]:Hide() end
--         else
--             radial:Hide()
--             for i = 1, 24 do arcSegments[i]:Show() end
--         end

--         centerRing:SetVertexColor(sR, sG, sB, 0.85)
--         seal:Show()
--     end

--     local events = CreateFrame("Frame")
--     events:RegisterEvent("UNIT_SPELLCAST_START")
--     events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
--     events:RegisterEvent("UNIT_SPELLCAST_STOP")
--     events:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
--     events:RegisterEvent("UNIT_SPELLCAST_FAILED")
--     events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
--     events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
--     events:SetScript("OnEvent", function(_, ev, unit)
--         if unit ~= "player" then return end
--         if ev == "UNIT_SPELLCAST_START" then
--             local name, _, texture, _, endTime = UnitCastingInfo("player")
--             if name and endTime then
--                 StartCast(name, texture, (endTime / 1000) - GetTime(), GetTime(), false)
--             end
--         elseif ev == "UNIT_SPELLCAST_CHANNEL_START" then
--             local name, _, texture, _, endTime = UnitChannelInfo("player")
--             if name and endTime then
--                 StartCast(name, texture, (endTime / 1000) - GetTime(), GetTime(), true)
--             end
--         else
--             seal:Hide()
--         end
--     end)
-- end

-- -- ============================================================================
-- -- 2. BARRA DE CAST DO ALVO E DO NPC (NAMEPLATES NO MUNDO)
-- -- ============================================================================
-- local function StyleCastBarFrame(castBar)
--     if not castBar or castBar._rfSkinned then return end
--     castBar._rfSkinned = true

--     for _, reg in ipairs({ castBar:GetRegions() }) do
--         if reg:GetObjectType() == "Texture" and reg ~= castBar:GetStatusBarTexture() then
--             NukeRegion(reg)
--         elseif reg:GetObjectType() == "FontString" then
--             NukeRegion(reg)
--         end
--     end

--     if castBar.Border then NukeRegion(castBar.Border) end
--     if castBar.BorderShield then NukeRegion(castBar.BorderShield) end
--     if castBar.Flash then NukeRegion(castBar.Flash) end
--     if castBar.Spark then NukeRegion(castBar.Spark) end
--     if castBar.Text then NukeRegion(castBar.Text) end
--     if castBar.Icon then NukeRegion(castBar.Icon) end

--     castBar:SetSize(180, 12)

--     local bg = CreateFrame("Frame", nil, castBar, "BackdropTemplate")
--     bg:SetPoint("TOPLEFT", castBar, "TOPLEFT", -1, 1)
--     bg:SetPoint("BOTTOMRIGHT", castBar, "BOTTOMRIGHT", 1, -1)
--     bg:SetFrameLevel(math.max(1, castBar:GetFrameLevel() - 1))
--     ReforgedUI:ApplyMinimalBackdrop(bg, 0.76)

--     ReforgedUI:ApplyUntarnishedTexture(castBar, 0.88, 0.36, 0.20)
-- end

-- function CastBarModule:Init()
--     SetupPlayerArcaneCircle(PlayerCastingBarFrame or CastingBarFrame)
--     SetupTargetCastBar = SetupTargetCastBar or function() end

--     -- Aplica skin limpa também nas barras de cast de NPCs/Nameplates no mundo (Imagem 1)
--     C_Timer.After(1.0, function()
--         if WorldFrame then
--             for _, child in ipairs({ WorldFrame:GetChildren() }) do
--                 if child.spellbar or child.CastingBar then
--                     StyleCastBarFrame(child.spellbar or child.CastingBar)
--                 end
--             end
--         end
--     end)
-- end