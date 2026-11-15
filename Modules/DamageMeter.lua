local _, ReforgedUI = ...
local MeterModule = {}
ReforgedUI.Modules.DamageMeter = MeterModule

local function NukeTextures(frame)
    if not frame or (frame.IsForbidden and frame:IsForbidden()) then return end
    if not frame.GetRegions then return end
    for _, reg in ipairs({ frame:GetRegions() }) do
        if reg and reg:GetObjectType() == "Texture" then
            reg:SetTexture(nil)
            reg:SetAlpha(0)
        end
    end
end

local function StripNativeBorders(win)
    if not win or (win.IsForbidden and win:IsForbidden()) then return end
    NukeTextures(win)

    if win.NineSlice then win.NineSlice:SetAlpha(0); win.NineSlice:Hide() end
    if win.Background then win.Background:SetAlpha(0); win.Background:Hide() end
    if win.Border then win.Border:SetAlpha(0); win.Border:Hide() end

    if win.Header then
        NukeTextures(win.Header)
        if win.Header.Background then
            if win.Header.Background.SetTexture then win.Header.Background:SetTexture(nil) end
            win.Header.Background:SetAlpha(0)
        end
    end

    if win.MinimizeContainer then
        NukeTextures(win.MinimizeContainer)
        if win.MinimizeContainer.Background then
            if win.MinimizeContainer.Background.SetTexture then
                win.MinimizeContainer.Background:SetTexture(nil)
            end
            win.MinimizeContainer.Background:SetAlpha(0)
        end
        if win.MinimizeContainer.NotActive then
            NukeTextures(win.MinimizeContainer.NotActive)
        end
    end
end

local function SkinDamageMeterWindow(win)
    if not win or (win.IsForbidden and win:IsForbidden()) then return end

    StripNativeBorders(win)

    if win._rfClean then return end
    win._rfClean = true

    win:HookScript("OnShow", function(self)
        StripNativeBorders(self)
    end)

    -- Varre filhos internos: limpa fundos residuais e deixa as barras flutuando limpas (igual ao da direita)
    local function CleanChildren(parent, depth)
        if not parent or depth > 5 or (parent.IsForbidden and parent:IsForbidden()) or not parent.GetChildren then return end
        for _, child in ipairs({ parent:GetChildren() }) do
            if child and not (child.IsForbidden and child:IsForbidden()) then
                local cType = child:GetObjectType()
                if cType == "StatusBar" then
                    child:SetStatusBarTexture(ReforgedUI.FlatTexture)
                    local r, g, b = child:GetStatusBarColor()
                    if r and g and b then
                        child:SetStatusBarColor(r, g, b, 0.85)
                    end
                elseif cType == "Frame" then
                    NukeTextures(child)
                end
                CleanChildren(child, depth + 1)
            end
        end
    end
    CleanChildren(win, 1)

    -- Mantém tipografia limpa no título e nos textos
    for _, reg in ipairs({ win:GetRegions() }) do
        if reg and reg:GetObjectType() == "FontString" then
            reg:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            reg:SetTextColor(0.96, 0.94, 0.88, 1.0)
        end
    end
end

function MeterModule:Init()
    local function RunScan()
        for i = 1, 10 do
            local win = _G["DamageMeterSessionWindow" .. i]
            if win then
                SkinDamageMeterWindow(win)
            end
        end
    end

    RunScan()
    C_Timer.After(0.5, RunScan)
    C_Timer.After(1.5, RunScan)
    C_Timer.After(3.0, RunScan)

    if DamageMeter and DamageMeter.SetupSessionWindow then
        hooksecurefunc(DamageMeter, "SetupSessionWindow", function(_, window)
            if window then SkinDamageMeterWindow(window) end
            C_Timer.After(0.05, RunScan)
        end)
    end

    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("ADDON_LOADED")
    watcher:RegisterEvent("PLAYER_REGEN_DISABLED")
    watcher:RegisterEvent("PLAYER_ENTERING_WORLD")
    watcher:SetScript("OnEvent", function(_, event, addonName)
        if event == "ADDON_LOADED" and addonName == "Blizzard_DamageMeter" then
            if DamageMeter and DamageMeter.SetupSessionWindow then
                hooksecurefunc(DamageMeter, "SetupSessionWindow", function(_, window)
                    if window then SkinDamageMeterWindow(window) end
                    C_Timer.After(0.05, RunScan)
                end)
            end
        end
        C_Timer.After(0.2, RunScan)
    end)
end