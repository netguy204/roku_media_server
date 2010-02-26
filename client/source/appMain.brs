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

Function ShowBusy() as Object
    port = CreateObject("roMessagePort")
    busyDlg = CreateObject("roOneLineDialog")
    busyDlg.SetTitle("retrieving...")
    busyDlg.showBusyAnimation()
    busyDlg.SetMessagePort(port)
    busyDlg.Show()
    return busyDlg
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
        print "unexpected error in CreateMediaRSSConnection"
    end if

    port = CreateObject("roMessagePort")

    busyDlg = ShowBusy()

    while true
        ' Try "Transient" section first for backwards compatibility
        server = RegGet("Server", "Transient")
        if server = invalid then
            server = RegGet("Server", "Settings")
        else
            RegSave("Server", server, "Settings")
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
                'exit the app gently so that the screen doesnt flash to black'
                print "Exiting app"
                screenFacade.showMessage("")
                sleep(25)
                return
            end if
        elseif pl.items.Count() = 0         ' looks like the server always returns the mymusic folder
            if ShowListProblemDialog() then ' should it always return all top level folders???
                print "Outta here!"
                'exit the app gently so that the screen doesnt flash to black'
                print "Exiting app"
                screenFacade.showMessage("")
                sleep(25)
                return
            end if
        else
            exit while
        end if
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
        print "mainloop msg = "; type(msg)
        print "type = "; msg.GetType()
        print "index = "; msg.GetIndex()

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
            pscr[level].screen.Show()
        else if type(msg) = "roPosterScreenEvent" then
            if msg.isListItemSelected() then
                itemIndex = msg.GetIndex()

                posters = pscr[level].GetPosters()
                item = posters[itemIndex].item

                if item.IsPlayable() then
                    audio.Stop()
                    audio.ClearContent()

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
                        'maxSong = posters.Count() - 1
                        songs = buildAudioContent(posters)
                        currentSong = itemIndex
                        currentSong = showSpringboardScreen(audio, port, songs, currentSong)
                    else if item.GetType() = "jpg" then
                        REM print "Photo: "; item.GetTitle()
                        REM print item.GetMedia()
                        REM ss = CreateObject("roSlideShow")
                        REM ss.addContent({url: item.GetMedia() })
                        REM ss.show()
                    REM else if item.GetType() = "image" then
                        print "Photo: "; item.GetTitle()
                        print item.GetMedia()
                        ss = CreateObject("roSlideShow")
                        cl = CreateObject("roArray",1,true)
                        ss.SetContentList(cl)
                        ss.addContent({url: item.GetMedia(), TextOverlayBody: "This is an overlay", TextOverLayUL: "asdf asdfdf",
                            Title: "this it the title"})
                        ss.SetPeriod(0)
                        ss.SetMessagePort(port)
                        ss.SetDisplayMode("scale-to-fit")
                        ss.SetUnderScan(2.5)
                        ss.show()
                        while true
                            ssmsg = wait(0, port)
                            print "mainloop msg = "; type(ssmsg)
                            print "type = "; ssmsg.GetType()
                            print "index = "; ssmsg.GetIndex()
                            if ssmsg.isScreenClosed() then exit while
                        end while
                    end if

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
                        if ShowServerProblemDialog(server) then
                            print "Outta here!"
                            exit while
                        end if
                    else if ShowListProblemDialog() then
                        print "Outta here!"
                        exit while
                    end if
                    busyDlg.Close()
                end if
            end if
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
            REM if msg.isRequestSucceeded() then
                REM print "audio isRequestSucceeded"

                REM 'queue the next song'
                REM posters = pscr[level].GetPosters()
                REM song = currentBaseSong + 1
                REM maxsong = posters.Count() - 1

                REM if song > maxsong
                    REM song = 0
                REM end if

                REM print "song: ";Stri(song)
                REM print "max song: ";Stri(maxsong)

                REM audio.Stop()
                REM audio.ClearContent()
                REM item = posters[song].item

                REM 'stop if the next item is a video'
                REM if not item.GetType() = "mp4" then
                    REM audio.AddContent(item.GetPlayable())
                    REM audio.Play()
                REM end if

                REM pscr[level].screen.SetFocusedListItem(song)
                REM currentBaseSong = song
            REM end if
            REM if msg.isPartialResult() then
                REM print "audio partial result"
            REM end if
            REM if msg.isRequestFailed() then
                REM print "audio request failed: ";msg.GetMessage()
                REM print "error code: ";Stri(msg.GetIndex())
            REM end if
            REM if msg.isFullResult() then
                REM print "isFullResult"
            REM end if
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
    app.SetTheme(theme)

End Sub


Function buildAudioContent(posters as object) as Object
    print "buildAudioContent"

    songs = CreateObject("roArray",1,true)
print posters.Count(); " posters"
    maxidx = posters.Count() - 1
    for i = 0 to maxidx
        'if posters[i].item.GetType() = "mp3" then     '!!! need to change to "audio"
            item = posters[i].item
            song = item.GetPlayable()
            song.Title = item.GetTitle()
            poster = item.GetPosterItem()
            song.SDPosterURL = poster.SDPosterURL
            song.HDPosterURL = poster.HDPosterURL
            'song.Length = 333 ' !!! need to get real length
            song.Album = poster.ShortDescriptionLine1
            song.Artist = poster.ShortDescriptionLine2
            songs.Push(song)
        'end if
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
    audio.Play()

    progress = -1
    length = songs[idx].LookUp("Length")
print "length = "; length
    cumulative = 0
    timer = CreateObject("roTimespan")
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
                    screen.SetProgressIndicator(0, length) '!!! need to get real length
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
                        screen.SetProgressIndicator(0, length) '!!! need to get real length
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

