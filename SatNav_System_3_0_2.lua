local cmdPattern = [[([hHuUdDcCaAlLxXbBrR])]]
local locPattern = [['([%w ]*)']]
local num        = ' *[+-]?%d+%.?%d*e?[+-]?%d*'
local posPattern = '(::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' ..
                   num ..  ',' .. num .. '})'
-- echo command text
system.print([[SatNav command recieved: "]]..text..[["]])

--get command
local cmd= string.lower(string.match(text,cmdPattern,1))
--if not(cmd==nil) then system.print("Command = "..cmd) end
--get first location Name
local locName1= string.match(text,locPattern,1)
--if not(locName1==nil) then system.print("locName1:"..locName1) end
--get first ::pos
--local locPos1Sys,locPos1Bdy,locPos1X,locPos1Y,locPos1Z = string.match(text,posPattern,1)
local locPos1 = string.match(text,posPattern,1)
--if not(locPos1Sys==nil) then system.print("locPos1:"..locPos1Sys..locPos1Bdy..locPos1X..locPos1Y..locPos1Z) end
--if not(locPos1==nil) then system.print("locPos1:"..locPos1) end


--if string.sub(text,1,2) == "u " then
if cmd=="u" then
    if locName1==nil then system.print("Invalid location name in command: "..text)
    elseif lastLocationSelected=="" or lastLocationSelected==nil then system.print("Select a valid location from SatNav list and re-enter command")
    else
        updateLocationName(locName1,locPos1)
        if displayPlanetList[1] ~= "" then
            refreshDisplay()
            lastLocationSelected = ""
            DrawPlanetList()
        end
    end
elseif text == "dump SatNav" then
    dumpSatNavLocationsToLogfile()  
elseif text == "d SatNav" then
    if lastLocationSelected=="" or lastLocationSelected==nil then 
        system.print("Select a valid location from SatNav list and re-enter command")
    else
        deleteLocationName(lastLocationSelected)
    end
    if displayPlanetList[1] ~= "" then
        refreshDisplay()
        lastLocationSelected = ""
        DrawPlanetList()

    end
elseif cmd == "d" then
    if locName1==nil then system.print("Invalid location name in command: "..text)
    else
        deleteLocationName(locName1)
    end
    if displayPlanetList[1] ~= "" then
        refreshDisplay()
        lastLocationSelected = ""
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
elseif text == "backup" then
    if dupSatnavDB then
        system.print("BackupSatNavDB")
        backupSatnavDB()
    else
        system.print("Please link an empty databank to the programming board")
    end
elseif text == "restore" then
    if dupSatnavDB then
        system.print("RestoreSatNavDB")
        restoreSatnavDB()
        refreshDisplay()
        lastLocationSelected = ""
        DrawPlanetList()
    else
        system.print("Please link an empty databank to the programming board")
    end
elseif cmd == "a" then
    if locName1==nil then system.print("Invalid location name in command: "..text)
    else
        newLocation(locName1, locPos1)
        if displayPlanetList[1] ~= "" then
            refreshDisplay()
            lastLocationSelected = ""
            DrawPlanetList()
        end
    end
elseif cmd == "h" then
    system.print("SatNav Help:")
    system.print("u 'location name' ::pos{a,b,c,d,e}")
    system.print("    -update name and optionally ::pos of selected location")
    system.print("a 'location name' ::pos{a,b,c,d,e}")
    system.print("    -add a new location")
    system.print("d SatNav")
    system.print("    -delete the selected location")
    system.print("c SatNav")
    system.print("    -clear the SatNav databank")
    system.print("l SatNav")
    system.print("    -reload the default SatNav locations")
    system.print("backup")
    system.print("    -create a backup of SatNav databank")
    system.print("restore")
    system.print("    -restore SatNav databank from backup")
    system.print("dump SatNav")
    system.print("    -write all location to the DU Logfile")
    system.print("h")
    system.print("    -this help")
else system.print("Unrecognised SatNav command")
end
