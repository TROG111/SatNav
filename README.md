# Introduction
Welcome to Trog's SatNav for Dual Universe.  This is a location/bookmark manager for :pos(.....) locations which includes integration into the Dimecia Hud to enable autopiloting to your stored locations.  SatNav can be used in stand alone mode or as integrated into the Dimencia Hud.  These instructions have been updated for SatNav version 2_1_2.  To install a previous version please contact me directly.

# Installation:
1) Ensure that you have the following libraries installed in your DU <ProgramData> (the directory on your local drive in which you installed DU) LUA folder:

    <ProgrmData>/DualUniverse/Game/data/lua/cpml/vec3.lua
    
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/utils.lua
    
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/planetref.lua
    
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/atlas.lua
    
    planetref.lua and atlas.lua can be obtained from the following GitLab url: https://gitlab.com/JayleBreak/dualuniverse/-/blob/master/DUflightfiles/autoconf/custom/atlas.lua and https://gitlab.com/JayleBreak/dualuniverse/-/blob/master/DUflightfiles/autoconf/custom/planetref.lua.  On the GitLab pages, click the download button and when prompted for a filename, make sure that the filename is only atlas.lua and planetref.lua and not the given long name.
 
 2) Install a PB onto your ship and link it to: 1) the core, 2) a screen, 3) a new (empty) databank (we shall call this the SatNav databank), 4) Dimencia Hud databank - IN THIS ORDER PLEASE.  The SatNav databank should be either completely empty (remove dynamic content while the databank is in you inventory before placing it) or a SatNav databank from version 2_1_0 or 2_1_1.
 
 3) Copy the most recent SatNav_PB_Paste file (currently that is SatNav_PB_Paste_2_1_2) into you copy paste buffer
 
 4) In game, right click on your SatNav PB and select 'Advanced' / 'Paste LUA configuration from cliboard'
 
 5) Turn on screen, activate PB and you are ready to go.... good luck!
 
 # Integration with Dimencia Hud:
 1) ensure you have a recent version of the Dimencia Hud already loaded and configured on your pilot seat.  Version 2_1_0 requires its own databank and you should not try to use the Dimencia Hud databank for both 3 and 4 (in the installation), this will likely cause problems and so is not supported.
 
 2) edit the LUA in your pilot seat that has the Dimencia Hud installed
 
 3) create a new unit.start trigger and insert the following LUA code:
    
        unit.setTimer("spbTimer",5)
        
        myAutopilotTarget=""
        
      
 4) create a new unit.tick(spbTimer) trigger and insert the following LUA code
    
    ```myAutopilotTarget = dbHud.getStringValue("SPBAutopilotTargetName")
    if myAutopilotTarget ~= nil and myAutopilotTarget ~= "" and myAutopilotTarget ~= "SatNavNotChanged" then
        local result = json.decode(dbHud.getStringValue("SavedLocations"))
        if result ~= nil then
        _G["SavedLocations"] = result        
        local index = -1        
        local newLocation        
        for k, v in pairs(SavedLocations) do        
            if v.name and v.name == "SatNav Location" then                   
                index = k                
                break                
            end            
        end        
        if index ~= -1 then       
            newLocation = SavedLocations[index]            
            index = -1            
            for k, v in pairs(atlas[0]) do           
                if v.name and v.name == "SatNav Location" then               
                    index = k                    
                    break                  
                end                
            end            
            if index > -1 then           
                atlas[0][index] = newLocation                
            end            
            UpdateAtlasLocationsList()           
            MsgText = newLocation.name .. " position updated"            
        end       
    end
    
    for i=1,#AtlasOrdered do    
        if AtlasOrdered[i].name == myAutopilotTarget then
            AutopilotTargetIndex = i
            system.print("Index = "..AutopilotTargetIndex.." "..AtlasOrdered[i].name)          
            UpdateAutopilotTarget()
            dbHud.setStringValue("SPBAutopilotTargetName", "SatNavNotChanged")            
        end     
    end
`end


    
 
 # Usaged:
 1) By default the PB is programmed with a selection of locations including the market places on Alioth.  These will be automatically loaded into your SatNav databank the first time that you use the application.
 
 2) The lefthand (light blue) panel of the SatNav lists all the DU planets.  You can page up/down this list using the correspondingly coloured arrow buttons below the table.  Clicking on a specific planet will display the list of Stored Locations for than planet in the righthand (purple) panel.
 
 3) You can page up/down the list of Stored Locations using the correspondingly coloured (purple) arrow buttons below the table.  Clicking on a specific location will print the locations coordinates into the LUA chat and will set your destination to that location.  In addition, and if you have integrated with Dimencia Hud, the selected location will be sent to your pilot seat ready for use the next time you engage autopilot in the Hud.  It is also possible to use SatNav while remaining seated in the Pilot Seat and the selected location will be sent to your running Dimencia Hud.
 
 4) If you wish to add a new location to the SatNav databank this can be done in a couple of ways:
 
    a) you can add new locations one at a time by pressing the 'Save Current Location' button which will create a new entry named 'SatNav Location (nnn)'.
    
    b) you can edit the initial default locations in the Programming Board and add new entries (this is best used for bulk entry).  Open the PB for LUA editing and access the code in the unit.tick(loadwp) trigger.  Then simply edit or add new entries to this table.  Once you have the new exntries in the table execute the 'l SatNav' command below (5e) to relad the table.
    
 5) With the latest DU patch, SatNav now has a command line capability this provides the following function by typing into the LUA Chat panel:
 
    a) 'u newLocationName' - you can amend th name of a SatNav location by selecting it from the on screen location list, then typing 'u ' followed by the ew name for that location
    
    b) 'd SatNav' - this command will delete the currently selected location from the database - use with care ;-)
    
    c) 'c SatNav' - this will clear the SatNav databank of all stored locations
    
    d) 'c Hud' - this will clear all Saved Locations from the Dimencia Hud databank (use with care!)
    
    e) 'l SatNav' - this will reload all of the default location from the SatNav PB (including any new ones that you may have added in step 4b above
    
    f) 'l Hud' - this will copy all of the Dimencia Hud stored locations from the Hud's databank into the SatNav databank
    
    g) 'x SatNav' - this command will duplicate/clone the SatNav databank if an additional empty databank has been linked to the PB in slot 5.  The purpose of this feature is to enable users to copy their locations to multiple ships.
 
  5) When using your Dimencia Hud, you will find that the location you loaded in 3 (above) ha been renamed as 'SatNav Location' and is now available using the Alt+1/Alt+2 keys..  This will also have been set as the destination on the Dim Hud buttons screen.  Unlike previous versions of SatNav, we now only copy across a single location to Dim Hud - this is due to a limitation in the Dim Hud which would cause a cpu overload error if we copied all of the SatNav locations across.
 
 # Known issues:
 
 The order of linking the core/screen/databanks is extremely important.  They should always be: 1) core, 2) screen, 3) satnav databank, 4) Dimencia Hud databank, 5) satanav databank copy (used in the x SatNav command only).
 
 Some users are struggling to locate the DU LUA library folder on their local drives.  This is located below the directory that you originally installed DU.
 
 Some users are struggling to download the planetref.lua and atlas.lua libraries.  These two files can be found in the GitLab URL link provided above, they must be copied in their entirity into the DU Lua library folder.  You can check them once you have downloaded by opening the lua files and seeing that they contain the appropriate LUA code.
 
 I have recently experience a problem with DimHud linking to the incorrect databank when I did a clean new DimHud configuration.  The outcome of this is that it may corrupt the content of the SatNav databank (for example if DimHud has linked to the SatNav databank).  Therefore, the following is my recommendation:
 a) before you do a DimHud update, always back up your SatNav databank (using the 'x SatNav' command described above) and then remove the backup copy into your inventory; b) immediately after doing a DimHud update, check the databank that is linked to the DimHud pilot seat.  If it is the incorrect databank, then remove the link and manually link to the correct DimHud databank - do this BEFORE activating DimHud for the first time after the update.
 
 # Version history:
 
 2_0_0 - Released version
 
 2_0_1 - pre-release version, use at your own risk.  Update includes location/planet distances and warp cell estimates.  verification of connection to Dimencia Hud.
 
 2_0_2 - a few bug fixes and enhancements
 
 2_1_0 - updated to avoid cpu overload problems and utilise the new setWaypoint and inputText features of DU 0.23
 
 2_1_1 - update includes: 1) attempt to try and avoid installation issues with linking databanks in wrong order; 2) added fix for new Space locations which were always being assigned to planets instead of 'Space'; 3) a few bug fixes
 
 2_1_2 - update includes: 1) improved avoidance of databank linking issues during installation; 3) improved readability of screens: a) highlighting of selected planets/location is now shown by a bar rather than a font colour change; b) 4 LUA parameters have been added to allow users to change the colours for Planet Panel Backgroun; Location Panel Background; Panel font colour; and highlight bar colour.
