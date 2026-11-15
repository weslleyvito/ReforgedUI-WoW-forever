local _, ReforgedUI = ...
local MinimapModule = {}
ReforgedUI.Modules.Minimap = MinimapModule

function MinimapModule:Init()
    if not Minimap then return end

    Minimap:SetMaskTexture(ReforgedUI.FlatTexture)
    Minimap:SetSize(215, 215)
    Minimap:ClearAllPoints()
    Minimap:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -14, -26)

    local bg = CreateFrame("Frame", nil, Minimap, "BackdropTemplate")
    bg:SetPoint("TOPLEFT", Minimap, "TOPLEFT", -1, 1)
    bg:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 1, -1)
    bg:SetFrameLevel(math.max(1, Minimap:GetFrameLevel() - 1))
    ReforgedUI:ApplyMinimalBackdrop(bg, 0.90)

    -- 1. Remove molduras circulares douradas da Blizzard
    local ringTextures = {
        MinimapCompassTexture, MinimapBorder, MinimapBorderTop,
        MinimapNorthTag, MinimapBackdrop
    }
    for _, tex in ipairs(ringTextures) do
        if tex then
            tex:SetTexture(nil)
            tex:SetAlpha(0)
            tex:Hide()
            tex.Show = function() end
        end
    end

    for _, frame in ipairs({ Minimap, MinimapCluster, MinimapCluster and MinimapCluster.BorderTop }) do
        if frame then
            for _, reg in ipairs({ frame:GetRegions() }) do
                if reg:GetObjectType() == "Texture" then
                    reg:SetTexture(nil)
                    reg:SetAlpha(0)
                end
            end
        end
    end

    -- 2. Oculta apenas zoom (+/-) e mapa mundial
    local toHide = { MinimapZoomIn, MinimapZoomOut, MiniMapWorldMapButton, MinimapToggleButton }
    for _, btn in ipairs(toHide) do
        if btn then
            btn:SetAlpha(0)
            btn:Hide()
            btn.Show = function() end
        end
    end

    -- 3. Nome da zona no topo
   local zoneBtn = (MinimapCluster and MinimapCluster.ZoneTextButton) or MinimapZoneTextButton
    if zoneBtn then
        zoneBtn:ClearAllPoints()

        -- ocupa toda a largura do minimapa
        zoneBtn:SetPoint("BOTTOMLEFT", Minimap, "TOPLEFT", 0, 4)
        zoneBtn:SetPoint("BOTTOMRIGHT", Minimap, "TOPRIGHT", 0, 4)
        zoneBtn:SetHeight(18)

        for _, reg in ipairs({ zoneBtn:GetRegions() }) do
            if reg:GetObjectType() == "Texture" then
                reg:SetTexture(nil)
                reg:SetAlpha(0)
            end
        end
    end

    if MinimapZoneText then
        MinimapZoneText:ClearAllPoints()
        MinimapZoneText:SetPoint("CENTER", zoneBtn, "CENTER", 0, 0)

        MinimapZoneText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        MinimapZoneText:SetTextColor(0.96, 0.94, 0.88, 1.0)
        MinimapZoneText:SetJustifyH("CENTER")
    end

    -- 4. Relógio centralizado na parte inferior interna
    local function LockClockPosition()
        if not TimeManagerClockButton then return end
        TimeManagerClockButton:SetParent(Minimap)
        TimeManagerClockButton:ClearAllPoints()
        TimeManagerClockButton:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, 8)
        TimeManagerClockButton:SetSize(46, 16)
        TimeManagerClockButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)

        for _, reg in ipairs({ TimeManagerClockButton:GetRegions() }) do
            if reg:GetObjectType() == "Texture" then
                reg:SetTexture(nil)
                reg:SetAlpha(0)
            end
        end

        if TimeManagerClockTicker then
            TimeManagerClockTicker:ClearAllPoints()
            TimeManagerClockTicker:SetPoint("CENTER", TimeManagerClockButton, "CENTER", 0, 0)
            TimeManagerClockTicker:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            TimeManagerClockTicker:SetTextColor(0.96, 0.94, 0.88, 1.0)
        end
    end

    -- 5. Busca recursiva pelo ícone da Lua/Sol e posicionamento na quina superior direita
    local function FindAndMoveMoon(frame, depth)
        if not frame or depth > 4 then return end
        local name = frame:GetName() or ""
        if string.find(name, "LibDBIcon", 1, true) or string.find(name, "Addon", 1, true) then
            return
        end

        for _, reg in ipairs({ frame:GetRegions() }) do
            if reg:GetObjectType() == "Texture" then
                local tex = string.lower(tostring(reg:GetTexture() or ""))
                -- Identifica texturas nativas do indicador de dia/noite (Lua/Sol)
                if string.find(tex, "moon", 1, true) or string.find(tex, "sun", 1, true) or string.find(tex, "day", 1, true) or string.find(tex, "night", 1, true) or string.find(tex, "timemanager", 1, true) then
                    if frame ~= TimeManagerClockButton and frame ~= Minimap and frame ~= MinimapCluster then
                        frame:SetParent(Minimap)
                        frame:ClearAllPoints()
                        frame:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -4, -4)
                        frame:SetScale(0.80)
                        frame:SetFrameLevel(Minimap:GetFrameLevel() + 8)
                        return
                    end
                end
            end
        end

        for _, child in ipairs({ frame:GetChildren() }) do
            FindAndMoveMoon(child, depth + 1)
        end
    end

local function LockMoonPosition()
    if not MinimapCluster or not MinimapCluster.MinimapContainer then
        return
    end

    local container = MinimapCluster.MinimapContainer

    -- Procura por texturas da lua dentro do container
    for _, child in ipairs({ container:GetChildren() }) do
        local name = child:GetName() or ""

        if child ~= Minimap and child ~= TimeManagerClockButton then
            child:ClearAllPoints()
            child:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -4, -4)
            child:SetScale(0.80)
        end
    end

    -- Procura texturas diretamente anexadas
    for _, region in ipairs({ container:GetRegions() }) do
        if region:GetObjectType() == "Texture" then
            local texture = tostring(region:GetTexture() or ""):lower()

            if texture:find("moon")
            or texture:find("sun")
            or texture:find("night")
            or texture:find("day")
            or texture:find("diel") then

                region:ClearAllPoints()
                region:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", -4, -4)
            end
        end
    end
end

    LockClockPosition()
    C_Timer.After(0.4, function()
        LockClockPosition()
        LockMoonPosition()
    end)

    if MinimapCluster and MinimapCluster.Layout then
        hooksecurefunc(MinimapCluster, "Layout", function()
            LockClockPosition()
            LockMoonPosition()
        end)
    end

    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 then Minimap_ZoomIn() else Minimap_ZoomOut() end
    end)
end

