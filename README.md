# Introduction
Welcome to Trog's SatNav for Dual Universe.  This is a location/bookmark manager for :pos(.....) locations which includes integration into the Dimecia Hud to enable autopiloting to your stored locations.  SatNav can be used in stand alone mode or as integrated into the Dimencia Hud.  These instructions have been updated for SatNav version 2_1_0.  To install a previous version please contact me directly.

# Installation:
1) Ensure that you have the following libraries installed in your DU ProgramData LUA folder:

    <ProgrmData>/DualUniverse/Game/data/lua/cpml/vec3.lua
    
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/utils.lua
    
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/planetref.lua
    
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/atlas.lua
    
    planetref.lua and atlas.lua can be obtained from the following GitLab url:  https://gitlab.com/JayleBreak/dualuniverse/-/tree/master/DUflightfiles/autoconf/custom
 
 2) Install a PB onto your ship and link it to: 1) the core, 2) a screen, 3) a new databank (we shall call this the SatNav databank), 4) Dimencia Hud databank - in this order please.  
 
 3) Copy the most recent SatNav_PB_Paste file (currently that is SatNav_PB_Paste_2_1_0) into you copy paste buffer
 
 4) In game, right click on your SatNav PB and select 'Advanced' / 'Paste LUA configuration from cliboard'
 
 5) Turn on screen, activate PB and you are ready to go.... good luck!
 
 # Integration with Dimencia Hud:
 1) ensure you have a recent version of the Dimencia Hud already loaded and configured on your pilot seat
 
 2) edit the LUA in your pilot seat that has the Dimencia Hud installed
 
 3) create a new unit.start trigger and insert the following LUA code:
 
     unit.setTimer("spbTimer",5)
     
     myAutopilotTarget=""
      
 4) create a new unit.tick(spbTimer) trigger and insert the following LUA code
 
    prevAutopilotTarget = myAutopilotTarget
    
    myAutopilotTarget = dbHud.getStringValue("SPBAutopilotTargetName")
    
    if myAutopilotTarget ~= nil and myAutopilotTarget ~= "" and myAutopilotTarget ~= prevAutopilotTarget then
    
        for i=1,#AtlasOrdered do
        
            if AtlasOrdered[i].name == myAutopilotTarget then
            
                AutopilotTargetIndex = i
                
                system.print("Index = "..AutopilotTargetIndex.." "..AtlasOrdered[i].name)
                
                UpdateAutopilotTarget()
                
            end
            
        end
        
    end
    
 
 # Usaged:
 1) By default the PB is programmed with a selection of locations including the market places on Alioth.  These will be automatically loaded into your SatNav databank the first time that you use the application.
 
 2) The lefthand (light blue) panel of the SatNav lists all the DU planets.  You can page up/down this list using the correspondingly coloured arrow buttons below the table.  Clicking on a specific planet will display the list of Stored Locations for than planet in the righthand (purple) panel.
 
 3) You can page up/down the list of Stored Locations using the correspondingly coloured (purple) arrow buttons below the table.  Clicking on a specific location will print the locations coordinates into the LUA chat and will set your destination to that location.  In addition, and if you have integrated with Dimencia Hud, the selected location will be sent to your pilot seat ready for use the next time you engage autopilot in the Hud.  It is also possible to use SatNav while remaining seated in the Pilot Seat and the selected location will be sent to your running Dimencia Hud.
 
 4) If you wish to add a new location to the SatNav databank this can be done in a couple of ways:
 
    a) you can add new locations one at a time by pressing the 'Save Current Location' button which will create a new entry named 'SatNav Location (nnn)'.
    
    b) you can edit the initial default locations in the Programming Board and add new entries (this is best used for bulk entry).  Open the PB for LUA editing and access the code in the unit.tick(loadwp) trigger.  Then simply edit or add new entries to this table.
    
 5) With the latest DU patch, SatNav now has a command line capability this provides the following function by typing into the LUA Chat panel:
 
    a) 'u newLocationName' - you can amend th name of a SatNav location by selecting it from the on screen location list, then typing 'u ' followed by the ew name for that location
    
    b) 'd SatNav' - this command will delete the currently selected location from the database - use with care ;-)
    
    c) 'c SatNav' - this will clear the SatNav databank of all stored locations
    
    d) 'c Hud' - this will clear all Saved Locations from the Dimencia Hud databank
    
    e) 'l SatNav' - this will reload all of the default location from the SatNav PB (including any new ones that you may have added in step 4b above
    
    f) 'l Hud' - this will copy all of the Dimencia Hud stored locations from the Hud's databank into the SatNav databank
 
  5) When using your Dimencia Hud, you will find that the location you loaded in 3 (above) ha been renamed as 'SatNav Location' and is now available using the Alt+1/Alt+2 keys..  This will also have been set as the destination on the Dim Hud buttons screen.  Unlike previous versions of SatNav, we not only copy across a single location to Dim Hud - this is due to a limitation in the Dim Hud which would cause a cpu overload error if we copied all of the SatNav locations across.
 
 ###Known issues:
 
 
 ###Version history:
 
 2_0_0 - Released version
 
 2_0_1 - pre-release version, use at your own risk.  Update includes location/planet distances and warp cell estimates.  verification of connection to Dimencia Hud.
 
 2_0_2 - a few bug fixes and enhancements
 
 2_1_0 - updated to avoid cpu overload problems and utilise the new setWaypoint and inputText features of DU 0.23
