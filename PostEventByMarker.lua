

function WaapiConnect()

  if(reaper.AK_Waapi_Connect("127.0.0.1", 8080)) then
    reaper.ShowConsoleMsg("")
    reaper.ShowConsoleMsg("Connected to Wwise")
    
end

function WaapiRegisterObject()
    local registerArg = reaper.AK_AkJson_Map()
    local registerCommand = "ak.soundengine.registerGameObj"
      
    reaper.AK_AkJson_Map_Set(registerArg, "gameObject", reaper.AK_AkVariant_Int(0))
    reaper.AK_AkJson_Map_Set(registerArg, "name", reaper.AK_AkVariant_String("GameObj"))
    reaper.AK_Waapi_Call(registerCommand, registerArg, reaper.AK_AkJson_Map())
end

function WaapiSetListener()

   
    local listenerCommand = "ak.soundengine.setDefaultListeners"
    local listenerOptions = reaper.AK_AkJson_Map()
    local listenerArray = reaper.AK_AkJson_Array()
    local listenerArgs = reaper.AK_AkJson_Map()
    reaper.AK_AkJson_Array_Add(listenerArray, reaper.AK_AkVariant_Int(0))
    reaper.AK_AkJson_Map_Set(listenerArgs,"listeners", listenerArray)
    
    reaper.AK_Waapi_Call(listenerCommand, listenerArgs, listenerOptions)

end


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

end


function GetTime()

  reaper.defer(GetTime)

  local currentPlayTime = reaper.GetPlayPosition()
   
end


function OutsideDefer()
  loopCount = 1
  checkArray = { } 
  

end


function GetMarker()
  
  local currentPlayTime = reaper.GetPlayPosition()
  local lastMarkerNum = reaper.GetLastMarkerAndCurRegion(0, currentPlayTime)
  local ret, isrgn, pos, rgnend, markerName, markrgnindexnumber = reaper.EnumProjectMarkers(lastMarkerNum)
  
  
  
  reaper.ShowConsoleMsg("")

  if markerName then
    
    checkArray[loopCount] = ret
   
    loopCount = loopCount + 1
  end
  
  if loopCount > 2 then
    loopCount = 1
  end
  
  if checkArray[1] ~= checkArray[2] then
 
    WaapiPostEvent(markerName)
  end
  
 
  
  reaper.defer(GetMarker)
  
end

--Run functions
WaapiConnect()
WaapiRegisterObject()
WaapiSetListener()
OutsideDefer()
GetMarker()

