' started as main/next netguy204-roku_media_server-d01e74f.zip
' ********************************************************************'
' **  MyMedia - Springboard/SlideShow version'
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

Function ShowSettings(currentSettings as Object, toolate=true) as Object
    print "ShowSettings"

    currentServer = currentSettings.server
    currentDelay = currentSettings.ssDelay
    newserver = currentServer
    newdelay = currentDelay

    port = CreateObject("roMessagePort")
    settings = invalid

    while true
        settings = CreateObject("roParagraphScreen")
        settings.SetMessagePort(port)
        settings.AddHeaderText("Current configuration:")
        settings.AddParagraph("Server:"+chr(10)+currentServer)
        settings.AddParagraph("Slide show delay:"+chr(10)+currentDelay+" seconds")
        settings.AddButton(1,"Edit server")
        settings.AddButton(2,"Edit slide show delay")
        settings.AddButton(3,"Finished")

        settings.Show()

        msg = wait(0, port)

        if msg.GetIndex() = 1 then
            newserver = EditDialog("Enter server ip address and port",currentServer,"Example:  http://192.168.1.100:8001/feed",50)
        else if msg.GetIndex() = 2 then
            newdelay = EditDialog("Enter slide show delay",currentDelay,"Slide show delay in seconds",4)
        else
            exit while
        end if
        if newserver <> currentServer or newdelay <> currentDelay then
            nd = newdelay.toInt()
            newdelay = nd.toStr()
            RegSave("Server", newserver, "Settings")
            RegSave("Slide show delay", newdelay, "Settings")
            if newserver <> currentServer and toolate then
                ShowServerWarning()
            end if
            currentServer = newserver
            currentDelay = newdelay
print "New server: "; newserver, "New delay: "; newdelay
        end if
    end  while

    newSettings = {server: currentServer, ssDelay: currentDelay}
    return newSettings
End Function

Function EditDialog(title as String, val as String, hint as String, maxlen as Integer)
    port = CreateObject("roMessagePort")
    kb = CreateObject("roKeyboardScreen")
    kb.SetMessagePort(port)
    kb.SetMaxLength(maxlen) '50)
    kb.SetTitle(title) '"Enter server ip address and port")
    kb.SetDisplayText(hint) '"Example:  http://192.168.1.100:8001/feed")
    kb.SetText(val)
    kb.AddButton(1,"Finished")
    kb.Show()
    while true
        msg = wait(0, kb.GetMessagePort())

        if type(msg) = "roKeyboardScreenEvent" then
            if msg.isScreenClosed() then
                ' only way to get here is if the Home remote button was press (I think),
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

    dialog.SetTitle(title)  '"Media List Problem")
    dialog.SetText(text)    '"No media items retrieved.  Is the media path set correctly? Does the selected path contain playable files?")
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

Function ShowBusy() as Object
    port = CreateObject("roMessagePort")
    busyDlg = CreateObject("roOneLineDialog")
    busyDlg.SetTitle("retrieving...")
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

    return {server: server, ssDelay: ssDelay}
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
        busyDlg = ShowBusy()

        pl = rss.GetSongListFromFeed(currentConfig.server)
        if pl = invalid then
            svrContact = false
            items = CreateObject("roList")
            pl = {items: items, theme: "media"}
        else
            svrContact = true
        end if

        ' Add the "settings" poster before proceeding (may be only poster if no contact w/server established)
        CreateSettingsPoster(pl.items)

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
                initTheme(app, "media")
                tmpscr.screen.Close()
                exit while
            end if
        end while
    end while

    ' Create an array to store Poster screens as we traverse the hierarchy
    pscr = CreateObject("roArray",1,true)

    ' Create the top level folders poster screen
    pscr[0] = makePosterScreen("","")
    pscr[0].SetPlayList(pl)
    level = 0

    audio = CreateObject("roAudioPlayer")

    currentBaseSong = 0
    currentTheme = "media"

    pscr[0].screen.Show()
    busyDlg.Close()
    port = pscr[level].screen.GetMessagePort()
    audio.SetMessagePort(port)

    while true
        msg = wait(0, port)
        'print "mainloop msg = "; type(msg)
        'print "type = "; msg.GetType()
        'print "index = "; msg.GetIndex()

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
                        'maxSong = posters.Count() - 1
                        songs = buildAudioContent(posters)
                        currentSong = itemIndex
                        currentSong = showSpringboardScreen(audio, port, songs, currentSong)
                    else if item.GetType() = "image" then
                        ssBusyDlg = ShowBusy()
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
                    end if

                else if item.IsSettings()
                    print "settings selected"
                    initTheme(app, "settings")
                    pscr[0].screen.Show()
                    currentConfig = ShowSettings(currentConfig)
                    initTheme(app, "media")
                    pscr[0].screen.Show()
                else
                    'load the sub items and display those'
                    busyDlg = ShowBusy()
                    print "loading subitems for "; itemIndex; " - "; item.GetTitle()
                    pl = item.GetSubItems()
                    if pl <> invalid and pl.items.Count() <> 0 then
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
                if msg.GetMessage() = "end of stream" then
                    currentSong = GetNextSong(songs,currentSong)
                    print "Song "; currentSong; " should be next"
                    audio.SetNext(currentSong)
                    audio.Play()
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
    theme.BreadcrumbTextLeft = "#89B811"
    theme.BreadcrumbTextRight = "#FAFAFA"
    'theme.BreadcrumbDelimeter = "#FF00FF"
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
        else
            newidx = newidx - 1
        end if
    end for
    return newidx
End Function

Function buildAudioContent(posters as object) as Object
    print "buildAudioContent"

    songs = CreateObject("roArray",1,true)
print posters.Count(); " posters"
    maxidx = posters.Count() - 1
    for i = 0 to maxidx
        item = posters[i].item
        song = item.GetPlayable()
        'song.Title = item.GetTitle()
        poster = item.GetPosterItem()
        song.SDPosterURL = poster.SDPosterURL
        song.HDPosterURL = poster.HDPosterURL
        'song.Length = 333 ' !!! need to get real length
        'song.Album = poster.ShortDescriptionLine1
        'song.Artist = poster.ShortDescriptionLine2
        songs.Push(song)
    end for
    return songs
End Function

Function GetNextSong(songs as Object, idx as Integer) as Integer
    print "GetNextSong"

    maxidx = songs.Count() - 1
    idx = idx + 1
    if idx > maxidx then idx = 0
    while songs[idx].LookUp("ContentType") <> "audio"
        idx = idx + 1
        if idx > maxidx then idx = 0
    end while
    return idx
End Function

Function GetPreviousSong(songs as Object, idx as Integer) as Integer
    print "GetPreviousSong"

    maxidx = songs.Count() - 1
    idx = idx - 1
    if idx < 0 then idx = maxidx
    while songs[idx].LookUp("ContentType") <> "audio"
        idx = idx - 1
        if idx < 0 then idx = maxidx
    end while
    return idx
End Function

'*************************************************************'
'** showSpringboardScreen()'
'*************************************************************'

Function showSpringboardScreen(audio as object, port as object, songs as object, idx as Integer) As Integer
    print "showSpringboardScreen"

    screen = CreateObject("roSpringboardScreen")
    screen.SetMessagePort(port)
    screen.AllowUpdates(false)

    print songs.Count(); " songs in playlist"
    maxidx = songs.Count() - 1
    audio.SetContentList(songs)
    audio.SetNext(idx)
    audio.SetLoop(false)

    screen.SetContent(songs[idx])
    screen.SetDescriptionStyle("audio")
    screen.ClearButtons()
    screen.AddButton(1,"Pause")
    screen.AddButton(2,"Go Back")
    screen.SetStaticRatingEnabled(false)
    screen.SetProgressIndicatorEnabled(true)
    screen.AllowNavLeft(true)
    screen.AllowNavRight(true)
    'screen.AllowNavRewind(true)  INVALID FUNCTIONS!!!
    'screen.AllowNavFastForward(true)
    screen.AllowUpdates(true)

    screen.Show()

    remoteLeft = 4
    remoteRight = 5

    paused = false

    progress = -1
    length = songs[idx].LookUp("Length")

    cumulative = 0
    timer = CreateObject("roTimespan")
    audio.Play()
    while true
        msg = wait(1000, port)  ' wait no more than a second so progress bar can be updated
        if not paused and progress >= 0 then
            progress = cumulative + timer.TotalSeconds()
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
                    if msg.GetIndex() = remoteLeft then
                        idx = GetPreviousSong(songs,idx)
                    else
                        idx = GetNextSong(songs,idx)
                    end if
                    audio.Stop()
                    audio.SetNext(idx)
                    screen.AllowUpdates(false)
                    screen.SetContent(songs[idx])
                    length = songs[idx].LookUp("Length")
                    screen.SetProgressIndicator(0, length)
                    screen.AllowUpdates(true)
                    progress = -1
                    cumulative = 0
                    audio.Play()
                else
                    print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
                end if
            else if type(msg) = "roAudioPlayerEvent" then
                print "AudioPlayerEvent: ";msg.GetType(); " msg: "; msg.GetMessage()
                if msg.isStatusMessage() then
                    if msg.GetMessage() = "start of play" then
                        timer.Mark()
                        progress = 0    ' allows code to update progress bar
                    else if msg.GetMessage() = "end of stream" then
                        progress = -1   ' flag so code won't update progress bar
                        cumulative = 0
                        idx = GetNextSong(songs,idx)
                        print "Song "; idx; " should be next"
                        audio.SetNext(idx)
                        screen.AllowUpdates(false)
                        screen.SetContent(songs[idx])
                        length = songs[idx].LookUp("Length")
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

    return idx
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
