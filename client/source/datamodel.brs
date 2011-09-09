' ********************************************************************
' **  RssPlayer
' **  Brian Taylor el.wubo@gmail.com
' **  Copyright (c) 2010
' ********************************************************************

Function CreateMediaRSSConnection() As Object
	 rss = {
                port: CreateObject("roMessagePort"),
                http: CreateObject("roUrlTransfer"),

                GetSongListFromFeed: GetSongListFromFeed,
                AsyncGetSongListFromFeed: AsyncGetSongListFromFeed,
                ParseSongListFromFeed: ParseSongListFromFeed
                }

        return rss
End Function

Function GetSongListFromFeed(feed_url) As Dynamic
    print "GetSongListFromFeed"

    m.http.SetUrl(feed_url)
    xml = m.http.GetToString()
    rss=CreateObject("roXMLElement")
    if not rss.Parse(xml) then
        print "No xml received from server"
        return invalid
    end if
    print "rss@verion=";rss@version
print "feed_url: ";feed_url
'print "XML: ";xml

    items = CreateObject("roList")

    theme = rss.channel.theme.GetText()

    for each item in rss.channel.item
        items.Push(newMediaFromXML(m, item))
        'print "got media item: "; items.Peek().GetTitle()
    next

    return { items:items, theme:theme}
End Function

Function ParseSongListFromFeed(xml as String) as Dynamic
    rss=CreateObject("roXMLElement")
    if not rss.Parse(xml) then
        print "No xml received from server"
        return invalid
    end if
    'print "rss@verion=";rss@version
'print "XML: ";xml

    items = CreateObject("roList")

    theme = rss.channel.theme.GetText()

    for each item in rss.channel.item
        items.Push(newMediaFromXML(m, item))
        'print "got media item: "; items.Peek().GetTitle()
    next

    return { items:items, theme:theme }
End Function

Function AsyncGetSongListFromFeed(feed_url,port) As Boolean
    print "AsyncGetSongListFromFeed"

    m.http.SetUrl(feed_url)
    m.http.SetPort(port)
    return m.http.AsyncGetToString()
End Function

Function CreateRadioParadiseRSSConnection() As Object
    rss = {
            port: CreateObject("roMessagePort"),
            http: CreateObject("roUrlTransfer"),

            GetInfo: GetRPInfo
            }

    return rss
End Function

Function RpInfoToSong(rpinfo as Object, song as Object) as Object
    song.artist = rpinfo.artist
    song.title = rpinfo.title
    song.album = stripSlash(rpinfo.album)
    song.length = rpinfo.refresh_time.toInt() - rpinfo.timestamp.toInt()
    song.ReleaseDate = rpinfo.release_date
    if rpinfo.asin = "0" or rpinfo.asin = "" then
        arturl = "pkg:/images/streams_square.jpg"
    else
        'arturl = "http://www.radioparadise.com/graphics/covers/l/"+rpinfo.asin+".jpg"
        arturl = rpinfo.coverart
    end if
    song.HDPosterUrl = arturl
    song.SDPosterUrl = arturl
    song.streamFormat = "mp3"
    song.contentType = "audio"
    return song
End Function

Function GetRPInfo(s = invalid) As Dynamic
    print "GetRPInfo"
    m.http.SetUrl("http://www2.radioparadise.com/now_playing.xml")
    xml = m.http.GetToString()
    rppl=CreateObject("roXMLElement")
    if not rppl.Parse(xml) then
        print "No xml received from server"
        return invalid
    else
        rpinfo = CreateObject("roAssociativeArray")
        song = rppl.GetChildElements()
        rpinfo.refresh_time = song.refresh_time.GetText()
        rpinfo.playtime = song.playtime.GetText()
        rpinfo.timestamp = song.timestamp.GetText()
        rpinfo.artist = song.artist.GetText()
        rpinfo.title = song.title.GetText()
        rpinfo.songid = song.songid.GetText()
        rpinfo.album = song.album.GetText()
        rpinfo.release_date = song.release_date.GetText()
        rpinfo.coverart = song.coverart.GetText()
        rpinfo.asin = song.asin.GetText()
        if s <> invalid then RpInfoToSong(rpinfo,s)
    end if
    return rpinfo
End Function

Function GetTimestamp(url=invalid) as Integer
    print "GetTimestamp"
    tsurl = CreateObject("roUrlTransfer")
    if url = invalid
        cfg = GetConfig()
        url = cfg.server + "/timestamp"
    end if
    tsurl.setUrl(url)
    ts = tsurl.GetToString()
    print ts
    return ts.toInt()
end Function


Sub CreateSimplePoster(items as Object, title as String, image as String, description as String, name as String)
' Creates a bare minimum XML entry for a simple poster.
' Most of the item.GetXxx functions are not valid.
' Use item.IsSimple(name) to check for the simple poster entry before
' proceeding with other functions.
    print "CreateSimplePoster"

    simpleXML = CreateObject("roXMLElement")
    simpleXML.SetName(title + " root")
    ne=simpleXML.AddBodyElement()
    ne.SetName("title")
    ne.SetBody(title)
    ne=simpleXML.AddBodyElement()
    ne.SetName("image")
    ne.SetBody(image)
    ne=simpleXML.AddBodyElement()
    ne.SetName("description")
    ne.SetBody(description)
    ne=simpleXML.AddBodyElement()
    ne.SetName("name")
    ne.SetBody(name)
    items.Push(newMediaFromXML(invalid, simpleXML))
End Sub

Sub PrintXML(element As Object, depth As Integer)
    if depth = 0 then print "PrintXML"

    print tab(depth*3);"Name: ";element.GetName()
    if not element.GetAttributes().IsEmpty() then
        print tab(depth*3);"Attributes: ";
        for each a in element.GetAttributes()
            print a;"=";left(element.GetAttributes()[a], 60);
            if element.GetAttributes().IsNext() then print ", ";
        end for
        print
    end if

    if element.GetText()<>invalid then
        print tab(depth*3);"Contains Text: ";left(element.GetText(), 60)
    end if

    if element.GetChildElements()<>invalid
        print tab(depth*3);"Contains roXMLList:"
        for each e in element.GetChildElements()
            PrintXML(e, depth+1)
        end for
    end if
    print
end sub

Function newMediaFromXML(rss As Object, xml As Object) As Object
'PrintXML(xml,0)
    item = {
        rss:rss,
        xml:xml,
        GetTitle:itemGetTitle,
        GetMedia:itemGetMedia,
        GetPlayable:itemGetPlayable,
        GetPosterItem:itemGetPosterItem,
        GetDescription:itemGetDescription,
        GetStreamFormat:itemGetStreamFormat,
        GetContentType:itemGetContentType,
        GetSubtitleUrl:itemGetSubtitleUrl,
        GetBifUrl:itemGetBifUrl,
        GetType:itemGetType,
        GetLength:itemGetLength,
        GetAlbum:itemGetAlbum,
        GetArtist:itemGetArtist,
        GetDate:itemGetDate,
        IsPlayable:itemIsPlayable
        IsSimple:itemIsSimple,
        GetSubItems:itemGetSubItems,
        AsyncGetSubItems:itemAsyncGetSubItems,
        ParseSongListFromFeed:itemParseSongListFromFeed
        }

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

Function itemGetType()
    return m.xml.filetype.GetText()
End Function

Function itemGetStreamFormat()
    return m.xml.StreamFormat.GetText()
End Function

Function itemGetContentType()
    return m.xml.ContentType.GetText()
End Function

Function itemGetSubtitleUrl()
    return m.xml.SubtitleUrl.GetText()
End Function

Function itemGetBifUrl()
    return m.xml.BifUrl.GetText()
End Function

Function itemGetLength()
    l = m.xml.playtime.GetText()
    return l.toInt()
End Function

Function itemGetAlbum()
    return m.xml.album.GetText()
End Function

Function itemGetArtist()
    return m.xml.description.GetText()
End Function

Function itemGetDate()
    return m.xml.release_date.GetText()
End Function

Function itemGetPlayable()
    'print "getting playable for ";m.GetMedia()
    'print "type: "; m.GetType()
    sf = m.GetStreamFormat()
    ct = m.GetContentType()
    stu = m.GetSubtitleUrl()
    bu = m.GetBifUrl()
    return { Url: m.GetMedia(), ContentType: ct, Title: m.GetTitle(), StreamFormat: sf, SubtitleUrl:stu, SDBifUrl:bu, HDBifUrl:bu,
             Length: m.GetLength(), Artist: m.GetArtist(), Album: m.GetAlbum(), ReleaseDate: m.GetDate()}
End Function

Function itemGetPosterItem()
    'print "itemGetPosterItem"

    icon = "pkg:/images/music_square.jpg"

    'see if there is an image associated with this item'
    if m.xml.image.Count() > 0 then
        icon = m.xml.image.GetText()
    else if not m.IsPlayable() then
        icon = "pkg:/images/folder_square.jpg"
    else if m.IsPlayable() and m.GetContentType() = "movie" then
        icon = "pkg:/images/videos_square.jpg"
    end if

'print "ShortDescriptionLine1: "; m.GetTitle()
'print "ShortDescriptionLine2: "; m.GetDescription()
'print "HDPosterUrl: "; icon
'print "SDPosterUrl: "; icon
    sd1 = m.GetTitle()
    sd2 = m.GetDescription()
    if sd2 = "Video" then
        offset = GetOffset(sd1)
        if offset <> 0 then
            if offset = -1 then
                ts = RegGet(sd1, "Resume")
                sec = Left(ts,10)
                dt = CreateObject("roDateTime")
                dt.fromSeconds(sec.toInt())
                sd2 = "Watched " + dt.asDateString("long-date")
            else
                sd2 = "Progress:  " + SecsToHrMinSec(offset.toStr())
            end if
        end if
    end if

    return {
        ShortDescriptionLine1: sd1,
        ShortDescriptionLine2: sd2,
        HDPosterUrl: icon,
        SDPosterUrl: icon,
        item: m }
End Function

Function itemIsPlayable()
    return m.xml.enclosure.Count() > 0
End Function

Function itemIsSimple(name)
    if m.xml.name.Count() > 0 then return m.xml.name.GetText() = name
    return false
End Function

Function itemGetSubItems()
    return m.rss.GetSongListFromFeed(m.GetMedia())
End Function

Function itemAsyncGetSubItems(port)
    return m.rss.AsyncGetSongListFromFeed(m.GetMedia(),port)
End Function

Function itemParseSongListFromFeed(xml as String) as Dynamic
    return m.rss.ParseSongListFromFeed(xml)
End Function

