local _, ReforgedUI = ...
local BagsMicroModule = {}
ReforgedUI.Modules.BagsAndMicro = BagsMicroModule

local function NukeNativeBar(frame)
    if not frame then return end
    frame:SetAlpha(0)
    frame:Hide()
    if not frame._rfHooked then
        frame._rfHooked = true
        hooksecurefunc(frame, "Show", function(self)
            self:SetAlpha(0)
            self:Hide()
        end)
    end
end

local function GetTotalFreeBagSlots()
    local totalFree = 0
    local getNumFree = (C_Container and C_Container.GetContainerNumFreeSlots) or GetContainerNumFreeSlots
    if getNumFree then
        for bagID = 0, (NUM_BAG_SLOTS or 4) do
            local free = getNumFree(bagID)
            if free then
                totalFree = totalFree + free
            end
        end
    end
    return totalFree
end

function BagsMicroModule:Init()
    -- Oculta as barras nativas da Blizzard para o Edit Mode não puxar os ícones de volta para o meio
    NukeNativeBar(MicroMenu)
    NukeNativeBar(MicroMenuContainer)
    NukeNativeBar(BagsBar)
    NukeNativeBar(MicroButtonAndBagsBar)

    for _, name in ipairs({
        "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton",
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
        "SocialsMicroButton", "LFGMicroButton", "CollectionsMicroButton",
        "EJMicroButton", "StoreMicroButton", "MainMenuMicroButton", "HelpMicroButton",
        "MainMenuBarBackpackButton", "CharacterBag0Slot", "CharacterBag1Slot",
        "CharacterBag2Slot", "CharacterBag3Slot", "BagBarExpandToggle"
    }) do
        NukeNativeBar(_G[name])
    end

    -- Dock minimalista fixo no canto inferior direito
    local dock = CreateFrame("Frame", "ReforgedUIBottomRightDock", UIParent, "BackdropTemplate")
    dock:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -14, 14)
    dock:SetHeight(32)
    dock:SetAlpha(0.35)
    ReforgedUI:ApplyMinimalBackdrop(dock, 0.55)

    local function OnDockEnter() dock:SetAlpha(1.0) end
    local function OnDockLeave()
        if not dock:IsMouseOver() then
            dock:SetAlpha(0.35)
        end
    end

    dock:EnableMouse(true)
    dock:SetScript("OnEnter", OnDockEnter)
    dock:SetScript("OnLeave", OnDockLeave)

    -- 1. Botão único da Mochila Principal com contador de espaços livres
    local bagBtn = CreateFrame("Button", "ReforgedUIMainBagButton", dock)
    bagBtn:SetSize(24, 24)
    bagBtn:SetPoint("RIGHT", dock, "RIGHT", -5, 0)

    local bagIcon = bagBtn:CreateTexture(nil, "ARTWORK")
    bagIcon:SetAllPoints()
    bagIcon:SetTexture("Interface\\Icons\\INV_Misc_Bag_08")
    bagIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local bagBorder = bagBtn:CreateTexture(nil, "OVERLAY")
    bagBorder:SetAllPoints()
    bagBorder:SetTexture(ReforgedUI.FlatTexture)
    bagBorder:SetVertexColor(0.83, 0.69, 0.22, 0.45)
    bagBorder:SetDrawLayer("BORDER")

    local freeText = ReforgedUI:CreateCleanText(bagBtn, 11, "CENTER")
    freeText:SetPoint("BOTTOM", bagBtn, "BOTTOM", 0, 1)

    local function UpdateFreeSlots()
        local free = GetTotalFreeBagSlots()
        freeText:SetText(tostring(free))
        if free == 0 then
            freeText:SetTextColor(0.95, 0.25, 0.25, 1.0)
        elseif free <= 5 then
            freeText:SetTextColor(0.95, 0.65, 0.20, 1.0)
        else
            freeText:SetTextColor(0.96, 0.94, 0.88, 1.0)
        end
    end
    UpdateFreeSlots()

    local bagEvents = CreateFrame("Frame")
    bagEvents:RegisterEvent("BAG_UPDATE")
    bagEvents:RegisterEvent("BAG_UPDATE_DELAYED")
    bagEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    bagEvents:SetScript("OnEvent", UpdateFreeSlots)

    bagBtn:SetScript("OnClick", function()
        if ToggleAllBags then
            ToggleAllBags()
        elseif ToggleBackpack then
            ToggleBackpack()
        end
    end)

    -- 2. Gaveta expansível para os 4 slots de bolsa (aparece no hover da mochila ou ao segurar uma bolsa)
    local drawer = CreateFrame("Frame", "ReforgedUIBagDrawer", UIParent, "BackdropTemplate")
    drawer:SetPoint("BOTTOMRIGHT", bagBtn, "TOPRIGHT", 2, 6)
    drawer:SetSize(116, 32)
    drawer:SetFrameStrata("HIGH")
    ReforgedUI:ApplyMinimalBackdrop(drawer, 0.88)
    drawer:Hide()

    local function CheckDrawer()
        C_Timer.After(0.08, function()
            local holding = CursorHasItem and CursorHasItem()
            if holding or bagBtn:IsMouseOver() or drawer:IsMouseOver() then
                drawer:Show()
                dock:SetAlpha(1.0)
            else
                drawer:Hide()
                if not dock:IsMouseOver() then
                    dock:SetAlpha(0.35)
                end
            end
        end)
    end

    -- Cria os 4 slots interativos de equipamento de bolsa (ContainerID 1 a 4 -> InventorySlot "Bag0Slot" a "Bag3Slot")
    for idx = 1, 4 do
        local slotName = "Bag" .. (idx - 1) .. "Slot"
        local invSlotId = GetInventorySlotInfo(slotName)
        local slotBtn = CreateFrame("Button", "ReforgedUIBagSlot" .. idx, drawer)
        slotBtn:SetSize(24, 24)
        slotBtn:SetPoint("RIGHT", drawer, "RIGHT", -5 - ((idx - 1) * 27), 0)

        local tex = slotBtn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local function RefreshSlotIcon()
            local itemTex = GetInventoryItemTexture("player", invSlotId)
            if itemTex then
                tex:SetTexture(itemTex)
                tex:SetDesaturated(false)
                tex:SetVertexColor(1, 1, 1, 1)
            else
                tex:SetTexture("Interface\\PaperDoll\\UI-PaperDoll-Slot-Bag")
                tex:SetDesaturated(true)
                tex:SetVertexColor(0.6, 0.6, 0.6, 0.6)
            end
        end
        RefreshSlotIcon()

        local slotWatcher = CreateFrame("Frame")
        slotWatcher:RegisterEvent("UNIT_INVENTORY_CHANGED")
        slotWatcher:RegisterEvent("BAG_UPDATE")
        slotWatcher:SetScript("OnEvent", RefreshSlotIcon)

        slotBtn:RegisterForDrag("LeftButton")
        slotBtn:SetScript("OnClick", function()
            if CursorHasItem and CursorHasItem() then
                PutItemInBag(invSlotId)
            elseif ToggleBag then
                ToggleBag(idx)
            end
        end)
        slotBtn:SetScript("OnReceiveDrag", function()
            if CursorHasItem and CursorHasItem() then
                PutItemInBag(invSlotId)
            end
        end)
        slotBtn:SetScript("OnDragStart", function()
            PickupBagFromSlot(invSlotId)
        end)
        slotBtn:SetScript("OnEnter", function(self)
            CheckDrawer()
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            if not GameTooltip:SetInventoryItem("player", invSlotId) then
                GameTooltip:SetText("Slot de Bolsa Vazio")
            end
            GameTooltip:Show()
        end)
        slotBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
            CheckDrawer()
        end)
    end

    bagBtn:SetScript("OnEnter", function(self)
        CheckDrawer()
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Mochilas (" .. GetTotalFreeBagSlots() .. " espaços livres)")
        GameTooltip:Show()
    end)
    bagBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
        CheckDrawer()
    end)

    local cursorWatcher = CreateFrame("Frame")
    cursorWatcher:RegisterEvent("CURSOR_CHANGED")
    cursorWatcher:SetScript("OnEvent", CheckDrawer)

    -- 3. Atalhos limpos do MicroMenu à esquerda da mochila
    local microItems = {
        {
            label = "Personagem",
            icon = "Interface\\Icons\\INV_Helmet_03",
            onClick = function() ToggleCharacter("PaperDollFrame") end,
        },
        {
            label = "Grimório",
            icon = "Interface\\Icons\\INV_Misc_Book_09",
            onClick = function() ToggleSpellBook(BOOKTYPE_SPELL) end,
        },
        {
            label = "Talentos",
            icon = "Interface\\Icons\\Ability_Marksmanship",
            onClick = function()
                if ToggleTalentFrame then ToggleTalentFrame() end
            end,
        },
        {
            label = "Missões",
            icon = "Interface\\Icons\\INV_Misc_Note_01",
            onClick = function() ToggleQuestLog() end,
        },
        {
            label = "Social / Guilda",
            icon = "Interface\\Icons\\INV_Shirt_GuildTabard_01",
            onClick = function() ToggleFriendsFrame() end,
        },
        {
            label = "Menu do Jogo",
            icon = "Interface\\Icons\\INV_Misc_Gear_01",
            onClick = function()
                if GameMenuFrame:IsShown() then
                    HideUIPanel(GameMenuFrame)
                else
                    ShowUIPanel(GameMenuFrame)
                end
            end,
        },
    }

    local lastBtn = bagBtn
    for i = #microItems, 1, -1 do
        local info = microItems[i]
        local btn = CreateFrame("Button", nil, dock)
        btn:SetSize(20, 20)
        btn:SetPoint("RIGHT", lastBtn, "LEFT", (lastBtn == bagBtn) and -10 or -4, 0)

        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(info.icon)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        tex:SetDesaturated(true)
        tex:SetVertexColor(0.85, 0.82, 0.75, 0.85)

        btn:SetScript("OnClick", info.onClick)
        btn:SetScript("OnEnter", function(self)
            OnDockEnter()
            tex:SetDesaturated(false)
            tex:SetVertexColor(1, 1, 1, 1)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(info.label)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
            tex:SetDesaturated(true)
            tex:SetVertexColor(0.85, 0.82, 0.75, 0.85)
            OnDockLeave()
        end)

        lastBtn = btn
    end

    dock:SetWidth((#microItems * 24) + 44)
end