' ********************************************************************'
' **  MyMedia - Springboard version'
' **'
' **  Initial revision'
' **  Brian Taylor el.wubo@gmail.com'
' **  Copyright (c) 2010'
' **  Distribute under the terms of the GPL'
' **'
' **  Contributions from'
' **  Brian Taylor'
' **  Jim Truscello'
' **'
' **  This code was derived from:'
' **  Sample PlayVideo App'
' **  Copyright (c) 2009 Roku Inc. All Rights Reserved.'
' ********************************************************************'

Function makePosterScreen(port) As Object

    screen=CreateObject("roPosterScreen")

    screen.SetMessagePort(port)
    screen.SetListStyle("arced-square")
    screen.SetListDisplayMode("best-fit")
    cats = CreateObject("roArray",3,false)
    cats[0] = "My Music"
    cats[1] = "My Videos"
    cats[2] = "My Photos"
    'screen.SetListNames(cats)
    screen.SetBreadCrumbEnabled(true)

    return {
        screen: screen,
        port: port,
        GetSelection: psGetSelection,
        SetPlayList: psSetPlayList,
        GetPosters: psGetPosters,
        posters: []}

End Function

Function psGetPosters()
    return m.posters
End Function

Function psSetPlayList(pl)
    posters=CreateObject("roList")
    for each song in pl.items
        posters.Push(song.GetPosterItem())
    next

    m.posters = posters
    m.screen.SetIconArray(posters)
    m.screen.SetFocusedListItem(0)
End Function

Function psGetSelection(timeout)
    print "psGetSelection"
    m.screen.Show()

    while true
        msg = wait(timeout, m.screen.GetMessagePort())
        print "psGetSelection typemsg = "; type(msg)

        if msg.isScreenClosed() then return -1

        if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                print "psGetSelection got: " + Stri(msg.GetIndex())
                return msg.GetIndex()
            end if
        end if
    end while
End Function

' still here so i can maybe do video stuff later... '
Function CreateVideoItem(desc as object)
    item = {   ContentType:"episode"
               SDPosterUrl:"file://pkg:/images/DanGilbert.jpg"
               HDPosterUrl:"file://pkg:/images/DanGilbert.jpg"
               IsHD:False
               HDBranded:False
               ShortDescriptionLine1:"Dan Gilbert asks, Why are we happy?"
               ShortDescriptionLine2:""
               Description:"Harvard psychologist Dan Gilbert says our beliefs about what will make us happy are often wrong -- a premise he supports with intriguing research, and explains in his accessible and unexpectedly funny book, Stumbling on Happiness."
               Rating:"NR"
               StarRating:"80"
               Length:1280
               Categories:["Technology","Talk"]
               Title:"Dan Gilbert asks, Why are we happy?"}

     return item
End Function

Function ShowResumeDialog() as Boolean
    print "ShowResumeDialog"
    
    port = CreateObject("roMessagePort") 
    dialog = CreateObject("roMessageDialog") 
    dialog.SetMessagePort(port) 
 
    dialog.SetTitle("Starting position") 
    dialog.SetText("Resume from last saved position?") 
    dialog.AddButton(1, "resume playing") 
    dialog.AddButton(2, "play from beginning") 
    dialog.Show() 
 
    while true 
        dlgMsg = wait(0, dialog.GetMessagePort()) 
        exit while                 
    end while 

    if dlgMsg.GetIndex() = 1 then
        return true
    else
        return false
    end if
End Function 

Sub RegDelete(key as String, section as String)
    print "RegDelete"
    
    reg = CreateObject("roRegistry")
    sect = CreateObject("roRegistrySection", section)
    
    if sect.Exists(key) then    ' the documentation is pretty poor
        sect.Delete(key)        ' not sure if we need to check for existence before    
        sect.Flush()            ' deleting it or if we need to flush (probably)
    end if
End Sub

Sub RegSave(key as String, value as String, section as String)
    print "RegSave"
    
    reg = CreateObject("roRegistry")
    sect = CreateObject("roRegistrySection", section)
    
    sect.Write(key,value)
    sect.Flush()
End Sub

Function RegGet(key as String, section as String) as Dynamic 
    print "RegGet"
    
    reg = CreateObject("roRegistry")
    sect = CreateObject("roRegistrySection", section)
    
    if sect.Exists(key) then
        return sect.Read(key)
    else
        return invalid
    end if
End Function

Function ShowServerProblemDialog(s As String) as Boolean
    print "ShowServerProblemDialog "; s
    
    port = CreateObject("roMessagePort") 
    dialog = CreateObject("roMessageDialog") 
    dialog.SetMessagePort(port) 
  
    dialog.SetTitle("Server Problem") 
    dialog.SetText("Cannot retrieve media list from:"+chr(10)+s+chr(10)+"Is the address correct and is the server running?")
    dialog.AddButton(1, "Enter server address manually") 
    dialog.AddButton(2, "Try again") 
    dialog.AddButton(3, "Abort") 
    dialog.Show() 
 
    while true 
        dlgMsg = wait(0, dialog.GetMessagePort()) 
        exit while                 
    end while 
    
    if dlgMsg.isScreenClosed() then 
        print "ShowServerProblemDialog screen closed"
        return true
    end if
    
    if dlgMsg.GetIndex() = 1 then
        kb = CreateObject("roKeyboardScreen")
        kb.SetMessagePort(port) 
        kb.SetMaxLength(50)
        kb.SetTitle("Enter server ip address and port")
        kb.SetDisplayText("Example:  http://192.168.1.100:8001/feed")
        kb.SetText(s)
        kb.AddButton(1,"Finished")
        kb.Show()
        while true 
            msg = wait(0, kb.GetMessagePort()) 
     
            if type(msg) = "roKeyboardScreenEvent" then
                print "message received" 
                if msg.isButtonPressed() then
                    if msg.GetIndex() = 1  then
                        svr = kb.GetText() 
                        print "New server: "; svr
                        RegSave("Server",svr, "Settings")
                        exit while
                    end if 
                end if 
            end if 
        end while 
    else if dlgMsg.GetIndex() = 3 then
        return true
    end if
    return false
End Function

Function ShowListProblemDialog() as Boolean ' returns true if Abort was selected
    print "ShowListProblemDialog"
    
    port = CreateObject("roMessagePort") 
    dialog = CreateObject("roMessageDialog") 
    dialog.SetMessagePort(port) 
 
    dialog.SetTitle("Media List Problem") 
    dialog.SetText("No media items retrieved.  Is the media path set correctly? Does the selected path contain playable files?") 
    dialog.AddButton(1, "Ok") 
    dialog.AddButton(2, "Abort") 
    dialog.Show() 
 
    dlgMsg = wait(0, dialog.GetMessagePort())
print "got message"    
    if dlgMsg.isScreenClosed() then 
        print "ShowListProblemDialog screen closed"
        return true
    end if
    
    if dlgMsg.GetIndex() = 2 then return true
    return false
End Function

Sub SaveOffset(title as String, offset as String)
    print "SaveOffset"
    
    reg = CreateObject("roRegistry")        
    sect = CreateObject("roRegistrySection", "Resume")
    
    dt = CreateObject("roDateTime")
    now = dt.asSeconds()
    value = now.toStr() + offset    ' timestamp concatenated w/offset as string
    sect.Write(title,value)
    sect.Flush()    

    ' Check for more than 100 saved resume points
    keys = sect.GetKeyList()
    if keys.Count() > 100  then
        oldest = &h7fffffff
        keys.ResetIndex()
        key = keys.GetIndex()
        while key <> invalid
            val = RegGet(key, "Resume")
            timestamp = left(val,10) ' unless we go back in time, timestamps are 10 digits
            ts = timestamp.toInt()
            if ts < oldest then 
                oldest = ts
                oldestKey = key
            end if
            key = keys.GetIndex()
        end while
        RegDelete(oldestKey, "Resume")
    end if    
End Sub

Function GetOffset(title as String) as Integer
    print "GetOffset"

    offset = RegGet(title, "Resume")
    if offset <> invalid then
        offset = Right(offset,offset.Len() - 10) ' trim off 10 digits of timestamp
        return offset.toInt()
    else
        return 0
    end if
End Function

Sub Main()
    'initialize theme attributes like titles, logos and overhang color'

    app = CreateObject("roAppManager")
    initTheme(app, "media")

    'display a fake screen while the real one initializes. this screen'
    'has to live for the duration of the whole app to prevent flashing'
    'back to the roku home screen.'
    screenFacade = CreateObject("roPosterScreen")
    screenFacade.show()

    rss = CreateMediaRSSConnection()
    if rss=invalid then
        print "unexpected error in CreateMediaRSSConnection"
    end if

    port = CreateObject("roMessagePort")
    
    while true    
        ' Try "Transient" section first for backwards compatibility
        server = RegGet("Server", "Transient")
print "Transient server "; server        
        if server = invalid then
            server = RegGet("Server", "Settings")
        end if
        if server = invalid then
            print "Setting server to default"
            server = "SERVER_NAME" + "/feed"
        else
            print "Retrieved server from registry"
        end if
        print "server = "; server    
        pl = rss.GetSongListFromFeed(server)
        if pl = invalid then
            if ShowServerProblemDialog(server) then 
                print "Outta here!"
                return
            end if
        elseif pl.items.Count() = 0         ' looks like the server always returns the mymusic folder
            if ShowListProblemDialog() then ' should it always return all top level folders???
                print "Outta here!"
                return
            end if
        else
            exit while
        end if
    end while
    
    pscr = makePosterScreen(port)
    pscr.SetPlayList(pl)

    audio = CreateObject("roAudioPlayer")
    audio.SetMessagePort(port)
    audio.SetLoop(false)

    currentBaseSong = 0
    currentTheme = "media"
    layers = CreateObject("roList")
    layers.AddTail( { playlist: pl, last_selected: 0 } )
    dontKillPosterScreen = false

    pscr.screen.Show()

    while true
        msg = wait(0, port)
        print "mainloop msg = "; type(msg)
        print "type = "; msg.GetType()
        print "index = "; msg.GetIndex()

        if msg.isRemoteKeyPressed() then
            stop
        else if msg.isButtonPressed() then
            print "button pressed idx= ";msg.GetIndex()
            print "button pressed data= ";msg.GetData()
stop            
        else if msg.isScreenClosed() then
            print "isScreenClosed()"
            if layers.Count() = 1 then exit while

            'if dontKillPosterScreen then
                'do nothing. we weren't called by the user
print "dontKillPosterScreen"                
                dontKillPosterScreen = false
            'else
                'recreate the pscr since it just got closed'
                print "fetching old pl"

                'pscr = makePosterScreen(port)
                last_selected = layers.GetTail().last_selected
                layers.RemoveTail()
                rec = layers.GetTail()

                pscr.SetPlayList(rec.playlist)
                if rec.playlist.theme <> currentTheme then
                    currentTheme = rec.playlist.theme
                    initTheme(app, currentTheme)
                end if
                pscr.screen.Show()
                pscr.screen.SetFocusedListItem(last_selected)
            'end if
        else if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                song = msg.GetIndex()

                posters = pscr.GetPosters()
                item = posters[song].item

                if item.IsPlayable() then
print item.GetType()                
                    'play the selected song'

                    audio.Stop()
                    audio.ClearContent()

                    'unless its really a video'
                    if item.GetType() = "mp4" then
                        offset = GetOffset(item.GetTitle())
                        if offset > 0 then
                            if not ShowResumeDialog() then offset = 0
                        end if
                        print "Starting from position "; offset
                        offset = displayVideo(item.GetMedia(),item.GetTitle(),offset)
                        if offset = 0 then
                            ' Delete reg key
                            RegDelete(item.GetTitle(), "Resume")
                        else
                            ' Save offset
                            SaveOffset(item.GetTitle(),offset.toStr())
                        end if
                    else if item.GetType() = "mp3" then ' or wma
                        showSpringboardScreen(audio, port, item)
                        REM audio.AddContent(item.GetPlayable())
                        REM print item.GetTitle()
                        REM currentBaseSong = song
                        REM print "current base song ";Stri(song)
                        REM audio.Play()
                    else if item.GetType() = "jpg" then
                        print "Photo: "; item.GetTitle()
                        print item.GetMedia()
                        ss = CreateObject("roSlideShow")
                        ss.show()
                        ss.addContent({url: item.GetMedia() })
                    end if

                else
                    'load the sub items and display those'

                    print "loading subitems for "; song; " - "; item.GetTitle()
                    pl = item.GetSubItems()
                    if pl <> invalid and pl.items.Count() <> 0 then
                        layers.AddTail( { playlist: pl, last_selected: song } )
                        dontKillPosterScreen = true
                        oldScr = pscr.screen
                        if pl.theme <> currentTheme then
                            currentTheme = pl.theme
                            initTheme(app, currentTheme)
                        end if
                        'pscr = makePosterScreen(port)
                        pscr.SetPlayList(pl)
                        pscr.screen.SetBreadcrumbText("1","2")
                        pscr.screen.Show()
                        'oldScr.Close()
                        currentBaseSong = 0

                    else if pl = invalid then
                        if ShowServerProblemDialog(server) then
                            print "Outta here!"
                            return
                        end if
                    else if ShowListProblemDialog() then
                        print "Outta here!"
                        return
                    end if
                end if
            end if
        else if type(msg) = "roAudioPlayerEvent" then
            if msg.isStatusMessage() then
                print "audio status: ";msg.GetMessage()
            end if
            if msg.isRequestSucceeded() then
                print "audio isRequestSucceeded"

                'queue the next song'
                posters = pscr.GetPosters()
                song = currentBaseSong + 1
                maxsong = posters.Count() - 1

                if song > maxsong
                    song = 0
                end if

                print "song: ";Stri(song)
                print "max song: ";Stri(maxsong)

                audio.Stop()
                audio.ClearContent()
                item = posters[song].item

                'stop if the next item is a video'
                if not item.GetType() = "mp4" then
                    audio.AddContent(item.GetPlayable())
                    audio.Play()
                end if

                pscr.screen.SetFocusedListItem(song)
                currentBaseSong = song
            end if
            if msg.isPartialResult() then
                print "audio partial result"
            end if
            if msg.isRequestFailed() then
                print "audio request failed: ";msg.GetMessage()
                print "error code: ";Stri(msg.GetIndex())
            end if
            if msg.isFullResult() then
                print "isFullResult"
            end if
            print "end roAudioPlayerEvent"
        end if
    end while

    'showSpringboardScreen(item)'
    
    'exit the app gently so that the screen doesnt flash to black'
    print "Exiting app"
    screenFacade.showMessage("")
    sleep(25)
End Sub

'*************************************************************'
'** Set the configurable theme attributes for the application'
'** '
'** Configure the custom overhang and Logo attributes'
'*************************************************************'

Sub initTheme(app as object, themeName as String)
    theme = CreateObject("roAssociativeArray")

    theme.OverhangPrimaryLogoOffsetSD_X = "72"
    theme.OverhangPrimaryLogoOffsetSD_Y = "15"
    theme.OverhangSliceSD = "pkg:/images/Overhang_BackgroundSlice_SD43.png"
    theme.OverhangPrimaryLogoSD  = "pkg:/images/" + themeName + "_Logo_Overhang_SD43.png"

    theme.OverhangPrimaryLogoOffsetHD_X = "123"
    theme.OverhangPrimaryLogoOffsetHD_Y = "20"
    theme.OverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_HD.png"
    theme.OverhangPrimaryLogoHD  = "pkg:/images/" + themeName + "_Logo_Overhang_HD.png"
    
    print "theme logo "; theme.OverhangPrimaryLogoHD
    app.SetTheme(theme)

End Sub


'*************************************************************'
'** showSpringboardScreen()'
'*************************************************************'

Function showSpringboardScreen(audio as object, port as object, item as object) As Boolean
    print "showSpringboardScreen"

x = createObject("roAssociativeArray")
x.AddReplace("key 1", "val 1")   
x.AddReplace("key 2", "val 2")   
x.AddReplace("key 3", "val 3")   
x.AddReplace("key 4", "val 4")   
'y = x.Reset()
for each y in x
   print y
'   y = x.Next()
end for
    
    screen = CreateObject("roSpringboardScreen")

    screen.SetMessagePort(port)
    screen.AllowUpdates(false)
    song = item.GetPlayable()
    song.Title = item.GetTitle()
    poster = item.GetPosterItem()
    song.SDPosterURL = poster.SDPosterURL
    song.HDPosterURL = poster.HDPosterURL
        
    song.Album = "Uh, what album?"
    song.Album = poster.ShortDescriptionLine1
    song.Artist = "Who is this, anyway?"
    song.Artist = poster.ShortDescriptionLine2

    screen.SetContent(song)
    screen.SetDescriptionStyle("audio") 
    screen.ClearButtons()
    screen.AddButton(1,"Pause")
    screen.AddButton(2,"Go Back")
    screen.SetStaticRatingEnabled(false)
    'screen.SetPosterStyle("rounded-square-generic") ' not needed for audio type
    screen.SetProgressIndicatorEnabled(true)
    screen.AllowUpdates(true)
    
    print item.GetTitle()
    'audio.AddContent(item.GetPlayable())
    audio.AddContent(song)
    print "StreamFormat: "; song.LookUp("StreamFormat")
    print "ContentType: "; song.LookUp("ContentType")
    'print item.GetType()
    'currentBaseSong = song
    'print "current base song ";Stri(song)

for each s in song
  print s
  print song.LookUp(s)
end for  
    
    screen.Show()
    
    paused = false
    audio.Play()

    progress = -1
    length = 5*60     ' 5 minutes
    cumulative = 0
    timer = CreateObject("roTimespan")
    while true
        msg = wait(1000, port)
        if not paused and progress >= 0 then 
            progress = cumulative + timer.TotalSeconds()
print cumulative, timer.TotalSeconds(), progress
            screen.SetProgressIndicator(progress, length)
        end if
        if msg <> invalid then
            print "Message: "; msg.GetIndex(); " "; msg.GetData()
            if type(msg) = "roSpringboardScreenEvent"
                if msg.isScreenClosed()
                    print "Springboard Screen closed"
                    exit while                
                else if msg.isButtonPressed()           
                    print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                    if msg.GetIndex() = 1 then
                        if paused then
                            paused = false
                            audio.Resume()
                            timer.Mark()
                            screen.AllowUpdates(false)
                            screen.ClearButtons()
                            screen.AddButton(1,"Pause")
                            screen.AddButton(2,"Go Back")
                            screen.AllowUpdates(true)
                        else
                            cumulative = progress
                            paused = true
                            audio.Pause()
                            screen.AllowUpdates(false)
                            screen.ClearButtons()
                            screen.AddButton(1,"Play")
                            screen.AddButton(2,"Go Back")
                            screen.AllowUpdates(true)
                        end if
                    else if msg.GetIndex() = 2
                        print "Outta here!"
                        return true
                    end if
                else
                    print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                end if
            else if type(msg) = "roAudioPlayerEvent" then
                print "AudioPlayerEvent: ";msg.GetType(); " msg: "; msg.GetMessage()
                if msg.isStatusMessage() then
                    if msg.GetMessage() = "start of play" and progress < 0 then
                        progress = 0
                        timer.Mark()
                    else if msg.GetMessage() = "end of stream" then
                        return true
                    end if
                end if
            else
                print "unexpected type.... type=";msg.GetType(); " msg: "; msg.GetMessage()
            end if
        end if
    end while

    return true
End Function


'*************************************************************'
'** displayVideo()'
'*************************************************************'

Function displayVideo(url,title,offset) as Integer
    print "Displaying video: "
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)
    video.SetPositionNotificationPeriod(10)

    'bitrates  = [0]'          ' 0 = no dots'
    'bitrates  = [348000]'    ' <500 Kbps = 1 dot'
    'bitrates  = [664000]'    ' <800 Kbps = 2 dots'
    'bitrates  = [996000]'    ' <1.1Mbps  = 3 dots'
    'bitrates  = [2048000]'    ' >=1.1Mbps = 4 dots'
    bitrates  = [1500]    
    urls = [url]
    qualities = ["SD"]
    'qualities = ["HD"]'
    
    videoclip = CreateObject("roAssociativeArray") ' MOVE THIS STUFF TO dataModel.brs!!!
    videoclip.StreamBitrates = bitrates
    videoclip.StreamUrls = urls
    videoclip.StreamQualities = qualities
    videoclip.StreamFormat = "mp4"
    videoclip.Title = title
    videoclip.PlayStart = offset

    'videoclip.StreamFormat = "wmv"'  NEEDS TO BE FIXED/ADDED!!!
 
    video.SetContent(videoclip)
    video.show()

    nowpos = offset
    
    while true
        msg = wait(0, video.GetMessagePort())
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 'ScreenClosed event'
                print "Closing video screen"
                exit while
            else if msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
print nowpos
            else if msg.isRequestFailed()
                print "play failed: "; msg.GetMessage()
            else if msg.isFullResult()
                return 0
            else if msg.isPartialResult()
                return nowpos
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            end if
        end if
    end while
    return nowpos
End Function

