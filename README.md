
Welcome to Trog's SatNav for Dual Universe.  This is a location/bookmark manager for :pos(.....) locations which includes integration into the Dimecia Hud to enable autopiloting to your stored locations.  SatNav can be used in stand alone mode or as integrated into the Dimencia Hud.

###Installation:
1) Ensure that you have the following libraries installed in your DU ProgramData LUA folder:
    <ProgrmData>/DualUniverse/Game/data/lua/dkjson.lua
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/vec3.lua
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/utils.lua
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/planetref.lua
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/atlas.lua
    
    planetref.lua and atlas.lua can be obtained from the following GitLab url:  https://gitlab.com/JayleBreak/dualuniverse/-/tree/master/DUflightfiles/autoconf/custom
    
 2) Install a PB onto your ship and link it to: 1) the core, 2) a screen, 3) a databank - in this order please.  If you have Dimencia Hud installed in your Pilot Seat, then the databank in 3 should be the databank that is connected to the pilot seat.
 
 3) Copy the most recent SatNav_PB_Paste file (currently that is SatNav_PB_Paste_2_0_0) into you copy paste buffer
 
 4) In game, right click on your SatNav PB and select 'Advanced' / 'Paste LUA configuration from cliboard'
 
 5) Turn on screen, activate PB and you are ready to go.... good luck!
 
 ###Integration with Dimencia Hud:
 1) ensure you have a recent version of the Dimencia Hud already loaded and configured on your pilot seat
 
 2) edit the LUA in your pilot seat that has the Dimencia Hud installed
 
 3) create a new unit.start trigger and insert the following LUA code:
     unit.setTimer("spbTimer",5)
     firstTime = 1
     
 4) create a new unit.tick(spbTimer) trigger and insert the following LUA code
     if firstTime == 1 then
         myAutopilotTarget = dbHud.getStringValue("SPBAutopilotTargetName")
         if myAutopilotTarget ~= nil and myAutopilotTarget ~= "" then
             for i=1,#AtlasOrdered do
                if AtlasOrdered[i].name == myAutopilotTarget then
                    AutopilotTargetIndex = i
                    UpdateAutopilotTarget()
                end
             end
        end
        firstTime = 0
    end
 
 ###Usaged:
 1) By default the PB is programmed with a selection of locations including the market places on Alioth.  To add/edit/delect locations you will need to edit the system.start LUA code on your programming board.  This is relatively simple, open the system.start section of the LUA code on your PB and add/amend an entry in the table.  You can obtain ::pos(....) coordinates by simply cut/paste from the DUA map functions in game.
 
 2) The lefthand (light blue) panel of the SatNav lists all the DU planets.  You can page up/down this list using the correspondingly coloured arrow buttons below the table.  Clicking on a specific planet will display the list of Stored Locations for than planet in the righthand (purple) panel.
 
 3) You can page up/down the list of Stored Locations using the correspondingly coloured (purple) arrow buttons below the table.  Clicking on a specific location will print the locations coordinates into the LUA chat in a form that you can right click and set as your destination.  In addition, and if you have integrated with Dimencia Hud, the selected location will be sent to your pilot seat ready for use the next time you engage autopilot in the Hud.
 
 4) When you switch on the PB it will pull the list of Stored Locations from the attached databank - initially this may be empty if you have not already defined any Stored Locations using the Dimencia Hud 'Store Location' function.  In order to load the list of default stored locations (from 1 above) into the databank you must click on the SatNav 'Load Saved Locations' button.
 
 5) If you wish to remove the 'old' list of stored locations from your databank, click on the SatNav 'Clear Saved Locations' button.
 
 6) When using your Dimencia Hud, you will find that the stored locations you loaded in 3 (above) are available using the Alt+1/Alt+2 keys..  However, since Dim Hud only loads its stored locations when it starts up, you will need to operate the SatNav application while you are not sitting in the pilot seat.
 
 ###Known issues:
 
 1) if the SatNav app crashes the first time that you try to use it to load the default locations provided, this is sometimes caused by either you have linked the core, screen, databank in the wrong order, or the databank you are using has not been correctly configured by Dimencia Hud (or you are in stand alone mode).  Sometimes this can be fixd by pressing the on screen Clear Stored Locations button.
 
 ###Version history:
 
 2_0_0 - Released version
 
 2_0_1 - pre-release version, use at your own risk.  Update includes location/planet distances and warp cell estimates.  verification of connection to Dimencia Hud.
