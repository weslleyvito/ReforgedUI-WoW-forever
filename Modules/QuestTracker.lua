local _, ReforgedUI = ...
local QuestModule = {}
ReforgedUI.Modules.QuestTracker = QuestModule

function QuestModule:Init()
    local tracker = ObjectiveTrackerFrame
    if not tracker then return end

    tracker:ClearAllPoints()
    tracker:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", -2, -16)

    if tracker.Header then
        tracker.Header:SetAlpha(0)
        tracker.Header:Hide()
    end

    local function CleanQuestBlocks()
        if not QuestObjectiveTracker or not QuestObjectiveTracker.ContentsFrame then return end

        if QuestObjectiveTracker.Header then
            QuestObjectiveTracker.Header:SetAlpha(0)
            QuestObjectiveTracker.Header:Hide()
        end

        for _, block in ipairs({ QuestObjectiveTracker.ContentsFrame:GetChildren() }) do
            if block then
                -- Oculta o ícone redondo de ? / ! da esquerda e o botão de seta da direita
                if block.ItemButton then block.ItemButton:SetScale(0.85) end
                if block.poiButton then block.poiButton:SetAlpha(0); block.poiButton:Hide() end
                for _, sub in ipairs({ block:GetChildren() }) do
                    if sub:GetObjectType() == "Button" and sub ~= block.ItemButton then
                        sub:SetAlpha(0)
                        sub:Hide()
                    end
                end

                if block.HeaderText then
                    block.HeaderText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
                    block.HeaderText:SetTextColor(0.96, 0.94, 0.88, 1.0)

                    -- Linha vertical minimalista estilo Genshin Impact
                    if not block._rfLine then
                        block._rfLine = block:CreateTexture(nil, "OVERLAY")
                        block._rfLine:SetSize(2, 13)
                        block._rfLine:SetPoint("RIGHT", block.HeaderText, "LEFT", -6, 0)
                        block._rfLine:SetTexture(ReforgedUI.FlatTexture)
                        block._rfLine:SetVertexColor(0.92, 0.76, 0.32, 0.95)
                    end
                end

                if block.lines then
                    for _, line in pairs(block.lines) do
                        if line.Text then
                            line.Text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
                            line.Text:SetTextColor(0.82, 0.84, 0.88, 0.95)
                        end
                    end
                end
            end
        end
    end

    hooksecurefunc(tracker, "Update", CleanQuestBlocks)
    C_Timer.After(0.5, CleanQuestBlocks)
end