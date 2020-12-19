if string.sub(text,1,2) == "u " then
    local newLocName = string.sub(text,3,string.len(text))
    updateLocationName(newLocName)
    if displayPlanetList[1] ~= "" then
                        lastPlanetSelected = displayPlanetList[1]
                        lastLocationSelected = ""
                        buildPlanetLocList(lastPlanetSelected)
                        clearLocDispList()
                        selected = ""
                        CurrentLocationPage=1
                        CurrentPlanetPage=1
                        DrawPlanetList()
    end
elseif text == "d SatNav" then
    deleteLocationName(lastLocationSelected)
    if displayPlanetList[1] ~= "" then
                        lastPlanetSelected = displayPlanetList[1]
                        lastLocationSelected = ""
                        buildPlanetLocList(lastPlanetSelected)
                        clearLocDispList()
                        selected = ""
                        CurrentLocationPage=1
                        CurrentPlanetPage=1
                        DrawPlanetList()
    end
elseif text == "c SatNav" then
    system.print("ClearSatNavLocations")
    CheckClick(0, 0, "ClearSatNavLocations")
elseif text == "c Hud" then
    if HUD == "Dimencia" then
        system.print("ClearHudLocations")
        CheckClick(0, 0, "ClearHudLocations")
    else
        system.print("ClearHudLocations not available in standalone mode")
    end
elseif text == "l SatNav" then
    system.print("LoadSatNavLocations")
    CheckClick(0, 0, "LoadSatNavLocations")
elseif text == "l Hud" then
    if HUD == "Dimencia" then
        system.print("LoadHudLocations")
        CheckClick(0, 0, "LoadHudLocations")
    else
        system.print("LoadHudLocations not available in standalone mode")
    end
elseif text == "x SatNav" then
    if dupSatnavDB then
        system.print("DuplicateSatNavDB")
        duplicateSatnavDB()
    else
        system.print("Please link an empty databank to the programming board")
    end
elseif string.sub(text,1,2) == "a " then
    local newLocNamePos = text:find("}") 
    if newLocNamePos > 0 then
        -- @TODO: add more validation
        local newLocPos = string.sub(text,3,newLocNamePos)
        local newLocName = string.sub(text, newLocNamePos + 2, string.len(text))
        newLocation(newLocName, newLocPos)
        if displayPlanetList[1] ~= "" then
            lastPlanetSelected = displayPlanetList[1]
            lastLocationSelected = ""
            buildPlanetLocList(lastPlanetSelected)
            clearLocDispList()
            selected = ""
            CurrentLocationPage=1
            CurrentPlanetPage=1
            DrawPlanetList()
        end
    end
end