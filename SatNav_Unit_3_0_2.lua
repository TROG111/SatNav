--[[
	SatNav version 3_0_1
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
	unit.setTimer("heartbeat",5)
end
if pcall(initiateRequiredLibaries) then
	system.print("Libaries loaded successfully")
	else
	system.print("Libaries failed to load: check that the following libraries exist:")
	system.print("(<ProgrmData> is the directory in to which you installed DU)")
	--system.print("    <ProgrmData>/DualUniverse/Game/data/lua/dkjson")
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

local version = "3_0_1" --incorporated Merl suggestions

local UpdateInterval = 1 
local defaultNewLocName = "SatNav Location" --export: default name used for new locations
local PlanetPanelColour = "99eeff" --export: Hex code for colour of planet panel and buttons (you need to include the quotes)
local LocPanelColour = "aa99ff" --export: Hex code for colour of locations panel and buttons (you need to include the quotes)
local FontPanelColour = "000000" --export: Hex code for font colour of planet/locations panel (you need to include the quotes)
local LineHighlightColour = "ccffff"--export: Hex code for colour of highlighted lines in planet/location panel (you need to include the quotes)

local BackgroundColor = "#1e1e1e"
local PlanetBackgroundColor = "#"  .. PlanetPanelColour
local LocationBackgroundColor = "#"  .. LocPanelColour
local MainFontColor = "#"  .. FontPanelColour
local HighlightColor = "#"  .. LineHighlightColour
local planetIconColour = "grey" --export: default colour of planet icons
local marketIconColour = "green" --export: default colout of market icons
local mineIconColour = "red" --export: default colout of mine site icons
local crashIconColour = "blue" --export: default colout of crash site icons
local baseIconColour = "purple" --export: default colout of bases icons
local favouriteIconColour = "yellow" --export: default colout of favourite icons
local buttonColour = "lightsteelblue" --export: default colout of favourite icons
local lastPlanetSelected = "Alioth" --export: The default start planet for displaying locations

local pngMarketIcon = [[xlink:href="assets.prod.novaquark.com/67573/2bf5f13f-6386-428e-9ad2-2a8427eb6449.png"]]
local pngMineIcon = [[xlink:href="assets.prod.novaquark.com/67573/ba7458cf-640a-4fa5-83e8-c77ad544d85c.png"]]
local pngCrashIcon = [[xlink:href="assets.prod.novaquark.com/67573/bb0ae118-31e5-4479-88b3-045dbe83ef8b.png"]]
local pngBaseIcon = [[xlink:href=""]]
local pngPlanetIcon = [[xlink:href="assets.prod.novaquark.com/67573/13e46ea4-a890-4b67-b6f1-4653ae45e4fc.png"]]
local pngFavouriteIcon = [[xlink:href=""]]

local clickAreas = {}
local locList={}
pageLines=12
displayPlanetList={}
displayLocationList={}
CurrentLocationPage = 1
CurrentPlanetPage = 1
currentFilter = "PlanetFilter"
sortOrder = "az"
myDatabank={}
dbHud={}
isPlanet = ""
local SatNavDBLocs = "SatNavLocs"

if db1 then db1Keys = db1.getKeys() end
if db2 then db2Keys = db2.getKeys() end

--if db1Keys then system.print("DB1 Keys: "..string.sub(db1Keys,1,50)) end
--if db2Keys then system.print("DB2 Keys: "..string.sub(db2Keys,1,50)) end

if db1 and (db1Keys==nil or db1Keys == "" or db1Keys == "[]" or string.match(db1Keys, "lastNewLoc")) then
	myDatabank = db1
	system.print("SatNav Databank Identified")
elseif db2 and (db2Keys==nil or db2Keys == "" or db2Keys == "[]" or string.match(db2Keys, "lastNewLoc")) then
	myDatabank = db2
	system.print("SatNav Databank Identified")
else 
	system.print("SatNav databank not found... application will stop")
	if db1Keys then system.print("DB1 Keys: "..string.sub(db1Keys,1,50)) end
	if db2Keys then system.print("DB2 Keys: "..string.sub(db2Keys,1,50)) end
	unit.exit()
	unit.deactivate()
end

if myDatabank then
	local tmpLocation = myDatabank.getStringValue(SatNavDBLocs)
	system.print("SatNav Databank Size = "..string.len(tmpLocation).." bytes")
	tmpLocation=""
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
locTagList={}

function getKeysSortedByValue(tbl, sortFunction)
  local keys = {}
  for key in pairs(tbl) do
    table.insert(keys, key)
  end

  table.sort(keys, function(a, b)
    return sortFunction(tbl[a], tbl[b])
  end)

  return keys
end

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
    local tempPlanetList = {}
    local tempPlanetDist = {}
	for i=1,200 do
		if helios[tonumber(i)] ~= nil then
			planet = helios[tonumber(i)]
			tempPlanetList[#tempPlanetList+1] = planet.name
			local planetDistance = planet:getDistance(currentLoc)
               tempPlanetDist[planet.name] = planetDistance
			planetDistList[planet.name] = formatDistance(planetDistance) .. 
				string.format(" [%.0f wc]", ((planetDistance/200000)*(shipMass/1000)/4000))
		end
	end
	tempPlanetList[#tempPlanetList+1]="Space"
	planetDistList["Space"] = 0
	table.sort(tempPlanetList)
	if sortOrder == "km" then
		local sortedKeys = getKeysSortedByValue(tempPlanetList, function(a, b) 
				if tonumber(tempPlanetDist[a]) and tonumber(tempPlanetDist[b]) then 
					return tonumber(tempPlanetDist[a]) < tonumber(tempPlanetDist[b])
				else return false
				end
			 end)
		
		for i=1,#sortedKeys do
			planetList[i] = tempPlanetList[sortedKeys[i]]
		end
	else
		for i=1,#tempPlanetList do
			planetList[i] = tempPlanetList[i]
		end
	end
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

local find, gsub = string.find, string.gsub

local function extractStringJsonValue (json, key, init)
  local pattern = [["]] .. key .. [["%s*:%s*"([^"]*)"]]
  local startIndex, endIndex, valueStr = find(json, pattern, init)
  return valueStr, startIndex, endIndex
end

local function extractNumberJsonValue (json, key, init)
  local pattern = [["]] .. key .. [["%s*:%s*(-?[0-9.e-]+)]]
  local startIndex, endIndex, valueStr = find(json, pattern, init)
  return tonumber(valueStr), startIndex, endIndex
end

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

local function extractListJsonValue (json, key, init)
  local pattern = [["]] .. key .. [["%s*:%s*([[][]].."^]"..[[]*[]].."]".."])"
  --]]
  local startIndex, endIndex, valueStr = string.find(json, pattern, init)
  return valueStr, startIndex, endIndex
end

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


local function extractAllStringJsonValues (json, key, stopAfterIndex, stopAfterValue)
  return extractAllJsonValues(extractStringJsonValue, json, key, stopAfterIndex, stopAfterValue)
end

local function extractAllNumberJsonValues (json, key, stopAfterIndex, stopAfterValue)
  return extractAllJsonValues(extractNumberJsonValue, json, key, stopAfterIndex, stopAfterValue)
end

local function extractAllBooleanJsonValues (json, key, stopAfterIndex, stopAfterValue)
  return extractAllJsonValues(extractBooleanJsonValue, json, key, stopAfterIndex, stopAfterValue)
end

local function extractAllListJsonValues (json, key, stopAfterIndex, stopAfterValue)
  return extractAllJsonValues(extractListJsonValue, json, key, stopAfterIndex, stopAfterValue)
end
-- end json Parser

function extractSatNavValues()
	local savedLocation = myDatabank.getStringValue(SatNavDBLocs)

	local atmosphere     = extractAllNumberJsonValues(savedLocation,"at")
	local gravity   = extractAllNumberJsonValues(savedLocation,"gr")
	local planetname = extractAllStringJsonValues(savedLocation,"pl")
	local posX	   = extractAllNumberJsonValues(savedLocation,"x")
	local posY	   = extractAllNumberJsonValues(savedLocation,"y")
	local posZ	   = extractAllNumberJsonValues(savedLocation,"z")
	local name	   = extractAllStringJsonValues(savedLocation,"na")
	local tags       = extractAllListJsonValues(savedLocation,"ta")
 
	return atmosphere, gravity, planetname, posX, posY, posZ, name, tags
end

function dbUpdate()
	if myDatabank.hasKey("SavedLocations") then
		local savedLocation = myDatabank.getStringValue("SavedLocations")
		if #savedLocation > 5 then 
			system.print("Converting SatNav DB to version 3")
			local atmosphere     = extractAllNumberJsonValues(savedLocation,"atmosphere")
			local gravity   = extractAllNumberJsonValues(savedLocation,"gravity")
			local planetname = extractAllStringJsonValues(savedLocation,"planetname")
			local posX	   = extractAllNumberJsonValues(savedLocation,"x")
			local posY	   = extractAllNumberJsonValues(savedLocation,"y")
			local posZ	   = extractAllNumberJsonValues(savedLocation,"z")
			local name	   = extractAllStringJsonValues(savedLocation,"name")
			local tags       = extractAllListJsonValues(savedLocation,"tag")
			saveSavedLocations(name, planetname, atmosphere, gravity, posX, posY, posZ, tags)
			myDatabank.setStringValue("SavedLocations","")
		end
	end
end

function buildPlanetLocList(planetName)
	local atmosphere, gravity, planetname, posX, posY, posZ, name, tags     = extractSatNavValues()
   
	local currentLoc = vec3(core.getConstructWorldPos())
	local shipMass = core.getConstructMass()
	local planet={}
	locList={}
	tempLocList = {}
	tempLocDist = {}
	
	if planetName ~= "Space" and currentFilter == "PlanetFilter" then
		table.insert(tempLocList, planetName)  -- add planet name into the list as a default
		isPlanet = planetName
		locDistList[planetName] = planetDistList[planetName]
	end
	if #name > 0 then 
		for i=1,#name do
			if (currentFilter == "MarketFilter" and not(string.find(tags[i],"m")==nil)) or
				(currentFilter == "MineFilter" and not(string.find(tags[i],"q")==nil)) or
				(currentFilter == "CrashFilter" and not(string.find(tags[i],"c")==nil)) or
				(currentFilter == "BaseFilter" and not(string.find(tags[i],"b")==nil)) or
				(currentFilter == "FavouriteFilter" and not(string.find(tags[i],"f")==nil)) then
				table.insert(tempLocList, name[i])
				local locDistance = (currentLoc - vec3(posX[i],posY[i],posZ[i])):len()
				tempLocDist[name[i]] = locDistance
				if planetName == "Space" then
					locDistList[name[i]] = formatDistance(locDistance) ..
					string.format(" [%.0f wc]", ((locDistance/200000)*(shipMass/1000)/4000))
				else
					locDistList[name[i]] = formatDistance(locDistance)
				end
			elseif currentFilter == "PlanetFilter" then
				if string.lower(planetname[i]) == string.lower(planetName) or
				   string.find(string.lower(planetname[i]),string.lower(planetName)) then
					table.insert(tempLocList, name[i])
				elseif planetname[i] == "" and planetName == "Space" then -- a space location
					table.insert(tempLocList, name[i])
				end
				local locDistance = (currentLoc - vec3(posX[i],posY[i],posZ[i])):len()
				tempLocDist[name[i]] = locDistance
				if planetName == "Space" then
					locDistList[name[i]] = formatDistance(locDistance) ..
					string.format(" [%.0f wc]", ((locDistance/200000)*(shipMass/1000)/4000))
				else
					locDistList[name[i]] = formatDistance(locDistance)
				end
			end
			if #tags > 0 then
				locTagList[name[i]]=tags[i]
			else
				locTagList[name[i]]="[]"
			end
		 end
	end
	table.sort(tempLocList)

	if sortOrder == "km" then
		local sortedKeys = getKeysSortedByValue(tempLocList, function(a, b) 
				if tonumber(tempLocDist[a]) and tonumber(tempLocDist[b]) then 
					return tonumber(tempLocDist[a]) < tonumber(tempLocDist[b])
				else return false
				end
			 end)
		
		for i=1,#sortedKeys do
			locList[i] = tempLocList[sortedKeys[i]]
		end
	else
		for i=1,#tempLocList do
			locList[i] = tempLocList[i]
		end	
	end
end

function printLocMapPos(locationName)
	local wayPoint=""
	local atmosphere, gravity, planetname, posX, posY, posZ, name, tags     = extractSatNavValues()
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

function dumpSatNavLocationsToLogfile()
	local logString=""
	local atmosphere, gravity, planetname, posX, posY, posZ, name, tags     = extractSatNavValues()
	local planet={}
	for i = 1, #name do
		local bodyId = getBodyId(planetname[i])
		planet = helios[tonumber(bodyId)] 
		if planet ~= nil then
			worldCoords = planet:convertToMapPosition(vec3(posX[i],posY[i],posZ[i]))
			wayPoint=string.format([[locationTable[#locationTable+1]={"%s","::pos{%d,%d,%f,%f,%f}"} ]],
							name[i],
							worldCoords.systemId,
							worldCoords.bodyId,
							worldCoords.latitude*constants.rad2deg,
							worldCoords.longitude*constants.rad2deg,
							worldCoords.altitude)
		else
			wayPoint=string.format([[locationTable[#locationTable+1]={"%s","::pos{%d,%d,%f,%f,%f}"} ]],
							name[i],
							0,
							bodyId,
							posX[i],posY[i],posZ[i])
		end
		logString = logString .. wayPoint 
	end
	system.logInfo(logString)
end

function clearSavedLocations()
	myDatabank.setStringValue(SatNavDBLocs,"[]")
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

function saveSavedLocations (name, planetname, atmosphere, gravity, posX, posY, posZ,tags)
	local newSavedLocations = "["
	for i = 1, #name do
		if tags[i] == nil then
			tags[i] = "[]"
		end
		if atmosphere[i] == nil or gravity[i] == nil or posX[i] == nil or posY[i] == nil or posZ[i] == nil then
			-- corrupt entry
		else
			if name[i]~="" then
				  newSavedLocations = newSavedLocations..
								"{"..[["na":"]]..name[i]..
									 [[","pl":"]]..planetname[i]..[["]]..
									 [[,"at":]]..(math.floor((atmosphere[i]*10))/10)..
									 [[,"gr":]]..(math.floor((gravity[i]*10))/10)..
									 [[,"ta":]]..tags[i]..
									 [[,"po":{"x":]]..(math.floor((posX[i]*10000))/10000)..
									 [[,"y":]]..(math.floor((posY[i]*10000))/10000)..
									 [[,"z":]]..(math.floor((posZ[i]*10000))/10000).."}}"
			end
			if i+1<#name then
				newSavedLocations= newSavedLocations..","
			end
		end
	end
	newSavedLocations= newSavedLocations.."]"     
	--system.print(newSavedLocations)
	myDatabank.setStringValue(SatNavDBLocs,newSavedLocations)
	system.print("Satnav Databank Updated")
end

function updateLocationName(newLocName, newLocPos)
	if isPlanet == lastLocationSelected then system.print("Cannot update dummy planet location entry") return end
	local num        = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
	local posPattern = '::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' ..
				   num ..  ',' .. num .. '}'
	if newLocName ~= nil and newLocName ~= "" and 
	   lastLocationSelected ~= nil and lastLocationSelected ~= "" then
		if newLocName ~= lastLocationSelected then
			system.print("Updating location: "..lastLocationSelected)
		end
	else
		system.print("Invalid update request")
		return
	end
	if newLocName == lastLocationSelected and newLocPos == nil then
		-- this is a button change to the location pos
		newLocPos = unit.system.getWaypointFromPlayerPos()
		worldPos = core.getConstructWorldPos()
		newLocPosSys, newLocPosBdy, newLocPosX, newLocPosY, newLocPosZ 
			  = string.match(newLocPos, posPattern, 1)
		local body = helios:closestBody(worldPos)
		newlocAlt = ((vec3(worldPos)-vec3(body.center)):len())/(1000)
		newLocPosSys = 0
		if newlocAlt < (((body.radius)/1000) + 200) then
			newLocPosBdy = getBodyId(body.name)
		else
			newLocPosBdy = 0
		end
		system.print("Updating pos for: '"..newLocName..
					 "' to ::pos{"..newLocPosSys..","..newLocPosBdy..","..newLocPosX ..","..
								   newLocPosY..","..newLocPosZ.."}")
	elseif newLocPos ~= nil then
		newLocPosSys, newLocPosBdy, newLocPosX, newLocPosY, newLocPosZ 
			  = string.match(newLocPos, posPattern, 1)
		if newLocPosSys == nil then system.print("Invalid pos string: "..newLocPos) end
	end

	local oldLocFound = false
	local atmosphere, gravity, planetname, posX, posY, posZ, name, tags     = extractSatNavValues()
	for i = 1, #name do
		if name[i] == lastLocationSelected then
			--system.print("Found: "..lastLocationSelected)
			name[i] = newLocName
			oldLocFound = true
			if newLocPosSys ~= nil then
				local planet = helios[tonumber(newLocPosBdy)]
				if tonumber(newLocPosBdy) > 0 then
					local planet = helios[tonumber(newLocPosBdy)]
					local worldCoords = planet:convertToWorldCoordinates(newLocPos)
					posX[i]=worldCoords["x"]
					posY[i]=worldCoords["y"]
					posZ[i]=worldCoords["z"]
					planetname[i]=planet.name
				else -- it is a space location
					posX[i]=newLocPosX
					posY[i]=newLocPosY
					posZ[i]=newLocPosZ
					gravity[i]=0
					atmosphere[i]=0
					planetname[i]="Space"
				end  
			end
			break
		end
	end
	
	if oldLocFound then   
		saveSavedLocations(name, planetname, atmosphere, gravity, posX, posY, posZ, tags)
	else
		system.print("Old Location Name Not Found")
	end
end

function deleteLocationName(delLocName)
	if delLocName ~= nil and delLocName ~= "" and delLocName ~= isPlanet then
		system.print("Deleting location name: "..delLocName)
	else
		system.print("Invalid update request")
		return
	end
	local oldLocFound = false
	local atmosphere, gravity, planetname, posX, posY, posZ, name, tags     = extractSatNavValues()
	for i = 1, #name do
		if name[i] == delLocName then
			--system.print("Found: "..delLocName)
			name[i] = ""
			oldLocFound = true
			break
		end
	end
	
	if oldLocFound then   
		saveSavedLocations(name, planetname, atmosphere, gravity, posX, posY, posZ,tags)
	else
		system.print("Location Name Not Found")
	end
end

function loadPointsOfInterest()
	local atmosphere, gravity, planetname, posX, posY, posZ, name, tags     = extractSatNavValues()
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
			local newTags = locationTable[i][3]
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
				planetname[newRef]="Space"
				
			end
			if not(newTags == nil) then
			    tags[newRef]= "["..newTags.."]"
			else
				tags[newRef]="[]"
			end
		else
			system.print("Duplicate entry for location ignored: "..locationTable[i][1])
		end
	end
	saveSavedLocations(name, planetname, atmosphere, gravity, posX, posY, posZ,tags)
	--system.print("Default SatNav locations loaded")
end

function loadHudLocations()
	local atmosphere, gravity, planetname, posX, posY, posZ, name, tags     = extractSatNavValues()
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
			tags[newRef]="[]"			
		else
			system.print("Duplicate entry for location ignored: "..hudname[i])
		end
	end
	saveSavedLocations(name, planetname, atmosphere, gravity, posX, posY, posZ,tags)
end


function newLocation (xnewLocName, newLocPos)
	local location
	if xnewLocName and newLocPos then
		location = newLocPos
	else
		location = system.getWaypointFromPlayerPos()
	end
	  
	local newLocName
	if xnewLocName then
		newLocName = xnewLocName
	else
		local newLocId = myDatabank.getIntValue("lastNewLoc") + 1
		myDatabank.setIntValue("lastNewLoc",newLocId)
		newLocName = defaultNewLocName.." ("..newLocId..")"
	end
	
	local num        = ' *([+-]?%d+%.?%d*e?[+-]?%d*)'
	local posPattern = '::pos{' .. num .. ',' .. num .. ',' ..  num .. ',' ..
				   num ..  ',' .. num .. '}'
	
	local atmosphere, gravity, planetname, posX, posY, posZ, name, tags     = extractSatNavValues()
	local systemId, bodyId, latitude, longitude, altitude =
								 string.match(location, posPattern)
	local worldPos = core.getConstructWorldPos()
	local body = helios:closestBody(worldPos)

	newlocAlt = ((vec3(worldPos)-vec3(body.center)):len())/(1000)
	if newlocAlt < (((body.radius)/1000) + 200) then
		local bodyId = getBodyId(body.name)
		local planet = helios[tonumber(bodyId)]          -- PlanetaryReference.BodyParameters instance
		local worldCoords = planet:convertToWorldCoordinates(location)
		newRef = #name + 1
		name[newRef]=newLocName
		posX[newRef]=worldCoords["x"]
		posY[newRef]=worldCoords["y"]
		posZ[newRef]=worldCoords["z"]
		gravity[newRef]=( core.g() or 0 )
		atmosphere[newRef]=( unit.getAtmosphereDensity() or 0 )
		planetname[newRef]=body.name
	else
		newRef = #name + 1
		name[newRef]=newLocName
		posX[newRef]=latitude
		posY[newRef]=longitude
		posZ[newRef]=altitude
		gravity[newRef]=0
		atmosphere[newRef]=0
		planetname[newRef]="Space"

	end
	tags[newRef]="[]"
	saveSavedLocations(name, planetname, atmosphere, gravity, posX, posY, posZ,tags)
	system.print("New location: "..newLocName.." added to SatNav databank")
	printLocMapPos(newLocName)
end

function copySelectedToHud (locationName)
	
	local locName, locplanetname, locatmosphere, locgravity, locX, locY, locZ = 
		printLocMapPos(locationName)
	if HUD == "Dimencia" then
		savedLocation = dbHud.getStringValue("SavedLocations")
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
		if locplanetname ~= "" and locationName ~= isPlanet then
				newSavedLocations = newSavedLocations..
							"{"..[["name":"]].."SatNav Location"..
								 [[","planetname":"]]..locplanetname..[["]]..
								 [[,"atmosphere":]]..locatmosphere..
								 [[,"gravity":]]..locgravity..
								 [[,"position":{"x":]]..locX..
								 [[,"y":]]..locY..
								 [[,"z":]]..locZ..[[}}]]
			dbHud.setStringValue("SPBAutopilotTargetName","SatNav Location")
		else
			dbHud.setStringValue("SPBAutopilotTargetName",isPlanet)
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

function backupSatnavDB()
	local satnavLocation = myDatabank.getStringValue(SatNavDBLocs)
	local lastNewLoc = myDatabank.getIntValue("lastNewLoc")
	if dupSatnavDB then
		dupSatnavDB.clear()
		dupSatnavDB.setStringValue(SatNavDBLocs,satnavLocation)
		dupSatnavDB.setIntValue("lastNewLoc",lastNewLoc)
		system.print("SatNav Databank Backup Successfully")
	else
		system.print("No backup databank linked, backup aborted")
	end
end

function restoreSatnavDB()
	if dupSatnavDB then
		local satnavLocation = dupSatnavDB.getStringValue(SatNavDBLocs)
		local lastNewLoc = dupSatnavDB.getIntValue("lastNewLoc")
		if not(satnavLocation == nil) then
			myDatabank.clear()
			myDatabank.setStringValue(SatNavDBLocs,satnavLocation)
			myDatabank.setIntValue("lastNewLoc",lastNewLoc)
			system.print("SatNav Databank Restored Successfully")
		else
			system.print("Databank does not contain backup, restore aborted")
		end
	else
		system.print("No backup databank linked, restore aborted")
	end
end

function toggleTag (locName, tag)
	if locName == isPlanet then system.print("Cannot add tag to dummy planet location entry") return end
	if not(locName == nil) then
		local oldLocFound = false
		local atmosphere, gravity, planetname, posX, posY, posZ, name, tags     = extractSatNavValues()
		for i = 1, #name do
			if name[i] == locName then
				oldLocFound = true
				if tags[i] == nil then
					tags[i]="["..tag.."]"
				elseif not(string.find(tags[i],tag)==nil) then
					tags[i] = string.gsub(tags[i],tag,"")
				elseif string.len(tags[i])>5 then
					system.print("Maximum of 4 tags per location")
				else
					tags[i]=string.gsub(tags[i],"]",tag.."]")
				end
				locTagList[locName]=tags[i]
				break
			end
		end
		
		if oldLocFound then   
			saveSavedLocations(name, planetname, atmosphere, gravity, posX, posY, posZ, tags)
		end
	end
end

buildPlanetList()
buildPlanetLocList(lastPlanetSelected)
local planetCount=#planetList

function refreshDisplay()
	if displayPlanetList[1] ~= "" then
				lastPlanetSelected = displayPlanetList[1]
				lastLocationSelected = ""
				buildPlanetLocList(lastPlanetSelected)
				clearLocDispList()
				selected = ""
				CurrentLocationPage=1
				CurrentPlanetPage=1
	end
end
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
	for k, v in pairs(clickAreas) do
		if v.id == candidate then
			clickAreas[k] = newEntry
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
	AddClickArea({id = "NewLocation", x1 = 300, x2 = 700, y1 = 900, y2 = 1000})
	AddClickArea({id = "UpdateLocation", x1 = 800, x2 = 1200, y1 = 900, y2 = 1000})
	AddClickArea({id = "DeleteLocation", x1 = 1300, x2 = 1700, y1 = 900, y2 = 1000})
	AddClickArea({id = "ClearHudLocations", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
	AddClickArea({id = "PlanetPageDown", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
	AddClickArea({id = "PlanetPageUp", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
	AddClickArea({id = "LocationPageDown", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
	AddClickArea({id = "LocationPageUp", x1 = -1, x2 = -1, y1 = -1, y2 = -1})
	
	AddClickArea({id = "MarketTag", x1 = 1400, x2 = 1460, y1 = 100, y2 = 160})
	AddClickArea({id = "MineTag", x1 = 1500, x2 = 1560, y1 = 100, y2 = 160})
	AddClickArea({id = "CrashTag", x1 = 1600, x2 = 1660, y1 = 100, y2 = 160})
	AddClickArea({id = "BaseTag", x1 = 1700, x2 = 1760, y1 = 100, y2 = 160})
	AddClickArea({id = "FavouriteTag", x1 = 1800, x2 = 1860, y1 = 100, y2 = 160})
	
	AddClickArea({id = "PlanetFilter", x1 = 720, x2 = 830, y1 = 150, y2 = 240})
	AddClickArea({id = "MarketFilter", x1 = 720, x2 = 830, y1 = 250, y2 = 340})
	AddClickArea({id = "MineFilter", x1 = 720, x2 = 830, y1 = 350, y2 = 440})
	AddClickArea({id = "CrashFilter", x1 = 720, x2 = 830, y1 = 450, y2 = 540})
	AddClickArea({id = "BaseFilter", x1 = 720, x2 = 830, y1 = 550, y2 = 640})
	AddClickArea({id = "FavouriteFilter", x1 = 720, x2 = 830, y1 = 650, y2 = 740})
	
	AddClickArea({id = "SortOrder", x1 = 720, x2 = 830, y1 = 800, y2 = 900})
	
	for i = 1, pageLines do
		AddClickArea({id = string.format("PList%d",i), x1 = 90, x2 = 700, y1 = (170 + i * 55), y2 = (225 + i * 55)})
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
 
	if HitTarget == "PlanetPageDown" then
		CurrentPlanetPage = CurrentPlanetPage+1
	elseif HitTarget == "PlanetPageUp" then
		CurrentPlanetPage = math.max(CurrentPlanetPage-1,0)
	elseif HitTarget == "LocationPageDown" then
		CurrentLocationPage = CurrentLocationPage+1
	elseif HitTarget == "LocationPageUp" then
		CurrentLocationPage = math.max(CurrentLocationPage-1,0)
	elseif HitTarget == "MarketTag" then
		toggleTag(lastLocationSelected,"m")
	elseif HitTarget == "MineTag" then
		toggleTag(lastLocationSelected,"q")
	elseif HitTarget == "CrashTag" then
		toggleTag(lastLocationSelected,"c")
	elseif HitTarget == "BaseTag" then
		toggleTag(lastLocationSelected,"b")
	elseif HitTarget == "FavouriteTag" then
		toggleTag(lastLocationSelected,"f")
	elseif HitTarget == "PlanetFilter" then
		currentFilter = "PlanetFilter"
		buildPlanetLocList(lastPlanetSelected)
		myDatabank.setStringValue("currentFilter",currentFilter)
		CurrentLocationPage=1
	elseif HitTarget == "MarketFilter" then
		currentFilter = "MarketFilter"
		buildPlanetLocList(lastPlanetSelected)
		myDatabank.setStringValue("currentFilter",currentFilter)
		CurrentLocationPage=1
	elseif HitTarget == "MineFilter" then
		currentFilter = "MineFilter"
		buildPlanetLocList(lastPlanetSelected)
		myDatabank.setStringValue("currentFilter",currentFilter)
		CurrentLocationPage=1
	elseif HitTarget == "CrashFilter" then
		currentFilter = "CrashFilter"
		buildPlanetLocList(lastPlanetSelected)
		myDatabank.setStringValue("currentFilter",currentFilter)
		CurrentLocationPage=1
	elseif HitTarget == "BaseFilter" then
		currentFilter = "BaseFilter"
		buildPlanetLocList(lastPlanetSelected)
		myDatabank.setStringValue("currentFilter",currentFilter)
		CurrentLocationPage=1
	elseif HitTarget == "FavouriteFilter" then
		currentFilter = "FavouriteFilter"
		buildPlanetLocList(lastPlanetSelected)
		myDatabank.setStringValue("currentFilter",currentFilter)
		CurrentLocationPage=1
	elseif HitTarget == "LoadSatNavLocations" then
		loadPointsOfInterest()
		refreshDisplay()
	elseif HitTarget == "LoadHudLocations" then
		loadHudLocations()
		refreshDisplay()
	elseif HitTarget == "ClearSatNavLocations" then
		system.print("ClearSavedLocations")
		clearSavedLocations()
		refreshDisplay()
	elseif HitTarget == "ClearHudLocations" then
		clearHudLocations()
	elseif HitTarget == "NewLocation" then
		system.print("NewLocation")
		newLocation()
		refreshDisplay()
	elseif HitTarget == "UpdateLocation" then
		system.print("UpdateLocation")
		updateLocationName(lastLocationSelected,nil)
		refreshDisplay()
	elseif HitTarget == "DeleteLocation" then
		system.print("DeleteLocation")
		deleteLocationName(lastLocationSelected)
		refreshDisplay()
	elseif HitTarget == "SortOrder" then
		if sortOrder=="az" then sortOrder = "km" else sortOrder="az" end
		buildPlanetList()
		refreshDisplay()
	else
			for i = 1,pageLines do
				if HitTarget == string.format("PList%s",i) then
					if displayPlanetList[i] ~= "" then
						lastPlanetSelected = displayPlanetList[i]
						currentFilter = "PlanetFilter"
						buildPlanetLocList(lastPlanetSelected)
						clearLocDispList()
						selected = ""
						lastLocationSelected = ""
						CurrentLocationPage=1
						myDatabank.setStringValue("lastPlanetSelected",lastPlanetSelected)
						myDatabank.setStringValue("currentFilter",currentFilter)
					end
				end
				if HitTarget == string.format("LList%s",i) then
					if displayLocationList[i] ~= "" then
						selected = displayLocationList[i]
						if HUD == "Dimencia" then
							copySelectedToHud(selected)
						else
							printLocMapPos(selected)
						end
						lastLocationSelected = selected
						selected = ""
					end
				end
			end
	end
	DrawPlanetList()
end

-----------------------------------------------
-- Code for building screen content and displaying it
-----------------------------------------------

local svgBootstrap = [[<svg class="bootstrap" viewBox="0 0 1920 1120" width="1920" 
				height="1120" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
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
					  .fmstartg { font-size: 30px; text-anchor: start; fill: ]]..MainFontColor..[[;}
					  .fmstartp { font-size: 40px; text-anchor: start; fill:]]..PlanetBackgroundColor..[[;}
					  .fmstartl { font-size: 40px; text-anchor: start; fill:]]..LocationBackgroundColor..[[;}
					  .fmstarty { font-size: 40px; text-anchor: start; fill: #aaaa00;}
					  .fmstartb { font-size: 40px; text-anchor: end; fill: black;}
					  .fmstartr { font-size: 40px; text-anchor: end; fill: #ff0000;}
					  .fmmiddle { font-size: 30px; text-anchor: middle; fill: ]]..MainFontColor..[[;}
					  .fmmiddles { font-size: 20px; text-anchor: middle; fill: ]]..MainFontColor..[[;}
					  .fmmiddleb { font-size: 30px; text-anchor: middle; fill: ]]..MainFontColor..[[;}
					  .fmmiddler { font-size: 30px; text-anchor: middle; fill: red;}
					  .fmend { font-size: 25px; text-anchor: end; fill: ]]..MainFontColor..[[;}
				</style></defs>]]

function DrawPlanetList()

	local screenOutput = ""

		-- Draw Header
	screenOutput = screenOutput .. svgBootstrap

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
					   [[<rect x="70" y="150" rx="10" ry="10" width="620" height="]] ..
					   ((pageLines + 1) * 55) ..
					   [[" style="fill:]].. PlanetBackgroundColor .. [[;stroke:#ffff00;stroke-width:3;" />]]
	screenOutput = screenOutput ..
					   [[<rect x="80" y="160" rx="5" ry="5" width="600" height="40" style="fill:#33331a;" />]]      
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
					   [[" width="620" height="55"]] ..
					   [[" style="fill:]].. HighlightColor .. [[;" />]]
			end

			screenOutput = screenOutput .. [[<text x="90" y="]] ..
								   (180 + i * 55) .. [[" class="fmstartg">]] .. planetName ..  
									[[</text>]]
			if planetName ~= "Space" then
			screenOutput = screenOutput .. [[<text x="675" y="]] ..
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
					   [[<rect x="870" y="150" rx="10" ry="10" width="1020" height="]] ..
					   ((pageLines + 1) * 55) ..
					   [[" style="fill:]]..
					   LocationBackgroundColor..
					   [[;stroke:#ffff00;stroke-width:3;" />]]
	screenOutput = screenOutput ..
					   [[<rect x="880" y="160" rx="5" ry="5" width="1000" height="40" style="fill:#33331a;" />]]
	if currentFilter == "PlanetFilter" then
		locHeaderText = lastPlanetSelected .." Locations"
	else
		locHeaderText = currentFilter.." Locations"
	end
		screenOutput = screenOutput ..
					   [[<text x="890" y="191" class="fcapstart">]].. locHeaderText ..[[</text>]]
		   
	local i = 0
	for j = 1 + (CurrentLocationPage - 1) * pageLines, pageLines +
				(CurrentLocationPage - 1) * pageLines, 1 do
		
		i = i + 1
		if j <= #locList and j>0 then
			if lastLocationSelected == locList[j] then
				screenOutput = screenOutput ..
					   [[<rect x="880" y="]]..(140 + i * 55) .. 
					   [[" width="1000" height="55"]] ..
					   [[" style="fill:]].. HighlightColor .. [[;" />]]
			end
			screenOutput = screenOutput .. [[<text x="1090" y="]] ..
								   (180 + i * 55) .. [[" class="fmstartg">]] .. locList[j] ..  
									[[</text>]]
			displayLocationList[i]=locList[j]
			screenOutput = screenOutput .. [[<text x="1875" y="]] ..
								   (180 + i * 55) .. [[" class="fmend">]] .. locDistList[locList[j]] ..    
								   [[</text>]] 
			local tagIndent=884
			if not(locTagList[locList[j]]==nil) and not(string.find(locTagList[locList[j]],"m")==nil) then
				screenOutput = screenOutput .. [[<svg x="]]..(tagIndent)..[[" y="]]..(142 + i * 55) .. 
					[["><rect width="50" height="50" style="fill:]]..marketIconColour..
					[[;" /><image x="10" y="10" width="30" height="30" ]]..pngMarketIcon..[[/></svg>]]
				tagIndent=tagIndent+50
			end
			if not(locTagList[locList[j]]==nil) and not(string.find(locTagList[locList[j]],"q")==nil) then
				screenOutput = screenOutput .. [[<svg x="]]..(tagIndent)..[[" y="]]..(142 + i * 55) .. 
					[["><rect width="50" height="50" style="fill:]]..mineIconColour..
					[[;" /><image x="10" y="10" width="30" height="30" ]]..pngMineIcon..[[/></svg>]]
				tagIndent=tagIndent+50
			end
			if not(locTagList[locList[j]]==nil) and not(string.find(locTagList[locList[j]],"c")==nil) then
				screenOutput = screenOutput .. [[<svg x="]]..(tagIndent)..[[" y="]]..(142 + i * 55) .. 
					[["><rect width="50" height="50" style="fill:]]..crashIconColour..
					[[;" /><image x="10" y="10" width="30" height="30" ]]..pngCrashIcon..[[/></svg>]]
				tagIndent=tagIndent+50
			end
			if not(locTagList[locList[j]]==nil) and not(string.find(locTagList[locList[j]],"b")==nil) then
				screenOutput = screenOutput .. [[<svg x="]]..(tagIndent)..[[" y="]]..(142 + i * 55) .. 
					[["><rect width="50" height="50" style="fill:]]..baseIconColour..[[;" />
					</svg>]]
				tagIndent=tagIndent+50
			end
			if not(locTagList[locList[j]]==nil) and not(string.find(locTagList[locList[j]],"f")==nil) then
				screenOutput = screenOutput .. [[<svg x="]]..(tagIndent)..[[" y="]]..(142 + i * 55) .. 
					[["><rect width="50" height="50" style="fill:]]..favouriteIconColour..[[;" />
					</svg>]]
				tagIndent=tagIndent+50
			end
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
							   [[<rect x="300" y="900" rx="10" ry="10" width="400" height="60" style="fill:]]..buttonColour..[[;" />]] ..
							   [[<text x="500" y="940" class="fmmiddle">Save Current Location</text>]]

	screenOutput = screenOutput ..
							   [[<rect x="800" y="900" rx="10" ry="10" width="400" height="60" style="fill:]]..buttonColour..[[;" />]] ..
							   [[<text x="1000" y="940" class="fmmiddle">Update Location</text>]]

	screenOutput = screenOutput ..
							   [[<rect x="1300" y="900" rx="10" ry="10" width="400" height="60" style="fill:]]..buttonColour..[[;" />]] ..
							   [[<text x="1500" y="940" class="fmmiddle">Delete Location</text>]]
							   
--	screenOutput = screenOutput .. [[<text x="880" y="115" class="fmstartl">Toggle Location Tags -- </text>]]
--	screenOutput = screenOutput .. [[<text x="700" y="200" class="fmstartl">Filters</text>]]

	screenOutput = screenOutput .. [[<svg x="1400" y="70" >
						<rect width="60" height="60" style="fill:]]..marketIconColour..
					[[;" /><image x="10" y="10" width="40" height="40" ]]..pngMarketIcon..[[/></svg>]]
	screenOutput = screenOutput .. [[<svg x="1500" y="70" >
						<rect width="60" height="60" style="fill:]]..mineIconColour..
					[[;" /><image x="10" y="10" width="40" height="40" ]]..pngMineIcon..[[/></svg>]]
	screenOutput = screenOutput .. [[<svg x="1600" y="70" >
						<rect width="60" height="60" style="fill:]]..crashIconColour..
					[[;" /><image x="10" y="10" width="40" height="40" ]]..pngCrashIcon..[[/></svg>]]
	screenOutput = screenOutput .. [[<svg x="1700" y="70" >
						<rect width="60" height="60" style="fill:]]..baseIconColour..[[;" />
						</svg>]]
	screenOutput = screenOutput .. [[<svg x="1800" y="70" >
						<rect width="60" height="60" style="fill:]]..favouriteIconColour..[[;" />
						</svg>]]


	screenOutput = screenOutput .. [[<svg x="720" y="140" >]]
	if currentFilter == "PlanetFilter" then
						screenOutput = screenOutput .. [[<rect width="95" height="95" style="fill:]]..planetIconColour..[[;" />]]
	end
	screenOutput = screenOutput .. [[<image width="75" height="75" x="10" y="10" ]]..pngPlanetIcon..[[/></svg>]]

	screenOutput = screenOutput .. [[<svg x="720" y="240" >]]
	if currentFilter == "MarketFilter" then
						screenOutput = screenOutput .. [[<rect width="95" height="95" style="fill:]]..marketIconColour..[[;" />]]
	end
	screenOutput = screenOutput .. [[<image width="75" height="75" x="10" y="10" ]]..pngMarketIcon..[[/></svg>]]
	
	screenOutput = screenOutput .. [[<svg x="720" y="340" >]]
	if currentFilter == "MineFilter" then
						screenOutput = screenOutput .. [[<rect width="95" height="95" style="fill:]]..mineIconColour..[[;" />]]
	end
	screenOutput = screenOutput .. [[<image width="75" height="75" x="10" y="10" ]]..pngMineIcon..[[/></svg>]]
	
	screenOutput = screenOutput .. [[<svg x="720" y="440" >]]
	if currentFilter == "CrashFilter" then
						screenOutput = screenOutput .. [[<rect width="95" height="95" style="fill:]]..crashIconColour..[[;" />]]
	end
	screenOutput = screenOutput .. [[<image width="75" height="75" x="10" y="10" ]]..pngCrashIcon..[[/></svg>]]
	
	screenOutput = screenOutput .. [[<svg x="720" y="540" >]]
	if currentFilter == "BaseFilter" then
						screenOutput = screenOutput .. [[<rect width="95" height="95" style="fill:]]..baseIconColour..[[;" />]]
	end
	screenOutput = screenOutput .. [[<rect width="75" height="75" x="10" y="10" style="fill:]]..baseIconColour..[[;" />
						</svg>]]
	screenOutput = screenOutput .. [[<svg x="720" y="640" >]]
	if currentFilter == "FavouriteFilter" then
						screenOutput = screenOutput .. [[<rect width="95" height="95" style="fill:]]..favouriteIconColour..[[;" />]]
	end
	screenOutput = screenOutput .. [[<rect width="75" height="75" x="10" y="10" style="fill:]]..favouriteIconColour..[[;" />
						</svg>]]
						
	screenOutput = screenOutput .. [[<svg x="720" y="790" >]]
	screenOutput = screenOutput .. [[<rect width="75" height="75" x="10" y="10" style="fill:]]..buttonColour..[[;" />
						<text x="45" y="30" class="fmmiddles">(sort)</text>
						<text x="45" y="60" class="fmmiddle">]]..sortOrder..[[</text>
						</svg>]]

	DrawSVG(screenOutput)

--	forceRedraw = false
end

-----------------------------------------------
-- Execute
-----------------------------------------------

unit.hide()
dbUpdate()
InitiateClickAreas()

lastPlanetSelected = myDatabank.getStringValue("lastPlanetSelected")
if lastPlanetSelected == "" then lastPlanetSelected = "Alioth" end
currentFilter = myDatabank.getStringValue("currentFilter")
if currentFilter == "" then currentFilter = "PlanetFilter" end
sortOrder = myDatabank.getStringValue("sortOrder")
if sortOrder == "" then sortOrder = "az" end

buildPlanetLocList(lastPlanetSelected)
DrawPlanetList()
system.print("Running")
unit.setTimer("loadwp",1)
