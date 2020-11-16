--[[
    SatNav version 2.0.0
    Created By TrogLaByte

    Discord: Trog#5105
    InGame: TrogLaByte
    
    GNU Public License 3.0. Use whatever you want, be so kind to leave credit.

    Thanks to Dorien Grey for his SVG and onscreen button code.
]] 
-----------------------------------------------
-- requirements
-----------------------------------------------

function initiateRequiredLibaries()
    json = require('dkjson')
    vec3  = require('cpml.vec3')
    utils = require('cpml.utils')
    planetRef = require('cpml.planetref')
    referenceTableSource = require('cpml.atlas')
    clamp  = utils.clamp
end
if pcall(initiateRequiredLibaries) then
    system.print("Libaries loaded successfully")
    else
    system.print("Libaries failed to load: check that the following libraries exist:")
    system.print("    <ProgrmData>/DualUniverse/Game/data/lua/dkjson")
    system.print("    <ProgrmData>/DualUniverse/Game/data/lua/cpml/vec3")
    system.print("    <ProgrmData>/DualUniverse/Game/data/lua/cpml/utils")
    system.print("    <ProgrmData>/DualUniverse/Game/data/lua/cpml/planetref")
    system.print("    <ProgrmData>/DualUniverse/Game/data/lua/cpml/atlas")
    system.print("")
    system.print("planetref.lua and atlas.lua can be obtained from the following GitLab url:")
    system.print("https://gitlab.com/JayleBreak/dualuniverse/-/tree/master/DUflightfiles/autoconf/custom")
    unit.exit()
end
-----------------------------------------------
-- Global Variables
-----------------------------------------------

local UpdateInterval = 1 --export: Interval in seconds between updates of the calculations and (if anything changed) redrawing to the screen(s). You need to restart the script after changing this value.
local BackgroundColor = "#1e1e1e"
local PlanetBackgroundColor = "#34b1eb" --export Set the background color of the screens. YOU NEED TO LEAVE THE QUOTATION MARKS.
local LocationBackgroundColor = "#6e3de3" --export Set the background color of the screens. YOU NEED TO LEAVE THE QUOTATION MARKS.
local clickAreas = {}
local locList={}
local lastPlanetSelected = "Alioth"
local pageLines=12
local displayPlanetList={}
local displayLocationList={}
local CurrentLocationPage = 1
local CurrentPlanetPage = 1

-----------------------------------------------
-- initiate slots to know names
-----------------------------------------------

function InitiateSlots()
    for slot_name, slot in pairs(unit) do
        if type(slot) == "table" and type(slot.export) == "table" and
            slot.getElementClass then
            --system.print(slot.getElementClass())
            if slot.getElementClass():lower():find("coreunit") then
                core = slot
                --system.print("found core")
            end
            if slot.getElementClass():lower():find("screenunit") then
                screen = slot
                --system.print("found screen")
            end
            if slot.getElementClass():lower():find("databankunit") then
                myDatabank = slot
                --system.print("found databank")
            end
        end
    end
end
InitiateSlots()
-----------------------------------------------
-- set up galaxy data and functions for planets and locations
-----------------------------------------------

galaxyReference = planetRef(referenceTableSource)
helios = galaxyReference[0] -- PlanetaryReference.PlanetarySystem instance
planetList={}
jdecode = json.decode
jencode = json.encode

function getBodyId(planetName)
    for i=1,200 do
        if helios[tonumber(i)] ~= nil then
            if string.lower(helios[tonumber(i)].name) ==string.lower(planetName) then
                return i
            end
        end
    end
    return 0
end

function buildPlanetList()
    for i=1,200 do
        if helios[tonumber(i)] ~= nil then
            planetList[#planetList+1]=helios[tonumber(i)].name
        end
    end
    planetList[#planetList+1]="Space"
    table.sort(planetList)
end

function buildPlanetLocList(planetName)
    local savedLocation = myDatabank.getStringValue("SavedLocations")  
    local planet={}
    locList={}
    if planetName ~= "Space" then
        table.insert(locList, planetName)  -- add planet name into the list as a default
    end
    if savedLocation ~= nil and savedLocations ~= "" then 
        local result = jdecode(savedLocation)
        if result ~= nil then
            --system.print("Loc Planet: "..planetName)
             for k, v in pairs(result) do
                --system.print("Planet: "..v["planetname"])
                if string.lower(v["planetname"]) == string.lower(planetName) or
                    string.find(string.lower(v["planetname"]),string.lower(planetName))
                    then
                    local location = v["position"]
                    local bodyId = getBodyId(v["planetname"])
                    planet = helios[tonumber(bodyId)] 

                    worldCoords = planet:convertToMapPosition(vec3(location["x"],location["y"],location["z"]))

                    --system.print(string.format([["%s" @ ::pos{%d,%d,%f,%f,%f}]],
                    --    v["name"],
                    --    worldCoords.systemId,
                    --    worldCoords.bodyId,
                    --    worldCoords.latitude*constants.rad2deg,
                    --    worldCoords.longitude*constants.rad2deg,
                    --   worldCoords.altitude))
                    table.insert(locList, v["name"])
                else if v["planetname"] == "" and planetName == "Space" then -- a space location
                        local location = v["position"]
                    --    system.print(string.format([["%s" @ ::pos{%d,%d,%f,%f,%f}]],
                    --        v["name"],
                    --        0,
                    --        0,
                    --        location["x"],
                    --        location["y"],
                    --        location["z"]))
                        table.insert(locList, v["name"])
                     end
                end
             end
         end
    end
    table.sort(locList)
end

function printLocMapPos(locationName)
    local savedLocation = myDatabank.getStringValue("SavedLocations")  
    local planet={}
    if savedLocation ~= nil and savedLocations ~= "" then 
        --system.print(savedLocation)
        local result = jdecode(savedLocation)
        if result ~= nil then
             for k, v in pairs(result) do
                if string.lower(v["name"]) == string.lower(locationName) then
                    local location = v["position"]
                    local bodyId = getBodyId(v["planetname"])
                    planet = helios[tonumber(bodyId)] 
                    if planet ~= nil then
                        worldCoords = planet:convertToMapPosition(vec3(location["x"],location["y"],location["z"]))

                        system.print(string.format([["%s" @ ::pos{%d,%d,%f,%f,%f}]],
                            v["name"],
                            worldCoords.systemId,
                            worldCoords.bodyId,
                            worldCoords.latitude*constants.rad2deg,
                            worldCoords.longitude*constants.rad2deg,
                            worldCoords.altitude))
                        return locationName
                    else
                        system.print(string.format([["%s" @ ::pos{%d,%d,%f,%f,%f}]],
                            v["name"],
                            0,
                            bodyId,
                            location["x"],
                            location["y"],
                            location["z"]))
                        return locationName
                    end
                    break
                end
             end   
         end
    end
    return ""
end

function clearSavedLocations()
    myDatabank.setStringValue("SavedLocations","[]")
    system.print("Databank cleared")
end

function isDuplicateLocation(locName, savedLocations)
    for i=1,#savedLocations do
        if savedLocations and savedLocations[i].name ~= nil then
            if savedLocations[i].name == locName then
                return locName
            end
        end
    end
    return ""
end

function loadPointsOfInterest()
    local num        = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
    local posPattern = '::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' ..
                   num ..  ',' .. num .. '}'
    local savedLocation = {}
    local j=0
    loadLocationTable()
    savedLocation = jdecode(myDatabank.getStringValue("SavedLocations"))
    
    for i = 1, #locationTable do
        local newLoc={}
        local planet={}
        if isDuplicateLocation(locationTable[i][1],savedLocation) == "" then
            newLoc["name"]=locationTable[i][1]
            local newLocPos = locationTable[i][2]
            --system.print("Name: "..locationTable[i][1].." "..newLocPos)
            local systemId, bodyId, latitude, longitude, altitude =
                                            string.match(locationTable[i][2], posPattern)
            --system.print("BodyId: ".. bodyId)
            if tonumber(bodyId) > 0 then
                planet = helios[tonumber(bodyId)]   
                local worldCoords = planet:convertToWorldCoordinates(newLocPos)
                newLoc["position"]=worldCoords
                newLoc["gravity"]=unit.getClosestPlanetInfluence()
                newLoc["atmosphere"]=unit.getAtmosphereDensity()
                newLoc["planetname"]=planet.name
            else -- it is a space location
                newLoc["position"]=vec3(tonumber(latitude), tonumber(longitude), tonumber(altitude))
                newLoc["gravity"]=0
                newLoc["atmosphere"]=0
                newLoc["planetname"]=""
            end
        
            if savedLocation == nil then
                savedLocation = {}
                savedLocation[1]=newLoc
                j = 1
            else
                j = j + 1
                savedLocation[#savedLocation+1]=newLoc
            end
        else
            system.print("Duplicate entry for location ignored: "..locationTable[i][1])
        end
    end
    myDatabank.setStringValue("SavedLocations",jencode(savedLocation))
    system.print(j .. " Saved Locations loaded")
end

buildPlanetList()
buildPlanetLocList(lastPlanetSelected)
local planetCount=#planetList

-----------------------------------------------
-- Code for on screen buttons
-----------------------------------------------

function DrawSVG(output) screen.setSVG(output) end

function AddClickArea(newEntry) table.insert(clickAreas, newEntry) end

function RemoveFromClickAreas(candidate)
    for k, v in pairs(clickAreas) do
        if v.id == candidate then
            clickAreas[k] = nil
            break
        end
    end
end

function UpdateClickArea(candidate, newEntry)
    --system.print("Candidate: "..candidate.." x1"..newEntry.x1)
    for k, v in pairs(clickAreas) do
        if v.id == candidate then
            clickAreas[k] = newEntry
                    --system.print("Click Area: "..candidate.." x1"..clickAreas[k].x1)
            break
        end
    end
end

function DisableClickArea(candidate)
    for k, v in pairs(clickAreas) do
        if v.id == candidate then
            UpdateClickArea(candidate, {
                id = candidate,
                x1 = -1,
                x2 = -1,
                y1 = -1,
                y2 = -1
            })
            break
        end
    end
end

function InitiateClickAreas()
    clickAreas = {}
  
    AddClickArea({id = "LoadSavedLocations", x1 = 300, x2 = 800, y1 = 900, y2 = 1000})
    AddClickArea({id = "ClearSavedLocations", x1 = 1200, x2 = 1700, y1 = 900, y2 = 1000})
    AddClickArea({id = "PlanetPageDown", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
    AddClickArea({id = "PlanetPageUp", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
    AddClickArea({id = "LocationPageDown", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
    AddClickArea({id = "LocationPageUp", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
    
    for i = 1, pageLines do
        AddClickArea({id = string.format("PList%d",i), x1 = 90, x2 = 800, y1 = (180 + i * 55), y2 = (235 + i * 55)})
        AddClickArea({id = string.format("LList%d",i), x1 = 1090, x2 = 1500, y1 = (180 + i * 55), y2 = (235 + i * 55)})
    end
end

function FlushClickAreas() clickAreas = {} end

function clearLocDispList()
    for i=1,pageLines do
        displayLocationList[i] = ""
    end
end

function CheckClick(x, y, HitTarget)
    HitTarget = HitTarget or ""
    if HitTarget == "" then
        for k, v in pairs(clickAreas) do
            if v and x >= v.x1 and x <= v.x2 and y >= v.y1 and y <= v.y2 then
                HitTarget = v.id
                break
            end
        end
    end
  
    --system.print("Target Hit = "..HitTarget)
    
    if HitTarget == "PlanetPageDown" then
        CurrentPlanetPage = CurrentPlanetPage+1
        DrawPlanetList()
    elseif HitTarget == "PlanetPageUp" then
            CurrentPlanetPage = math.max(CurrentPlanetPage-1,0)
            DrawPlanetList()
    elseif HitTarget == "LocationPageDown" then
            CurrentLocationPage = CurrentLocationPage+1
            DrawPlanetList()
    elseif HitTarget == "LocationPageUp" then
            CurrentLocationPage = math.max(CurrentLocationPage-1,0)
            DrawPlanetList()
    elseif HitTarget == "LoadSavedLocations" then
            --system.print("LoadSavedLocations")
            loadPointsOfInterest()
            if displayPlanetList[1] ~= "" then
                        lastPlanetSelected = displayPlanetList[1]
                        buildPlanetLocList(lastPlanetSelected)
                        clearLocDispList()
                        selected = ""
                        CurrentLocationPage=1
                        CurrentPlanetPage=1
                        DrawPlanetList()
            end
    elseif HitTarget == "ClearSavedLocations" then
            --system.print("ClearSavedLocations")
            clearSavedLocations()
            if displayPlanetList[1] ~= "" then
                        lastPlanetSelected = displayPlanetList[1]
                        buildPlanetLocList(lastPlanetSelected)
                        clearLocDispList()
                        selected = ""
                        CurrentLocationPage=1
                        CurrentPlanetPage=1
                        DrawPlanetList()
            end
        else
            for i = 1,pageLines do
                if HitTarget == string.format("PList%s",i) then
                    --system.print("PHitTarget: "..HitTarget)
                    if displayPlanetList[i] ~= "" then
                        lastPlanetSelected = displayPlanetList[i]
                        buildPlanetLocList(lastPlanetSelected)
                        clearLocDispList()
                        selected = ""
                        DrawPlanetList()
                    end
                end
                if HitTarget == string.format("LList%s",i) then
                    if displayLocationList[i] ~= "" then
                        selected = displayLocationList[i]
                        if printLocMapPos(selected) == "" then
                            system.print("Location: "..selected.." sent to Hud")
                        else
                            myDatabank.setStringValue("SPBAutopilotTargetName",selected)
                        end
                    end
                end
            end
    end
end

-----------------------------------------------
-- Code for building screen content and displaying it
-----------------------------------------------

local svgBootstrap = [[<svg class="bootstrap" viewBox="0 0 1920 1120" width="1920" height="1120">
                <defs><style>
                      .ftitle { font-size: 60px; text-anchor: start;fill: white; }
                      .ftitlew { font-size: 60px; text-anchor: start;fill: red; }
                      .ftitle2 { font-size: 60px; text-anchor: start;fill: #565656; }
                      .ftopmiddle { font-size: 40px; text-anchor: middle;}
                      .ftopend { font-size: 40px; text-anchor: end;}
                      .fcapstart { font-size: 30px; text-anchor: start; fill: white;}
                      .fcapstarthy { font-size: 30px; text-anchor: start; fill: yellow;}
                      .fcapstarthr { font-size: 30px; text-anchor: start; fill: red;}
                      .fcapmiddle { font-size: 30px; text-anchor: middle; fill: white;}
                      .fcapend { font-size: 30px; text-anchor: end; fill: white;}
                      .fmstart { font-size: 25px; text-anchor: start; fill: white;}
                      .fmstartg { font-size: 40px; text-anchor: start; fill: #1e1e1e;}
                      .fmstartp { font-size: 40px; text-anchor: start; fill:]]..PlanetBackgroundColor..[[;}
                      .fmstartl { font-size: 40px; text-anchor: start; fill:]]..LocationBackgroundColor..[[;}
                      .fmstarty { font-size: 40px; text-anchor: start; fill: #aaaa00;}
                      .fmstartr { font-size: 40px; text-anchor: end; fill: #ff0000;}
                      .fmmiddle { font-size: 30px; text-anchor: middle; fill: white;}
                      .fmmiddleb { font-size: 30px; text-anchor: middle; fill: black;}
                      .fmmiddler { font-size: 30px; text-anchor: middle; fill: red;}
                      .fmend { font-size: 25px; text-anchor: end; fill: white;}
                </style></defs>]]

function DrawPlanetList()
    local healthyColor = "#00aa00"
    local brokenColor = "#aa0000"
    local damagedColor = "#aaaa00"
    local integrityColor = "#aaaaaa"
    local healthyTextColor = "white"
    local brokenTextColor = "#ff4444"
    local damagedTextColor = "#ffff44"
    local integrityTextColor = "white"
    

    local screenOutput = ""

        -- Draw Header
    screenOutput = screenOutput .. svgBootstrap
                           
        -- Draw main background
    screenOutput = screenOutput ..
                       [[<rect width="1920" height="1120" style="fill: #]]..BackgroundColor..[["/><g></g>]]
    screenOutput = screenOutput ..
                       [[<text x="70" y="120" class="ftitle">Sat Nav</text>]]
    screenOutput = screenOutput ..
                       [[<rect x="70" y="150" rx="10" ry="10" width="820" height="]] ..
                       ((pageLines + 1) * 55) ..
                       [[" style="fill:]].. PlanetBackgroundColor .. [[;stroke:#ffff00;stroke-width:3;" />]]
    screenOutput = screenOutput ..
                       [[<rect x="80" y="160" rx="5" ry="5" width="800" height="40" style="fill:#33331a;" />]]      
    screenOutput = screenOutput ..
                       [[<text x="90" y="191" class="fcapstart">Planets</text>]]
           

    local i = 0
    for j = 1 + (CurrentPlanetPage - 1) * pageLines, pageLines +
                (CurrentPlanetPage - 1) * pageLines, 1 do
        i = i + 1
        if j < #planetList and j>0 then
            if lastPlanetSelected == planetList[j] then
                screenOutput = screenOutput .. [[<text x="90" y="]] ..
                                   (180 + i * 55) .. [[" class="fmstarty">]] ..
                                   string.format("%s", planetList[j]) .. [[</text>]]
            else
                screenOutput = screenOutput .. [[<text x="90" y="]] ..
                                   (180 + i * 55) .. [[" class="fmstartg">]] ..
                                   string.format("%s", planetList[j]) .. [[</text>]]
            end
            displayPlanetList[i]=planetList[j]
        else
            displayPlanetList[i]=""
        end
    end
   
    if planetCount > 12 then
                screenOutput = screenOutput ..
                                   [[<text x="70" y="1000" class="fmstartp">Page ]] ..
                                   CurrentPlanetPage .. " of " ..
                                   math.ceil(planetCount / 12) ..
                                   [[</text>]]

        if CurrentPlanetPage < math.ceil(planetCount / 12) then
                    screenOutput = screenOutput .. [[<svg x="70" y="1050">
                                <rect x="0" y="0" rx="10" ry="10" width="200" height="50" style="fill:]]..PlanetBackgroundColor..[[;" />
                                <svg x="80" y="15"><path d="M52.48,35.23,69.6,19.4a3.23,3.23,0,0,0-2.19-5.6H32.59a3.23,3.23,0,0,0-2.19,5.6L47.52,35.23A3.66,3.66,0,0,0,52.48,35.23Z" transform="translate(-29.36 -13.8)"/></svg>
                            </svg>]]
            UpdateClickArea("PlanetPageDown", {
                        id = "PlanetPageDown",
                        x1 = 70,
                        x2 = 270,
                        y1 = 1050,
                        y2 = 1105
                    })
        else
            DisableClickArea("PlanetPageDown")
        end

        if planetCount > 1 and CurrentPlanetPage > 1 then
                    screenOutput = screenOutput .. [[<svg x="280" y="1050">
                                <rect x="0" y="0" rx="10" ry="10" width="200" height="50" style="fill:]]..PlanetBackgroundColor..[[;" />
                                <svg x="80" y="15"><path d="M47.52,14.77,30.4,30.6a3.23,3.23,0,0,0,2.19,5.6H67.41a3.23,3.23,0,0,0,2.19-5.6L52.48,14.77A3.66,3.66,0,0,0,47.52,14.77Z" transform="translate(-29.36 -13.8)"/></svg>
                            </svg>]]
            UpdateClickArea("PlanetPageUp", {
                        id = "PlanetPageUp",
                        x1 = 280,
                        x2 = 480,
                        y1 = 1050,
                        y2 = 1105
                    })
        else
            DisableClickArea("PlanetPageUp")
        end
    end
    -- Start of Location List
    screenOutput = screenOutput ..
                       [[<rect x="1070" y="150" rx="10" ry="10" width="820" height="]] ..
                       ((pageLines + 1) * 55) ..
                       [[" style="fill:]]..
                       LocationBackgroundColor..
                       [[;stroke:#ffff00;stroke-width:3;" />]]
    screenOutput = screenOutput ..
                       [[<rect x="1080" y="160" rx="5" ry="5" width="800" height="40" style="fill:#33331a;" />]]      
    screenOutput = screenOutput ..
                       [[<text x="1090" y="191" class="fcapstart">]].. lastPlanetSelected ..[[ Locations</text>]]
           

    local i = 0
    for j = 1 + (CurrentLocationPage - 1) * pageLines, pageLines +
                (CurrentLocationPage - 1) * pageLines, 1 do
        --system.print("locList: "..locList[j])
        i = i + 1
        if j <= #locList and j>0 then
            screenOutput = screenOutput .. [[<text x="1090" y="]] ..
                                   (180 + i * 55) .. [[" class="fmstartg">]] ..
                                   string.format("%s", locList[j]) .. [[</text>]]
            displayLocationList[i]=locList[j]
        else
            displayLocationList[i]=""
        end
    end
   
    if #locList > 12 then
        screenOutput = screenOutput ..
                                   [[<text x="1070" y="1000" class="fmstartl">Page ]] ..
                                   CurrentLocationPage .. " of " ..
                                   math.ceil(#locList / 12) ..
                                   [[</text>]]

        if CurrentLocationPage < math.ceil(#locList / 12) then
            screenOutput = screenOutput .. [[<svg x="1070" y="1050">
                                <rect x="0" y="0" rx="10" ry="10" width="200" height="50" style="fill:]]..LocationBackgroundColor..[[;" />
                                <svg x="80" y="15"><path d="M52.48,35.23,69.6,19.4a3.23,3.23,0,0,0-2.19-5.6H32.59a3.23,3.23,0,0,0-2.19,5.6L47.52,35.23A3.66,3.66,0,0,0,52.48,35.23Z" transform="translate(-29.36 -13.8)"/></svg>
                            </svg>]]
            UpdateClickArea("LocationPageDown", {
                        id = "LocationPageDown",
                        x1 = 1070,
                        x2 = 1270,
                        y1 = 1050,
                        y2 = 1105
                    })
        else
            DisableClickArea("LocationPageDown")
        end

        if #locList > 1 and CurrentLocationPage > 1 then
                    screenOutput = screenOutput .. [[<svg x="1280" y="1050">
                                <rect x="0" y="0" rx="10" ry="10" width="200" height="50" style="fill:]]..LocationBackgroundColor..[[;" />
                                <svg x="80" y="15"><path d="M47.52,14.77,30.4,30.6a3.23,3.23,0,0,0,2.19,5.6H67.41a3.23,3.23,0,0,0,2.19-5.6L52.48,14.77A3.66,3.66,0,0,0,47.52,14.77Z" transform="translate(-29.36 -13.8)"/></svg>
                            </svg>]]
            UpdateClickArea("LocationPageUp", {
                        id = "LocationPageUp",
                        x1 = 1280,
                        x2 = 1480,
                        y1 = 1050,
                        y2 = 1105
                    })
        else
            DisableClickArea("LocationPageUp")
        end
    end
        
    screenOutput = screenOutput ..
                               [[<rect x="300" y="900" rx="10" ry="10" width="500" height="60" style="fill:#ff6666;" />]] ..
                               [[<text x="540" y="940" class="fmmiddle">Load Saved Locations</text>]]
       
    screenOutput = screenOutput ..
                               [[<rect x="1200" y="900" rx="10" ry="10" width="500" height="60" style="fill:#ff6666;" />]] ..
                               [[<text x="1440" y="940" class="fmmiddle">Clear Saved Locations</text>]]

    screenOutput = screenOutput .. [[</svg>]]

    DrawSVG(screenOutput)

    forceRedraw = false
end

-----------------------------------------------
-- Execute
-----------------------------------------------

unit.hide()
InitiateClickAreas()
DrawPlanetList()

