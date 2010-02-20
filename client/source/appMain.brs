' ********************************************************************'
' **  MyMusic'
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
    for each song in pl
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
            endif
        endif
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

Sub RegDelete(key as String)    ' may have to add a "section" parameter later

    print "RegDelete"
    reg = CreateObject("roRegistry")

    'Use the "Transient" section for now
    sect = CreateObject("roRegistrySection", "Transient")
    
    if sect.Exists(key) then    ' the documentation is pretty poor
        sect.Delete(key)        ' not sure if we need to check for existence before    
        sect.Flush()            ' deleting it or if we need to flush (probably)
    end if

End Sub

Sub RegSave(key as String, value as String) ' may have to add a "section" parameter later

    print "RegSave"
    reg = CreateObject("roRegistry")
    
    'Use the "Transient" section for now
    sect = CreateObject("roRegistrySection", "Transient")
    sect.Write(key,value)
    sect.Flush()

End Sub

Function RegGet(key as String) as Dynamic  ' may have to add a "section" parameter later

    print "RegGet"
    reg = CreateObject("roRegistry")

    'Use the "Transient" section for now
    sect = CreateObject("roRegistrySection", "Transient")
    
    if sect.Exists(key) then
        return sect.Read(key)
    else
        return invalid
    end if
        
End Function

Sub ShowServerProblemMsg(s As String)

    print "ShowServerProblemMsg "; s
    port = CreateObject("roMessagePort") 
    dialog = CreateObject("roParagraphScreen") 
    dialog.SetMessagePort(port) 
 
    dialog.SetTitle("Server Problem") 
    dialog.AddHeaderText("Cannot retrieve media list")
    dialog.AddParagraph("Cannot retrieve media list from:")
    dialog.AddParagraph(s)
    dialog.AddParagraph("Is the address correct and is the server running?")
    dialog.AddButton(1, "Enter server address manually") 
    dialog.AddButton(2, "Try again") 
    dialog.Show() 
 
    while true 
        dlgMsg = wait(0, dialog.GetMessagePort()) 
        exit while                 
    end while 
    
    if dlgMsg.GetIndex() = 1 then
        kb = CreateObject("roKeyboardScreen")
        kb.SetMessagePort(port) 
        kb.SetTitle("Enter server ip address and port")
        kb.SetDisplayText("Example:  http://192.168.1.100:8001/feed")
        kb.SetText(s)
        kb.AddButton(1,"Finished")
        kb.Show()
        while true 
            msg = wait(0, kb.GetMessagePort()) 
     
            if type(msg) = "roKeyboardScreenEvent" then
            print "message received" 
                if msg.isScreenClosed() then
                    return  
     
                else if msg.isButtonPressed() then
                    if msg.GetIndex() = 1  then
                        svr = kb.GetText() 
                        print "New server: "; svr
                        RegSave("Server",svr)
                        exit while
                    end if 
                end if 
            end if 
        end while 
    end if
End Sub 

Sub ShowListProblemDialog()

    print "ShowListProblemDialog"
    port = CreateObject("roMessagePort") 
    dialog = CreateObject("roMessageDialog") 
    dialog.SetMessagePort(port) 
 
    dialog.SetTitle("Media List Problem") 
    dialog.SetText("No media items retrieved.  Is the media path set correctly? Does the selected path contain playable files?") 
    dialog.AddButton(1, "Ok") 
    dialog.Show() 
 
    while true 
        dlgMsg = wait(0, dialog.GetMessagePort()) 
        exit while                 
    end while 
End Sub 

Sub Main()
    'initialize theme attributes like titles, logos and overhang color'
    initTheme()

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
        server = RegGet("Server")
        if server = invalid then
            print "Setting server to default"
            server = "SERVER_NAME" + "/feed"
        else
            print "Retrieved server from registry"
        end if
        print "server = "; server    
        pl = rss.GetSongListFromFeed(server)
        if pl = invalid then
            ShowServerProblemMsg(server)
        elseif pl.Count() = 0
            ShowListProblemDialog()
            return
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
    layers = CreateObject("roList")
    layers.AddTail( { playlist: pl, last_selected: 0 } )

    pscr.screen.Show()

    while true
        msg = wait(0, port)
        print "mainloop msg = "; type(msg)
        print "type = ";msg.GetType()

        if msg.isScreenClosed() then
            print "isScreenClosed()"
            if layers.Count() = 1 then return

            'recreate the pscr since it just got closed'
            print "fetching old pl"

            pscr = makePosterScreen(port)
            last_selected = layers.GetTail().last_selected
            layers.RemoveTail()
            rec = layers.GetTail()

            pscr.SetPlayList(rec.playlist)
            pscr.screen.Show()
            pscr.screen.SetFocusedListItem(last_selected)

        else if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                song = msg.GetIndex()

                posters = pscr.GetPosters()
                item = posters[song].item

                if item.IsPlayable() then
                    'play the selected song'

                    audio.Stop()
                    audio.ClearContent()

                    'unless its really a video'
                    if item.GetType() = "mp4" then
                        offset = 0
                        regoffset = RegGet(item.GetTitle())
                        if regoffset <> invalid then
                            if ShowResumeDialog() then offset = regoffset.toInt()
                        end if
                        print "Starting from position "; offset
                        offset = displayVideo(item.GetMedia(),item.GetTitle(),offset)
                        if offset = 0 then
                            ' Delete reg key
                            RegDelete(item.GetTitle())
                        else
                            ' Save offset
                            RegSave(item.GetTitle(),offset.toStr())
                        end if
                    else
                        audio.AddContent(item.GetPlayable())
                        print item.GetTitle()
                        currentBaseSong = song
                        print "current base song ";Stri(song)
                        audio.Play()
                    endif

                else
                    'load the sub items and display those'

                    print "loading subitems for "; song
                    pl = item.GetSubItems()
                    if pl <> invalid and pl.Count() <> 0 then
                        layers.AddTail( { playlist: pl, last_selected: song } )
                        pscr.SetPlayList(pl)
                        currentBaseSong = 0
                    else if pl = invalid then
                        ShowServerProblemMsg(server)
                    else
                        ShowListProblemDialog()
                    endif
                endif
            endif
        else if type(msg) = "roAudioPlayerEvent" then
            if msg.isStatusMessage() then
                print "audio status: ";msg.GetMessage()
            endif
            if msg.isRequestSucceeded() then
                print "audio isRequestSucceeded"

                'queue the next song'
                posters = pscr.GetPosters()
                song = currentBaseSong + 1
                maxsong = posters.Count() - 1

                if song > maxsong
                    song = 0
                endif

                print "song: ";Stri(song)
                print "max song: ";Stri(maxsong)

                audio.Stop()
                audio.ClearContent()
                item = posters[song].item

                'stop if the next item is a video'
                if not item.GetType() = "mp4" then
                    audio.AddContent(item.GetPlayable())
                    audio.Play()
                endif

                pscr.screen.SetFocusedListItem(song)
                currentBaseSong = song
            endif
            if msg.isPartialResult() then
                print "audio partial result"
            endif
            if msg.isRequestFailed() then
                print "audio request failed: ";msg.GetMessage()
                print "error code: ";Stri(msg.GetIndex())
            endif
            if msg.isFullResult() then
                print "isFullResult"
            endif
            print "end roAudioPlayerEvent"
        endif
    end while

    'showSpringboardScreen(item)'
    
    'exit the app gently so that the screen doesnt flash to black'
    screenFacade.showMessage("")
    sleep(25)
End Sub

'*************************************************************'
'** Set the configurable theme attributes for the application'
'** '
'** Configure the custom overhang and Logo attributes'
'*************************************************************'

Sub initTheme()

    app = CreateObject("roAppManager")
    theme = CreateObject("roAssociativeArray")

    theme.OverhangPrimaryLogoOffsetSD_X = "72"
    theme.OverhangPrimaryLogoOffsetSD_Y = "15"
    theme.OverhangSliceSD = "pkg:/images/Overhang_BackgroundSlice_SD43.png"
    theme.OverhangPrimaryLogoSD  = "pkg:/images/media_Logo_Overhang_SD43.png"

    theme.OverhangPrimaryLogoOffsetHD_X = "123"
    theme.OverhangPrimaryLogoOffsetHD_Y = "20"
    theme.OverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_HD.png"
    theme.OverhangPrimaryLogoHD  = "pkg:/images/media_Logo_Overhang_HD.png"
    
    app.SetTheme(theme)

End Sub


'*************************************************************'
'** showSpringboardScreen()'
'*************************************************************'

Function showSpringboardScreen(item as object) As Boolean
    port = CreateObject("roMessagePort")
    screen = CreateObject("roSpringboardScreen")

    print "showSpringboardScreen"
    
    screen.SetMessagePort(port)
    screen.AllowUpdates(false)
    if item <> invalid and type(item) = "roAssociativeArray"
        screen.SetContent(item)
    endif

    screen.SetDescriptionStyle("generic") 'audio, movie, video, generic
                                        ' generic+episode=4x3,
    screen.ClearButtons()
    screen.AddButton(1,"Play")
    screen.AddButton(2,"Go Back")
    screen.AddButton(3,"Smile")
    screen.SetStaticRatingEnabled(false)
    screen.AllowUpdates(true)
    screen.Show()

    downKey=3
    selectKey=6
    while true
        msg = wait(0, screen.GetMessagePort())
        if type(msg) = "roSpringboardScreenEvent"
            if msg.isScreenClosed()
                print "Screen closed"
                exit while                
            else if msg.isButtonPressed()
                    print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                    if msg.GetIndex() = 1
                         displayVideo()
                    else if msg.GetIndex() = 2
                         return true
                    else if msg.GetIndex() = 3
                         print "Hello world"
                         return true
                    endif
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        else 
            print "wrong type.... type=";msg.GetType(); " msg: "; msg.GetMessage()
        endif
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
    
    videoclip = CreateObject("roAssociativeArray")
    videoclip.StreamBitrates = bitrates
    videoclip.StreamUrls = urls
    videoclip.StreamQualities = qualities
    videoclip.StreamFormat = "mp4"
    videoclip.Title = title
    videoclip.PlayStart = offset

    'videoclip.StreamFormat = "wmv"'
 
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
            endif
        end if
    end while
End Function

