local _, ReforgedUI = ...
local NameplatesModule = {}
ReforgedUI.Modules.Nameplates = NameplatesModule

local function StyleNameplate(plate)
    if not plate or plate._rfSkinned then return end
    plate._rfSkinned = true

    local healthBar, nameText
    
    for _, region in ipairs({ plate:GetRegions() }) do
        if region:GetObjectType() == "FontString" then
            nameText = region
        end
    end

    for _, child in ipairs({ plate:GetChildren() }) do
        if child:GetObjectType() == "StatusBar" then
            healthBar = child
            break
        end
    end

    if healthBar then
        for _, reg in ipairs({ healthBar:GetRegions() }) do
            if reg:GetObjectType() == "Texture" and reg ~= healthBar:GetStatusBarTexture() then
                reg:SetTexture(nil)
                reg:SetAlpha(0)
            end
        end

        healthBar:SetSize(110, 8)
        healthBar:SetStatusBarTexture(ReforgedUI.FlatTexture)

        local bg = CreateFrame("Frame", nil, healthBar, "BackdropTemplate")
        bg:SetPoint("TOPLEFT", healthBar, "TOPLEFT", -1, 1)
        bg:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 1, -1)
        bg:SetFrameLevel(math.max(1, healthBar:GetFrameLevel() - 1))
        ReforgedUI:ApplyMinimalBackdrop(bg, 0.78)
    end

    if nameText then
        nameText:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        nameText:SetTextColor(0.96, 0.94, 0.88, 1.0)
    end
end

function NameplatesModule:Init()
    local frame = CreateFrame("Frame")
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer > 0.15 then
            self.timer = 0
            if WorldFrame then
                for _, child in ipairs({ WorldFrame:GetChildren() }) do
                    if child and child:IsShown() then
                        -- Verifica se o objeto possui uma barra de vida (característica de nameplate)
                        for _, sub in ipairs({ child:GetChildren() }) do
                            if sub:GetObjectType() == "StatusBar" then
                                StyleNameplate(child)
                            end
                        end
                    end
                end
            end
        end
    end)
end