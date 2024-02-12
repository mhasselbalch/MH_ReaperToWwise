

-- ReaperToWwise
-- by Marc Hasselbalch
-- 2024
-- https://github.com/mhasselbalch/MH_ReaperToWwise

versionNumber = "0.9"

-- Initialize tables and other 
function Init()
  RTPCInputName = ""
  loopCount = 1 
  checkArray = {} 
  itemArray = {} 
  numArray = {} 
  startsArray = {}
  laneNameArray = {}
  currentItem = 0
  selItemArray = {}  
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
  envNameArray = {}
  envCollArray = {}
  envByNameArray = {}
  envFormatArray = {}
  inputNameArray = {}
  envStrArray = {}
  envStateArray = {}
  iCount = 0
  fIndex = 0
  
  portNumber = 8080
  
  if reaper.AK_Waapi_Connect("127.0.0.1", portNumber) then
    WaapiConnect(tonumber(portNumber))
    WaapiRegisterObject()
    WaapiSetListener()
    
  end
  
end

-- Port connection

function ReconnectPort()
 
  WaapiConnect(tonumber(portNumber))
  WaapiRegisterObject()
  WaapiSetListener()

  
end

-- Port reonnection

function ConnectPort()

  local ok, values = reaper.GetUserInputs('Connect to Wwise at port: ', 1, 'Port number','')
  
  WaapiConnect(tonumber(values))
  WaapiRegisterObject()
  WaapiSetListener()
  
  portNumber = values
  
end


--GUI initialize

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please install 'Lokasenna's GUI library v2 for Lua', available on ReaPack, then run the 'Set Lokasenna_GUI v2 library path.lua' script in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

GUI.req("Classes/Class - Label.lua")()
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Frame.lua")()
GUI.req("Classes/Class - Textbox.lua")()
-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end

GUI.name = "ReaperToWwise" .. versionNumber
GUI.x, GUI.y, GUI.w, GUI.h = 0, 0, 240, 240
GUI.anchor, GUI.corner = "mouse", "C"

-- Script state functions
-- FIX
function ScriptState()

  scriptRunning = not scriptRunning
  
  if scriptRunning == false then
    GUI.Val("StateLabel2",tostring("Disabled"))
    GUI.Val("EnableButton",tostring("Disable"))
  end

 if scriptRunning == true then
    GUI.Val("StateLabel2",tostring("Enabled"))
    GUI.Val("EnableButton",tostring("Enable"))
 end
 
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
  end

  if reaper.AK_Waapi_Connect("127.0.0.1", portNumber) then
  
    GUI.elms.PortLabel.color = "white"
    GUI.Val("PortLabel",tostring(portNumber))
  end
  
  if reaper.AK_Waapi_Connect("127.0.0.1", portNumber) == false  then
     reaper.ShowMessageBox("Could not connect at the chosen port", "ReaperToWWise",0)
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

-- RTPC

function AutomationRTPC()

  local playState = reaper.GetPlayState()
  local currentPlayTime = reaper.GetPlayPositionEx()
  local rtpcTrack = reaper.GetSelectedTrack(0,0) -- FIX
  
   if rtpcTrack == nil then
    rtpcTrack = reaper.GetTrack(0,0)
   end
   
    if trackEnv == nil then
       trackEnv = reaper.GetFXEnvelope(rtpcTrack,0,0,true) -- FIX?
    end
   
  -- Add dummy RTPC lane if no user-made ones have been created (FIX ?)
  if trackEnv == nil then
   AddJSFX("dummy",0,1)
  end
  
  if playState == 1 then
    EvalRTPC()
  end
  
  
  if playState == 1 then
    for i=1, tableSize(laneNameArray) do
      --EvalRTPC(laneNameArray[i])
    end
  end
    
   reaper.defer(AutomationRTPC)

end

-- Evaluate automation envelope track value
function EvalRTPC()
    
    for i=1, tableSize(laneNameArray) do
      inputNameArray[i] = laneNameArray[i]
      envNameArray[i] = tostring(inputNameArray[i]) .. " " .. "/" .. " " .. "ReaperToWwise_RTPC_Slider"--.jsfx"
    end
    
    local playState = reaper.GetPlayState()
    local blockSize =  128
    local sampleRate = 48000
    local currentPlayTime = reaper.GetPlayPositionEx()
    local thisTrack = reaper.GetSelectedTrack(0,0) -- FIX
    
    -- FIX
    if thisTrack == nil then
      thisTrack = reaper.GetTrack(0,0) -- to prevent crashes (for now)
    end 
    
    local laneCount = LaneCount() -- FIX
  
      for i=1, tableSize(laneNameArray) do -- FIX 
         
         if playState == 1 then
          
              envByNameArray[i] = reaper.GetTrackEnvelopeByName(thisTrack, envNameArray[i])
              
              retval, str = reaper.GetEnvelopeStateChunk(envByNameArray[i], "ARM", false)
              envStrArray[i] = str
              
              local pattern = "ARM%s+(%d+)"
            
              for value in str:gmatch(pattern) do
                envStateArray[i] = tonumber(value)
              end
           
            if envStateArray[i] == 1 then
                local retVal, envVal = reaper.Envelope_Evaluate(envByNameArray[i], currentPlayTime, sampleRate, blockSize)
                envValArray[i] = envVal

            --local rtpcName = envNameArray[i]
            local rtpcName = laneNameArray[i]
            local rtpcValFrom = envValArray[i]
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

    reaper.defer(EvalRTPC)

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

-- Count items on selected track

function CountSelectedItems()
 
 -- FIX
 if thisTrack == nil then
  thisTrack = reaper.GetTrack(0,0)
 end
 
  selItemCount = reaper.CountTrackMediaItems(thisTrack)
  
  -- FIX
  reaper.defer(CountSelectedItems)
  
end


--Parse empty item notes based on seperator

function ParseNotes(notes)
 

  local t = {}
  
  if playState == 0 then
  end
    
       local str = notes
       local function helper(line) 
          table.insert(t, line) 
          return ""
       end  
       helper((str:gsub("(.-)\r?\n", helper)))

      for i=1, #t do  
     
    -- Parse event
    if string.sub(t[i], 1, 1) == "e" then   
        local  pe = t[i]:gsub('%,','')
        local  pee = string.sub(pe, 3,40) -- FIX this could cause issues
         WaapiPostEvent(pee)
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
        
        local playState = reaper.GetPlayState()
        local playPosition = reaper.GetPlayPositionEx(0)
        local thisTrack = reaper.GetTrack(0,0)
 
        if selItemCount == nil then
          reaper.AddMediaItemToTrack(thisTrack)
        end

       for i = 0, selItemCount - 1 do
               itemArray[i + 1] = reaper.GetTrackMediaItem(thisTrack,i) 
               startsArray[i + 1] = reaper.GetMediaItemInfo_Value(itemArray[i + 1], "D_POSITION")
              -- idArray[i + 1] = reaper.GetMediaItemInfo_Value(itemArray[i + 1], "IP_ITEMNUMBER")
       end
       
      limitTableSize(startsArray,selItemCount)
      limitTableSize(itemArray,selItemCount)
       
       -- FIX
      if playState == 0 then
      iCount = 0
        for i=1, selItemCount do
          triggeredPositions[i] = false
        end
      end

      if playState == 1 then
 
        nextVal, nextIndex = GetClosestIndex(startsArray, playPosition)
      
        if nextIndex == nil then
          nextIndex = 0 -- FIX
        end
      
        if nextIndex > 0 and iCount == 0 then
          fIndex = nextIndex
          iCount = 1
          for i=1, fIndex do
            triggeredPositions[i] = true
          end
        end
      

          for i, sIndex in ipairs(startsArray) do
                
                
                if playPosition >= sIndex and not triggeredPositions[i] then
        
                  -- FIX
                  if i > selItemCount then
                      --something to prevent mediatrack crash
                  end
                  
                    local retval, notes = reaper.GetSetMediaItemInfo_String(itemArray[i], "P_NOTES", '', false)
                    ParseNotes(notes)
                    triggeredPositions[i] = true 
                    
                    elseif playPosition < sIndex then
                      triggeredPositions[i] = false 
                    end
            end
            else
             -- Triggerpos reset
            for i, _ in ipairs(triggeredPositions) do
                triggeredPositions[i] = false
            end 

          end
      
      reaper.defer(GetItemStarts)
      
end

-- Button, run script
function RunScript()
  
  -- FIX
  thisTrack = reaper.GetTrack(0,0)
  playState = reaper.GetPlayState()
  
  CountSelectedItems()
  GetItemStarts()
   
   if selItemCount == 0 then
     reaper.ShowConsoleMsg("")
    reaper.ShowMessageBox(tostring("Please select at least 1 item on the timeline, press 'Run' and start the transport."), tostring("ReaperToWwise"),0)
   end
   
    selItemCountLabel = selItemCount
    LaneCount()
    CollectEnvsInit()
    AutomationRTPC()
    UpdateGUI()
     
end

-- Update gui
function UpdateGUI() 
     
     if selItemCount == nil then
      GUI.Val("SelItemCount",tostring("none"))
     end
     
     if selItemCount ~= nil then
     GUI.Val("SelItemCount",tostring(selItemCount))
     end

end

-- Instruction button

function Instructions()

reaper.ShowMessageBox(tostring(
"1. Connect to Wwise via a chosen port" .. string.char(10) ..
"2. Create an empty item" .. string.char(10) ..
"3. Double click the item to enter 'Notes'" .. string.char(10) ..
"4. Write your commands (see 'Commands'), seperate commands by commas and new line" .. string.char(10) ..
"5. Click 'Run' in the ReaperToWwise window" .. string.char(10) ..
"6. Start the transport" .. string.char(10) .. string.char(10) ..
"NOTE: When you add new events and game syncs to the Wwise project, you will need to (re)generate the Soundbank for the script to be able to call them correctly." .. string.char(10)
),
tostring("ReaperToWwise"),0)

end

-- Commands button

function Commands()

  reaper.ShowMessageBox(tostring(
  "COMMANDS" .. string.char(10) ..
  string.char(10) ..
  "e/eventName"
  ..string.char(10)..
  "post event" 
  .. string.char(10) .. string.char(10) ..
  "sw/switchGroup/switchName"
  ..string.char(10) ..
  "set switch"
  .. string.char(10) .. string.char(10) ..
  "st/stateGroup/stateName"
  .. string.char(10) ..
  "set state"
  .. string.char(10) .. string.char(10) ..
  "r/rtpcName/rtpcValue"
  .. string.char(10) ..
  "set RTPC value"
  .. string.char(10) .. string.char(10) ..
  "t/triggerName"
  ..string.char(10) ..
  "post trigger"
  ),
  tostring("ReaperToWwise"),0) 

end


-- Automation lane count

function LaneCount()

  if rtpcTrack == nil then
    rtpcTrack = reaper.GetTrack(0,0) -- FIX ?
  end
  
  laneCount = reaper.CountTrackEnvelopes(rtpcTrack) 

  reaper.defer(LaneCount)
  
  return laneCount
end

-- RTPC lane

function RTPCLane()
  
  if reaper.GetPlayState() ~= 0 then
    reaper.ShowMessageBox("Please stop the transport before adding new RTPC lanes", "ReaperToWwise",0)
  end
  
   -- FIX
  if reaper.GetPlayState() == 0 then
  
      retValArray = {}
      
    local ok, values = reaper.GetUserInputs('Add new automation track', 3, 'RTPC name,min,max',"name,0,1")
    
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

local cLaneName

  -- Filter out already existing env lanes (by name) and do not add to array -- FIX
  local laneName = RTPCInputName
  local isNamePresent = false
  
  for _, existingName in ipairs(laneNameArray) do
      if existingName == laneName then
          isNamePresent = true
          break
      end
  end

  if not isNamePresent then
      table.insert(laneNameArray, laneName)
      cLaneName = laneName
  end
  
  if rtpcTrack == nil then
    rtpcTrack = reaper.GetTrack(0,0)
  end
  
  if fxIndex == nil then
    fxIndex = 0
  end

    for i=1, LaneCount() do
      trackEnv = reaper.GetFXEnvelope(rtpcTrack,fxIndex,0,true) -- FIX
     if trackEnv then
          envArray[i] = trackEnv
          else
            break
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
  
  rtpcTrack = reaper.GetSelectedTrack(0,0)
  
  if rtpcTrack == nil then
    rtpcTrack = reaper.GetTrack(0,0) -- FIX
  end
  
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
  
  -- get selected track, FIX
   rtpcTrack = reaper.GetSelectedTrack(0, 0)
  
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
  
  local currentPlayTime = reaper.GetPlayPositionEx()
  local playState = reaper.GetPlayState() 
  
  CollectEnvs(RTPCInputName, rtpcTrack, fxIndex)
  
  AutomationRTPC()

end


-- Generate Soundbank -- FIX

function GenerateSoundbank()

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

-- Open repo webpage

function OpenRepo()

  local success = reaper.CF_ShellExecute("https://github.com/mhasselbalch/MH_ReaperToWwise")
  if not success then
      reaper.ShowMessageBox("Failed to open repo webpage.", "Error", 0)
  end

end


-- "StopAll" event call

function StopAllFunc () 
  WaapiPostEvent("StopAll")
end


--GUI 

GUI.New("RunButton", "Button", {
    z = 11,
    x = 16,
    y = 190,
    w = 48,
    h = 24,
    caption = "Run",
    font = 3,
    col_txt = "white",
    col_fill = "elm_frame",
    func = RunScript
})

GUI.New("StopAll", "Button", {
    z = 11,
    x = 148,
    y = 190,
    w = 48,
    h = 24,
    caption = "StopAll",
    font = 3,
    col_txt = "white",
    col_fill = "elm_frame",
    func = StopAllFunc
})

GUI.New("TitleLabel", "Label", {
    z = 11,
    x = 16,
    y = 10,
    caption = "ReaperToWwise".." "..versionNumber,
    font = 4,
    color = "white",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("InstructionButton", "Button", {
    z = 11,
    x = 16,
    y = 34,
    w = 95,
    h = 20,
    caption = "Instructions",
    font = 4,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = Instructions
})

GUI.New("CommandsButton", "Button", {
    z = 11,
    x = 16,
    y = 60,
    w = 95,
    h = 20,
    caption = "Commands",
    font = 4,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = Commands
})

GUI.New("RTPCHelp", "Button", {
    z = 11,
    x = 16,
    y = 86,
    w = 95,
    h = 20,
    caption = "RTPC help",
    font = 4,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = RTPCHelp
})

GUI.New("RTPCButton", "Button", {
    z = 11,
    x = 16,
    y = 112,
    w = 95,
    h = 20,
    caption = "Add RTPC lane",
    font = 4,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = RTPCLane
})

--[[
GUI.New("SoundbankButton", "Button", {
    z = 11,
    x = 16,
    y = 138,
    w = 128,
    h = 20,
    caption = "Generate Soundbank",
    font = 4,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = GenerateSoundbank
})
--]]

GUI.New("ConnectButton", "Button", {
    z = 11,
    x = 148,
    y = 16,
    w = 74,
    h = 20,
    caption = "Connect",
    font = 4,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = ConnectPort
})

GUI.New("ReconnectButton", "Button", {
    z = 11,
    x = 148,
    y = 42,
    w = 74,
    h = 20,
    caption = "Reconnect",
    font = 4,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = ReconnectPort
})

GUI.New("OpenRepoButton", "Button", {
    z = 11,
    x = 148,
    y = 112,
    w = 74,
    h = 20,
    caption = "Go to repo",
    font = 4,
    col_txt = "txt",
    col_fill = "elm_frame",
    func = OpenRepo
})


GUI.New("ConnectionLabel", "Label", {
    z = 11,
    x = 148,
    y = 70,
    caption = "Port:",
    font = 4,
    color = "gray",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("PortLabel", "Label", {
    z = 11, 
    x = 148,
    y = 86,
    caption = "not connected",
    font = 4,
    color = "white",
    bg = "wnd_bg",
    shadow = false
})

--[[
GUI.New("BankLabel", "Label", {
    z = 11, 
    x = 148,
    y = 104,
    caption = "Bank name:",
    font = 4,
    color = "gray",
    bg = "wnd_bg",
    shadow = false
})

GUI.New("BankNameLabel", "Label", {
    z = 11, 
    x = 148,
    y = 120,
    caption = "[BankName]",
    font = 4,
    color = "white",
    bg = "wnd_bg",
    shadow = false
})
--]]

GUI.New("Frame1", "Frame", {
    z = 24,
    x = 0,
    y = 0,
    w = 400,
    h = 256,
    shadow = false,
    fill = false,
    color = "elm_frame",
    bg = "wnd_bg",
    round = 0,
    text = "",
    txt_indent = 0,
    txt_pad = 0,
    pad = 4,
    font = 4,
    col_txt = "txt"
})


-- Run functions init

  GUI.Init()
  GUI.Main()
  Init()
  

