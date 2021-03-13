# Introduction
Welcome to Trog's SatNav for Dual Universe.  This is a location/bookmark manager for :pos(.....) locations which includes integration into the Dimecia Hud to enable autopiloting to your stored locations.  SatNav can be used in stand alone mode or as integrated into the Dimencia Hud.  These instructions have been updated for SatNav version 3_0_4.  To install a previous version please contact me directly.

Due to the 'cowboy' development behaviour of the Dimencia Hud team I will be removing all integration support for SatNav with the DimHud platform.  I will leave the existing code in place in SatNav, however, players use this code entirely at their own risk,.  I do not guarentee the consistency or quality of any data stored in the DimHud databank if you install SatNav alongside DimHud.  Neither will I provide any support for issues relating to this integration.  If you have any issues relating to SatNav and Integration with DimHud then please address these with the DimHud Team directly - from my experience over the past 6 months, the root cause of 85% of SatNav users issues were either 1) mistakes by the user during their installation of Dimencia Hud; 3) bug propogated from DimHud that affected Satav.

# Latest Version
The latest version is 3_0_4.

# Installation:
0) Before starting a SatNav update (if you have previously installed SatNav and have an active SatNav Databank) i highly recommend doing a databank backup (in case there are any issues with the update)

1) Ensure that you have the following libraries installed in your DU <ProgramData> (the directory on your local drive in which you installed DU) LUA folder:

    <ProgrmData>/DualUniverse/Game/data/lua/cpml/vec3.lua
    
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/utils.lua
    
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/planetref.lua
    
    <ProgrmData>/DualUniverse/Game/data/lua/cpml/atlas.lua
    
    planetref.lua and atlas.lua can be obtained from the following GitLab url: https://gitlab.com/JayleBreak/dualuniverse/-/blob/master/DUflightfiles/autoconf/custom/atlas.lua and https://gitlab.com/JayleBreak/dualuniverse/-/blob/master/DUflightfiles/autoconf/custom/planetref.lua.  On the GitLab pages, click the download button and when prompted for a filename, make sure that the filename is only atlas.lua and planetref.lua and not the given long name.
 
 2) Install a PB onto your ship and link it to: 1) the core, 2) a screen, 3) a new (empty) databank (we shall call this the SatNav databank), 4) Dimencia Hud databank - IN THIS ORDER PLEASE, 5) (optionally a backup databank for SatNav).  The SatNav databank should be either completely empty (remove dynamic content while the databank is in your inventory before placing it) or a SatNav databank from version 2_1_0 or above.
 
 3) Copy the most recent SatNav_PB_Paste file (see section above for the latest version number) into you copy paste buffer
 
 4) In game, right click on your SatNav PB and select 'Advanced' / 'Paste LUA configuration from cliboard'
 
 5) Turn on screen, activate PB and you are ready to go.... good luck!  If you are updating SatNav then the script will automatically update the databank to the latest version and should inform you that this has completed.
 
 # Integration with Dimencia Hud:
 1) ensure you have a recent version of the Dimencia Hud already loaded and configured on your pilot seat.  Version 2_1_0 onwards requires its own databank and you should not try to use the Dimencia Hud databank for both 3 and 4 (in the installation), this will likely cause problems and so is not supported.
 
 2) Since version 4.9.00 of Dim Hud, integration for SatNav has been built in and therefore does not require any changes to the DimHud code (as was the case with previous version)
 
 3) After installing Dimencia Hud, check which databank it has linked to and make appropriate change if necessary (i.e. if it is linked to the wrong databank)
       
 4) Face the pilot seat and right click mouse, selected Advanced/Edit Lua Parameters to edit the Dimencia Hud lua parameters.  Select the following two parameters and ensure that they are active: 1) useTheseSettings and UseSatNav.  Sit on the Dimencia Hud pilot seat and then exit the seat (this should ensure that the Dimencia Hud variables are written to the Dim Hud databank)
 
 # Usaged:
 1) By default the PB is programmed with a selection of locations including the market places on Alioth.  These will be automatically loaded into your SatNav databank the first time that you use the application.
 
 2) The lefthand (light blue) panel of the SatNav lists all the DU planets.  You can page up/down this list using the correspondingly coloured arrow buttons below the table.  Clicking on a specific planet will display the list of Stored Locations for than planet in the righthand (purple) panel.  You can also sort these by either Alphanumeric (AZ) or Distances (KM) by pressing the 'sort' button.
 
 3) You can page up/down the list of Stored Locations using the correspondingly coloured (purple) arrow buttons below the table.  Clicking on a specific location will print the locations coordinates into the LUA chat and will set your destination to that location.  In addition, and if you have integrated with Dimencia Hud, the selected location will be sent to your pilot seat ready for use the next time you engage autopilot in the Hud.  It is also possible to use SatNav while remaining seated in the Pilot Seat and the selected location will be sent to your running Dimencia Hud. You can also sort the locations by either Alphanumeric (AZ) or Distances (KM) by pressing the 'sort' button.
 
 4) If you wish to add a new location to the SatNav databank this can be done in a couple of ways:
 
    a) you can add new locations one at a time by pressing the 'Save Current Location' button which will create a new entry named 'SatNav Location (nnn)'.
    
    b) you can edit the initial default locations in the Programming Board and add new entries (this is best used for bulk entry).  Open the PB for LUA editing and access the code in the unit.tick(loadwp) trigger.  Then simply edit or add new entries to this table.  Once you have the new exntries in the table execute the 'l SatNav' command below (5e) to relad the table.
    
 5) If you wish to change the coordinates of a SatNav location you can do this one at a time by pressing the 'Update Location' button which will change the coordinates for the selected location to those of the players current position'
    
 6) With the latest DU patch, SatNav now has a command line capability this provides the following function by typing into the LUA Chat panel:
 
    a) 'u <newLocationName> ::pos{<a>,<b>,<c>,<d>,<e>}' - you can amend the name of a SatNav location by selecting it from the on screen location list, then typing 'u ' followed by the new name for that location <newLocationName>. n.b. the new location name in <newLocationName> must be enclosed in single quotes (e.g. 'My New Location') and can contain spaces and other alphanumeric characters.  You can also, optionally, change the coordinates for the location at the same time by providing a ::pos{<a>,<b>,<c>,<d>,<e>} string.
    
    b) 'd SatNav' - this command will delete the currently selected location from the database - use with care ;-)
    
    c) 'c SatNav' - this will clear the SatNav databank of all stored locations
    
    d) 'c Hud' - this will clear all Saved Locations from the Dimencia Hud databank (use with care!)
    
    e) 'l SatNav' - this will reload all of the default location from the SatNav PB (including any new ones that you may have added in step 4b above)
    
    f) 'l Hud' - this will copy all of the Dimencia Hud stored locations from the Hud's databank into the SatNav databank
    
    g) 'backup' - this command will duplicate/clone the SatNav databank if an additional empty databank has been linked to the PB in slot 5.  The purpose of this feature is to enable users to copy their locations to multiple ships.
    
    h) 'a ::pos{<a>,<b>,<c>,<d>,<e>} <location name>' - this command will add a new location. <a>, <b>, <c>, <d> and <e> are the systemid, bodyid, x, y and z coordinates for the new location.  <location name> is an optional name of the new location, if this is left blank then SatNav will generate an automatic location name.  
    
    i) 'dump SatNav' - this command will write out all of the SatNav locations into the DU logfile.  This is not pretty, but it provides a way to backup your SatNav locations and reload them - requires you to edit the DU logfile; extract the location strings; replace the '&quot;' with double quotes;  and copy them into the SatNav PB.
    
    j) 'h' - help will display this list of command line commands.
    
    k) 'restore' - this will restore the contents of the SatNav databank from the backup copy.
 
  7) When using your Dimencia Hud, you will find that the location you loaded in 3 (above) has been renamed as 'SatNav Location' and is now available using the Alt+1/Alt+2 keys..  This will also have been set as the destination on the Dim Hud buttons screen.  Unlike previous versions of SatNav, we now only copy across a single location to Dim Hud - this is due to a limitation in the Dim Hud which would cause a cpu overload error if we copied all of the SatNav locations across.
  
  8) SatNav supports tagging of your locations using the 'tag' buttons (top right of screen) - currently this supports tags for Markets, Mines, Crash Sites, Bases or Favourites.  To set/unset a tag for a specific location: a) click on the desired location; b) click on the desired tag.  Locations can have 0-4 tags.
  
  9) There are 6 filter buttons (middle of screen) which allow you to filter the locations displayed by the tags you have set. The filters are: Planet, Markets, Mines, Crash Sites, Bases and Favourites.
 
 # Known issues:
 
 The order of linking the core/screen/databanks should always be: 1) core, 2) screen, 3) satnav databank, 4) Dimencia Hud databank, 5) (otional) satanav databank copy (used in the x SatNav command only).
 
 Some users are struggling to locate the DU LUA library folder on their local drives.  This is located below the directory that you originally installed DU.
 
 Some users are struggling to download the planetref.lua and atlas.lua libraries.  These two files can be found in the GitLab URL link provided above, they must be copied in their entirity into the DU Lua library folder.  You can check them once you have downloaded by opening the lua files and seeing that they contain the appropriate LUA code.
 
 I have recently experience a problem with DimHud linking to the incorrect databank when I did a clean new DimHud configuration.  The outcome of this is that it may corrupt the content of the SatNav databank (for example if DimHud has linked to the SatNav databank).  Therefore, the following is my recommendation:
 a) before you do a DimHud update, always back up your SatNav databank (using the 'x SatNav' command described above) and then remove the backup copy into your inventory; b) immediately after doing a DimHud update, check the databank that is linked to the DimHud pilot seat.  If it is the incorrect databank, then remove the link and manually link to the correct DimHud databank - do this BEFORE activating DimHud for the first time after the update.
 
 On a couple of occasion with 2_1_3 we have found that on sitting down at the DimHud seat the first time, the 'SatNav Location position updated' message is flashed up every 5 seconds on the Hud.  Not sure why this happens (it might be something to do with synchronisation of databank data with the DU server), but getting out of the seat and then sitting back down seems to fix this.
 
 If the SatNav PB has been activated via a Detection Zone then you may find that you cannot set a waypoint from SatNav, this is an issue with activating PBs from DZ which do not set the owning player correctly and hence SatNav is unable to set a waypoint for the player.  Therefore, I recommend always acivating SatNav by directly pressing 'f' on the PB.
 
 Due to DU limitations on the distance a player can be from a Programming Board connected to a databank, I have added a heartbeat function which checks to see if the databank has been unloaded from the players client.  If it detects that the databank is unloaded, then the PB will do a soft exit.
 
 # Version history:
 
 2_0_0 - Released version
 
 2_0_1 - pre-release version, use at your own risk.  Update includes location/planet distances and warp cell estimates.  verification of connection to Dimencia Hud.
 
 2_0_2 - a few bug fixes and enhancements
 
 2_1_0 - updated to avoid cpu overload problems and utilise the new setWaypoint and inputText features of DU 0.23
 
 2_1_1 - update includes: 1) attempt to try and avoid installation issues with linking databanks in wrong order; 2) added fix for new Space locations which were always being assigned to planets instead of 'Space'; 3) a few bug fixes
 
 2_1_2 - update includes: 1) improved avoidance of databank linking issues during installation; 2) improved readability of screens: a) highlighting of selected planets/location is now shown by a bar rather than a font colour change; b) 4 LUA parameters have been added to allow users to change the colours for Planet Panel Backgroun; Location Panel Background; Panel font colour; and highlight bar colour.
 
 2_1_3 - update includes: 1) fixed issue when using SatNav while seated in DimHud seat, SatNav location was not being read as DimHud only loads the saved locations when it boots; 2) added a new command to add locations from the command line; 3) yet another fix for SatNav bootup to get the correct databank links.
 
 2_1_4 - bug fix for adding new location
 
 2_1_5 - added: 1) new 'update location' button; 2) added validation to command line entry of ::pos strings; 3) enabled entry of 'spaces' in locations names entered via the command line
 
 2_1_6 - fixed 1) problem with 'new location' and 'update location' always assigning location to Alioth; 2) added a heartbeat mechanism so that SatNav will auto turn off if the player moves out of range (and the SatNav databank is unloaded by DU); 3) added a 'delete location' button to the main screen
 
 3_0_2 - added: 1) support for location tags (adding, removing and filtering); 2) sorting of planets and locations by alphanumeric name or distances, 3) restore from backup command line; 4) heartbeat for players moving too far from programming board.
 
 3_0_3 - added: 1) scrollbars to planet and location panels and removed the page up/down buttons respectively; 2) added validation to 'u'/update commands to try and catch any attempts to update a location without a name.
 
 3_0_4 - SatNav will now delete all DimHud saved locations and thus avoid contamination from Dimencia Hud introduced bugs.
