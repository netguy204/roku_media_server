' started as DeftAvocado2-1e9c6ee
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
        itemIndex: -1,
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
    'm.screen.SetIconArray(posters)
    m.screen.SetContentList(posters)
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

Function SecsToHrMinSec(secs as String) as String
    t = secs.toInt()
    hr = Int(t/3600)
    t = t - hr*3600
    min = Int(t/60)
    t = t - min*60
    sec = t
    if min < 10 then
        m10 = ":0"
    else
        m10 = ":"
    end if
    if sec < 10 then
        s10 = ":0"
    else
        s10 = ":"
    end if
    return hr.toStr()+m10+min.toStr()+s10+sec.toStr()
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

Function GetYesNo(title as String) as Boolean
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
    if dlgMsg.GetIndex() = 1 then return true
    return false
End Function

Function ShowSettings(currentSettings as Object, toolate=true) as Object
    print "ShowSettings"

    currentServer = currentSettings.server
    currentDelay = currentSettings.ssDelay
    currentAutoplay = currentSettings.autoplay
    currentAutorefresh = currentSettings.autorefresh
    currentAutomove = currentSettings.automove
    currentPhotoOverlay = currentSettings.photoOverlay
    newserver = currentServer
    newdelay = currentDelay
    newautoplay = currentAutoplay
    newautorefresh = currentAutorefresh
    newautomove = currentAutomove
    newphotooverlay = currentPhotoOverlay

    port = CreateObject("roMessagePort")
    settings = invalid
    if currentAutoplay then
        ap = "Yes"
    else
        ap = "No"
    end if
    if currentPhotoOverlay then
        po = "Yes"
    else
        po = "No"
    end if
    if currentAutorefresh then
        ar = "Yes"
    else
        ar = "No"
    end if
    if currentAutomove then
        am = "Yes"
    else
        am = "No"
    end if

    while true
        settings = CreateObject("roParagraphScreen")
        settings.SetMessagePort(port)
        settings.AddHeaderText("Current configuration:")
        settings.AddParagraph("Server:      "+currentServer)
        settings.AddParagraph("Slide show delay:      "+currentDelay+" seconds")
        settings.AddParagraph("Display photo overlays:   "+po)
        settings.AddParagraph("Autoplay music subfolders:      "+ap)
        settings.AddParagraph("Autorefresh folders:      "+ar)
        settings.AddParagraph("Automatically move to first unwatched video:      "+am)
        settings.AddButton(1,"Edit server")
        settings.AddButton(2,"Edit slide show delay")
        settings.AddButton(3,"Edit photo overlays")
        settings.AddButton(4,"Edit autoplay")
        settings.AddButton(5,"Edit autorefresh")
        settings.AddButton(6,"Edit automove")
        settings.AddButton(9,"Finished")

        settings.Show()

        msg = wait(0, port)

        if msg.GetIndex() = 1 then
            newserver = EditDialog("Enter server ip address and port",currentServer,"Example:  http://192.168.1.100:8001",50)
        else if msg.GetIndex() = 2 then
            newdelay = EditDialog("Enter slide show delay",currentDelay,"Slide show delay in seconds",4)
        else if msg.GetIndex() = 3 then
            newphotooverlay = GetYesNo("Display photo overlays?")
        else if msg.GetIndex() = 4 then
            newautoplay = GetYesNo("Automatically play music subfolders?")
        else if msg.GetIndex() = 5 then
            newautorefresh = GetYesNo("Automatically refresh folders?")
        else if msg.GetIndex() = 6 then
            newautomove = GetYesNo("Automatically move to unwatched video?")
        else
            exit while
        end if
        if newdelay <> currentDelay then
            nd = newdelay.toInt()
            newdelay = nd.toStr()
            RegSave("Slide show delay", newdelay, "Settings")
            currentDelay = newdelay
        else if newphotooverlay <> currentPhotoOverlay
            if newphotooverlay then
                po = "Yes"
            else
                po = "No"
            end if
            RegSave("PhotoOverlay",po,"Settings")
            currentPhotoOverlay = newphotooverlay
        else if newserver <> currentServer
            RegSave("Server", newserver, "Settings")
            if newserver <> currentServer and toolate then
                ShowServerWarning()
            end if
            currentServer = newserver
        else if newautoplay <> currentAutoplay
            if newautoplay then
                ap = "Yes"
            else
                ap = "No"
            end if
            RegSave("Autoplay",ap,"Settings")
            currentAutoplay = newautoplay
        else if newautorefresh <> currentAutorefresh
            if newautorefresh then
                ar = "Yes"
            else
                ar = "No"
            end if
            RegSave("Autorefresh",ar,"Settings")
            currentAutorefresh = newautorefresh
        else if newautomove <> currentAutomove
            if newautomove then
                am = "Yes"
            else
                am = "No"
            end if
            RegSave("Automove",am,"Settings")
            currentAutomove = newautomove
        end if
    end  while

print "New server: "; newserver; " New delay:";newdelay; " New photo overlay: ";newphotooverlay;" New autoplay: ";newautoplay; " New autorefresh: ";newautorefresh;
    newSettings = {server: currentServer, ssDelay: currentDelay, autoplay: currentAutoplay, autorefresh: currentAutorefresh, photoOverlay: currentPhotoOverlay, automove: currentAutomove}
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
    if keys.Count() > 250  then
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
        'ShowOkDialog("Deleted One",oldestkey)
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


Sub UpdateVideoStatus(pscrns as Object, level as Integer, idx as Integer, offset as Integer)
    print "UpdateVideoStatus"

    tmpposters = pscrns[level].screen.GetContentList()
    if offset <> -1 then
        tmpposters[idx].ShortDescriptionLine2 = "Progress:  " + SecsToHrMinSec(offset.toStr())
    else
        dt = CreateObject("roDateTime")
        tmpposters[idx].ShortDescriptionLine2 = "Watched " + dt.asDateString("long-date")
    end if
    pscrns[level].screen.SetContentList(tmpposters)
    pscrns[level].screen.show()
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
        server = "SERVER_NAME"
        RegSave("Server", server, "Settings")
    else
        print "Retrieved server from registry"
    end if
    ' Get rid of "/feed" if it's there
    if Right(server,5) = "/feed" then
        server = Left(server,server.Len()-5)
        RegSave("Server", server, "Settings")
    end if
    print "server = "; server

    ssDelay = RegGet("Slide show delay","Settings")
    if ssDelay = invalid then ssDelay = "5"
    print "slide show delay = "; ssDelay

    po = RegGet("PhotoOverlay","Settings")
    if po = invalid then
        photoOverlay = true
        RegSave("PhotoOverlay","Yes","Settings")
    else if po = "Yes" then
        photoOverlay = true
    else
        photoOverlay = false
    end if
    print "photoOverlay = "; photoOverlay

    ap = RegGet("Autoplay","Settings")
    if ap = invalid then
        autoplay = true
        RegSave("Autoplay","Yes","Settings")
    else if ap = "Yes" then
        autoplay = true
    else
        autoplay = false
    end if
    print "autoplay = "; autoplay

    ar = RegGet("Autorefresh","Settings")
    if ar = invalid then
        autorefresh = true
        RegSave("Autorefresh","Yes","Settings")
    else if ar = "Yes" then
        autorefresh = true
    else
        autorefresh = false
    end if
    print "autorefresh = "; autorefresh

    am = RegGet("Automove","Settings")
    if am = invalid then
        automove = true
        RegSave("Automove","Yes","Settings")
    else if am = "Yes" then
        automove = true
    else
        automove = false
    end if
    print "automove = "; automove

    return {server: server, ssDelay: ssDelay, autoplay: autoplay, autorefresh: autorefresh, photoOverlay: photoOverlay, automove: automove}
End Function

Function RefreshPosters(pscrs as Object, level as Integer, app as Object, automove=false) as Boolean
    print "RefreshPosters"

    if level = 0 then
        ' nothing to do
        initTheme(app, "media")
        pscrs[0].screen.show()
        return false
    end if

    if pscrs[level].itemIndex = -1 then
        busyDlg = ShowBusy("retrieving...")
print "retrieving..."
    else
        busyDlg = ShowBusy("refreshing...")
print "refreshing..."
    end if

    ' Save the current selected poster so it can be restored
    if pscrs[level].itemIndex <> -1 then
        posters = pscrs[level].GetPosters()
        item = posters[pscrs[level].itemIndex].item
        oldSel = item.GetTitle()
    end if

    ' Get the selected poster of the parent level
    posters = pscrs[level-1].GetPosters()
    itemIndex = pscrs[level-1].itemIndex
    item = posters[itemIndex].item

    'load the sub items and display those'
    print "loading subitems for "; itemIndex; " - "; item.GetTitle()
    pl = item.GetSubItems()
'print "theme is ";pl.theme
    if pl <> invalid and pl.items.Count() <> 0 then
        startidx = 0
        if pl.theme = "music" then
            items = CreateObject("roList")
            pl1 = {items: items, theme: "media"}
            CreateSimplePoster(pl1.items, "Shuffle All", "pkg:/images/shuffleall_square.jpg", "Shuffle everything", "shuffleall")
            CreateSimplePoster(pl1.items, "Play All", "pkg:/images/playall_square.jpg", "Play everything", "playall")
            startidx = 2
            for each it in pl1.items
                pl.items.AddHead(it)
            end for
        else if pl.theme = "video" then
            items = CreateObject("roList")
            pl1 = {items: items, theme: "media"}
            CreateSimplePoster(pl1.items, "Play Unwatched", "pkg:/images/playall_square.jpg", "Play all unwatched", "playunwatched")
            CreateSimplePoster(pl1.items, "Play All", "pkg:/images/playall_square.jpg", "Play everything", "playallvideo")
            startidx = 2
            for each it in pl1.items
                pl.items.AddHead(it)
            end for
        end if

        pscrs[level].SetPlayList(pl)

        if pl.theme = "video" and automove then
            posters = pscrs[level].GetPosters()
            skip = 0
            for each p in posters
                if skip < 2 then
                    skip = skip + 1
                else
                    if Left(p.ShortDescriptionLine2,5) = "Watch" then
                        startidx = startidx + 1
                    else
                        exit for
                    end if
                end if
            end for
        end if
        if startIdx >= pl.items.Count() then startIdx = 2

        if pscrs[level].itemIndex = -1 then
            i = startIdx
        else
            ' Try to restore the current selection
            for i = startidx to pl.items.Count() - 1
                if pl.items[i].GetTitle() = oldSel then exit for
            end for
            if i = pl.items.Count() then i = startIdx   ' ???
        end if
        pscrs[level].screen.SetFocusedListItem(i)
        pscrs[level].itemIndex = i
        initTheme(app, pl.theme)
        pscrs[level].screen.Show()
    else if pl = invalid then
        if ShowOkAbortDialog("Server Problem","Communications with the server has been lost.") then
            print "Outta here!"
            busyDlg.Close()
            return true
        end if
    else if ShowOkAbortDialog("Empty folder","No media items retrieved.  Is the media path set correctly? Does the selected path contain playable files?") then
        print "Outta here!"
        busyDlg.Close()
        return true
    end if
    busyDlg.Close()
    return false
End Function

Sub Main()
    print "Main"

reg = CreateObject("roRegistry")
sect = CreateObject("roRegistrySection", "Resume")
kl = sect.GetKeyList()
'print kl
print kl.Count(); " resume entries"

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
        ShowOkDialog("Major Problem","Cannot create RSS Connection")
        'exit the app gently so that the screen doesnt flash to black'
        print "Exiting app"
        screenFacade.showMessage("")
        sleep(25)
        return
    end if

    currentConfig = GetConfig()

    while true
        busyDlg = ShowBusy("retrieving...")

        pl = rss.GetSongListFromFeed(currentConfig.server+"/feed")
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

    pscr[0].screen.Show()
    busyDlg.Close()
    port = pscr[level].screen.GetMessagePort()
    audio.SetMessagePort(port)
    rokutime = CreateObject("roDateTime")
    rplastcheck = 0
    timeout = 0
    radioparadise = false

    while true
        msg = wait(timeout, port)

        if audioPlaying then
            if currentSong.isStream then
                if radioparadise then
                    rokutime.Mark()
                    timestamp = rokutime.asSeconds()
                    if timestamp <> rplastcheck then
                        rplastcheck = timestamp
                        if timestamp - (currentSong.timediff - 1) >= rprefresh then
                            print "Checking for new song"
                            for i = 1 to 10
                                rpinfo = currentSong.rprss.GetInfo()
                                if rpinfo <> invalid then exit for
                            end for
                            if rpinfo = invalid then
                                ShowOkDialog("Lost communications","Cannot retrieve playlist")
                                radioparadise = false
                                timeout = 0
                            else if rpinfo.songid <> songid then
                                print "new song"
                                currentSong.timediff = timestamp - rpinfo.timestamp.toInt()
                                rprefresh = rpinfo.refresh_time.toInt()
                                newsong = CreateObject("roAssociativeArray")
                                currentSong.rprss.GetInfo(newsong)
                                songid = rpinfo.songid
                                currentSong.rplist.AddTail({song: newsong, info: rpinfo})
                                print "New song:  ";newsong.title
                            end if
                        end if

                        if not currentSong.paused and currentSong.rplist.Count() > 1 and timestamp >= (currentSong.rpupdate + currentSong.timediff + currentSong.latency + 7) then ' the 7 is a fudge factor
                            currentSong.rplist.RemoveHead()
                            head = currentSong.rplist.GetHead()
                            song = head.song
                            rpinfo = head.info
                            rppl = currentSong.rppl
                            if rppl.Count() = 10 then
                                rppl.RemoveTail()
                            end if
                            rppl.AddHead(song.title+"  by  "+song.artist)
                            if currentSong.rplist.Count() > 1 then
                                rpinfo = currentSong.rplist[1].info
                                currentSong.rpupdate = rpinfo.timestamp.toInt()
                            else
                                currentSong.rpupdate = rpinfo.refresh_time.toInt()
                            end if
                            UpdateNowPlaying(pscr,song.title,level)
                        end if
                    end if
                end if
            else
                if shuffleMode then
                    if randgots < randgets then
                        idx = GetNextSong(audio,audioContent,currentConfig.autoplay)
                        '!!!*** if gns = -1 ***!!!
                        randgots = randgots + 1
                    end if
                end if
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
                if currentConfig.autorefresh then
                    if RefreshPosters(pscr,level,app) then exit while
                end if
                initTheme(app, pscr[level].theme)
                ' this is here to try to make sure the theme change takes effect
                pscr[level].screen.SetFocusedListItem(pscr[level].itemIndex)
                pscr[level].screen.show()
            else if msg.isListItemSelected() then
                itemIndex = msg.GetIndex()
                pscr[level].itemIndex = itemIndex

                posters = pscr[level].GetPosters()
                item = posters[itemIndex].item

                if item.IsPlayable() then
                    if item.GetContentType() = "movie"
                        audio.Stop()
                        audio.ClearContent()
                        audioPlaying = false
                        UpdateNowPlaying(pscr,"Return to Audio Player",level)
                        offset = GetOffset(item.GetTitle())
                        if offset > 0 then
                            if not ShowResumeDialog() then offset = 0
                        else
                            offset = 0
                        end if
                        print "Starting from position "; offset
                        offset = displayVideo(item.GetPlayable(),offset)
                        SaveOffset(item.GetTitle(),offset.toStr())
                        if currentConfig.autorefresh then
                            if RefreshPosters(pscr,level,app) then exit while
                        else
                            UpdateVideoStatus(pscr,level,itemIndex,offset)
                            pscr[level].screen.show()
                        end if
                    else if item.GetContentType() = "audio" then
                        audio.Stop()
                        audio.ClearContent()
                        shuffleMode = false
                        if pscr[level].theme = "music" then
                            ' Create an array to store audio playlists as we traverse the hierarchy
                            audioContent = CreateObject("roArray",1,true)
                            buildAudioContent(audioContent,posters,itemIndex)
                            currentSong = showSpringboardScreen(audio, port, audioContent)
                        else
                            stream = item.GetPlayable()
                            streamTitle = item.GetTitle()
                            if streamTitle = "Radio Paradise" then
                                radioparadise = true
                            else
                                radioparadise = false
                            end if
                            currentSong = showStreamScreen(audio, port, stream, streamTitle)
                        end if
                        timeout = 0
                        if currentSong.stopped then
                            UpdateNowPlaying(pscr,"Return to Audio Player")
                            audioPlaying = false
                        else
                            UpdateNowPlaying(pscr,currentSong.song.title,level)
                            audioPlaying = true
                            if currentSong.isStream then
                                if radioparadise then
                                    timeout = 1000
                                    tail = currentSong.rplist.GetTail()
                                    rpinfo = tail.info
                                    songid = rpinfo.songid
                                    rprefresh = rpinfo.refresh_time.toInt()
                                end if
                            else if shuffleMode then
                                timeout = 10
                            end if
                        end if
                        if currentConfig.autorefresh then
                            if RefreshPosters(pscr,level,app) then exit while
                        end if
                        pscr[level].screen.show()
                        randgets = 0
                        randgots = 0
                    else if item.GetType() = "image" then
                        ssBusyDlg = ShowBusy("retrieving...")
                        print "Photo: "; item.GetTitle()
                        print item.GetMedia()
                        ss = CreateObject("roSlideShow")
                        ssCl = CreateObject("roArray",1,true)
                        newidx = buildSlideShowContent(posters,itemIndex,ssCl,currentConfig.photoOverlay)
                        ss.SetContentList(ssCl)
                        ss.SetPeriod(currentConfig.ssDelay.toInt())
                        ss.SetTextOverlayHoldTime(2000)
                        ss.SetMessagePort(port)
                        ss.SetDisplayMode("scale-to-fit")
                        ss.SetUnderScan(5)
                        ss.SetNext(newidx,true)
                        ss.Show()
                        ssBusyDlg.Close()
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
                                if currentConfig.autorefresh then
                                    if RefreshPosters(pscr,level,app) then exit while
                                else
                                    initTheme(app,pscr[level].theme)
                                    pscr[level].screen.show()
                                end if
                                randgets = 0
                                randgots = 0
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
                    initTheme(app, "media")
                    pscr[0].screen.Show()
                else if item.IsSimple("playerctl")
                    if not audioPlaying then
                        ShowOkDialog("Audio Player Control","There's nothing playing at the moment")
                    else
                        if not currentSong.isStream then
                            initTheme(app,"music")
                            currentSong = showSpringboardScreen(audio, port, audioContent, currentSong,invalid,true,shuffleMode)
                        else
                            initTheme(app,"streams")
                            currentSong = showStreamScreen(audio, port, stream, streamTitle, currentSong, true)
                            if radioparadise then
                                tail = currentSong.rplist.GetTail()
                                rpinfo = tail.info
                                songid = rpinfo.songid
                                rprefresh = rpinfo.refresh_time.toInt()
                            end if
                        end if
                        if currentSong.stopped then
                            UpdateNowPlaying(pscr,"Return to Audio Player")
                            audioPlaying = false
                            timeout = 0
                        else
                            UpdateNowPlaying(pscr,currentSong.song.title,level)
                            audioPlaying = true
                        end if
                        if currentConfig.autorefresh then
                            if RefreshPosters(pscr,level,app) then exit while
                        end if
                        pscr[level].screen.show()
                        randgets = 0
                        randgots = 0
                        initTheme(app, "media")
                        pscr[0].screen.show()
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
                    UpdateNowPlaying(pscr,"Return to Audio Player",level)
                    ' Create an array to store audio playlists as we traverse the hierarchy
                    audioContent = CreateObject("roArray",1,true)
                    buildAudioContent(audioContent,posters,-1)
                    if GetNextSong(audio,audioContent,currentConfig.autoplay) >= 0 then
                        if shuffleMode then
                            if currentConfig.autoplay then
                                randget = rnd(250)
                            else
                                top = audioContent.Peek()
                                songs = top.songs
                                randget = rnd(songs.Count())
                            end if
                            for randgot = 0 to randget
                                GetNextSong(audio,audioContent,currentConfig.autoplay)
                    '!!!*** if gns = -1 ***!!!
                            end for
                        end if
                        audioPlaying = true
                        currentSong = showSpringboardScreen(audio, port, audioContent, invalid, busyDlg, false, shuffleMode)
                        UpdateNowPlaying(pscr,currentSong.song.title,level)
                        if currentConfig.autorefresh then
                            if RefreshPosters(pscr,level,app) then exit while
                        end if
                        pscr[level].screen.show()
                        randgets = 0
                        randgots = 0
                    else
                        busyDlg.Close()
                        if ShowOkAbortDialog("Empty folder","No audio items retrieved.  Is the media path set correctly? Does the selected path contain playable files?") then
                            print "Outta here!"
                            exit while
                        end if
                    end if
                else if item.IsSimple("playallvideo") or item.IsSimple("playunwatched") then
                    audio.Stop()
                    audio.ClearContent()
                    audioPlaying = false
                    UpdateNowPlaying(pscr,"Return to Audio Player",level)
                    videoContent = CreateObject("roArray",0,true)
                    if item.IsSimple("playallvideo") then
                        numvids = buildVideoContent(videoContent,posters,true)
                    else
                        numvids = buildVideoContent(videoContent,posters,false)
                    end if
print numvids; " items returned"
                    for each vid in videoContent
                        offset = GetOffset(vid.Title)
                        if offset > 0 then
                            if not ShowResumeDialog() then offset = 0
                        else
                            offset = 0
                        end if
                        print "Starting from position "; offset
                        offset = displayVideo(vid,offset)
                        SaveOffset(vid.Title,offset.toStr())
                        UpdateVideoStatus(pscr,level,vid.Index,offset)
                        if offset <> -1 then exit for
                    end for
                    if currentConfig.autorefresh then
                        if RefreshPosters(pscr,level,app) then exit while
                    end if
                    pscr[level].screen.show()
                else    ' must be a folder
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
                    if RefreshPosters(pscr,level,app,currentConfig.automove) then exit while
                    if pscr[level].posters.Count() = 0 then
                        ' if no posters were added, must be an empty directory; undo what we just did
                        level = level - 1
                        pscr.Pop()
                    else
                        port = pscr[level].screen.GetMessagePort()
                        audio.SetMessagePort(port)
                        currentBaseSong = 0
                    end if
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
                if currentConfig.autorefresh then
                    if RefreshPosters(pscr,level,app) then exit while
                end if
                pscr[level].screen.show()
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
                            if not currentConfig.autoplay then
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
                        idx = GetNextSong(audio,audioContent,currentConfig.autoplay)
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

    ' Huge kludge to get whether or not this is the High Contrast theme
    high_contrast = false
    ba = CreateObject("roByteArray")
    ba.ReadFile("pkg:/images/media_Logo_Overhang_SD43.png")
    if ba.Count() = 4553 then high_contrast = true
    if not high_contrast then
        ' top overhang background is "#FCC921"
        theme.BreadcrumbTextLeft = "#89B811"
        theme.BreadcrumbTextRight = "#FAFAFA"
        theme.BreadcrumbDelimiter = "#B9D957"
    else
        theme.BreadcrumbTextLeft = "#07B27D"
        theme.BreadcrumbTextRight = "#FAFAFA"
        theme.BreadcrumbDelimiter = "#69B79F"
theme.BackgroundColor = "#AAAAAA"
    endif
    ' these don't seem to do anything
    'theme.ButtonMenuHighlightColor = "#00FF00"
    'theme.ButtonMenuNormalOverlayColor = "#FFFF00"
    'theme.ButtonMenuNormalColor = "#00FFFF"
    'theme.ButtonNormalColor = "FF0000"
    'theme.ButtonHighlightColor = "#FCC921"  ' this is the only one that seems to do anything
    ' or is it?
    'theme.ButtonMenuHighlightText = "#00FF00"
    'theme.ButtonMenuNormalOverlayText = "#00FF00"
    'theme.ButtonMenuNormalText = "#0000FF"
    '
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


Function buildSlideShowContent(posters as object, idx as Integer, pics as Object, overlay as Boolean) as Integer
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
            if overlay then
                pic.TextOverlayBody = item.GetTitle()
                pic.TextOverlayUR = numpic.toStr()
            end if
            numpic = numpic + 1
            pics.Push(pic)
        else if i < idx then
            newidx = newidx - 1
        end if
    end for
    return newidx
End Function

Function buildVideoContent(vids as Object, posters as object, all as Boolean) as Integer
' Removes any sub-directories and other non-videos from the 'posters' list and builds
' an array of videos to be passed to the roVideoScreen component
    print "buildVideoContent"

    maxidx = posters.Count() - 1
    numvid = 0
    for i = 2 to maxidx         ' skip Playall posters
        item = posters[i].item
        if item.GetContentType() = "movie" then
            if all or not Left(posters[i].ShortDescriptionLine2,5) = "Watch" then
                vid = item.GetPlayable()
                vid.index = i
                numvid = numvid + 1
                vids.Push(vid)
            end if
        end if
    end for
    return numvid
End Function

Function buildAudioContent(ac as object, posters as object, idx as Integer) as Object
    print "buildAudioContent"

    idxsave = idx
    songs = CreateObject("roArray",1,true)
    items = CreateObject("roArray",1,true)
    playable = false
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
        else if i < idx then
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

    rokutime = CreateObject("roDateTime")
    now = rokutime.asSeconds()

    if not redisplay then
        audio.ClearContent()
        audio.SetContentList(songs)
        audio.SetNext(idx)
        audio.SetLoop(true) '!!!***
        song = songs[idx]
        progress = -1
        paused = false
        cumulative = 0
        neverstarted = false
    else
        song = currentSong.song
        cumulative = now - currentSong.starttime
        neverstarted = currentSong.neverstarted
        if neverstarted then cumulative = 0
        progress = 0
        timer.Mark()
        paused = currentSong.paused
        if paused then
            screen.SetProgressIndicator(cumulative, song.length)
        end if
    end if

    length = song.Length
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
    if length > 0 then
        screen.SetProgressIndicatorEnabled(true)
    else
        screen.SetProgressIndicatorEnabled(false)
    end if
    screen.AllowNavLeft(true)
    screen.AllowNavRight(true)
    'screen.AllowNavRewind(true)  'INVALID FUNCTIONS!!!
    'screen.AllowNavFastForward(true)
    screen.AllowUpdates(true)

    if busyDlg <> invalid then busyDlg.Close()
    screen.Show()

    remoteLeft = 4
    remoteRight = 5

    if not redisplay then
        audio.Play()
    end if

    shuffling = false
    randgets = 0
    randgots = 0
    autoplay = GetAutoplay()

    while true
        msg = wait(10, port)

        if not paused and progress >= 0 then
            progress = cumulative + timer.TotalSeconds()
            if progress <> lastupdate and length > 0 then
                screen.SetProgressIndicator(progress, length)
                lastupdate = progress
            end if
        end if

        if shuffle
            if randgots < randgets then
                idx = GetNextSong(audio,ac,autoplay)
                '!!!*** if gns = -1 ***!!!
                randgots = randgots + 1
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
                        screen.AllowUpdates(false)
                        screen.ClearButtons()
                        if paused then
                            paused = false
                            if neverstarted then
                                audio.Play()
                                neverstarted = false
                            else
                                audio.Resume()
                            end if
                            screen.AddButton(1,"Pause")
                            screen.AddButton(2,"Go Back")
                        else
                            cumulative = progress
                            progress = -1
                            paused = true
                            audio.Pause()
                            screen.AddButton(1,"Play")
                            screen.AddButton(2,"Go Back")
                        end if
                        screen.AllowUpdates(true)
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
                print "AudioPlayerEvent type:";msg.GetType(); " msg: "; msg.GetMessage(); " - index:"; msg.GetIndex(); " data:"; msg.GetData()
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
    return {stopped: false,
            song: song,
            neverstarted : neverstarted,
            starttime: starttime,
            paused: paused,
            isStream: false}
End Function

Function stripSlash(s as String) as String
    str = s
    p = Instr(1,str,"\'")
    while p <> 0
        if p <> 1 then
            l = Left(str,p-1)
        else
            l = ""
        end if
        r = Mid(str,p+1)
        print l;r
        str = l+r
        p = Instr(1,str,"\'")
    end while
    return str
End Function

Function ShowPlaylist(rppl as Object, port as Object, plscreen=invalid) as Object
    pls2 = CreateObject("roMessageDialog")
    pls2.SetTitle("Playlist")
    pls2.AddButton(1,"Close")
    pls2.SetMessagePort(port)
    pl = ""
    for each s in rppl
        pl = pl+s+chr(10)
    end for
    pls2.SetText(pl)
    pls2.show()
    if plscreen <> invalid then plscreen.Close()
    return pls2
End Function

Function showStreamScreen(audio as object, port as object, stream as object, title as string, currentSong = invalid, redisplay=false) As Object
    print "showStreamScreen"

    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)
    screen.AllowUpdates(false)
    screen.SetBreadcrumbText(title,"")

    timer = CreateObject("roTimespan")
    rokutime = CreateObject("roDateTime")
    now = rokutime.asSeconds()
    busyDlg = invalid

    cumulative = 0  ' only used for Radio Paradise
    if not redisplay then
        audio.ClearContent()
        audio.SetContentList([stream])
        audio.SetNext(0)
        audio.SetLoop(true)
        progress = -1
        paused = false
        pausedtime = 0
    else
        paused = currentSong.paused
        pausedtime = currentSong.pausedtime
        latency = currentSong.latency
        progress = 0
    end if

    latencytimer = CreateObject("roTimespan")
    radioparadise = false
    if title = "Radio Paradise" then
        print "Radio Paradise feed"
        radioparadise = true
        rpplup = false
        if not redisplay then
            rppl = CreateObject("roList")
            firstsong = CreateObject("roAssociativeArray")
            rprss = CreateRadioParadiseRSSConnection()
            rpinfo = rprss.GetInfo(firstsong)
            songid = rpinfo.songid
            rppl.AddTail(firstsong.title+"  by  "+firstsong.artist)
            rplist = CreateObject("roList")
            rplist.AddTail({song: firstsong, info: rpinfo})
            rprefresh = rpinfo.refresh_time.toInt()
            song = firstsong
            rokutime.Mark()
            now = rokutime.asSeconds()
            cumulative = now - rpinfo.timestamp.toInt() - 7  ' add in fudge factor so progress bar is more accurate
            timediff = -24   ' allow for -1 sec/hr time drift on Roku clock (assuming it sets its clock everyday)
            if now - timediff > rprefresh then
                timediff = now - rprefresh + 3  ' check for new song 3 seconds from now
            end if
            rpupdate = rprefresh
        else
' rplist[0] is currently playing song
' rplist[1] is next song; if rplist.Count() =  1, then we don't have the next song yet so rpupdate is undefined
' rpupdate = rplist[1].info.timestamp
            rprss = currentSong.rprss
            rplist = currentSong.rplist
            rppl = currentSong.rppl
            tail = rplist.GetTail()
            rpinfo = tail.info
            songid = rpinfo.songid
            rprefresh = rpinfo.refresh_time.toInt()
            timediff = currentSong.timediff
            rpupdate = currentSong.rpupdate
            rokutime.Mark()
            timestamp = rokutime.asSeconds()
            head = rplist.GetHead()
            song = head.song
            rpinfo = head.info
            if not paused then
                cumulative = timestamp - latency - timediff - 7 - rpinfo.timestamp.toInt()
            else
                cumulative = currentSong.cumulative
            end if
        end if
        if cumulative < 0 then cumulative = 0
        screen.SetProgressIndicator(cumulative, song.length)
    else
        song = stream
        arturl = "pkg:/images/streams_square.jpg"
        song.HDPosterUrl = arturl
        song.SDPosterUrl = arturl
        song.album = ""
        rprss = invalid
        rpinfo = invalid
        rppl = invalid
    end if

    length = song.Length
    if length = 0 then song.Length = ""
    screen.SetContent(song)
    screen.SetDescriptionStyle("audio")
    screen.ClearButtons()
    if paused then
        screen.AddButton(1,"Play")
    else
        screen.AddButton(1,"Pause")
    end if
    if radioparadise then screen.AddButton(2,"Show playlist")
    screen.AddButton(3,"Go Back")
    screen.SetStaticRatingEnabled(false)
    if length > 0 then
        screen.SetProgressIndicatorEnabled(true)
    else
        screen.SetProgressIndicatorEnabled(false)
    end if
    screen.AllowNavLeft(false)
    screen.AllowNavRight(false)
    'screen.AllowNavRewind(true)  'INVALID FUNCTIONS!!!
    'screen.AllowNavFastForward(true)
    screen.Show()
    if length = 0 then song.Length = 0
    screen.AllowUpdates(true)

    remoteLeft = 4
    remoteRight = 5

    if not redisplay then
        busyDlg = ShowBusy("buffering...")
        audio.Play()
    end if
    latencytimer.Mark()
    timer.Mark()
    stopped = false

    neverstarted = false
    updatepending = false

    while true
        msg = wait(1000, port)
        rokutime.Mark()
        timestamp = rokutime.asSeconds()

        if radioparadise then
            if timestamp - (timediff - 1) >= rprefresh then
                print "Checking for new song"
                for i = 1 to 10
                    rpinfo = rprss.GetInfo()
                    if rpinfo <> invalid then exit for
                end for
                if rpinfo = invalid then
                    ShowOkDialog("Lost communications","Cannot retrieve playlist")
                    audio.stop()
                    stopped = true
                    exit while
                end if
                if rpinfo.songid <> songid then
                    print "new song"
                    timediff = timestamp - rpinfo.timestamp.toInt()
                    if rplist.Count() = 1 then
                        rpupdate = rpinfo.timestamp.toInt()
                    end if
                    rprefresh = rpinfo.refresh_time.toInt()
                    newsong = CreateObject("roAssociativeArray")
                    rprss.GetInfo(newsong)
                    songid = rpinfo.songid
                    rplist.AddTail({song: newsong, info: rpinfo})
print "refresh:";rprefresh;" update:";rpupdate;" current time:";timestamp
print "timediff:";timediff;" latency:";latency
print "Count:";rplist.Count()
                    print "New song:  ";newsong.title
                end if
            end if

            if not paused and progress >= 0 then
                progress = cumulative + timer.TotalSeconds()
                screen.SetProgressIndicator(progress, length)
                if rplist.Count() > 1 and timestamp >= (rpupdate + timediff + latency + 7) then ' the 7 is a fudge factor
print "Count:";rplist.Count()
head = rplist.GetHead()
tail = rplist.GetTail()
sh = head.song
st = tail.song
print "Head: ";sh.title, "Tail: ";st.title
                    rplist.RemoveHead()
                    head = rplist.GetHead()
                    song = head.song
                    rpinfo = head.info
                    if rppl.Count() = 10 then
                        rppl.RemoveTail()
                    end if
                    rppl.AddHead(song.title+"  by  "+song.artist)
                    if rpplup then
                        plscreen = ShowPlaylist(rppl,port,plscreen)
                    end if
                    if rplist.Count() > 1 then
                        rpinfo = rplist[1].info
                        rpupdate = rpinfo.timestamp.toInt()
                    else
                        rpupdate = rpinfo.refresh_time.toInt()
                    end if
print "new rpupdate =";rpupdate
                    cumulative = 0
                    progress = 0
                    length = song.Length
                    screen.SetProgressIndicator(0, length)
                    timer.Mark()
                    screen.SetContent(song)
                    screen.Show()
                end if
            end if
        end if

        rokutime.Mark()
        timestamp = rokutime.asSeconds()
        if msg <> invalid then
            'print "Message: "; msg.GetIndex(); " "; msg.GetData()
            if type(msg) = "roSpringboardScreenEvent"
                if msg.isScreenClosed()
                    print "Springboard Screen closed"
                    exit while
                else if msg.isButtonPressed()
                    print "Button pressed: "; msg.GetIndex(); " " msg.GetData()
                    if msg.GetIndex() = 1 then
                        screen.AllowUpdates(false)
                        screen.ClearButtons()
                        if paused then
                            paused = false
                            latency = latency + timestamp - pausedtime
                            pausedtime = 0
                            if neverstarted then
                                audio.Play()
                                neverstarted = false
                            else
                                audio.Resume()
                            end if
                            screen.AddButton(1,"Pause")
                            if radioparadise then screen.AddButton(2,"Show playlist")
                            screen.AddButton(3,"Go Back")
                        else
                            cumulative = progress
                            progress = -1
                            paused = true
                            pausedtime = timestamp
                            audio.Pause()
                            screen.AddButton(1,"Play")
                            if radioparadise then screen.AddButton(2,"Show playlist")
                            screen.AddButton(3,"Go Back")
                        end if
                        screen.AllowUpdates(true)
                    else if msg.GetIndex() = 2 then
                        plscreen = ShowPlaylist(rppl,port)
                        rpplup = true
                    else if msg.GetIndex() = 3 then
                        print "Outta here!"
                        exit while
                    end if
                else
                    print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                end if
            else if type(msg) = "roAudioPlayerEvent" then
                print "AudioPlayerEvent type:";msg.GetType(); " msg: "; msg.GetMessage(); " - index:"; msg.GetIndex(); " data:"; msg.GetData()
                if msg.isStatusMessage() then
                    if msg.GetMessage() = "start of play" then
                        timer.Mark()
                        rokutime.Mark()
                        if busyDlg <> invalid then
                            busyDlg.close()
                            busyDlg = invalid
                            latency = latencytimer.TotalSeconds()
                        end if
                        if latency <= 0 then
                            ' This shouldn't happen, but it did at least once!
                            print "Had to go to backup latency!"
                            latency = rokutime.asSeconds() - now
                        end if
                        print "Latency = ";latency," now - initial timestamp = ";rokutime.asSeconds() - now
                        progress = 0    ' allows code to update progress bar
                    else if msg.GetMessage() = "end of stream" then
                        ' This shouldn't occur for a stream
                        print "Unexpected 'end of stream' received"
                        audio.Stop()
                        stopped = true
                        exit while
                    end if
                end if
            else if type(msg) = "roMessageDialogEvent" then
                if msg.isButtonPressed() then 'msg.GetIndex() = 1 then
                    plscreen.Close()
                    rpplup = false
                end if
            else
                print "unexpected type.... type=";msg.GetType();" index=";msg.GetIndex();" msg: "; msg.GetMessage()
            end if
        end if
    end while

    return {stopped: stopped,
            song : song,
            paused : paused,
            pausedtime : pausedtime,
            latency : latency,
            cumulative : cumulative,
            timediff : timediff,
            rprss : rprss,
            rplist : rplist,
            rppl : rppl,
            rpupdate : rpupdate,
            isStream : true
            }
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
    'qualities = ["HD"]

    videoclip = video

    videoclip.StreamBitrates = bitrates
    videoclip.StreamQualities = qualities
    videoclip.PlayStart = offset
    videoclip.StreamUrls = [video["url"]]

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
                print "isFullResult"
                nowpos = -1
            else if msg.isPartialResult()
                print "isPartialResult, nowpos = ";nowpos
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            end if
        end if
    end while
    return nowpos
End Function
