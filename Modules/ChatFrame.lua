local _, ReforgedUI = ...
local ChatModule = {}
ReforgedUI.Modules.ChatFrame = ChatModule

local function NukeChatButton(obj)
    if not obj then return end
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

function ChatModule:SetupSoulframeChat()
    local cf = ChatFrame1
    if not cf then return end

    cf:SetClampedToScreen(true)
    cf:SetUserPlaced(true)
    cf:ClearAllPoints()
    cf:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 18, 28)
    cf:SetSize(410, 168)

    if not cf._sfGradient then
        local gradFrame = CreateFrame("Frame", nil, cf)
        gradFrame:SetPoint("TOPLEFT", cf, "TOPLEFT", -10, 8)
        gradFrame:SetPoint("BOTTOMRIGHT", cf, "BOTTOMRIGHT", 14, -8)
        gradFrame:SetFrameLevel(math.max(1, cf:GetFrameLevel() - 2))
        gradFrame:SetAlpha(0.45)

        local grad = gradFrame:CreateTexture(nil, "BACKGROUND")
        grad:SetAllPoints()
        grad:SetTexture(ReforgedUI.FlatTexture)
        if grad.SetGradient and CreateColor then
            grad:SetGradient(
                "HORIZONTAL",
                CreateColor(0.03, 0.03, 0.04, 0.45),
                CreateColor(0.03, 0.03, 0.04, 0.0)
            )
        else
            grad:SetVertexColor(0.03, 0.03, 0.04, 0.25)
        end

        local leftHairline = gradFrame:CreateTexture(nil, "BORDER")
        leftHairline:SetWidth(1)
        leftHairline:SetPoint("TOPLEFT", gradFrame, "TOPLEFT", 2, -4)
        leftHairline:SetPoint("BOTTOMLEFT", gradFrame, "BOTTOMLEFT", 2, 4)
        leftHairline:SetTexture(ReforgedUI.FlatTexture)
        leftHairline:SetVertexColor(0.83, 0.69, 0.22, 0.40)

        cf._sfGradient = gradFrame

        cf:HookScript("OnEnter", function() gradFrame:SetAlpha(1.0) end)
        cf:HookScript("OnLeave", function() gradFrame:SetAlpha(0.45) end)
    end

    NukeChatButton(ChatFrameMenuButton)
    NukeChatButton(ChatFrameChannelButton)
    NukeChatButton(ChatFrameToggleVoiceDeafenButton)
    NukeChatButton(ChatFrameToggleVoiceMuteButton)
    NukeChatButton(QuickJoinToastButton)
    NukeChatButton(FriendsMicroButton)

    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local name = "ChatFrame" .. i
        local frame = _G[name]
        local tab = _G[name .. "Tab"]
        local editBox = _G[name .. "EditBox"]

        if frame then
            NukeChatButton(_G[name .. "ButtonFrameUpButton"])
            NukeChatButton(_G[name .. "ButtonFrameDownButton"])
            NukeChatButton(_G[name .. "ButtonFrameBottomButton"])
            NukeChatButton(_G[name .. "ButtonFrameMinimizeButton"])
            NukeChatButton(_G[name .. "ButtonFrame"])

            local font, size = frame:GetFont()
            frame:SetFont(font or "Fonts\\FRIZQT__.TTF", size or 12, "")
            frame:SetShadowOffset(1, -1)
            frame:SetShadowColor(0, 0, 0, 0.95)
            frame:SetFading(true)
            frame:SetTimeVisible(25)

            frame:EnableMouseWheel(true)
            frame:SetScript("OnMouseWheel", function(self, delta)
                if delta > 0 then
                    self:ScrollUp()
                else
                    self:ScrollDown()
                end
            end)

            for _, texSuffix in ipairs({ "Background", "TopLeftTexture", "TopRightTexture", "BottomLeftTexture", "BottomRightTexture", "LeftTexture", "RightTexture", "TopTexture", "BottomTexture" }) do
                local tex = _G[name .. texSuffix]
                if tex then
                    tex:SetAlpha(0)
                    tex:Hide()
                end
            end
        end

        if tab then
            for _, region in ipairs({ tab:GetRegions() }) do
                if region:GetObjectType() == "Texture" then
                    region:SetAlpha(0)
                end
            end
            local tabText = _G[name .. "TabText"]
            if tabText then
                tabText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                tabText:SetTextColor(0.88, 0.84, 0.74, 0.85)
            end

            if not tab._sfDiamond then
                local dia = tab:CreateTexture(nil, "OVERLAY")
                dia:SetSize(5, 5)
                dia:SetPoint("BOTTOM", tab, "BOTTOM", 0, 2)
                dia:SetTexture(ReforgedUI.FlatTexture)
                dia:SetRotation(math.rad(45))
                dia:SetVertexColor(0.83, 0.69, 0.22, 0.90)
                tab._sfDiamond = dia
            end
        end

        if editBox then
            editBox:ClearAllPoints()
            editBox:SetPoint("TOPLEFT", cf, "BOTTOMLEFT", -6, -4)
            editBox:SetPoint("TOPRIGHT", cf, "BOTTOMRIGHT", 6, -4)
            editBox:SetHeight(22)
            editBox:SetAltArrowKeyMode(false)

            for _, region in ipairs({ editBox:GetRegions() }) do
                if region:GetObjectType() == "Texture" then
                    region:SetAlpha(0)
                end
            end

            if not editBox._sfStyle then
                local ebBg = CreateFrame("Frame", nil, editBox)
                ebBg:SetAllPoints()
                ebBg:SetFrameLevel(math.max(1, editBox:GetFrameLevel() - 1))

                local fill = ebBg:CreateTexture(nil, "BACKGROUND")
                fill:SetAllPoints()
                fill:SetTexture(ReforgedUI.FlatTexture)
                fill:SetVertexColor(0.05, 0.05, 0.06, 0.82)

                local topLine = ebBg:CreateTexture(nil, "BORDER")
                topLine:SetHeight(1)
                topLine:SetPoint("TOPLEFT", ebBg, "TOPLEFT", 0, 0)
                topLine:SetPoint("TOPRIGHT", ebBg, "TOPRIGHT", 0, 0)
                topLine:SetTexture(ReforgedUI.FlatTexture)
                topLine:SetVertexColor(0.83, 0.69, 0.22, 0.65)

                editBox._sfStyle = ebBg
                ebBg:Hide()

                -- Só exibe a barra de digitação quando o campo realmente ganha foco (Enter)
                editBox:HookScript("OnEditFocusGained", function()
                    ebBg:Show()
                    if cf._sfGradient then cf._sfGradient:SetAlpha(1.0) end
                end)
                editBox:HookScript("OnEditFocusLost", function()
                    ebBg:Hide()
                    editBox:Hide()
                    if cf._sfGradient then cf._sfGradient:SetAlpha(0.45) end
                end)
            end
            editBox:Hide()
        end
    end
end

function ChatModule:Init()
    self:SetupSoulframeChat()
    C_Timer.After(0.25, function() self:SetupSoulframeChat() end)

    local updater = CreateFrame("Frame")
    updater:RegisterEvent("PLAYER_ENTERING_WORLD")
    updater:RegisterEvent("UPDATE_CHAT_WINDOWS")
    updater:SetScript("OnEvent", function()
        self:SetupSoulframeChat()
    end)
end