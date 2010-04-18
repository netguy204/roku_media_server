' started as next-dfb2d56
' ********************************************************************'
' **  MyMedia - Springboard/SlideShow/Playall&Shuffle Posters version'
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

Function makePosterScreen(bread1 as String, bread2 as String) As Object
    print "makePosterScreen"

    port = CreateObject("roMessagePort")

    screen=CreateObject("roPosterScreen")

    screen.SetMessagePort(port)
    screen.SetListStyle("arced-square")
    screen.SetListDisplayMode("best-fit")
    screen.SetBreadCrumbEnabled(true)
    screen.SetBreadCrumbText(bread1, bread2)

    return {
        screen: screen,
        port: port,
        GetSelection: psGetSelection,
        SetPlayList: psSetPlayList,
        GetPosters: psGetPosters,
        GetBC1: psGetBC1,
        GetBC2: psGetBC2,
        posters: [],
        theme: "",
        breadCrumb1: bread1
        breadCrumb2: bread2}
End Function

Function psGetBC1()
    return m.breadCrumb1
End Function

Function psGetBC2()
    return m.breadCrumb2
End Function

Function psGetPosters()
    return m.posters
End Function

Function psSetPlayList(pl)
    posters=CreateObject("roList")
    for each song in pl.items
        posters.Push(song.GetPosterItem())
    next

    m.theme = pl.theme
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
    'print "RegSave"

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

Function GetAutoplay() as Boolean
    print "GetAutoplay"

    autoplay = RegGet("Autoplay","Settings")
    if autoplay = "Yes" then return true
    return false
End Function


Sub ShowServerWarning()
    print "ShowServerWarning"

    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetTitle("Server updated")
    dialog.SetText("You must exit for the new server to take effect.")
    dialog.AddButton(1, "Ok")
    dialog.Show()

    dlgMsg = wait(0, dialog.GetMessagePort())
End Sub

Function GetYesNo(title as String) as String
    print "GetYesNo"

    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.SetText("Yes or No")
    dialog.AddButton(1, "Yes")
    dialog.AddButton(2, "No")
    dialog.Show()

    dlgMsg = wait(0, dialog.GetMessagePort())
    if dlgMsg.GetIndex() = 1 then return "Yes"
    return "No"
End Function

Function ShowSettings(currentSettings as Object, toolate=true) as Object
    print "ShowSettings"

    currentServer = currentSettings.server
    currentDelay = currentSettings.ssDelay
    currentAutoplay = currentSettings.autoplay
    newserver = currentServer
    newdelay = currentDelay
    newautoplay = currentAutoplay

    port = CreateObject("roMessagePort")
    settings = invalid

    while true
        settings = CreateObject("roParagraphScreen")
        settings.SetMessagePort(port)
        settings.AddHeaderText("Current configuration:")
        settings.AddParagraph("Server:"+chr(9)+chr(9)+chr(9)+currentServer)
        settings.AddParagraph("Slide show delay:"+chr(10)+currentDelay+" seconds")
        settings.AddParagraph("Autoplay subfolders:"+chr(10)+currentAutoplay)
        settings.AddButton(1,"Edit server")
        settings.AddButton(2,"Edit slide show delay")
        settings.AddButton(3,"Edit autoplay")
        settings.AddButton(9,"Finished")

        settings.Show()

        msg = wait(0, port)

        if msg.GetIndex() = 1 then
            newserver = EditDialog("Enter server ip address and port",currentServer,"Example:  http://192.168.1.100:8001/feed",50)
        else if msg.GetIndex() = 2 then
            newdelay = EditDialog("Enter slide show delay",currentDelay,"Slide show delay in seconds",4)
        else if msg.GetIndex() = 3 then
            newautoplay = GetYesNo("Automatically play subfolders?")
        else
            exit while
        end if
        if newdelay <> currentDelay then
            nd = newdelay.toInt()
            newdelay = nd.toStr()
            RegSave("Slide show delay", newdelay, "Settings")
            currentDelay = newdelay
        else if newserver <> currentServer
            RegSave("Server", newserver, "Settings")
            if newserver <> currentServer and toolate then
                ShowServerWarning()
            end if
            currentServer = newserver
        else if newautoplay <> currentAutoplay
            RegSave("Autoplay",newautoplay,"Settings")
            currentAutoplay = newautoplay
        end if
    end  while

print "New server: "; newserver, "New delay: "; newdelay, "New autoplay: ";newautoplay
    newSettings = {server: currentServer, ssDelay: currentDelay, autoplay: currentAutoplay}
    return newSettings
End Function

Function EditDialog(title as String, val as String, hint as String, maxlen as Integer)
    port = CreateObject("roMessagePort")
    kb = CreateObject("roKeyboardScreen")
    kb.SetMessagePort(port)
    kb.SetMaxLength(maxlen)
    kb.SetTitle(title)
    kb.SetDisplayText(hint)
    kb.SetText(val)
    kb.AddButton(1,"Finished")
    kb.Show()
    while true
        msg = wait(0, kb.GetMessagePort())

        if type(msg) = "roKeyboardScreenEvent" then
            if msg.isScreenClosed() then
                ' only way to get here is if the Home remote button was pressed (I think),
                ' so just bail out so the app can exit gracefully
                newval = val
                exit while
            end if
            if msg.isButtonPressed() then
                if msg.GetIndex() = 1  then
                    newval = kb.GetText()
                    print "New value: "; newval
                    exit while
                end if
            end if
        end if
    end while

    return newval
End Function

Function ShowOkAbortDialog(title as String, text as String) as Boolean ' returns true if Abort was selected
    print "ShowOkAbortDialog"

    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.SetText(text)
    dialog.AddButton(1, "Ok")
    dialog.AddButton(2, "Abort")
    dialog.Show()

    dlgMsg = wait(0, dialog.GetMessagePort())
    if dlgMsg.isScreenClosed() then
        print "ShowOkAbortDialog screen closed"
        return true
    end if

    if dlgMsg.GetIndex() = 2 then return true
    return false
End Function

Sub ShowOkDialog(title as String, text as String)
    print "ShowOkDialog"

    port = CreateObject("roMessagePort")
    dialog = CreateObject("roMessageDialog")
    dialog.SetMessagePort(port)

    dialog.SetTitle(title)
    dialog.SetText(text)
    dialog.AddButton(1, "Ok")
    dialog.Show()

    dlgMsg = wait(0, dialog.GetMessagePort())
End Sub

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

Sub UpdateNowPlaying(pscrns as Object, text as String, level as Integer)
    print "UpdateNowPlaying"

    tmpposters = pscrns[0].screen.GetContentList()
    for each p in tmpposters
        ' This is ugly, but I'm tired of these stupid encapsulated objects
        if p.ShortDescriptionLine1 = "Now Playing" then
            p.ShortDescriptionLine2 = text
            exit for
        end if
    end for
    pscrns[0].screen.SetContentList(tmpposters)
    if level = 0 then pscrns[0].screen.show()
End Sub

Function ShowBusy(text as String) as Object
    port = CreateObject("roMessagePort")
    busyDlg = CreateObject("roOneLineDialog")
    busyDlg.SetTitle(text)
    busyDlg.showBusyAnimation()
    busyDlg.SetMessagePort(port)
    busyDlg.Show()
    return busyDlg
End Function

Function GetConfig() as Object
    print "GetConfig"

    server = RegGet("Server", "Settings")
    if server = invalid then
        ' Try "Transient" section for backwards compatibility
        server = RegGet("Server", "Transient")
        if server <> invalid then
            RegSave("Server", server, "Settings")
        end if
    end if
    if server = invalid then
        print "Setting server to default"
        server = "SERVER_NAME" + "/feed"
        RegSave("Server", server, "Settings")
    else
        print "Retrieved server from registry"
    end if
    print "server = "; server

    ssDelay = RegGet("Slide show delay","Settings")
    if ssDelay = invalid then ssDelay = "5"
    print "slide show delay = "; ssDelay

    autoplay = RegGet("Autoplay","Settings")
    if autoplay = invalid then
        autoplay = "Yes"
        RegSave("Autoplay","Yes","Settings")
    end if
    print "autoplay = "; autoplay

    return {server: server, ssDelay: ssDelay, autoplay: autoplay}
End Function

Sub Main()
    print "Main"

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
        print "unexpected error in CreateMediaRSSConnection"    ' Can this really fail???
    end if

    currentConfig = GetConfig()

    while true
        busyDlg = ShowBusy("retrieving...")

        pl = rss.GetSongListFromFeed(currentConfig.server)
        if pl = invalid then
            svrContact = false
            items = CreateObject("roList")
            pl = {items: items, theme: "media"}
        else
            svrContact = true
            CreateSimplePoster(pl.items, "Now Playing", "pkg:/images/nowplaying_square.jpg", "Return to Audio Player", "playerctl")
        end if

        ' Add the "settings" poster before proceeding (may be only poster if no contact w/server established)
        CreateSimplePoster(pl.items, "My Settings", "pkg:/images/settings_square.jpg", "Channel Settings", "settings")

        if svrContact then exit while

        if ShowOkAbortDialog("Server Problem","Contact with server has not been established.  Check your settings and that the server is running.") then
            print "Outta here!"
            'exit the app gently so that the screen doesnt flash to black'
            print "Exiting app"
            screenFacade.showMessage("")
            sleep(25)
            return
        end if

        ' Stay here to allow user to change server without having to exit and re-enter channel
        tmpscr = makePosterScreen("","")
        tmpscr.SetPlayList(pl)
        currentTheme = "media"
        tmpscr.screen.Show()
        busyDlg.Close()
        port = tmpscr.screen.GetMessagePort()
        while true
            msg = wait(0,port)
            if msg.isScreenClosed() then
                print "isScreenClosed()"
                print "Outta here!"
                'exit the app gently so that the screen doesnt flash to black'
                print "Exiting app"
                screenFacade.showMessage("")
                sleep(25)
                return
            else if msg.isListItemSelected() then   ' There's only one item - the settings
                initTheme(app, "settings")
                tmpscr.screen.Show()
                currentConfig = ShowSettings(currentConfig,false)
                autoplay = GetAutoplay()
                initTheme(app, "media")
                tmpscr.screen.Close()
                exit while
            end if
        end while
    end while

    ' Create simple script we can call to cause/allow garbage collection to happen (at least I think it does)
    gc="Function Main()"+chr(10)+"return 999"+chr(10)+"End Function"+chr(10)
    WriteAsciiFile("tmp:/gc.brs",gc)
    ' Create an array to store Poster screens as we traverse the hierarchy
    pscr = CreateObject("roArray",1,true)

    ' Create the top level folders poster screen
    pscr[0] = makePosterScreen("","")
    pscr[0].SetPlayList(pl)
    level = 0

    audio = CreateObject("roAudioPlayer")
    audioPlaying = false
    shuffleMode = false
    randgets = 0
    randgots = 0

    currentBaseSong = 0
    currentTheme = "media"

    pscr[0].screen.Show()
    busyDlg.Close()
    port = pscr[level].screen.GetMessagePort()
    audio.SetMessagePort(port)
    autoplay = GetAutoplay()

    while true
        msg = wait(10, port)
        if audioPlaying and shuffleMode then
            if randgots < randgets then
                idx = GetNextSong(audio,audioContent,autoplay)
                '!!!*** if gns = -1 ***!!!
                randgots = randgots + 1
if randgots = randgets then print "randgots = ";randgots
            end if
        end if

        if type(msg) = "roPosterScreenEvent" then
            if msg.isScreenClosed() then
                print "isScreenClosed()"
                ' If the top level screen rcv'd the "closed" msg, we're outta here
                if level = 0 then exit while
                ' Otherwise, need to show the next screen up in the hierarchy
                print "Going up..."
                pscr.Pop()  ' throw away the current level
                level = level - 1
                port = pscr[level].screen.GetMessagePort()
                audio.SetMessagePort(port)
                if pscr[level].theme <> currentTheme then
                    currentTheme = pscr[level].theme
                    initTheme(app, currentTheme)
                end if
                pscr[level].screen.Show()
            else if msg.isListItemSelected() then
                itemIndex = msg.GetIndex()

                posters = pscr[level].GetPosters()
                item = posters[itemIndex].item

                if item.IsPlayable() then

                    if item.GetContentType() = "movie"
                        audio.Stop()
                        audio.ClearContent()
                        audioPlaying = false
                        UpdateNowPlaying(pscr,"",level)
                        offset = GetOffset(item.GetTitle())
                        if offset > 0 then
                            if not ShowResumeDialog() then offset = 0
                        end if
                        print "Starting from position "; offset
                        'offset = displayVideo(item.GetMedia(),item.GetTitle(),offset)
                        offset = displayVideo(item.GetPlayable(),offset)
                        if offset = 0 then
                            ' Delete reg key
                            RegDelete(item.GetTitle(), "Resume")
                        else
                            ' Save offset
                            SaveOffset(item.GetTitle(),offset.toStr())
                        end if
                    else if item.GetContentType() = "audio" then
                        audio.Stop()
                        audio.ClearContent()
                        audioPlaying = false
                        ' Create an array to store audio playlists as we traverse the hierarchy
                        audioContent = CreateObject("roArray",1,true)
                        buildAudioContent(audioContent,posters,itemIndex)
                        audioPlaying = true
                        shuffleMode = false
                        currentSong = showSpringboardScreen(audio, port, audioContent)
                        UpdateNowPlaying(pscr,currentSong.song.title,level)
                        randgets = 0
                        randgots = 0
                    else if item.GetType() = "image" then
                        ssBusyDlg = ShowBusy("retrieving...")
                        print "Photo: "; item.GetTitle()
                        print item.GetMedia()
                        ss = CreateObject("roSlideShow")
                        ssCl = CreateObject("roArray",1,true)
                        newidx = buildSlideShowContent(posters,itemIndex,ssCl)
                        ss.SetContentList(ssCl)
                        ss.SetPeriod(currentConfig.ssDelay.toInt())
                        ss.SetTextOverlayHoldTime(2000)
                        ss.SetMessagePort(port)
                        ss.SetDisplayMode("scale-to-fit")
                        ss.SetUnderScan(5)
                        ss.SetNext(newidx,true)
                        ss.Show()
                        ssBusyDlg.Close()
                        ssWait = true
                    else if item.GetContentType() = "playlist" then
                        busyDlg = ShowBusy("retrieving...")
                        print "Playlist: "; item.GetTitle()
                        pl = item.GetSubItems()
                        if pl <> invalid and pl.items.Count() <> 0 then
                            ptmp = makePosterScreen("","")
                            ptmp.SetPlayList(pl)

                            audioContent = CreateObject("roArray",1,true)
                            buildAudioContent(audioContent,ptmp.GetPosters(),-1)
                            if GetNextSong(audio,audioContent,false) >= 0 then
                                audioPlaying = true
                                currentSong = showSpringboardScreen(audio, port, audioContent, invalid, busyDlg, false, false)
                                UpdateNowPlaying(pscr,currentSong.song.title,level)
                                randgets = 0
                                randgots = 0
                                initTheme(app,pscr[level].theme)
                            else
                                busyDlg.Close()
                                if ShowOkAbortDialog("Error in playlist","No audio items retrieved.") then
                                    print "Outta here!"
                                    exit while
                                end if
                            end if
                        else if pl = invalid then
                            busyDlg.Close()
                            if ShowOkAbortDialog("Server Problem","Communications with the server has been lost.") then
                                print "Outta here!"
                                exit while
                            end if
                        else
                            busyDlg.Close()
                            if ShowOkAbortDialog("Empty playlist","No audio items retrieved.") then
                                print "Outta here!"
                                exit while
                            end if
                        end if
                    end if

                else if item.IsSimple("settings")
                    initTheme(app, "settings")
                    pscr[0].screen.Show()
                    currentConfig = ShowSettings(currentConfig)
                    autoplay = GetAutoplay()
                    initTheme(app, "media")
                    pscr[0].screen.Show()
                else if item.IsSimple("playerctl")
                    if not audioPlaying then
                        ShowOkDialog("Audio Player Control","There's nothing playing at the moment")
                    else
                        initTheme(app,"music")
                        currentSong = showSpringboardScreen(audio, port, audioContent, currentSong,invalid,true,shuffleMode)
                        initTheme(app,"media")
                        UpdateNowPlaying(pscr,currentSong.song.title,level)
                        randgets = 0
                        randgots = 0
                    end if
                else if item.IsSimple("playall") or item.IsSimple("shuffleall") then
                    if item.IsSimple("shuffleall") then
                        busyDlg = ShowBusy("shuffling...")
                        shuffleMode = true
                    else
                        busyDlg = ShowBusy("retrieving...")
                        shuffleMode = false
                    end if
                    audio.Stop()
                    audio.ClearContent()
                    audioPlaying = false
                    UpdateNowPlaying(pscr,"",level)
                    ' Create an array to store audio playlists as we traverse the hierarchy
                    audioContent = CreateObject("roArray",1,true)
                    buildAudioContent(audioContent,posters,-1)
                    if GetNextSong(audio,audioContent,autoplay) >= 0 then
                        if shuffleMode then
                            if autoplay then
                                randget = rnd(250)
                            else
                                top = audioContent.Peek()
                                songs = top.songs
                                randget = rnd(songs.Count())
                            end if
                            for randgot = 0 to randget
                                GetNextSong(audio,audioContent,autoplay)
                    '!!!*** if gns = -1 ***!!!
                            end for
                        end if
                        audioPlaying = true
                        currentSong = showSpringboardScreen(audio, port, audioContent, invalid, busyDlg, false, shuffleMode)
                        UpdateNowPlaying(pscr,currentSong.song.title,level)
                        randgets = 0
                        randgots = 0
                    else
                        busyDlg.Close()
                        if ShowOkAbortDialog("Empty folder","No audio items retrieved.  Is the media path set correctly? Does the selected path contain playable files?") then
                            print "Outta here!"
                            exit while
                        end if
                    end if
                else
                    startidx = 0
                    items = CreateObject("roList")
                    pl1 = {items: items, theme: "media"}
                    if (level = 0 and item.GetTitle() = "My Music") or pscr[level].theme = "music" then
                        CreateSimplePoster(pl1.items, "Shuffle All", "pkg:/images/shuffleall_square.jpg", "Shuffle everything", "shuffleall")
                        CreateSimplePoster(pl1.items, "Play All", "pkg:/images/playall_square.jpg", "Play everything", "playall")
                        startidx = 2
                    end if

                    'load the sub items and display those'
                    busyDlg = ShowBusy("retrieving...")
                    print "loading subitems for "; itemIndex; " - "; item.GetTitle()
                    pl = item.GetSubItems()
                    if pl <> invalid and pl.items.Count() <> 0 then
                        for each i in pl1.items
                            pl.items.AddHead(i)
                        end for

                        if pl.theme <> currentTheme then
                            currentTheme = pl.theme
                            initTheme(app, currentTheme)
                        end if

                        ' increment the level we're on
                        level = level + 1

                        ' setup breadcrumbs for new poster screen
                        if level = 1 then
                            bc1 = item.GetTitle()
                            bc2 = ""
                        else if level = 2
                            bc1 = pscr[level-1].GetBC1()
                            bc2 = item.GetTitle()
                        else
                            bc1 = pscr[level-1].GetBC2()
                            bc2 = item.GetTitle()
                        end if
                        ' create a new poster screen
                        pscr[level] = makePosterScreen(bc1,bc2)
                        pscr[level].SetPlayList(pl)
                        pscr[level].screen.SetFocusedListItem(startidx)
                        pscr[level].screen.Show()
                        port = pscr[level].screen.GetMessagePort()
                        audio.SetMessagePort(port)
                        currentBaseSong = 0
                    else if pl = invalid then
                        if ShowOkAbortDialog("Server Problem","Communications with the server has been lost.") then
                            print "Outta here!"
                            exit while
                        end if
                    else if ShowOkAbortDialog("Empty folder","No media items retrieved.  Is the media path set correctly? Does the selected path contain playable files?") then
                        print "Outta here!"
                        exit while
                    end if
                    busyDlg.Close()
                end if
            end if
        else if type(msg) = "roSlideShowEvent" then
            ' This is all in here waiting for Roku to fix the caching problem w/the slide show component
            print "slideshow event msg = "; type(msg)
            ssMsgHandled = false
            if msg.isStatusMessage() then
                print " slideshow status: ";msg.GetMessage()
            end if
            if msg.isButtonPressed() then
                print "  isButtonPressed"
                ssMsgHandled = true
            end if
            if msg.isScreenClosed() then
                print "  isScreenClosed"
                ssMsgHandled = true
            end if
            if msg.isPlaybackPosition() then
                print "  isPlaybackPosition"
                ssMsgHandled = true
            end if
            if msg.isRemoteKeyPressed() then
                print "  isRemoteKeyPressed"
                ssMsgHandled = true
            end if
            if msg.isRequestSucceeded() then
                print "  isRequestSucceeded"
                ssMsgHandled = true
            end if
            if msg.isRequestFailed() then
                print "  isRequestFailed"
                ssMsgHandled = true
            end if
            if msg.isRequestInterrupted() then
                print "  isRequestInterrupted"
                ssMsgHandled = true
            end if
            if msg.isPaused() then
                print "  isPaused"
                ssMsgHandled = true
            end if
            if msg.isResumed() then
                print "  isResumed"
                ssMsgHandled = true
            end if
            if ssMsgHandled = false
                print "  ***!!! unkown msg"
            end if
            print "  type = "; msg.GetType()
            print "  index = "; msg.GetIndex()
            print "end roSlideShowEvent"
        else if type(msg) = "roAudioPlayerEvent" then
            if msg.isStatusMessage() then
                print "audio status: ";msg.GetMessage()
                if msg.GetMessage() = "start of play" then
                    UpdateNowPlaying(pscr,currentSong.song.title,level)
                    dt = CreateObject("roDateTime")
                    now = dt.asSeconds()
                    currentSong.starttime = now
                    currentSong.paused = false
                    if shuffleMode then
                        randgots = 0
                        top = audioContent.Peek()
                        songs = top.songs
                        length = currentSong.song.Length
                        if length < 5 then
                            randgets = 1
                        else if length < 10 then
                                randgets = rnd(9)
                        else
                            if not autoplay then
                                ' if we're not traversing directories, just pick a number between 1
                                ' and the number of songs in the list
                                randgets = rnd(songs.Count() - 1)
                            else
                                ' otherwise pick a number loosely based on the length of the song
                                ' (longer songs give more time to "randomize")
                                randgets = length + rnd(length)
                            end if
                        end if
                    end if
                else if msg.GetMessage() = "end of stream" then
                    audio.Stop()
                    if not shuffleMode then
                        idx = GetNextSong(audio,audioContent,autoplay)
                '!!!*** if gns = -1 ***!!!
                    end if
                    top = audioContent.Peek()
                    songs = top.songs
                    idx = top.idxsave
                    audio.ClearContent()
                    audio.SetContentList(songs)
                    audio.SetNext(idx)
                    song = songs[idx]
                    print "Song "; idx; " - "+song.Title +" should be next"
                    audio.Play()
                    dt = CreateObject("roDateTime")
                    now = dt.asSeconds()
                    currentSong.song = song
                    currentSong.starttime = now
                    currentSong.paused = false
                end if
            end if
            print "end roAudioPlayerEvent"
'Test start
        REM else if randgots >= randgets and randgots <> 0 then
REM dt = CreateObject("roDateTime")
REM now = dt.asSeconds()
REM if now - currentSong.starttime > 10 then
            REM randgots = 0
            REM audio.Stop()
            REM if not shuffleMode then
                REM idx = GetNextSong(audio,audioContent,autoplay)
                REM '!!!*** if gns = -1 ***!!!
            REM end if
            REM top = audioContent.Peek()
            REM songs = top.songs
            REM idx = top.idxsave
            REM audio.ClearContent()
            REM audio.SetContentList(songs)
            REM audio.SetNext(idx)
            REM song = songs[idx]
            REM print "Song "; idx; " - "+song.Title +" should be next"
            REM audio.Play()
            REM currentSong.song = song
REM currentSong.starttime = now
REM end if
'Test end
        end if
    end while

    audio.Stop()
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
    theme.BreadcrumbTextLeft = "#89B811"
    theme.BreadcrumbTextRight = "#FAFAFA"
    theme.BreadcrumbDelimiter = "#B9D957"
    'theme.ButtonMenuHighlightColor = "#FF00FF"
    'theme.ButtonMenuNormalOverlayColor = "#FF00FF"
    'theme.ButtonMenuNormalColor = "#FF00FF"
    'theme.ButtonNormalColor = "#FF00FF"
    'theme.ButtonHighlightColor = "#FF00FF"
    'theme.BackgroundColor = "#FF00FF"
    'theme.ParagraphBodyText = "#FF00FF"
    'theme.ParagraphHeaderText = "#FF00FF"
    'theme.PosterScreenLine1Text = "#FF00FF"
    'theme.PosterScreenLine2Text = "#FF00FF"
    'theme.RegistrationCodeColor = "#FF00FF"
    'theme.RegistrationFocalColor = "#FF00FF"
    'theme.SpringboardTitleText = "#FF00FF"
    'theme.SpringboardActorColor = "#FF00FF"
    'theme.SpringboardSynopsisColor = "#FF00FF"
    'theme.SpringboardGenreColor = "#FF00FF"
    'theme.SpringboardRuntimeColor = "#FF00FF"
    'theme.SpringboardDirectorLabelColor = "#FF00FF"
    'theme.SpringboardDirectorColor = "#FF00FF"
    'theme.SpringboardButtonNormalColor = "#FF00FF"
    'theme.SpringboardButtonHighlightColor = "#FF00FF"
    'theme.SpringboardArtistColor = "#FF00FF"
    'theme.SpringboardArtistLabelColor = "#FF00FF"
    'theme.SpringboardAlbumColor = "#FF00FF"
    'theme.SpringboardAlbumLabelColor = "#FF00FF"
    'theme.EpisodeSynopsisText = "#FF00FF"
    'theme.FilterBannerActiveColor = "#FF00FF"
    'theme.FilterBannerInactiveColor = "#FF00FF"
    'theme.FilterBannerSideColor = "#FF00FF"

    app.SetTheme(theme)

End Sub


Function buildSlideShowContent(posters as object, idx as Integer, pics as Object) as Integer
' Removes any sub-directories and other non-images from the 'posters' list and builds
' a content list for the roSlideShow component.
' Returns the new index that should be displayed to correspond to the index from the
' poster list.
    print "buildSlideShowContent"

    newidx = idx
    maxidx = posters.Count() - 1
    numpic = 1
    for i = 0 to maxidx
        item = posters[i].item
        if item.GetType() = "image" then
            pic = item.GetPlayable()
            pic.TextOverlayBody = item.GetTitle()
            pic.TextOverlayUR = numpic.toStr()
            numpic = numpic + 1
            pics.Push(pic)
        else if i < idx then
            newidx = newidx - 1
        end if
    end for
    return newidx
End Function

REM Function GetSong(ac as object, idx as Integer) as Object
    REM print "GetSong"

    REM top = ac.Peek()
    REM songs = top.songs
    REM return songs[idx]
REM End Function

Function buildAudioContent(ac as object, posters as object, idx as Integer) as Object
    print "buildAudioContent"

    songs = CreateObject("roArray",1,true)
    items = CreateObject("roArray",1,true)
    playable = false
    idxsave = idx
print posters.Count(); " posters"
    maxidx = posters.Count() - 1
    for i = 0 to maxidx
        item = posters[i].item
        song = item.GetPlayable()   ' fills in title, length, artist and album among other things
        if song.ContentType = "audio" then playable = true  ' found at least one playable song
        if song.ContentType = "audio" or (song.Length = 0 and song.Artist = "Folder") then
            poster = item.GetPosterItem()
            song.SDPosterURL = poster.SDPosterURL
            song.HDPosterURL = poster.HDPosterURL
            songs.Push(song)
            items.Push(item)
        else if i < idx
            idxsave = idxsave - 1
        end if
    end for
    ac.Push({songs: songs, items: items, idxsave: idxsave, playable: playable})
    return ac
End Function

Function GetNextSong(audio as Object, ac as Object, autoplay=false) as Integer
    'print "GetNextSong"

    top = ac.Peek()
    songs = top.songs
    items = top.items
    idx = top.idxsave
    maxidx = songs.Count() - 1

    if not autoplay then
        idx = idx + 1
        if idx > maxidx then idx = 0
        while songs[idx].ContentType <> "audio"
            idx = idx + 1
            if idx > maxidx then idx = 0
        end while
        top.idxsave = idx
    else
        idx = idx + 1
        if idx > maxidx then
print "ac.Count() = ";ac.Count()
            if ac.Count() = 1 then
print "wrapping around"
x=              Run("tmp:/gc.brs")  ' call script to allow garbage collection
print x;"************************** Garbage Collection **************************";x
                ' If we got back here without finding anything playable, return -1
                if not top.playable then return -1
                top.idxsave = -1
                return GetNextSong(audio,ac,true)
            else
print "popping"
                playable = top.playable
                ac.Pop()
                top = ac.Peek()
                if playable then top.playable = true
                return GetNextSong(audio,ac,true)
            end if
        end if
        if songs[idx].ContentType = "audio" then
'print "simple case"
            top.idxsave = idx
            return idx
        end if
        if songs[idx].Length = 0 and songs[idx].Artist = "Folder" then '!!!*** change this to IsFolder
            ' Must be a folder
print "folder - ";songs[idx].Title
            pl = items[idx].GetSubItems()
            if pl <> invalid and pl.items.Count() <> 0 then
print "going down"
                ptmp = makePosterScreen("","")
                ptmp.SetPlayList(pl)
                top.idxsave = idx
                buildAudioContent(ac,ptmp.GetPosters(),-1)
                return GetNextSong(audio,ac,true)
            else if pl = invalid then
                '????
                return -1    '!!!***
                REM if ShowOkAbortDialog("Server Problem","Communications with the server has been lost.") then
                    REM print "Outta here!"
                    REM exit while
                REM end if
            else 'empty folder
print "empty folder"
                top.idxsave = idx
                return GetNextSong(audio,ac,true)
            end if
        end if
    end if
    top.idxsave = idx
    return idx
End Function

Function GetPreviousSong(audio as Object, ac as Object,autoplay=false) as Integer
    print "GetPreviousSong"

    top = ac.Peek()
    idx = top.idxsave
    songs = top.songs
    items = top.items
    maxidx = songs.Count() - 1

    idx = idx - 1
    if not autoplay then
        if idx < 0 then idx = maxidx
        while songs[idx].ContentType <> "audio"
            idx = idx - 1
            if idx < 0 then idx = maxidx
        end while
    else
        if idx < 0 then
print "ac.Count() = ";ac.Count()
            if ac.Count() = 1 then
print "wrapping around"
                top.idxsave = maxidx + 1
                return GetPreviousSong(audio,ac,true)
            else
print "popping"
                ac.Pop()
                return GetPreviousSong(audio,ac,true)
            end if
        end if

        ' idx is not less than 0
        if songs[idx].ContentType = "audio" then
print "simple case"
            top.idxsave = idx
            return idx
        end if

        if songs[idx].Length = 0 and songs[idx].Artist = "Folder" then '!!!*** change this to IsFolder
            ' Must be a folder
print "folder"
            pl = items[idx].GetSubItems()
            if pl <> invalid and pl.items.Count() <> 0 then
print "going down"
                ptmp = makePosterScreen("","")
                ptmp.SetPlayList(pl)
                top.idxsave = idx
                buildAudioContent(ac,ptmp.GetPosters(),0)
                top = ac.Peek()
                songs = top.songs
                top.idxsave = songs.Count()
                return GetPreviousSong(audio,ac,true)
            else if pl = invalid then
                '????
                return -1    '!!!***
                REM if ShowOkAbortDialog("Server Problem","Communications with the server has been lost.") then
                    REM print "Outta here!"
                    REM exit while
                REM end if
            else 'empty folder
print "empty folder"
                return GetPreviousSong(audio,ac,true)
            end if
        end if
    end if

    ' should never get here
    top.idxsave = idx
    return idx
End Function

'*************************************************************'
'** showSpringboardScreen()'
'*************************************************************'

Function showSpringboardScreen(audio as object, port as object, ac as object, currentSong=invalid,busyDlg=invalid,redisplay=false,shuffle=false) As Object
    print "showSpringboardScreen"

    top = ac.Peek()
    songs = top.songs
    idx = top.idxsave

    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)
    screen.AllowUpdates(false)

    print songs.Count(); " songs in playlist"

    timer = CreateObject("roTimespan")
    lastupdate = 0

    if not redisplay then
        audio.ClearContent()
        audio.SetContentList(songs)
        audio.SetNext(idx)
        audio.SetLoop(true) '!!!***
        song = songs[idx]
        progress = -1
        paused = false
        cumulative = 0
    else
        song = currentSong.song
        dt = CreateObject("roDateTime")
        now = dt.asSeconds()
        cumulative = now - currentSong.starttime
        progress = 0
        timer.Mark()
        paused = currentSong.paused
        if paused then
            screen.SetProgressIndicator(cumulative, song.length)
        end if
    end if

    screen.SetContent(song)
    screen.SetDescriptionStyle("audio")
    screen.ClearButtons()
    if paused then
        screen.AddButton(1,"Play")
    else
        screen.AddButton(1,"Pause")
    end if
    screen.AddButton(2,"Go Back")
    screen.SetStaticRatingEnabled(false)
    screen.SetProgressIndicatorEnabled(true)
    screen.AllowNavLeft(true)
    screen.AllowNavRight(true)
    'screen.AllowNavRewind(true)  INVALID FUNCTIONS!!!
    'screen.AllowNavFastForward(true)
    screen.AllowUpdates(true)

    if busyDlg <> invalid then busyDlg.Close()
    screen.Show()

    remoteLeft = 4
    remoteRight = 5

    length = song.Length

    if not redisplay then
        audio.Play()
    end if

    neverstarted = false
    shuffling = false
    randgets = 0
    randgots = 0
    autoplay = GetAutoplay()

    while true
        msg = wait(10, port)

        if not paused and progress >= 0 then
            progress = cumulative + timer.TotalSeconds()
            if progress <> lastupdate then
                screen.SetProgressIndicator(progress, length)
                lastupdate = progress
            end if
        end if

        if shuffle
            if randgots < randgets then
                idx = GetNextSong(audio,ac,autoplay)
                '!!!*** if gns = -1 ***!!!
                randgots = randgots + 1
if randgots = randgets then print "randgots = ";randgots
            end if
        end if

        if msg <> invalid then
            'print "Message: "; msg.GetIndex(); " "; msg.GetData()
            if type(msg) = "roSpringboardScreenEvent"
                if msg.isScreenClosed()
                    print "Springboard Screen closed"
                    exit while
                else if msg.isButtonPressed()
                    print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                    if msg.GetIndex() = 1 then
                        if paused then
                            paused = false
                            if neverstarted then
                                audio.Play()
                                neverstarted = false
                            else
                                audio.Resume()
                            end if
                            screen.AllowUpdates(false)
                            screen.ClearButtons()
                            screen.AddButton(1,"Pause")
                            screen.AddButton(2,"Go Back")
                            screen.AllowUpdates(true)
                        else
                            cumulative = progress
                            progress = -1
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
                        exit while
                    end if
                else if msg.GetIndex() = remoteLeft or msg.GetIndex() = remoteRight then
                    'randgots = 0
                    if msg.GetIndex() = remoteLeft then
                        idx = GetPreviousSong(audio,ac,autoplay)
                '!!!*** if gns = -1 ***!!!
                    else
                        idx = GetNextSong(audio,ac,autoplay)
                '!!!*** if gns = -1 ***!!!
                    end if
                    audio.Stop()
                    screen.AllowUpdates(false)
                    audio.ClearContent()
                    top = ac.Peek()
                    idx = top.idxsave
                    songs = top.songs
                    song = songs[idx]
                    audio.SetContentList(songs)
                    audio.SetNext(idx)
                    screen.SetContent(song)
                    length = song.Length
                    screen.SetProgressIndicator(0, length)
                    screen.AllowUpdates(true)
                    progress = -1
                    cumulative = 0
                    if paused then
                        neverstarted = true
                    else
                        audio.Play()
                    end if
                else
                    print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                end if
            else if type(msg) = "roAudioPlayerEvent" then
                print "AudioPlayerEvent: ";msg.GetType(); " msg: "; msg.GetMessage()
                if msg.isStatusMessage() then
                    if msg.GetMessage() = "start of play" then
                        timer.Mark()
                        progress = 0    ' allows code to update progress bar
                        if shuffle and cumulative = 0 then
                            ' only start shuffling if this is really the start of the song, not just a resume
                            randgots = 0
                            if length < 5 then
                                randgets = 1
                            else if length < 10 then
                                    randgets = rnd(9)
                            else
                                if not autoplay then
                                    ' if we're not traversing directories, just pick a number between 1
                                    ' and the number of songs in the list
                                    randgets = rnd(songs.Count() - 1)
                                else
                                    ' otherwise pick a number loosely based on the length of the song
                                    ' (longer songs give more time to "randomize")
                                    randgets = length + rnd(length)
                                end if
                            end if
                        end if
                    else if msg.GetMessage() = "end of stream" then
                        audio.Stop()
                        progress = -1   ' flag so code won't update progress bar anymore; wait for next song to start
                        cumulative = 0
                        if not shuffle then
                            idx = GetNextSong(audio,ac,autoplay)
                        '!!!*** if gns = -1 ***!!!
                        end if
                        top = ac.Peek()
                        songs = top.songs
                        idx = top.idxsave
                        audio.ClearContent()
                        audio.SetContentList(songs)
                        audio.SetNext(idx)
                        screen.AllowUpdates(false)
                        song = songs[idx]
                        print "Song "; idx; " - "+song.Title +" should be next"
                        screen.SetContent(song)
                        length = song.Length
                        screen.SetProgressIndicator(0, length)
                        screen.AllowUpdates(true)
                        audio.Play()
                    end if
                end if
            else
                print "unexpected type.... type=";msg.GetType(); " msg: "; msg.GetMessage()
            end if
        end if
    end while

    dt = CreateObject("roDateTime")
    now = dt.asSeconds()
    if paused then
        starttime = now - cumulative
    else
        starttime = now - progress
    end if
    return {song: song, starttime: starttime, paused: paused}
End Function


'*************************************************************'
'** displayVideo()'
'*************************************************************'

Function displayVideo(video as Object, offset as Integer) as Integer
    print "Displaying video: "
    port = CreateObject("roMessagePort")
    videoScreen = CreateObject("roVideoScreen")
    videoScreen.setMessagePort(port)
    videoScreen.SetPositionNotificationPeriod(10)

    'bitrates  = [0]'          ' 0 = no dots'
    'bitrates  = [348000]'    ' <500 Kbps = 1 dot'
    'bitrates  = [664000]'    ' <800 Kbps = 2 dots'
    'bitrates  = [996000]'    ' <1.1Mbps  = 3 dots'
    'bitrates  = [2048000]'    ' >=1.1Mbps = 4 dots'
    bitrates  = [1500]
    qualities = ["SD"]
    'qualities = ["HD"]'

    videoclip = video
    videoclip.StreamBitrates = bitrates
    videoclip.StreamUrls = [video["url"]]
    videoclip.StreamQualities = qualities
    videoclip.PlayStart = offset

    videoScreen.SetContent(videoclip)
    videoScreen.show()

    nowpos = offset

    while true
        msg = wait(0, port)
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 'ScreenClosed event'
                print "Closing video screen"
                exit while
            else if msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
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
