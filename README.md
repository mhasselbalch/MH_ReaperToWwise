# MH_ReaperToWwise 
Development of a Reaper script that is able to post events and game syncs directly to Wwise via the WAAPI.

**ReaperToWwise v0.9.0 (for testing)** 

Last update: February 12th 2024 

Welcome. \
If you are reading this, I've probably sent you a link to test this out. Thank you for doing so. \
It is still being developed, but I am now at a stage, where I would like to get people to test it out. \
If you encounter (and you most likely will) any issues, bugs and anything else, please report it to me alongside what you were doing and what happened when you encountered the issue as well as your Reaper version and operating system information. 

You can contact me via the Discord group below or via marchasselbalch[at]gmail[dot].com, but please read the "KNOWN ISSUES" section further down before doing so. 

Discord group for people to report bugs, request features, ask questions and showcase their use of the tool. \
Link: https://discord.gg/DYkfb9YAKB (invite should not expire, but let me know if it does) (UPDATED 20/2/2024)

If you have something to share/report and is not the Discord-using type, you are free to contact me by email. 

I can't stop you in sharing this test version with anyone you please, but if you do so, please send people to this page first. 

When the tool is ready, it will be available from ReaPack. 

––––

**Purpose:** \
The purpose of this script is to aid in testing out middleware implementation in Audiokinetic's Wwise from Cockos' Reaper DAW with no game engine running. Either for certain parts of development or for educational purposes. Or for anything else that you deem useful and fun. 

––––

**Pre-requisites:** \
Reaper (no versions outside of v7.07 on MacOS tested up until now) \
  https://www.reaper.fm/ \
    Note: The tool should be compatible with most Reaper versions, where the Lua interpreter is based on Lua 5.3 (Reaper v.6.x and earlier according to their website). While Reaper v7 introduced Lua 5.4 functionality, I haven't made use of any of it up until now. 

Wwise 2019.1+ (required for installing ReaWwise) \
  https://www.audiokinetic.com/en/products/wwise/
  
ReaWwise (can be installed via ReaPack inside of Reaper) \
  https://blog.audiokinetic.com/en/reawwise-connecting-reaper-and-wwise/ \
    Exposes raw WAAPI functions to Lua inside of Reaper.

Lokasenna's GUI library v2 for Lua (installed via ReaPack inside of Reaper) \
  It handles the GUI elements. 

––––

**How it works** \
The tool works by parsing text commands written inside of the "Notes" field of empty items on the Reaper timeline and will post already existings events and set game syncs inside of Wwise when the playcursor passes these items. 

You add an empty item, write in your commands, for example: "e/Footstep", and the tool will post the event named "Footstep" to Wwise and will trigger it – if it exists and is set up correctly. 

You are able to post more than one event or game sync from a single block by seperating each command with a comma and newline. 

You are also able to create automation lanes, which will set RTPC values during playback. 

PLEASE NOTE that the tool does not (at this point) create events or game syncs from scratch – it can simply trigger and set them if they exist and are set up in Wwise. 

––––

**Use** \
– Open Wwise and Reaper. \
– From Reaper, open the 'MH_ReaperToWwise_v0.9.lua' script and the tool window will appear. \
– In Wwise, go to Project -> Project Settings -> Network and check the communication ports ("Game Discovery Broadcast Port (game side)"). \
– Press the 'Connect' button and enter in the connection port that your open Wwise project uses.
– The connection port label in the tool window will change to the desired port number if the connection was sucessful. 
– Create an empty item on the timeline, double-click the item to open up the "Notes" text field and enter in your commands (see 'Commands' on this page or in the tool window inside of Reaper). \
– From the tool window in Reaper, press the 'Run' button. \
– Start the transport. \
– Test it out. 

**(Re)-generate the soundbank**

When adding and updating game syncs in your Wwise session, please (re)-generate your soundbank for the relevant IDs to be accessible via the WAAPI. If you don't do so, the WAAPI log will throw an error about not being able to find it. 

This is *especially* relevant when using RTPC automation lanes, since the WAAPI log will fill up with errors for each evaluation update, which can, seemingly, overload the WAAPI and cancel evaluation of any future envelope points and can even significantly slow down your system (depending on your setup). 

You also need to reconnect to the WAAPI at the given port when generating your soundbank. 

So please remember to re-generate your soundbank when adding and updating game syncs and name your RTPC lanes according to the existing RTPCs in your Wwise session. 


––––

**Commands** 

Events: \
e/eventName \
  Posts an event with the given 'eventName'. 

Switches: \
sw/switchGroup/switchName
  Sets a switch with the given 'switchName' from the given 'switchGroup'. 

States: \
st/stateGroup/stateName \
  Sets a state with the given 'stateName' from the given 'stateGroup'. 

Triggers: \
t/triggerName \
  Posts a trigger with the given 'triggerName'. 

RTPCs: \
r/rtpcName/rtpcValue \
  Sets a given RTPC to a given value.

––––


**RTPCs help** 

To add an automation lane to control a given RTPC, do the following: 
1. Press 'Add RTPC Lane' from the tool window. 
2. Enter the name of the RTPC you want to control and set its minimum and maximum value. 
3. A seperate JSFX plugin will automatically be created and added to the selected Reaper track's FX list. 
4. An automation lane will automatically be created under the selected track. 
5. Repeat for every RTPC you need. 

Note: If you want to set the RTPC value with an empty item, but have an RTPC lane created at the same time, you are advised to disarm the given automation lane, otherwise it will keep updating the automation value at every update, thus interferring with whatever value you set in the empty event item. \
So at this point it is not possible to have both working at the same time unless you have a specific use-case in mind. 

––––

**Known issues, work-arounds and notes:** 

– **PLEASE USE FIRST TRACK IN REAPER SESSION FOR EVENTS AND RTPCS**: For now, it is advised to use the first track (ID 0) in your Reaper project for both event items and RTPCs to ensure everything runs smoothly. You are free to try other tracks, but to handle certain potential crashes and nil exceptions, certain functions will auto-select the first track in the project if none are found or selected. This will be changed. 

– **STOPALL BUTTON**: I have added a 'StopAll' button in the tool window, which, in itself, does nothing if an event in the Wwise project named 'StopAll' doesn't exist. It simply posts the event 'StopAll'. \
Working with this tool can sometimes get messy if you accidentally trigger some looping sound sources, but have no way to stop them from Wwise as such, so I advise you set up an event named 'StopAll' that, as the name suggests, posts a Stop All action event. Basically just a make-shift panic button. 

– **DUMMY SLIDER**: When you press 'Run' in the script window, it will automatically create and add a JSFX slider plugin named "dummy" if no user-made RTPC lanes were created as it always expects one. This cannot be removed if this is the only plugin on the FX list. You are free to add what you need, but it will auto-create the "dummy" plugin to make sure one is always present in the FX list. Removing this (while other RTPC lanes are added) will cause a crash upon playback. So for now, do not remove the JSFX plugin named "dummy" from the list and make sure it is the first in the FX list. This will be changed. 

– **RTPC LANES NOT EVALUATING**: If you have added everything correctly and RTPC lanes are not evaluating, try stopping the transport and press 'Run' in the tool window again. 

– **VERTICALLY CROPPED POP-UP WINDOWS**: At certain times, the pop-up windows for "Instructions", "Commands" and "RTPC help" will be shortened vertically and you are not able to scroll down to read the rest of the text. Sometimes closing all scripts and re-opening the ReaperToWwise script will fix this. If not, a reboot of Reaper usually does the trick. At this point I don't know the cause, but I will try to fix it. 

– **RTPC EVALUATION LAG**: During playback when having added RTPC automation lanes and having pressed 'Run', the Reaper session and its GUI update will lag considerably during the first two runs or so, which can usually be heard in how the RTPC lane is being evaluated and sent to the WAAPI in unsmooth steps, but running it a few times will seemingly make it run smooth (at least on my system). I assume some sort of caching is taking place. I will try to fix it. I am very interested in hearing about how this runs on other machines and setups. 

– **WAAPI LOG 'OVERLOAD'**: As mentioned earlier, please take care in naming your RTPC lanes an existing name and that the soundbank has been (re)generated after adding or updating game syncs. Otherwise the WAAPI log can get swarmed with error messages, which can cause a slew of unpredictable behaviour, mostly slowing down your system or cancelling future envelope points from being evaluated altogether. It seems the WAAPI has a limit for how much data it can receive within a given timeframe, but I need to contact Audiokinetic about it to get a clearer picture. 

– **UNIQUE RTPC JSFX PLUGINS**: Since I haven't found a way to dynamically alter the JSFX script of the slider plugins from the main Lua script post-creation, each RTPC slider is its own separate JSFX file. These will be saved under [Reaper resource folder]/Effects/MH_ReaScripts", and this folder will be created if it doesn't already exists. And yes, this means that everytime you add a RTPC lane with a unique name, a unique file will be saved. Luckily these are small in size, but depending on your use of the tool, it could result in a lot of files. And yes, this would also mean that if you create, say, a RTPC lane with the name "Test1" with a min of 0 and max of 1 and then, perhaps in a new Reaper project, create a RTPC lane with the same name, but with a different min and max value, it will be overwritten, which could result in the first Reaper project's RTPC lanes not behaving as expected. As of now, I haven't devised a way to manage this reliably, but it will be changed down the line. 

– **RE-GENERATING SOUNDBANK FROM THE TOOL WINDOW**: I plan to implement a button to re-generate the last soundbank directly from the tool window. 

–––

**For now:** \
Thanks for testing this out. \
Please contact me if you need to. 

Cheers. \
– Marc Hasselbalch 



