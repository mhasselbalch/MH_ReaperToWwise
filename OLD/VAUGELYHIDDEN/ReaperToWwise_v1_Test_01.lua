
-- @description ReaperToWwise
-- @version 1.0
-- @author Marc Hasselbalch
-- @about
--   # ReaperToWWise v1.0 TEST 01
-- @changelog
--   Test 01 11102024

versionNumber = "1.0"

-- Debug console message

function Mess(message)

  if message == "/n" then
    reaper.ShowConsoleMsg(string.char(10))
  else
  reaper.ShowConsoleMsg(tostring(message))
end

end

-- Initialize tables and other 
function Init()
  runBool = true
  isRunning = false
  runCheckCount = 0
  playPos = 0
  playState = 0
  connectionStatus = "No connection"
  runCheck = false
  RTPCInputName = ""
  trackMutes = {}
  loopCount = 1 
  checkArray = {}
  trackItemArray = {} 
  itemArray = {} 
  numArray = {} 
  startsArray = {}
  laneNameArray = {}
  currentItem = 0
  selItemArray = {}  
  selItemCollect = {}
  trackCollect = {}
  selItemPos = {} 
  triggeredPositions = {}
  laneArray = {}
  rtpcArray = {}
  envArray = {}
  retValArray = {}
  idArray = {}
  scriptRunning = false
  currentIndex = 1
  envValArray = {}
  envValArraySlow = {}
  envNameArray = {}
  envCollArray = {}
  envByNameArray = {}
  envFormatArray = {}
  inputNameArray = {}
  envStrArray = {}
  envStateArray = {}
  iCount = 0
  fIndex = 0
  transportStopBool = true
  hasStopped = false
  rtpcValCompare = {}
  waitCount = 0 
  slowEnvVal = 48
  evalSpeedRV = 10
  trackCount = 1
  selItemCount = 1
  remainingSelItemCount = 1
  laneCount = 0
  rtpcSearchString = "RTPCs_DO_NOT_RENAME"
  rtpcCompare = {}
  logMax = 10
  logArray = {}
  soloArray = {}
  muteArray = {}
  muteCheck = false
  soloCheck = 0
  globSoloCount = 0
  playBool = false
  pauseBool = false
  stopBool = false
  toolsOpen = false
  helpOpen = false
  playbackStart = 0
  playbackRead = false
  indexSearch = 0
  remainCount = 0
  triggerSet = false
  debugCount = 0
  playPosCheck = {}
  lastPlayPos = {}
  playPosHasChanged = false
  stopTrigger = false

  portNumber = 8080

  SearchForRTPCName()

  if reaper.AK_Waapi_Connect("127.0.0.1", portNumber) then
    WaapiConnect(tonumber(portNumber))
    WaapiRegisterObject()
    WaapiSetListener()
    
  end

 end

-- Search for default RTPC lane name, add if not present

function SearchForRTPCName()

CountTotalTracks()

  local trackNames = {}

for i=1, trackCount do

  local tr = reaper.GetTrack(0, i-1)
  bool, trackNames[i] = reaper.GetTrackName(tr,"")

  if trackNames[i] == rtpcSearchString then
    rtpcTrack = reaper.GetTrack(0, i-1)
    matchFound = true
      break
    else
      matchFound = false

  end

end
  
  --[[
   for i, value in ipairs(trackNames) do
        if value == rtpcSearchString then
            matchFound = true
            rtpcTrack = reaper.GetTrack(0, i-1)
            break 
        end
    end
    --]]


    if not matchFound then
        AddRTPCDefault()
    end

    if matchFound then
      --reaper.defer(SearchForRTPCName)
    end

    --reaper.defer(SearchForRTPCName)
end


-- Global Reaper project states and information
-- Global playstate

function PlayState()  

  playBool = reaper.GetPlayStateEx(0)&1 == 1
  pauseBool = reaper.GetPlayStateEx(0)&2 == 2
  --playState = 0

  if playBool == true then
     playState = 1
     stopTrigger = false
  end

  if playBool == false then
     playState = 0

   if transportStopBool == true then
     StopAllFunc() 
   end

     remainCount = 0
  end

  if playState == 1 and runCheck == false and runBool == true then

    RunScript()

    for i=1, selItemCount do
          itemArray[i] = reaper.GetMediaItem(0, i-1)
          startsArray[i] = reaper.GetMediaItemInfo_Value(itemArray[i], "D_POSITION")
    end

  end

  if playState == 0  then -- here!
    triggerSet = false
    startsArray = {}
  end


  reaper.defer(PlayState)


end


-- Global playPos

function PlayPos()

local playPosRead = reaper.GetPlayPositionEx(0) -- Fix if timing is off

if playState == 1 and playbackRead == false then  
  playbackStart = playPosRead
  playbackRead = true
end

if playState == 1 then

-- Only update playPos if new value , FIX doesn't work OR DOES IT

local currentValue = playPosRead

for i = 1, 2 do

      if currentValue ~= lastPlayPos[i] then
          playPosHasChanged = true

          if lastPlayPos[i] == nil then
            lastPlayPos[i] = 0
          end

          break 
    end
end

if playPosHasChanged == true then

      lastPlayPos[2] = lastPlayPos[1]
      lastPlayPos[1] = currentValue


      -- Reset all triggeredpos array if jump in timeline detected (avoid retriggering all previous during playback)
      if currentValue > lastPlayPos[2] + 0.5 then -- adjust jump threshold if needed

          for i=1, selItemCount do
              triggeredPositions[i] = true
          end

      end

      playPos = currentValue

 end

  if playState == 0 then
    playPos = -1 -- fix
    playbackRead = false
  end

  end

    reaper.defer(PlayPos)
end



function AddRTPCDefault()

  CountTotalTracks()
  reaper.InsertTrackAtIndex(trackCount,true)
  CountTotalTracks()
  rtpcTrack = reaper.GetTrack(0, trackCount-1) -- fix
  reaper.GetSetMediaTrackInfo_String(rtpcTrack, "P_NAME", rtpcSearchString, true)
  reaper.SetTrackColor(rtpcTrack, reaper.ColorToNative(255,255,0)|0x1000000)

  if trackEnv == nil then
       AddJSFX("dummy",0,1) -- here
      trackEnv = reaper.GetFXEnvelope(rtpcTrack,0,0,true)-- FIX?
       local dummyEnv = reaper.GetTrackEnvelope(rtpcTrack, 0)
       reaper.GetSetEnvelopeInfo_String(trackEnv, "VISIBLE", "", true)
   end
end

-- Port connection

function ReconnectPort()
 
  WaapiConnect(tonumber(portNumber))
  WaapiRegisterObject()
  WaapiSetListener()
end

-- Port reconnection

function ConnectPort()

  local ok, values = reaper.GetUserInputs('Connect to Wwise at port: ', 1, 'Port number','')

    portNumber = values

   WaapiConnect(tonumber(values))
   WaapiRegisterObject()
   WaapiSetListener()
  
  
end

--Connect to Waapi

function WaapiConnect(portNumber)

  --FIX
  
  if type(portNumber) ~= "number" then
    reaper.ShowMessageBox(tostring("Port should be a number."), tostring("ReaperToWwise"), 0)
  end

  if portNumber == nil then
    reaper.ShowMessageBox("Port number set to Wwise default: 24024", "ReaperToWwise", 0)
    portNumber = 24024
    WaapiConnect(portNumber)
  end
  
  if reaper.AK_Waapi_Connect("127.0.0.1", portNumber) == false  then
     reaper.ShowMessageBox("Could not connect at the chosen port", "ReaperToWWise",0)
     connectionStatus = "Not connected"
  end

  if reaper.AK_Waapi_Connect("127.0.0.1", portNumber) then
    connectionStatus = "Connected"
  end 

--Register object

function WaapiRegisterObject()
    local registerArg = reaper.AK_AkJson_Map()
    local registerCommand = "ak.soundengine.registerGameObj"
       
    reaper.AK_AkJson_Map_Set(registerArg, "gameObject", reaper.AK_AkVariant_Int(0))
    reaper.AK_AkJson_Map_Set(registerArg, "name", reaper.AK_AkVariant_String("GameObj"))
    reaper.AK_Waapi_Call(registerCommand, registerArg, reaper.AK_AkJson_Map())
end

--Set listener

function WaapiSetListener()

    local listenerCommand = "ak.soundengine.setDefaultListeners"
    local listenerOptions = reaper.AK_AkJson_Map()
    local listenerArray = reaper.AK_AkJson_Array()
    local listenerArgs = reaper.AK_AkJson_Map()
    reaper.AK_AkJson_Array_Add(listenerArray, reaper.AK_AkVariant_Int(0))
    reaper.AK_AkJson_Map_Set(listenerArgs,"listeners", listenerArray)
    
    reaper.AK_Waapi_Call(listenerCommand, listenerArgs, listenerOptions)

  end

end

-- Post "StopAll" event on transport stop -- fix, doesn't work

function AutoStop()

if transportStopBool == true and playState == 0 then 

  if hasStopped == false and playState == 0 then
    WaapiPostEvent("StopAll")
    hasStopped = true
  end

  if playState == 1 and hasStopped == true then
    hasStopped = false
  end

end

--reaper.defer(AutoStop)


end


-- RTPC

function AutomationRTPC()
  
    if trackEnv == nil then
      -- trackEnv = reaper.GetFXEnvelope(rtpcTrack,0,0,true)-- FIX?
      --AddJSFX("dummy",0,1)
    end
   
  -- Add dummy RTPC lane if no user-made ones have been created (FIX ?)
  if trackEnv == nil then
   --AddJSFX("dummy",0,1)
   --trackEnv = reaper.GetFXEnvelope(0,0,0,true)

  end
  
  if playState == 1 then
      EvalRTPC()
  end
  
  if playState == 1 then
    for i=1, tableSize(laneNameArray) do
      --EvalRTPC(laneNameArray[i])
    end
  end
    
   --reaper.defer(AutomationRTPC) --  this is the issue

end


function CheckState()

  if playState == 1 and runCheck == false then
     --runCheck = true 
     --RunScript()
     --runCheck = true 
  end

  if playState == 0 and runCheck == true then
    --runCheck = false
  end
end

function RemoveRTPCSearch(searchName)

for i=1, LaneCount() do

-- search envname array for env name, remove index if not found

  if laneNameArray[i] == nil then
     -- table.remove(laneNameArray, i)
     -- laneCount = LaneCount()

     --FIX HERE
  end
end

end

-- Evaluate automation envelope track value
function EvalRTPC()

      --laneNameArray = {}

    
    for i=1, tableSize(laneNameArray) do
     -- inputNameArray[i] = laneNameArray[i]
      --envNameArray[i] = tostring(inputNameArray[i]) .. " " .. "/" .. " " .. "ReaperToWwise_RTPC_Slider"--.jsfx"
    end
    
    local blockSize =  128 --128
    local sampleRate = 48000
    local thisTrack = reaper.GetSelectedTrack(0,0) -- FIX
    local rtpcSendValue = 0
    local playPosition = reaper.GetPlayPositionEx(0)
    
    -- FIX
    if thisTrack == nil then
      --thisTrack = reaper.GetTrack(0,0) -- FIX, to prevent crashes (for now)
    end 
    
    local laneCount = LaneCount() -- FIX
  
         
         if playState == 1 then

            laneCount = LaneCount() -- FIX

            for i=1, #laneNameArray do -- FIX 

             -- RemoveRTPCSearch()

              for i=1, #laneNameArray do
                inputNameArray[i] = laneNameArray[i]
                envNameArray[i] = tostring(inputNameArray[i]) .. " " .. "/" .. " " .. "ReaperToWwise_RTPC_Slider"--.jsfx"
              end

              envByNameArray[i] = reaper.GetTrackEnvelopeByName(rtpcTrack, envNameArray[i])

              retval, str = reaper.GetEnvelopeStateChunk(envByNameArray[i], "ARM", false)
              envStrArray[i] = str
              
              local pattern = "ARM%s+(%d+)"
            
              for value in str:gmatch(pattern) do
                envStateArray[i] = tonumber(value)
              end
           
            if envStateArray[i] == 1 then
                local retVal, envVal = reaper.Envelope_Evaluate(envByNameArray[i], playPosition, sampleRate, blockSize)

                envVal = tonumber(string.format("%.4f", envVal)) -- float precision, change if items are skipped

                waitCount = waitCount + 1
                waitCount = waitCount % (slowEnvVal * (math.floor(evalSpeedRV)+1)) 

                envValArray[i] = envVal
            end

            if waitCount == 0 then 

              envValArraySlow[i] = envValArray[i]

            end
          
            -- check if RTPC value is different from last update, only post if it is

            lastRtpcValue = lastRtpcValue or {}

            for i = 1, 2 do
                local currentValue = envValArray[i]

                if currentValue ~= lastRtpcValue[i] then

                    lastRtpcValue[i] = currentValue
                    
                    rtpcSendValue = currentValue

            local rtpcName = laneNameArray[i]
            local rtpcValFrom = rtpcSendValue --envValArraySlow[i]
            local rtpcCommand = "ak.soundengine.setRTPCValue"
            local eventArg = reaper.AK_AkJson_Map()
            local gameObj = reaper.AK_AkVariant_Int(0)
            local eventOptions = reaper.AK_AkJson_Map()
            local rtpcString = reaper.AK_AkVariant_String(rtpcName)
            local rtpcVal = reaper.AK_AkVariant_Double(rtpcValFrom)
            reaper.AK_AkJson_Map_Set(eventArg, "rtpc", rtpcString)
            reaper.AK_AkJson_Map_Set(eventArg, "value", rtpcVal)
            reaper.AK_AkJson_Map_Set(eventArg, "gameObject", gameObj)
            
              if laneNameArray[i] ~= "dummy" then
                reaper.AK_Waapi_Call(rtpcCommand, eventArg, eventOptions)
                reaper.AK_AkJson_ClearAll()
              end
            end
          end
        end
      end
    

    --reaper.defer(EvalRTPC)

end


--Post event, set switches/states/triggers and RTPCs

function WaapiPostEvent(name)

    local postEventCommand = "ak.soundengine.postEvent"  
    local eventArg = reaper.AK_AkJson_Map()
    local eventName = reaper.AK_AkVariant_String(name)
    local gameObj =   reaper.AK_AkVariant_Int(0)
    local eventOptions = reaper.AK_AkJson_Map()
    reaper.AK_AkJson_Map_Set(eventArg, "event", eventName)
    reaper.AK_AkJson_Map_Set(eventArg, "gameObject", gameObj)
    
    reaper.AK_Waapi_Call(postEventCommand, eventArg, eventOptions)

    reaper.AK_AkJson_ClearAll()
   -- Mess(name)
  -- Mess("/n")
end


function WaapiPostTrigger(name)

    local postEventCommand = "ak.soundengine.postTrigger"  
    local eventArg = reaper.AK_AkJson_Map()
    local triggerName = reaper.AK_AkVariant_String(name)
    local gameObj = reaper.AK_AkVariant_Int(0)
    local eventOptions = reaper.AK_AkJson_Map()
    reaper.AK_AkJson_Map_Set(eventArg, "trigger", triggerName)
    reaper.AK_AkJson_Map_Set(eventArg, "gameObject", gameObj)
    
    reaper.AK_Waapi_Call(postEventCommand, eventArg, eventOptions)
    
    reaper.AK_AkJson_ClearAll()
end

function WaapiSwitch(group,state)
  
  local command = "ak.soundengine.setSwitch"  
  local eventArg = reaper.AK_AkJson_Map()
  local switchGroup = reaper.AK_AkVariant_String(group)
  local switchState = reaper.AK_AkVariant_String(state)
  local gameObj = reaper.AK_AkVariant_Int(0)
  local eventOptions = reaper.AK_AkJson_Map()
  reaper.AK_AkJson_Map_Set(eventArg, "switchGroup", switchGroup)
  reaper.AK_AkJson_Map_Set(eventArg, "switchState", switchState)
  reaper.AK_AkJson_Map_Set(eventArg, "gameObject", gameObj)
  
  reaper.AK_Waapi_Call(command, eventArg, eventOptions)
  
  reaper.AK_AkJson_ClearAll() 

end

function WaapiState(group,state)
  
  local command = "ak.soundengine.setState"  
  local eventArg = reaper.AK_AkJson_Map()
  local stateGroup = reaper.AK_AkVariant_String(group)
  local stateName = reaper.AK_AkVariant_String(state)
  local gameObj = reaper.AK_AkVariant_Int(0)
  local eventOptions = reaper.AK_AkJson_Map()
  reaper.AK_AkJson_Map_Set(eventArg, "stateGroup", stateGroup)
  reaper.AK_AkJson_Map_Set(eventArg, "state", stateName)
  --reaper.AK_AkJson_Map_Set(eventArg, "gameObject", gameObj)
  
  reaper.AK_Waapi_Call(command, eventArg, eventOptions)
  
  reaper.AK_AkJson_ClearAll() 

end

function WaapiRTPC(name,iVal)
  
  local command = "ak.soundengine.setRTPCValue"  
  local eventArg = reaper.AK_AkJson_Map()
  local rtpcString = reaper.AK_AkVariant_String(rtpcName)
  local eventOptions = reaper.AK_AkJson_Map()
  local rtpcVal = reaper.AK_AkVariant_Double(iVal)
  local gameObj = reaper.AK_AkVariant_Int(0)
  reaper.AK_AkJson_Map_Set(eventArg, "rtpc", rtpcString)
  reaper.AK_AkJson_Map_Set(eventArg, "value", rtpcVal)
  reaper.AK_AkJson_Map_Set(eventArg, "gameObject", gameObj)
  
  reaper.AK_Waapi_Call(command, eventArg, eventOptions)
  
  reaper.AK_AkJson_ClearAll() 

end

-- Count total number of tracks in project

function CountTotalTracks()

trackCount = reaper.CountTracks(0)

end

-- Count items on selected track

function CountSelectedItems()

trackCollect = {}
selItemCount = 0

 -- FIX
 if thisTrack == nil then
  thisTrack = reaper.GetTrack(0,0)
 end
 
for i=0, trackCount do
  trackCollect[i+1] = reaper.GetTrack(0, i) 
end
  
for i=1, trackCount do
    selItemCollect[i] = reaper.CountTrackMediaItems(trackCollect[i]) 
end

for i=1, trackCount do
  selItemCount = selItemCount + selItemCollect[i]
end

end

--Parse empty item notes based on seperator

function ParseNotes(notes,track)
 
  local t = {}

  muted = reaper.GetMediaTrackInfo_Value(track, 'B_MUTE')
  soloed = reaper.GetMediaTrackInfo_Value(track, 'I_SOLO')
  soloCheck = soloed
  muteCheck = muted

  local numTracks = reaper.CountTracks(0)
  local tracksSoloed = reaper.ImGui_DragDropFlags_SourceExtern()

  for i=0, numTracks-1 do
    if reaper.GetMediaTrackInfo_Value(reaper.GetTrack(0, i), 'I_SOLO') > 0 then
      tracksSoloed = true
      break
    end
  end

  local processNotes = false
  if tracksSoloed == true then
    if soloed > 0 then
      processNotes = true
    end
  else

    if muted == 0 then
      processNotes = true
    end
  end

if processNotes == true then
       local str = notes
       local function helper(line) 
          table.insert(t, line) 
          return ""
       end  
       helper((str:gsub("(.-)\r?\n", helper)))
end

    -- Parse event
    for i=1, #t do  

          if soloCheck ~= 0 or muteCheck ~= 1 then
          if string.sub(t[i], 1, 1) == "e" then   
              local  pe = t[i]:gsub('%,','')
              local  pee = string.sub(pe, 3,40) -- Max string length, FIX this could cause issues
       WaapiPostEvent(pee)
       
      end
    end

    -- Parse trigger
    if string.sub(t[i], 1, 1) == "t" then   
        local pe = t[i]:gsub('%,','')
        local pee = string.sub(pe, 3,40)
         WaapiPostTrigger(pee)
    end 
    
    -- Parse state
    if string.sub(t[i], 1, 2) == "st" then
      local tt = {}
      s = t[i]
      for one,two,three in string.gmatch(s, "(%w+)/(%w+)/(%w+)") do
        tt[1] = two
        tt[2] = three
      end

       stateGroup = tt[1]:gsub('%,','')
       stateName = tt[2]:gsub('%,','')
        
       WaapiState(stateGroup,stateName)
    end
    
    -- Parse switch
    if string.sub(t[i], 1, 2) == "sw" then
        
       local tt = {}
        s = t[i]
        for one,two,three in string.gmatch(s, "(%w+)/(%w+)/(%w+)") do
          tt[1] = two
          tt[2] = three
        end
        
         switchGroup = tt[1]:gsub('%,','')
         switchState = tt[2]:gsub('%,','')
          
         WaapiSwitch(switchGroup,switchState)
      
    end
    
    -- Parse RTPC
    if string.sub(t[i], 1, 1) == "r" then
      local tt = {}
      s = t[i] 
     
     for one,two,three in string.gmatch(s, "(%w+)/(%w+)/([%d%.]+)") do

        tt[1] = two
        tt[2] = three
      end
      
       rtpcName = tt[1]:gsub('%,','')
       rtpcVal = tt[2]:gsub('%,','')
        
       WaapiRTPC(rtpcName,rtpcVal)
      end
    end
end

-- Table size (for non-sequential elements)

function tableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

         
-- Limit tables to max size (=selItemCount)

function limitTableSize(tb, maxSize)
    while #tb > maxSize do
        table.remove(tb, 1) -- Remove the first element
    end
end
         
-- Get closest index from play cursor (to avoid triggering all event items prior to the playcursor position)

function GetClosestIndex(array, value)
    local closestValue = nil
    local closestIndex = nil
    local closestDistance = math.huge

    for i, arrayValue in ipairs(array) do
    
        if arrayValue >= value then
            local distance = math.abs(value - arrayValue)

            if distance < closestDistance then
                closestValue = arrayValue
                closestIndex = i
                closestDistance = distance
            end
        end
    end

    return closestValue, closestIndex
end

-- Get item starts

function GetItemStarts() 

     local playPosTrunc  = tonumber(string.format("%.3f", playPos)) -- adjust float precision, NOT USED

      if playState == 1 then

        for i=0, trackCount do
          trackCollect[i+1] = reaper.GetTrack(0, i) 
        end

        CountTotalTracks()
 
      if selItemCount == nil then
          InsertEmptyItem()
      end

      limitTableSize(startsArray,selItemCount)
      limitTableSize(itemArray,selItemCount)
       
            for i, start in ipairs(startsArray) do

              if triggerSet == false then

                nextVal, nextIndex = GetClosestIndex(startsArray, playPos)

                if nextIndex == nil then
                  nextIndex = 0 -- FIX
                end

                for i=1, selItemCount do
                  triggeredPositions[i] = true
                end

                triggerSet = true
              end

             if playPos > start and triggeredPositions[i] == false then 

                triggeredPositions[i] = true

                local retval, notes = reaper.GetSetMediaItemInfo_String(itemArray[i], "P_NOTES", '', false)
                local track =  reaper.GetMediaItemTrack(itemArray[i])

                ParseNotes(notes,track)
                    elseif playPos <= start then
                      triggeredPositions[i] = false
                    end
            end
  end

end



-- Button, run script
function RunScript()

  SearchForRTPCName()

  if rtpcTrack == nil then
    --SearchForRTPCName()
  end
  
  CountTotalTracks()
  CountSelectedItems()
  GetItemStarts()
   
  LaneCount()
  CollectEnvsInit()
  AutomationRTPC()

  end

-- Automation lane count

function LaneCount()

  laneCount = reaper.CountTrackEnvelopes(rtpcTrack)
  
  return laneCount
end

-- RTPC lane

function RTPCLane()
  
  if playState ~= 0 then
    reaper.ShowMessageBox("Please stop the transport before adding new RTPC lanes", "ReaperToWwise",0)
  end

   -- FIX
  if playState == 0 then
  
      retValArray = {}
      
    local ok, values = reaper.GetUserInputs('Add new RTPC automation track', 3, 'RTPC name,min,max',"name,0,1")
    
    local vi = 1
    
    for w in values:gmatch("[^,]+") do
      retValArray[vi] = w
      vi = vi + 1
    end
    
    userRTPCName = retValArray[1]
    userMin = retValArray[2]
    userMax = retValArray[3]
    
    if ok then
      AddJSFX(userRTPCName,userMin,userMax)
    end
    
  end

end

-- Collect FX envs from name, track and index

function CollectEnvs(RTPCInputName, rtpcTrack, fxIndex)

 -- laneNameArray = {}

local cLaneName

  -- Filter out already existing env lanes (by name) and do not add to array -- FIX

  if RTPCInputName ~= nil then -- here fix
    local laneName = RTPCInputName
    local isNamePresent = false

    if (RTPCInputName == "dummy") then
       -- reaper.Main_OnCommand(40884, 0) -- toggle show/hide sel env
    end

    -- check if stored name is present
    for _, existingName in ipairs(laneNameArray) do
        if existingName == laneName then
            isNamePresent = true
            break
        end
    end

    -- if not present, then add it to the lanenamearray
    if not isNamePresent then
        table.insert(laneNameArray, laneName)
        --table.remove(laneNameArray,i)
        cLaneName = laneName
    end

    -- check if stored name is actually present, remove at index if not
    for i=1, #envNameArray do
        if laneNameArray[i] ~= envNameArray[i] then
          table.remove(envNameArray, i)
          table.remove(laneNameArray, i)
        end
    end

    if fxIndex == nil then
      fxIndex = 0
    end


      for i=1, LaneCount() do
        trackEnv = reaper.GetFXEnvelope(rtpcTrack,fxIndex,0,true) -- FIX
       if trackEnv then
            envArray[i] = trackEnv
            else
              --table.remove(envArray,i)
          end
      
  end
end
  
end

-- Collect FX envs at 'Run'

function CollectEnvsInit()

  local laneName
  local cLaneName
  local thisEnv
  local trackEnv
  local pLaneName = {}
  
  for i=1, LaneCount() do
    thisEnv = reaper.GetFXEnvelope(rtpcTrack,i-1,0,false)
    retval, laneName = reaper.GetEnvelopeName(thisEnv)
  
   if laneName then
            local lanePrefix = laneName:match("([^/]+)/")
            lanePrefix = lanePrefix:gsub("^%s*(.-)%s*$", "%1")
            pLaneName[i] = lanePrefix
      end
    end

    for i=1, tableSize(pLaneName) do

      if pLaneName == nil then
        table.remove(pLaneName, i)
      end

     CollectEnvs(pLaneName[i], rtpcTrack, i-1) -- FIX not always index i
    end

end

-- Add JSFX slider plugin and auto-create lane for it

function AddJSFX(userRTPCName,userMin,userMax)

  RTPCInputName = userRTPCName
  
  -- JSFX code
  local jsfxCodeTemplate = [[
desc:ReaperToWwise_RTPC_Slider
slider1:0<%m,%n,0.005>%s
@slider
@sample
  ]]
  
   local jsfxCode = jsfxCodeTemplate:gsub("%%m" , userMin)
   jsfxCode = jsfxCode:gsub("%%n" , userMax)
   jsfxCode = jsfxCode:gsub("%%s" , userRTPCName)
  
  --Check if folder exists, if not, create it
  local dirPath = reaper.GetResourcePath() .. "/Effects/" .. "/MH_ReaScripts/"
  
  local dirExists = reaper.file_exists(dirPath)
  
  if not dirExists then
      local success = reaper.RecursiveCreateDirectory(dirPath, 1)
  end
  
  --Filename
  local fileName = "ReaperToWwise_RTPC_Slider" .. "_" .. userRTPCName .. ".jsfx"
  
  -- Save path
    local savePath = dirPath .. fileName
  
  -- Save to file (overwrite??)
  local file = io.open(savePath, "w")
  if file then
      file:write(jsfxCode)
      file:close()
  end
  
  -- Add JSFX to the track
  local jsfxIndex = reaper.TrackFX_AddByName(rtpcTrack, "JS: ReaperToWwise_RTPC_Slider" .. "_" .. userRTPCName, false, -1)
  
  -- FIX ?
  for i=1, LaneCount() do
    fxIndex = i
  end
  
  -- FIX ?
  if fxIndex == 0 or nil then
    for i=1, LaneCount() do
      fxIndex = i
    end
  end

  CollectEnvs(RTPCInputName, rtpcTrack, fxIndex)

end

-- Insert empty item at playcursor

function InsertEmptyItem()

  reaper.Main_OnCommand(40142,0)

end


-- Generate Soundbank -- FIX -- not needed

function GenerateSoundbank()

  --[[

  local ok, bankName = reaper.GetUserInputs('Generate Soundbank ', 1, 'Name of existing soundbank','')

  if not ok then
    bankName = "Soundbank"
  end
  
  if ok then
   GUI.Val("BankNameLabel",bankName)
  end
  
  local command = "ak.wwise.core.soundbank.generate"  
  local arg = reaper.AK_AkJson_Map()

  local pBankName = reaper.AK_AkVariant_String(bankName)
  local writeBool = reaper.AK_AkVariant_Bool(true)
  local banks = reaper.AK_AkVariant_String(soundbanks)
  local options = reaper.AK_AkJson_Map()
  reaper.AK_AkJson_Map_Set(arg, "soundbanks", banks)
  reaper.AK_AkJson_Map_Set(arg, "name", pBankName)
  reaper.AK_AkJson_Map_Set(arg, "writeToDisk", writeBool)
  
  reaper.AK_Waapi_Call(command, arg, options)
  
  reaper.AK_AkJson_ClearAll()

  --]]

end

-- RTPC help button

function RTPCHelp()
  
    reaper.ShowMessageBox(tostring(
    "RTPC help" .. string.char(10) ..
    string.char(10) ..
    "1. Press 'Add RTPC lane'" .. string.char(10) ..
    "2. Enter the name of the RTPC you want to control" .. string.char(10) ..
    "3. A seperate JSFX plugin will be added to the selected track with a single slider with the chosen name." .. string.char(10) ..
    "4. A track automation lane will automatically be created under the given track" .. string.char(10) ..
    "5. Repeat for every RTPC you need" .. string.char(10) .. string.char(10) ..
    "NOTE: If you want to set the RTPC value with an empty item, you are"
    .. string.char(10) .. "advised to disarm the RTPC automation lane –" .. string.char(10) ..
    "otherwise it will keep updating its current" .. string.char(10) .. "value at every update"
  ),tostring("ReaperToWwise"),0)

end

-- Open Github repo webpage

function OpenRepo()

  local success = reaper.CF_ShellExecute("https://github.com/mhasselbalch/MH_ReaperToWwise")
  if not success then
      reaper.ShowMessageBox("Failed to open repo webpage.", "Error", 0)
  end

end

-- Open donation site

function OpenCoffee()

  local success = reaper.CF_ShellExecute("https://www.buymeacoffee.com/mhasselbalch")
  if not success then
      reaper.ShowMessageBox("Failed to open webpage.", "Error", 0)
  end

end

-- Go to Discord room

function OpenDiscord()

  local success = reaper.CF_ShellExecute("https://discord.gg/XE4y5Fv7M8")
  if not success then
      reaper.ShowMessageBox("Failed to open webpage.", "Error", 0)
  end

end

function ConsoleWindowGUI()

  dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8')

local ctxConsole = reaper.ImGui_CreateContext('ReaperToWwise_Console')

local sans_serif = reaper.ImGui_CreateFont('sans-serif', 12)
reaper.ImGui_Attach(ctxConsole, sans_serif)

function consoleWindow()

  reaper.ImGui_LabelText(ctxConsole, "","LOG")

  flags = TableFlags_None
  reaper.ImGui_BeginTable(ctxConsole, "Log", 4, flags, 0, 0, 0) 

  reaper.ImGui_TableSetupColumn(ctxConsole, "label", flags)

  reaper.ImGui_TableNextRow(ctxConsole, flags)
  reaper.ImGui_TableSetColumnIndex(ctxConsole, 0)
  reaper.ImGui_Text(ctxConsole, "Call type")

  reaper.ImGui_TableNextRow(ctxConsole, flags)
  reaper.ImGui_TableSetColumnIndex(ctxConsole, 1)
  reaper.ImGui_Text(ctxConsole, "Call")

  reaper.ImGui_TableNextRow(ctxConsole, flags)
  reaper.ImGui_TableSetColumnIndex(ctxConsole, 2)
  reaper.ImGui_Text(ctxConsole, "Value")

  reaper.ImGui_TableNextRow(ctxConsole, flags)
  reaper.ImGui_TableSetColumnIndex(ctxConsole, 3)
  reaper.ImGui_Text(ctxConsole, "Time")

 reaper.ImGui_EndTable(ctxConsole)

end


local function loop()

  reaper.ImGui_PushFont(ctxConsole, sans_serif)
  
  reaper.ImGui_SetNextWindowSize(ctxConsole, 400, 80, reaper.ImGui_Cond_FirstUseEver())
  
  local visible, open = reaper.ImGui_Begin(ctxConsole, 'Console',1)
  
  if visible then
    consoleWindow()
    reaper.ImGui_End(ctxConsole)
  end
  reaper.ImGui_PopFont(ctxConsole)
  
  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)
end

-- main GUI window 

function MainWindowGUI()

dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8')

local ctxMain = reaper.ImGui_CreateContext('ReaperToWwise_MainWindow')
local ctxInstructions = reaper.ImGui_CreateContext('ReaperToWwise_Instructions')

local sans_serif = reaper.ImGui_CreateFont('sans-serif', 11)
reaper.ImGui_Attach(ctxMain, sans_serif)
reaper.ImGui_Attach(ctxInstructions,sans_serif)

local function mainWindow()
  local rv

  reaper.ImGui_LabelText(ctxMain, versionNumber, "ReaperToWwise")

  reaper.ImGui_LabelText(ctxMain, portNumber, "Port:")
  reaper.ImGui_LabelText(ctxMain, connectionStatus, "Status:")

  reaper.ImGui_SeparatorText(ctxMain, '')
    
  if reaper.ImGui_Button(ctxMain, 'Connect to port') then
    ConnectPort()
  end
  
  if reaper.ImGui_Button(ctxMain, 'Reconnect') then
    ReconnectPort()
  end
  
  if reaper.ImGui_Button(ctxMain, 'Help') then
    HelpWindowGUI()
  end

--[[
  if reaper.ImGui_Button(ctxMain, 'Tools') then
    ToolsWindowGUI()
  end
--]]

  --if reaper.ImGui_Button(ctxMain, 'Console') then
    --ConsoleWindowGUI()
  --end
  
  
  if reaper.ImGui_Button(ctxMain, 'Insert RTPC lane') then
    RTPCLane()
  end
  
  if reaper.ImGui_Button(ctxMain, 'Insert empty item') then
    InsertEmptyItem()
  end

  if reaper.ImGui_Button(ctxMain, '"StopAll"') then
    StopAllFunc()
  end

  reaper.ImGui_LabelText(ctxMain, "", "")

  reaper.ImGui_SeparatorText(ctxMain, 'RUN SCRIPT')
    if reaper.ImGui_Checkbox(ctxMain, "ON/OFF", runBool) then
    runBool = not runBool
   end
   --reaper.ImGui_Text(ctxMain, "")

    reaper.ImGui_LabelText(ctxMain, "", "")

   reaper.ImGui_SeparatorText(ctxMain, 'STOPALL ON TRANSPORT STOP')
    if reaper.ImGui_Checkbox(ctxMain, "ON/OFF",transportStopBool) then
    transportStopBool = not transportStopBool
   end
   reaper.ImGui_Text(ctxMain, "Will post 'StopAll' event when transport is stopped")

  reaper.ImGui_LabelText(ctxMain, "", "")

    reaper.ImGui_SeparatorText(ctxMain, 'RTPC EVALUATION SPEED CLAMP')
    bool, evalSpeedRV = reaper.ImGui_SliderDouble(ctxMain, " ", evalSpeedRV, 10.0, 100.0)
    reaper.ImGui_Text(ctxMain, "Lower values can increase Wwise CPU load.\n\zIf you experience Wwise/Reaper slowdows,\n\z try increasing this value.")

end

local function loop()
  reaper.ImGui_PushFont(ctxMain, sans_serif)
  reaper.ImGui_SetNextWindowSize(ctxMain, 400, 110, reaper.ImGui_Cond_FirstUseEver())
  local visible, open = reaper.ImGui_Begin(ctxMain, 'ReaperToWwise'.." "..versionNumber, true)
  if visible then
    mainWindow()
    reaper.ImGui_End(ctxMain)
  end
    reaper.ImGui_PopFont(ctxMain)
  
  if open then
    reaper.defer(loop)
  end
end

reaper.defer(loop)

end

-- Help window

function HelpWindowGUI()

dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8')

local ctxHelp = reaper.ImGui_CreateContext('ReaperToWwise_Help')

local sans_serif = reaper.ImGui_CreateFont('sans-serif', 12)
reaper.ImGui_Attach(ctxHelp, sans_serif)

local function helpWindow() 

  if reaper.ImGui_CollapsingHeader(ctxHelp, 'Use') then
    reaper.ImGui_SeparatorText(ctxHelp, 'HOW TO USE THIS TOOL:')
    reaper.ImGui_Text(ctxHelp, " \z
       1. Connect to Wwise via a chosen port  \n \z
       2. Create an empty item. \n \z
       3. Double click the item to enter 'Notes' \n \z
       4. Write your commands (see 'Commands'), seperate commands by comma and new line. \n \z
       5. Click 'Run' in the ReaperToWwise window. \n \z
       6. Start the transport.  \n \z
        \n \z
        NOTE: When you add new events and game syncs to the Wwise project, \n \z
        you will need to (re)generate the Soundbank for the script to be able to call them correctly.")
  end
  
  if reaper.ImGui_CollapsingHeader(ctxHelp, 'Commands') then
     reaper.ImGui_SeparatorText(ctxHelp, 'TEXT COMMANDS:')
     reaper.ImGui_LabelText(ctxHelp, "e/eventName", "Post event")
     reaper.ImGui_LabelText(ctxHelp, "sw/switchGroup/switchName", "Set switch")
     reaper.ImGui_LabelText(ctxHelp, "st/stateGroup/stateName", "Set state")
     reaper.ImGui_LabelText(ctxHelp, "r/rtpcName/rtpcValue", "Set RTPC")
     reaper.ImGui_LabelText(ctxHelp, "t/triggerName", "Set trigger")
  end
  
  if reaper.ImGui_CollapsingHeader(ctxHelp, 'RTPCs') then
    reaper.ImGui_SeparatorText(ctxHelp, 'HOW TO USE RTPC AUTOMATION LANES:')
    reaper.ImGui_Text(ctxHelp, " \z
      1. Press 'Add RTPC lane’ . \n \z
      2. Enter the name of the RTPC you want to control along with the minimum and maximum value. \n \z
      3. A seperate JSFX plugin will be added to the selected track \n \z
      with a single slider with the chosen name. \n \z
      4. A track automation lane will automatically be created under the given track. \n \z
      5. Repeat for every RTPC you need. \n \z
      \n \z
      NOTE: If you want to set the RTPC value with an empty item, \n \z
      you are advised to disarm the RTPC automation lane \n \z
      otherwise it will keep updating its current value at every update")
                            
  end
  
  if reaper.ImGui_CollapsingHeader(ctxHelp, 'About') then
     reaper.ImGui_SeparatorText(ctxHelp, 'WHO, WHAT, WHERE:')
     
     
     reaper.ImGui_Text(ctxHelp, "Reaper script that is able to post events \n \z
     and game syncs directly to Wwise via the WAAPI with no game engine running.")
     
     reaper.ImGui_Text(ctxHelp, " ")
     
     reaper.ImGui_Text(ctxHelp, "Created by Marc Hasselbalch ")
     
     reaper.ImGui_Text(ctxHelp, " ")
     
     local repoButton = reaper.ImGui_Button(ctxHelp, 'GO TO REPO')
     local coffeeButton = reaper.ImGui_Button(ctxHelp, 'BUY ME A COFFEE')
     local discordButton = reaper.ImGui_Button(ctxHelp, 'GO TO DISCORD')
    
     
    if repoButton then
      OpenRepo()
    end
    
    if coffeeButton then
      OpenCoffee()
    end
     
     if discordButton then
       OpenDiscord()
     end
      
  end
  
end

local function helpLoop()

  reaper.ImGui_PushFont(ctxHelp, sans_serif)
  
  reaper.ImGui_SetNextWindowSize(ctxHelp, 400, 80, reaper.ImGui_Cond_FirstUseEver())
  
  local visible, open = reaper.ImGui_Begin(ctxHelp, 'Help',1)
  
  if visible then
    helpWindow()
    reaper.ImGui_End(ctxHelp)
  end
  reaper.ImGui_PopFont(ctxHelp)
  
  if open then
    reaper.defer(helpLoop)
  end
end

reaper.defer(helpLoop)
end

-- Tools window

function ToolsWindowGUI()

dofile(reaper.GetResourcePath() ..
       '/Scripts/ReaTeam Extensions/API/imgui.lua')('0.8')

local ctxTools = reaper.ImGui_CreateContext('ReaperToWwise_Tools')

local sans_serif = reaper.ImGui_CreateFont('sans-serif', 12)
reaper.ImGui_Attach(ctxTools, sans_serif)

local function toolsWindow() 
--[[
    reaper.ImGui_SeparatorText(ctxTools, 'RTPC EVALUATION SPEED CLAMP')
    bool, evalSpeedRV = reaper.ImGui_SliderDouble(ctxTools, " ", evalSpeedRV, 10.0, 100.0)
    reaper.ImGui_Text(ctxTools, "Lower values can increase Wwise CPU load.\n\zIf you experience Wwise/Reaper slowdows, try increasing this value.")

     reaper.ImGui_SeparatorText(ctxTools, 'STOPALL ON TRANSPORT STOP')
    if reaper.ImGui_Checkbox(ctxTools, "ON/OFF",transportStopBool) then
    transportStopBool = not transportStopBool
   end
   reaper.ImGui_Text(ctxTools, "Will post 'StopAll' event when transport is stopped")
--]]
  end
       
local function toolsLoop()

  reaper.ImGui_PushFont(ctxTools, sans_serif)
  
  reaper.ImGui_SetNextWindowSize(ctxTools, 500, 80, reaper.ImGui_Cond_FirstUseEver())
  
  local visible, open = reaper.ImGui_Begin(ctxTools, 'Tools',1)
  
  if visible then
    toolsWindow()
    reaper.ImGui_End(ctxTools)
 end

  reaper.ImGui_PopFont(ctxTools)
  
  if open then
    reaper.defer(toolsLoop)
  end
 reaper.defer(toolsLoop)
end
end



-- "StopAll" event post

function StopAllFunc() 
  if stopTrigger == false then
    WaapiPostEvent("StopAll")
    stopTrigger = true
  end
end


-- Run functions init

  MainWindowGUI()
  Init()
  PlayState()
  PlayPos()
  --CheckState()  
  --RunScript()

