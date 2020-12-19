--[[
    SatNav version 2_1_2-merl1
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
    --json  = require('dkjson')
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
    system.print("(<ProgrmData> is the directory in to which you installed DU)")
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

local version = "2_1_2"

local UpdateInterval = 1 
local defaultNewLocName = "SatNav Location" --export: default name used for new locations
--[[Original colours are 34b1eb, 6e3de3 and 1e1e1e]]
local PlanetPanelColour = "99eeff" --export: Hex code for colour of planet panel and buttons (you need to include the quotes)
local LocPanelColour = "aa99ff" --export: Hex code for colour of locations panel and buttons (you need to include the quotes)
local FontPanelColour = "000000" --export: Hex code for font colour of planet/locations panel (you need to include the quotes)
local LineHighlightColour = "ccffff"--export: Hex code for colour of highlighted lines in planet/location panel (you need to include the quotes)

local BackgroundColor = "#1e1e1e"
local PlanetBackgroundColor = "#"  .. PlanetPanelColour
local LocationBackgroundColor = "#"  .. LocPanelColour
local MainFontColor = "#"  .. FontPanelColour
local HighlightColor = "#"  .. LineHighlightColour

local lastPlanetSelected = "Alioth" --export: The default start planet for displaying locations

local clickAreas = {}
local locList={}
pageLines=12
displayPlanetList={}
displayLocationList={}
CurrentLocationPage = 1
CurrentPlanetPage = 1
myDatabank={}
dbHud={}

if db1 then db1Keys = db1.getKeys() end
if db2 then db2Keys = db2.getKeys() end

--if db1Keys then system.print("DB1 Keys: "..string.sub(db1Keys,1,50)) end
--if db2Keys then system.print("DB2 Keys: "..string.sub(db2Keys,1,50)) end

if db1 and (db1Keys==nil or db1Keys == "" or string.match(db1Keys, "lastNewLoc")) then
    myDatabank = db1
    system.print("SatNav Databank Identified")
elseif db2 and (db2Keys==nil or db2Keys == "" or string.match(db2Keys, "lastNewLoc")) then
    myDatabank = db2
    system.print("SatNav Databank Identified")
else 
    system.print("SatNav databank not found... application will stop")
    if db1Keys then system.print("DB1 Keys: "..string.sub(db1Keys,1,50)) end
    if db2Keys then system.print("DB2 Keys: "..string.sub(db2Keys,1,50)) end
    unit.exit()
    unit.deactivate()
end

if myDatabank==db1 and db2 and string.match(db2Keys, "AutopilotTargetIndex") then
    dbHud = db2
    system.print("Dimencia Hud Identified")
    HUD = "Dimencia"
elseif myDatabank==db2 and db1 and string.match(db1Keys, "AutopilotTargetIndex") then
    dbHud = db1
    system.print("Dimencia Hud Identified")
    HUD = "Dimencia"
else 
    system.print("No Dimencia Hud Identified - will run in Stand Alone mode")
    HUD = "unknown"
end

--unit.exit()
-----------------------------------------------
-- set up galaxy data and functions for planets and locations
-----------------------------------------------

galaxyReference = planetRef(referenceTableSource)
helios = galaxyReference[0] -- PlanetaryReference.PlanetarySystem instance
planetList={}
planetDistList={}
locDistList={}

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
    local planet={}
    local currentLoc = vec3(core.getConstructWorldPos())
    local shipMass = core.getConstructMass()
    for i=1,200 do
        if helios[tonumber(i)] ~= nil then
            planet = helios[tonumber(i)]
            planetList[#planetList+1] = planet.name
            local planetDistance = planet:getDistance(currentLoc)
            planetDistList[planet.name] = formatDistance(planetDistance) .. 
                string.format(" [%.0f wc]", ((planetDistance/200000)*(shipMass/1000)/4000))
        end
    end
    planetList[#planetList+1]="Space"
    table.sort(planetList)
end

function formatDistance(distance)
    if distance < 200000 then
        return string.format("%.0f km",distance/1000)
    elseif distance < 4000000 then
        return string.format("%.2f su",distance/200000)
    else
        return string.format("%.0f su",distance/200000)
    end
end

-- json parser

-- Extracts values from a JSON string with pattern matching
-- This is faster than using dkjson when only a few fields are needed

-- Use this only with trusted data sources! Limitations:
-- * Character escapes are not supported
-- * Field nesting is ignored

local find, gsub = string.find, string.gsub

---@param json string
---@param key string
---@param init number|nil
---@return string|nil, number|nil, number|nil
local function extractStringJsonValue (json, key, init)
  local pattern = [["]] .. key .. [["%s*:%s*"([^"]*)"]]
  local startIndex, endIndex, valueStr = find(json, pattern, init)
  return valueStr, startIndex, endIndex
end

---@param json string
---@param key string
---@param init number|nil
---@return number|nil, number|nil, number|nil
local function extractNumberJsonValue (json, key, init)
  local pattern = [["]] .. key .. [["%s*:%s*(-?[0-9.e-]+)]]
  local startIndex, endIndex, valueStr = find(json, pattern, init)
  return tonumber(valueStr), startIndex, endIndex
end

---@param json string
---@param key string
---@param init number|nil
---@return boolean|nil, number|nil, number|nil
local function extractBooleanJsonValue (json, key, init)
  local pattern = [["]] .. key .. [["%s*:%s*([truefals]+)]]
  local startIndex, endIndex, valueStr = find(json, pattern, init)

  if valueStr == "true" then
    return true, startIndex, endIndex
  elseif valueStr == "false" then
    return false, startIndex, endIndex
  else
    return nil
  end
end

---@param extractJsonValue function
---@param json string
---@param key string
---@param stopAfterIndex number|nil
---@param stopAfterValue any|nil
---@return any[]
local function extractAllJsonValues (extractJsonValue, json, key, stopAfterIndex, stopAfterValue)
  local values = {}
  local valuesLen = 0

  local jsonPos = 1
  local value, valueStartIndex, valueEndIndex -- luacheck: ignore valueStartIndex -- unused

  repeat
    value, valueStartIndex, valueEndIndex = extractJsonValue(json, key, jsonPos)

    if value ~= nil then
      valuesLen = valuesLen + 1
      values[valuesLen] = value

      jsonPos = valueEndIndex + 1
    end

    if value == stopAfterValue then break end
    if valuesLen == stopAfterIndex then break end
  until value == nil

  return values
end

---@param json string
---@param key string
---@param stopAfterIndex number|nil
---@param stopAfterValue string|nil
---@return string[]
local function extractAllStringJsonValues (json, key, stopAfterIndex, stopAfterValue)
  return extractAllJsonValues(extractStringJsonValue, json, key, stopAfterIndex, stopAfterValue)
end

---@param json string
---@param key string
---@param stopAfterIndex number|nil
---@param stopAfterValue number|nil
---@return number[]
local function extractAllNumberJsonValues (json, key, stopAfterIndex, stopAfterValue)
  return extractAllJsonValues(extractNumberJsonValue, json, key, stopAfterIndex, stopAfterValue)
end

---@param json string
---@param key string
---@param stopAfterIndex number|nil
---@param stopAfterValue boolean|nil
---@return boolean[]
local function extractAllBooleanJsonValues (json, key, stopAfterIndex, stopAfterValue)
  return extractAllJsonValues(extractBooleanJsonValue, json, key, stopAfterIndex, stopAfterValue)
end

-- end json Parser


function buildPlanetLocList(planetName)
    local savedLocation = myDatabank.getStringValue("SavedLocations")
    local atmosphere={}
    local gravity={}
    local planetname = {}
    local posX	   = {}
    local posY	   = {}
    local posZ	   = {}
    local name	   = {}

    atmosphere     = extractAllNumberJsonValues(savedLocation,"atmosphere")
    gravity   = extractAllNumberJsonValues(savedLocation,"gravity")
    planetname = extractAllStringJsonValues(savedLocation,"planetname")
    posX	   = extractAllNumberJsonValues(savedLocation,"x")
    posY	   = extractAllNumberJsonValues(savedLocation,"y")
    posZ	   = extractAllNumberJsonValues(savedLocation,"z")
    name	   = extractAllStringJsonValues(savedLocation,"name")
   
    local currentLoc = vec3(core.getConstructWorldPos())
    local shipMass = core.getConstructMass()
    local planet={}
    locList={}
    if planetName ~= "Space" then
        table.insert(locList, planetName)  -- add planet name into the list as a default
        locDistList[planetName] = planetDistList[planetName]
    end
    if #name > 0 then 
        for i=1,#name do
            if string.lower(planetname[i]) == string.lower(planetName) or
               string.find(string.lower(planetname[i]),string.lower(planetName))
               then
                    table.insert(locList, name[i])
            elseif planetname[i] == "" and planetName == "Space" then -- a space location
                table.insert(locList, name[i])
            end
            local locDistance = (currentLoc - vec3(posX[i],posY[i],posZ[i])):len()
            if planetName == "Space" then
                locDistList[name[i]] = formatDistance(locDistance) ..
                string.format(" [%.0f wc]", ((locDistance/200000)*(shipMass/1000)/4000))
            else
                locDistList[name[i]] = formatDistance(locDistance)
            end
         end
    end
    table.sort(locList)
end

function printLocMapPos(locationName)
    local savedLocation = myDatabank.getStringValue("SavedLocations")
    local wayPoint=""
    local atmosphere={}
    local gravity={}
    local planetname = {}
    local posX	   = {}
    local posY	   = {}
    local posZ	   = {}
    local name	   = {}
    atmosphere     = extractAllNumberJsonValues(savedLocation,"atmosphere")
    gravity   = extractAllNumberJsonValues(savedLocation,"gravity")
    planetname = extractAllStringJsonValues(savedLocation,"planetname")
    posX	   = extractAllNumberJsonValues(savedLocation,"x")
    posY	   = extractAllNumberJsonValues(savedLocation,"y")
    posZ	   = extractAllNumberJsonValues(savedLocation,"z")
    name	   = extractAllStringJsonValues(savedLocation,"name")
    local planet={}
    if #name > 0 then 
        for i = 1, #name do
              if string.lower(name[i]) == string.lower(locationName) then
                    local bodyId = getBodyId(planetname[i])
                    planet = helios[tonumber(bodyId)] 
                    if planet ~= nil then
                        worldCoords = planet:convertToMapPosition(vec3(posX[i],posY[i],posZ[i]))
                        wayPoint=string.format([[::pos{%d,%d,%f,%f,%f}]],
                            worldCoords.systemId,
                            worldCoords.bodyId,
                            worldCoords.latitude*constants.rad2deg,
                            worldCoords.longitude*constants.rad2deg,
                            worldCoords.altitude)
                        system.print(name[i].." @ "..wayPoint)
                        system.setWaypoint(wayPoint)
                        return locationName,
                            planetname[i],
                            atmosphere[i],
                            gravity[i],
                            posX[i],
                            posY[i],
                            posZ[i]
                    else
                        wayPoint=string.format([[::pos{%d,%d,%f,%f,%f}]],
                            0,
                            bodyId,
                            posX[i],posY[i],posZ[i])
                        system.print(name[i].." @ "..wayPoint)
                        system.setWaypoint(wayPoint)
                        return locationName,
                            planetname[i],
                            atmosphere[i],
                            gravity[i],
                            posX[i],
                            posY[i],
                            posZ[i]
                    end
                    break
              end   
         end
    end
    return ""
end

function clearSavedLocations()
    myDatabank.setStringValue("SavedLocations","[]")
    system.print("Satnav Databank cleared")
end

function isDuplicateLocation(locName, locNameList)
    for i=1,#locNameList do
        if locNameList[i] == locName then
            return locName
        end
    end
    return ""
end

function saveSavedLocations (name, planetname, atmosphere, gravity, posX, posY, posZ)
    local newSavedLocations = "["
    for i = 1, #name do
        if name[i]~="" then
              newSavedLocations = newSavedLocations..
                            "{"..[["name":"]]..name[i]..
                                 [[","planetname":"]]..planetname[i]..[["]]..
                                 [[,"atmosphere":]]..atmosphere[i]..
                                 [[,"gravity":]]..gravity[i]..
                                 [[,"position":{"x":]]..posX[i]..
                                 [[,"y":]]..posY[i]..
                                 [[,"z":]]..posZ[i]..[[}}]]
        end
        if i+1<#name then
            newSavedLocations= newSavedLocations..","
        end
    end
    newSavedLocations= newSavedLocations.."]"     
    --system.print(newSavedLocations)
    myDatabank.setStringValue("SavedLocations",newSavedLocations)
    system.print("Satnav Databank Updated")
end

function updateLocationName(newLocName)
    if newLocName ~= nil and newLocName ~= "" and 
       lastLocationSelected ~= nil and lastLocationSelected ~= "" then
        system.print("Updating location name for: "..lastLocationSelected.." to: "..newLocName)
    else
        system.print("Invalid update request")
        return
    end
    local savedLocation = {}
    local oldLocFound = false
    savedLocation = myDatabank.getStringValue("SavedLocations")
    local atmosphere={}
    local gravity={}
    local planetname = {}
    local posX	   = {}
    local posY	   = {}
    local posZ	   = {}
    local name	   = {}
    atmosphere     = extractAllNumberJsonValues(savedLocation,"atmosphere")
    gravity   = extractAllNumberJsonValues(savedLocation,"gravity")
    planetname = extractAllStringJsonValues(savedLocation,"planetname")
    posX	   = extractAllNumberJsonValues(savedLocation,"x")
    posY	   = extractAllNumberJsonValues(savedLocation,"y")
    posZ	   = extractAllNumberJsonValues(savedLocation,"z")
    name	   = extractAllStringJsonValues(savedLocation,"name")
    for i = 1, #name do
        if name[i] == lastLocationSelected then
            --system.print("Found: "..lastLocationSelected)
            name[i] = newLocName
            oldLocFound = true
            break
        end
    end
    
    if oldLocFound then   
        saveSavedLocations(name, planetname, atmosphere, gravity, posX, posY, posZ)
    else
        system.print("Old Location Name Not Found")
    end
end

function deleteLocationName(delLocName)
    if delLocName ~= nil and delLocName ~= "" then
        system.print("Deleting location name: "..delLocName)
    else
        system.print("Invalid update request")
        return
    end
    local savedLocation = {}
    local oldLocFound = false
    savedLocation = myDatabank.getStringValue("SavedLocations")
    local atmosphere={}
    local gravity={}
    local planetname = {}
    local posX	   = {}
    local posY	   = {}
    local posZ	   = {}
    local name	   = {}
    atmosphere     = extractAllNumberJsonValues(savedLocation,"atmosphere")
    gravity   = extractAllNumberJsonValues(savedLocation,"gravity")
    planetname = extractAllStringJsonValues(savedLocation,"planetname")
    posX	   = extractAllNumberJsonValues(savedLocation,"x")
    posY	   = extractAllNumberJsonValues(savedLocation,"y")
    posZ	   = extractAllNumberJsonValues(savedLocation,"z")
    name	   = extractAllStringJsonValues(savedLocation,"name")
    for i = 1, #name do
        if name[i] == delLocName then
            --system.print("Found: "..delLocName)
            name[i] = ""
            oldLocFound = true
            break
        end
    end
    
    if oldLocFound then   
        saveSavedLocations(name, planetname, atmosphere, gravity, posX, posY, posZ)
    else
        system.print("Location Name Not Found")
    end
end

function loadPointsOfInterest()
    -- get existing locations from SatNav Databank
    local savedLocation = myDatabank.getStringValue("SavedLocations")
    local atmosphere={}
    local gravity={}
    local planetname = {}
    local posX	   = {}
    local posY	   = {}
    local posZ	   = {}
    local name	   = {}

    atmosphere     = extractAllNumberJsonValues(savedLocation,"atmosphere")
    gravity   = extractAllNumberJsonValues(savedLocation,"gravity")
    planetname = extractAllStringJsonValues(savedLocation,"planetname")
    posX	   = extractAllNumberJsonValues(savedLocation,"x")
    posY	   = extractAllNumberJsonValues(savedLocation,"y")
    posZ	   = extractAllNumberJsonValues(savedLocation,"z")
    name	   = extractAllStringJsonValues(savedLocation,"name")


    local num        = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
    local posPattern = '::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' ..
                   num ..  ',' .. num .. '}'
    local j=0
    loadLocationTable()
    
    for i = 1, #locationTable do
        local newRef = #name + 1
        if isDuplicateLocation(locationTable[i][1],name) == "" then
            name[newRef]=locationTable[i][1]
            local newLocPos = locationTable[i][2]
            --system.print("Name: "..locationTable[i][1].." "..newLocPos)
            local systemId, bodyId, latitude, longitude, altitude =
                                            string.match(locationTable[i][2], posPattern)
            --system.print("BodyId: ".. bodyId)
            if tonumber(bodyId) > 0 then
                local planet = helios[tonumber(bodyId)]   
                local worldCoords = planet:convertToWorldCoordinates(newLocPos)
                posX[newRef]=worldCoords["x"]
                posY[newRef]=worldCoords["y"]
                posZ[newRef]=worldCoords["z"]
                gravity[newRef]=core.g()
                atmosphere[newRef]=unit.getAtmosphereDensity()
                planetname[newRef]=planet.name
            else -- it is a space location
                posX[newRef]=latitude
                posY[newRef]=longitude
                posZ[newRef]=altitude
                gravity[newRef]=0
                atmosphere[newRef]=0
                planetname[newRef]=""
            end        
        else
            system.print("Duplicate entry for location ignored: "..locationTable[i][1])
        end
    end
    saveSavedLocations(name, planetname, atmosphere, gravity, posX, posY, posZ)
    --system.print("Default SatNav locations loaded")
end

function loadHudLocations()
    -- get existing locations from SatNav Databank
    local savedLocation = myDatabank.getStringValue("SavedLocations")
    local atmosphere={}
    local gravity={}
    local planetname = {}
    local posX	   = {}
    local posY	   = {}
    local posZ	   = {}
    local name	   = {}

    atmosphere     = extractAllNumberJsonValues(savedLocation,"atmosphere")
    gravity   = extractAllNumberJsonValues(savedLocation,"gravity")
    planetname = extractAllStringJsonValues(savedLocation,"planetname")
    posX	   = extractAllNumberJsonValues(savedLocation,"x")
    posY	   = extractAllNumberJsonValues(savedLocation,"y")
    posZ	   = extractAllNumberJsonValues(savedLocation,"z")
    name	   = extractAllStringJsonValues(savedLocation,"name")

    local hudLocation = dbHud.getStringValue("SavedLocations")
    local hudatmosphere={}
    local hudgravity={}
    local hudplanetname = {}
    local hudposX	   = {}
    local hudposY	   = {}
    local hudposZ	   = {}
    local hudname	   = {}

    hudatmosphere     = extractAllNumberJsonValues(hudLocation,"atmosphere")
    hudgravity   = extractAllNumberJsonValues(hudLocation,"gravity")
    hudplanetname = extractAllStringJsonValues(hudLocation,"planetname")
    hudposX	   = extractAllNumberJsonValues(hudLocation,"x")
    hudposY	   = extractAllNumberJsonValues(hudLocation,"y")
    hudposZ	   = extractAllNumberJsonValues(hudLocation,"z")
    hudname	   = extractAllStringJsonValues(hudLocation,"name")


    for i = 1, #hudname do
        local newRef = #name + 1
        system.print("HudName: "..hudname[i])
        if isDuplicateLocation(hudname[i],name) == "" and
           hudname[i] ~= "SatNav Location" then
            name[newRef]=hudname[i]
            posX[newRef]=hudposX[i]
            posY[newRef]=hudposY[i]
            posZ[newRef]=hudposZ[i]
            gravity[newRef]=hudgravity[i]
            atmosphere[newRef]=hudatmosphere[i]
            planetname[newRef]=hudplanetname[i]      
        else
            system.print("Duplicate entry for location ignored: "..hudname[i])
        end
    end
    saveSavedLocations(name, planetname, atmosphere, gravity, posX, posY, posZ)
    --system.print("Default SatNav locations loaded")
end


function newLocation (xnewLocName, newLocPos)
    local location
    if xnewLocName and newLocPos then
        location = newLocPos
    else
        location = system.getWaypointFromPlayerPos()
    end
    local newLocId = myDatabank.getIntValue("lastNewLoc") + 1
    myDatabank.setIntValue("lastNewLoc",newLocId)
    
    local newLocName
    if xnewLocName then
        newLocName = xnewLocName
    else
        newLocName = defaultNewLocName.." ("..newLocId..")"
    end
    
    local num        = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
    local posPattern = '::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' ..
                   num ..  ',' .. num .. '}'
    
    local savedLocation = {}
    savedLocation = myDatabank.getStringValue("SavedLocations")
    local atmosphere={}
    local gravity={}
    local planetname = {}
    local posX	   = {}
    local posY	   = {}
    local posZ	   = {}
    local name	   = {}
    atmosphere     = extractAllNumberJsonValues(savedLocation,"atmosphere")
    gravity   = extractAllNumberJsonValues(savedLocation,"gravity")
    planetname = extractAllStringJsonValues(savedLocation,"planetname")
    posX	   = extractAllNumberJsonValues(savedLocation,"x")
    posY	   = extractAllNumberJsonValues(savedLocation,"y")
    posZ	   = extractAllNumberJsonValues(savedLocation,"z")
    name	   = extractAllStringJsonValues(savedLocation,"name")
    
    local systemId, bodyId, latitude, longitude, altitude =
                                 string.match(location, posPattern)
    local worldPos = unit.getMasterPlayerRelativePosition()
    local body = helios:closestBody(worldPos)
    --system.print(json.encode(body))
    --system.print("Distance="..((vec3(worldPos)-vec3(body.center)):len())/(1000))
    --system.print("Calc="..((body.radius+body.center):len())/(1000))

    newlocAlt = ((vec3(worldPos)-vec3(body.center)):len())/(1000)
--    system.print("New Loc Alt:"..newlocAlt)
--    system.print("Radius:"..(((body.radius)/1000) + 200))
    if newlocAlt < (((body.radius)/1000) + 200) then
        local bodyId = getBodyId(body.name)
        --system.print("BodyId: ".. bodyId)
        local planet = helios[tonumber(bodyId)]          -- PlanetaryReference.BodyParameters instance
        --system.print("Planet BodyId: ".. planet.bodyId)
        local worldCoords = planet:convertToWorldCoordinates(location)
        newRef = #name + 1
        name[newRef]=newLocName
        posX[newRef]=worldCoords["x"]
        posY[newRef]=worldCoords["y"]
        posZ[newRef]=worldCoords["z"]
        gravity[newRef]=core.g()
        atmosphere[newRef]=unit.getAtmosphereDensity()
        planetname[newRef]=body.name
    else
        newRef = #name + 1
        name[newRef]=newLocName
        posX[newRef]=latitude
        posY[newRef]=longitude
        posZ[newRef]=altitude
        gravity[newRef]=core.g()
        atmosphere[newRef]=unit.getAtmosphereDensity()
        planetname[newRef]="Space"

    end
    saveSavedLocations(name, planetname, atmosphere, gravity, posX, posY, posZ)
    system.print("New location: "..newLocName.." added to SatNav databank")
    printLocMapPos(newLocName)
end

function copySelectedToHud (locName)
    
    local locName, locplanetname, locatmosphere, locgravity, locX, locY, locZ = 
        printLocMapPos(locName)
    if HUD == "Dimencia" then
        savedLocation = dbHud.getStringValue("SavedLocations")
        --system.print("savedLocation="..savedLocation)
        local atmosphere={}
        local gravity={}
        local planetname = {}
        local posX	   = {}
        local posY	   = {}
        local posZ	   = {}
        local name	   = {}
        atmosphere     = extractAllNumberJsonValues(savedLocation,"atmosphere")
        gravity   = extractAllNumberJsonValues(savedLocation,"gravity")
        planetname = extractAllStringJsonValues(savedLocation,"planetname")
        posX	   = extractAllNumberJsonValues(savedLocation,"x")
        posY	   = extractAllNumberJsonValues(savedLocation,"y")
        posZ	   = extractAllNumberJsonValues(savedLocation,"z")
        name	   = extractAllStringJsonValues(savedLocation,"name")
        local newSavedLocations = "["
        for i = 1, #name do
            if name[i] ~= "SatNav Location" then
                newSavedLocations = newSavedLocations..
                            "{"..[["name":"]]..name[i]..
                                 [[","planetname":"]]..planetname[i]..[["]]..
                                 [[,"atmosphere":]]..atmosphere[i]..
                                 [[,"gravity":]]..gravity[i]..
                                 [[,"position":{"x":]]..posX[i]..
                                 [[,"y":]]..posY[i]..
                                 [[,"z":]]..posZ[i]..[[}},]]
            end
        end
        if locplanetname ~= "" then
            newSavedLocations = newSavedLocations..
                            "{"..[["name":"]].."SatNav Location"..
                                 [[","planetname":"]]..locplanetname..[["]]..
                                 [[,"atmosphere":]]..locatmosphere..
                                 [[,"gravity":]]..locgravity..
                                 [[,"position":{"x":]]..locX..
                                 [[,"y":]]..locY..
                                 [[,"z":]]..locZ..[[}}]]
        end
        newSavedLocations= newSavedLocations.."]"        
        dbHud.setStringValue("SavedLocations",newSavedLocations)
        dbHud.setStringValue("SPBAutopilotTargetName","SatNav Location")
    end
end

function clearHudLocations()
    if HUD == "Dimencia" then
        dbHud.setStringValue("SavedLocations","[]")
        dbHud.setStringValue("SPBAutopilotTargetName","")
        system.print("Dimencia HUD Saved Locations Cleared")
    end
end

function duplicateSatnavDB()
    local satnavLocation = myDatabank.getStringValue("SavedLocations")
    local lastNewLoc = myDatabank.getIntValue("lastNewLoc")
    if dupSatnavDB then
        dupSatnavDB.clear()
        dupSatnavDB.setStringValue("SavedLocations",satnavLocation)
        dupSatnavDB.setIntValue("lastNewLoc",lastNewLoc)
        system.print("SatNav Databank Duplicated Successfully")
    else
        system.print("No space databank linked, duplication aborted")
    end
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
  
    AddClickArea({id = "LoadSatNavLocations", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
    AddClickArea({id = "LoadHudLocations", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
    AddClickArea({id = "NewLocation", x1 = 700, x2 = 1100, y1 = 900, y2 = 1000})
    AddClickArea({id = "ClearHudLocations", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
    AddClickArea({id = "PlanetPageDown", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
    AddClickArea({id = "PlanetPageUp", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
    AddClickArea({id = "LocationPageDown", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
    AddClickArea({id = "LocationPageUp", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
    
    for i = 1, pageLines do
        AddClickArea({id = string.format("PList%d",i), x1 = 90, x2 = 800, y1 = (170 + i * 55), y2 = (225 + i * 55)})
        AddClickArea({id = string.format("LList%d",i), x1 = 1090, x2 = 1500, y1 = (170 + i * 55), y2 = (225 + i * 55)})
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
    elseif HitTarget == "LoadSatNavLocations" then
            loadPointsOfInterest()
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
    elseif HitTarget == "LoadHudLocations" then
            loadHudLocations()
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
    elseif HitTarget == "ClearSatNavLocations" then
            system.print("ClearSavedLocations")
            clearSavedLocations()
            system.print("defaul="..displayPlanetList[1])
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
    elseif HitTarget == "ClearHudLocations" then
            --system.print("ClearSavedLocations")
            clearHudLocations()
    elseif HitTarget == "NewLocation" then
            system.print("NewLocation")
            newLocation()
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
                        if HUD == "Dimencia" then
                            copySelectedToHud(selected)
                        end
                        lastLocationSelected = selected
                        selected = ""
                        DrawPlanetList()
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
                      .ftitle { font-size: 80px; text-anchor: start;fill: white; }
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
                      .fmstartg { font-size: 40px; text-anchor: start; fill: ]]..MainFontColor..[[;}
                      .fmstartp { font-size: 40px; text-anchor: start; fill:]]..PlanetBackgroundColor..[[;}
                      .fmstartl { font-size: 40px; text-anchor: start; fill:]]..LocationBackgroundColor..[[;}
                      .fmstarty { font-size: 40px; text-anchor: start; fill: #aaaa00;}
                      .fmstartb { font-size: 40px; text-anchor: end; fill: black;}
                      .fmstartr { font-size: 40px; text-anchor: end; fill: #ff0000;}
                      .fmmiddle { font-size: 30px; text-anchor: middle; fill: white;}
                      .fmmiddleb { font-size: 30px; text-anchor: middle; fill: black;}
                      .fmmiddler { font-size: 30px; text-anchor: middle; fill: red;}
                      .fmend { font-size: 25px; text-anchor: end; fill: ]]..MainFontColor..[[;}
                </style></defs>]]

function DrawPlanetList()

    local screenOutput = ""

        -- Draw Header
    screenOutput = screenOutput .. svgBootstrap
                           
        -- Draw main background
    screenOutput = screenOutput ..
                       [[<rect width="1920" height="1120" style="fill: #]]..BackgroundColor..[["/><g></g>]]
    screenOutput = screenOutput ..
                       [[<text x="90" y="50" class="fmstart">(Version: ]]..version..[[)</text>]]
    screenOutput = screenOutput ..
                       [[<text x="800" y="50" class="ftitle">Sat Nav</text>]]
    if HUD == "Dimencia" then
        screenOutput = screenOutput ..
                       [[<text x="1500" y="50" class="fmstart">(Dimencia HUD enabled)</text>]]
    else 
        screenOutput = screenOutput ..
                       [[<text x="1500" y="50" class="fmstart">(Standalone mode enabled)</text>]]
    end
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
            local planetName = planetList[j]                          
            if lastPlanetSelected == planetList[j] then
                screenOutput = screenOutput ..
                       [[<rect x="70" y="]]..(140 + i * 55) .. 
                       [[" width="820" height="55"]] ..
                       [[" style="fill:]].. HighlightColor .. [[;" />]]
            end
            screenOutput = screenOutput .. [[<text x="90" y="]] ..
                                   (180 + i * 55) .. [[" class="fmstartg">]] .. planetName ..  
                                    [[</text>]]
            if planetName ~= "Space" then
            screenOutput = screenOutput .. [[<text x="875" y="]] ..
                                   (180 + i * 55) .. [[" class="fmend">]] .. planetDistList[planetName] ..    
                                   [[</text>]] 
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
        
        i = i + 1
        if j <= #locList and j>0 then
            if lastLocationSelected == locList[j] then
                screenOutput = screenOutput ..
                       [[<rect x="1080" y="]]..(140 + i * 55) .. 
                       [[" width="800" height="55"]] ..
                       [[" style="fill:]].. HighlightColor .. [[;" />]]
            end
            screenOutput = screenOutput .. [[<text x="1090" y="]] ..
                                   (180 + i * 55) .. [[" class="fmstartg">]] .. locList[j] ..  
                                    [[</text>]]
            displayLocationList[i]=locList[j]
            screenOutput = screenOutput .. [[<text x="1875" y="]] ..
                                   (180 + i * 55) .. [[" class="fmend">]] .. locDistList[locList[j]] ..    
                                   [[</text>]] 
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
        
--    screenOutput = screenOutput ..
--                               [[<rect x="200" y="900" rx="10" ry="10" width="400" height="60" style="fill:#ff6666;" />]] ..
--                               [[<text x="400" y="940" class="fmmiddle">Load SatNav DB</text>]]
       
    screenOutput = screenOutput ..
                               [[<rect x="700" y="900" rx="10" ry="10" width="400" height="60" style="fill:#008015;" />]] ..
                               [[<text x="900" y="940" class="fmmiddle">Save Current Location</text>]]

--    screenOutput = screenOutput ..
--                               [[<rect x="1200" y="900" rx="10" ry="10" width="400" height="60" style="fill:#ff6666;" />]] ..
--                               [[<text x="1400" y="940" class="fmmiddle">Clear HUD Locs</text>]]


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
system.print("Running")
unit.setTimer("loadwp",1)
