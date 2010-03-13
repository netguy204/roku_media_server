' ********************************************************************'
' **  RssPlayer'
' **  Brian Taylor el.wubo@gmail.com'
' **  Copyright (c) 2010'
' ********************************************************************'

Function CreateMediaRSSConnection() As Object
        rss = {
                port: CreateObject("roMessagePort"),
                http: CreateObject("roUrlTransfer"),

                GetSongListFromFeed: GetSongListFromFeed
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
'print "feed_url: ";feed_url
'print "XML: ";xml

    items = CreateObject("roList")

    theme = rss.channel.theme.GetText()

    for each item in rss.channel.item
        items.Push(newMediaFromXML(m, item))
        '!!!***print "got media item: "; items.Peek().GetTitle()
    next

    return { items:items, theme:theme }
End Function

Sub CreateSettingsPoster(items)
' Creates a bare minimum XML entry for the "settings" poster.
' Most of the item.GetXxx functions are not valid.
' Use item.IsSettings() to check for the settings entry before 
' proceeding with other functions.
    print "CreateSettingsPoster"

    settingsXML = CreateObject("roXMLElement")
    settingsXML.SetName("Settings root")
    ne=settingsXML.AddBodyElement()
    ne.SetName("title")
    ne.SetBody("My Settings")
    ne=settingsXML.AddBodyElement()
    ne.SetName("image")
    ne.SetBody("pkg:/images/settings_square.jpg")
    ne=settingsXML.AddBodyElement()
    ne.SetName("description")
    ne.SetBody("Channel Settings")
    ne=settingsXML.AddBodyElement()
    ne.SetName("settings")
    'ne.SetBody("settings")
    items.Push(newMediaFromXML(invalid, settingsXML))
End Sub

Sub CreateNowPlayingPoster(items)
' Creates a bare minimum XML entry for the "Now Playing" poster.
' Most of the item.GetXxx functions are not valid.
' Use item.IsNowPlaying() to check for the settings entry before 
' proceeding with other functions.
    print "CreateNowPlayingPoster"

    settingsXML = CreateObject("roXMLElement")
    settingsXML.SetName("Now Playing root")
    ne=settingsXML.AddBodyElement()
    ne.SetName("title")
    ne.SetBody("Now Playing")
    ne=settingsXML.AddBodyElement()
    ne.SetName("image")
    ne.SetBody("pkg:/images/nowplaying_square.jpg")
    ne=settingsXML.AddBodyElement()
    ne.SetName("description")
    ne.SetBody("Return to Audio Player")
    ne=settingsXML.AddBodyElement()
    ne.SetName("playerctl")
    'ne.SetBody("settings")
    items.Push(newMediaFromXML(invalid, settingsXML))
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
        GetType:itemGetType,
        GetLength:itemGetLength,
        GetAlbum:itemGetAlbum,
        GetArtist:itemGetArtist,
        IsPlayable:itemIsPlayable
        IsSettings:itemIsSettings,
        IsNowPlaying:itemIsNowPlaying,
        GetSubItems:itemGetSubItems }

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

Function itemGetPlayable()
    '!!!***print "getting playable for ";m.GetMedia()
    '!!!***print "type: "; m.GetType()
    sf = m.GetStreamFormat()
    ct = m.GetContentType()
    return { Url: m.GetMedia(), ContentType: ct, Title: m.GetTitle(), StreamFormat: sf,
             Length: m.GetLength(), Artist: m.GetArtist(), Album: m.GetAlbum() }
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

    return {
        ShortDescriptionLine1: m.GetTitle(),
        ShortDescriptionLine2: m.GetDescription(),
        HDPosterUrl: icon,
        SDPosterUrl: icon,
        item: m }
End Function

Function itemIsPlayable()
    return m.xml.enclosure.Count() > 0
End Function

Function itemIsSettings()
    return m.xml.settings.Count() > 0
End Function

Function itemIsNowPlaying()
    return m.xml.playerctl.Count() > 0
End Function

Function itemGetSubItems()
    return m.rss.GetSongListFromFeed(m.GetMedia())
End Function
