# MH_ReaperToWwise 
Development of a Reaper script that is able to post events directly to Wwise via the WAAPI.

Welcome. \
This repo is password-protected for the time being, mostly to have a sense of who I share this very first version of the script with. Obviously I can't stop you in sharing this script with anyone.

––––

**Pre-requisites:** 
\
Reaper (no versions outside of v7.07 on MacOS tested up until now) \
  https://www.reaper.fm/

Wwise 2019.1+ (required for installing ReaWwise) \
  https://www.audiokinetic.com/en/products/wwise/
  
ReaWwise (can be installed via ReaPack inside of Reaper) \
  https://blog.audiokinetic.com/en/reawwise-connecting-reaper-and-wwise/


**Use** \
– Open Wwise and Reaper \
– In Wwise, go to Project -> Project Settings -> Network and check the communication ports ("Game Discovery Broadcast Port (game side)"). \
  The script uses the port number 8080. You change it. \
– In Reaper, run the script and the ReaScript console should confirm your connection to Wwise on the given port. \
– Test it out. 

**Purpose:** \
The purpose of this script is to aid in testing out middleware implementation in Wwise with no engine running. Either for certain parts of production or for educational purposes. 

**Current functionality:** \
The script reads the name of a marker placed on the timeline as the playcursor passes it and send this name to Wwise via the WAAPI. \
If it matches the name of an event present in the Wwise project, it will post this event.

**Video example:** \
https://www.youtube.com/watch?v=g02M2WDO-5w 

**To-do list:** \
– Rewrite how the script handles the event triggering (right now it can result in triggering the previous marker/event in the timeline if you are looping a segment. I suggest to place a "dummy" marker that is not used for any event posting in Wwise at the start of the loop) \
– Test alternatives to markers (i.e empty items, regions, etc) \
– Test the use of automation tracks for driving RTPCs \
– Test the use of different WAAPI functions to set states and switches \
– Collect functionality wishes and user experiences. \
– Make a simple GUI to show connection confirmation, buttons for "run" and "stop" and so forth.  


**Known issues:** \
As far as I can gather, Reaper's global timer, used for polling, runs at 30-50Hz, so markers placed very close to each-other could result in only the first triggering and the next being dropped, which means stacked, simultaneous events are not possible right now. There *has* to be some delay between the markers. I haven't yet calculated the necessary minimum time between each marker.

**For now:** \
Let me know if there is any thoughts and ideas in the discussions. 
I am not an expert programmer (even less so in ReaScripts), so I have/will possibly do some things oddly. Let me know if there are some oddities that can be improved for better use and performance. 

Cheers. \
– M. Hasselbalch



