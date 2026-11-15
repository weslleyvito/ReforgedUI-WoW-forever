local _, ReforgedUI = ...
local BlizzardClean = {}
ReforgedUI.Modules.BlizzardClean = BlizzardClean

local function StripVisual(obj)
    if not obj then return end
    obj:Hide()
    hooksecurefunc(obj, "Show", function(self)
        self:Hide()
    end)
end

function BlizzardClean:Init()
    --------------------------------------------------------------------
    -- ARTES DA BLIZZARD
    --------------------------------------------------------------------

    local heavyArt = {
        MainMenuBarArtFrame,
        MainMenuBarLeftEndCap,
        MainMenuBarRightEndCap,

        MainMenuXPBarTexture0,
        MainMenuXPBarTexture1,
        MainMenuXPBarTexture2,
        MainMenuXPBarTexture3,

        MainMenuMaxLevelBar0,
        MainMenuMaxLevelBar1,
        MainMenuMaxLevelBar2,
        MainMenuMaxLevelBar3,

        ExhaustionTick,
        BonusActionBarTexture0,
        BonusActionBarTexture1,

        ShapeshiftBarLeft,
        ShapeshiftBarMiddle,
        ShapeshiftBarRight,

        -- NÃO esconder a XP!
        -- MainMenuExpBar,
        -- ReputationWatchBar,
        -- StatusTrackingBarManager,
    }

    for _, frame in pairs(heavyArt) do
        StripVisual(frame)
    end

    --------------------------------------------------------------------
    -- LIMPA TEXTURAS DO MAIN BAR
    --------------------------------------------------------------------

    if MainMenuBarArtFrame then
        for _, region in ipairs({ MainMenuBarArtFrame:GetRegions() }) do
            if region:GetObjectType() == "Texture" then
                region:SetTexture(nil)
                region:Hide()
            end
        end
    end

    --------------------------------------------------------------------
    -- MICRO MENU
    --------------------------------------------------------------------

    local microAndBags = {
        CharacterMicroButton,
        SpellbookMicroButton,
        TalentMicroButton,
        QuestLogMicroButton,
        SocialsMicroButton,
        WorldMapMicroButton,
        MainMenuMicroButton,
        HelpMicroButton,
        MainMenuBarBackpackButton,
        CharacterBag0Slot,
        CharacterBag1Slot,
        CharacterBag2Slot,
        CharacterBag3Slot,
        KeyRingButton,
        MicroButtonAndBagsBar,
    }

    for _, obj in pairs(microAndBags) do
        StripVisual(obj)
    end

    --------------------------------------------------------------------
    -- XP BAR TOPO CENTRAL
    --------------------------------------------------------------------

    if MainMenuExpBar then

        MainMenuExpBar:Show()
        MainMenuExpBar:SetAlpha(1)

        MainMenuExpBar:ClearAllPoints()
        MainMenuExpBar:SetParent(UIParent)

        MainMenuExpBar:SetPoint(
            "TOP",
            UIParent,
            "TOP",
            0,
            -2
        )

        MainMenuExpBar:SetSize(500, 12)

        local bg = CreateFrame(
            "Frame",
            nil,
            MainMenuExpBar,
            "BackdropTemplate"
        )

        bg:SetPoint("TOPLEFT", -1, 1)
        bg:SetPoint("BOTTOMRIGHT", 1, -1)

        if ReforgedUI.ApplyMinimalBackdrop then
            ReforgedUI:ApplyMinimalBackdrop(bg, 0.90)
        end

        bg:SetFrameLevel(
            math.max(
                1,
                MainMenuExpBar:GetFrameLevel() - 1
            )
        )
    end

    --------------------------------------------------------------------
    -- REPUTAÇÃO ABAIXO DA XP
    --------------------------------------------------------------------

    if ReputationWatchBar then
        ReputationWatchBar:Show()

        ReputationWatchBar:ClearAllPoints()
        ReputationWatchBar:SetParent(UIParent)

        ReputationWatchBar:SetPoint(
            "TOP",
            MainMenuExpBar,
            "BOTTOM",
            0,
            -2
        )

        ReputationWatchBar:SetSize(500, 8)
    end
end
