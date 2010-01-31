' ********************************************************************
' **  Sample PlayVideo App
' **  Copyright (c) 2009 Roku Inc. All Rights Reserved.
' ********************************************************************

Function CreateMediaRSSConnection()As Object
	rss = {
		port: CreateObject("roMessagePort"),
		http: CreateObject("roUrlTransfer"),

		GetSongListFromFeed: GetSongListFromFeed,
		}

	return rss
End Function

Function GetSongListFromFeed(feed_url) As Object
    print "GetSongListFromFeed"

    m.http.SetUrl(feed_url)
    xml = m.http.GetToString()
    rss=CreateObject("roXMLElement")
    if not rss.Parse(xml) then stop
    print "rss@verion=";rss@version

    pl=CreateObject("roList")
    for each item in rss.channel.item
        pl.Push(newMediaFromXML(m.http, item))
        print "got media item";pl.Peek().GetTitle()
    next

    return pl
End Function

Function newMediaFromXML(http As Object, xml As Object) As Object
    item = {
        http:http,
        xml:xml,
        GetTitle:itemGetTitle,
        GetMedia:itemGetMedia,
        GetPlayable:itemGetPlayable,
        GetPosterItem:itemGetPosterItem,
        GetDescription:itemGetDescription }

    return item
End Function

Function itemGetTitle()
    return m.xml.title.GetText()
End Function

Function itemGetMedia()
    return m.xml.link.GetText()
End Function

Function itemGetDescription()
    return m.xml.description.GetText()
End Function

Function itemGetPlayable()
    print "getting playable for ";m.GetMedia()
    return { Url: m.GetMedia(), StreamFormat: "mp3" }
End Function

Function itemGetPosterItem()
    return {
        ShortDescriptionLine1: m.GetTitle(),
        ShortDescriptionLine2: m.GetDescription(),
        HDPosterUrl: "pkg:/images/music.jpg",
        SDPosterUrl: "pkg:/images/music.jpg",
        item: m }
End Function

Function makePosterScreen(items) As Object

    screen=CreateObject("roPosterScreen")
    port=CreateObject("roMessagePort")

    screen.SetMessagePort(port)
    screen.SetListStyle("flat-episodic")
    screen.SetListDisplayMode("best-fit")
    screen.SetFocusedListItem(0)
    screen.SetIconArray(items)

    return {
        screen: screen,
        port: port,
        GetSelection: psGetSelection }

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
    pl=rss.GetSongListFromFeed("http://buster:8001/feed")



    posters=CreateObject("roList")
    audio = CreateObject("roAudioPlayer")
    for each song in pl
        audio.AddContent(song.GetPlayable())
        posters.Push(song.GetPosterItem())
    next
    audio.SetLoop(false)
    audio.Play()

    desc = invalid
    item = CreateVideoItem(desc)
    
    pscr = makePosterScreen(posters)
    
    while true
        song = pscr.GetSelection(0)
        if song = -1 then
            return
        endif
        item = posters[song].item
        audio.Stop()
        audio.ClearContent()
        audio.AddContent(item.GetPlayable())
        audio.Play()
        print item.GetTitle()
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
    theme.OverhangPrimaryLogoSD  = "pkg:/images/Logo_Overhang_SD43.png"

    theme.OverhangPrimaryLogoOffsetHD_X = "123"
    theme.OverhangPrimaryLogoOffsetHD_Y = "20"
    theme.OverhangSliceHD = "pkg:/images/Overhang_BackgroundSlice_HD.png"
    theme.OverhangPrimaryLogoHD  = "pkg:/images/Logo_Overhang_HD.png"
    
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

Function displayVideo()
    print "Displaying video: "
    p = CreateObject("roMessagePort")
    video = CreateObject("roVideoScreen")
    video.setMessagePort(p)

    'bitrates  = [0]'          ' 0 = no dots'
    'bitrates  = [348000]'    ' <500 Kbps = 1 dot'
    'bitrates  = [664000]'    ' <800 Kbps = 2 dots'
    'bitrates  = [996000]'    ' <1.1Mbps  = 3 dots'
    'bitrates  = [2048000]'    ' >=1.1Mbps = 4 dots'
    bitrates  = [1500]    
    urls = ["http://video.ted.com/talks/podcast/DanGilbert_2004_480.mp4"]
    qualities = ["SD"]
    'qualities = ["HD"]'
    
    videoclip = CreateObject("roAssociativeArray")
    videoclip.StreamBitrates = bitrates
    videoclip.StreamUrls = urls
    videoclip.StreamQualities = qualities
    videoclip.StreamFormat = "mp4"
    videoclip.Title = "Dan Gilbert asks, Why are we happy?"

    'videoclip.StreamFormat = "wmv"'
 
    video.SetContent(videoclip)
    video.show()

    lastSavedPos   = 0
    statusInterval = 10 'position must change by more than this number of seconds before saving'

    while true
        msg = wait(0, video.GetMessagePort())
        if type(msg) = "roVideoScreenEvent"
            if msg.isScreenClosed() then 'ScreenClosed event
                print "Closing video screen"
                exit while
            else if msg.isPlaybackPosition() then
                nowpos = msg.GetIndex()
                if nowpos > 10000
                    
                end if
                if nowpos > 0
                    if abs(nowpos - lastSavedPos) > statusInterval
                        lastSavedPos = nowpos
                    end if
                end if
            else if msg.isRequestFailed()
                print "play failed: "; msg.GetMessage()
            else
                print "Unknown event: "; msg.GetType(); " msg: "; msg.GetMessage()
            endif
        end if
    end while
End Function

