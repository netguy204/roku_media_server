' ********************************************************************'
' **  RssPlayer'
' **  Brian Taylor el.wubo@gmail.com'
' **  Copyright (c) 2010'
' ********************************************************************'

Function CreateMediaRSSConnection() As Object
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
        pl.Push(newMediaFromXML(m, item))
        print "got media item";pl.Peek().GetTitle()
    next

    return pl
End Function

Function newMediaFromXML(rss As Object, xml As Object) As Object
    item = {
        rss:rss,
        xml:xml,
        GetTitle:itemGetTitle,
        GetMedia:itemGetMedia,
        GetPlayable:itemGetPlayable,
        GetPosterItem:itemGetPosterItem,
        GetDescription:itemGetDescription,
        IsPlayable:itemIsPlayable,
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

Function itemGetPlayable()
    print "getting playable for ";m.GetMedia()
    return { Url: m.GetMedia(), StreamFormat: "mp3" }
End Function

Function itemGetPosterItem()
    icon = "pkg:/images/music.jpg"
    
    'see if there is an image associated with this item'
    if m.xml.image.Count() > 0 then
        icon = m.xml.image.GetText()
    else if not m.IsPlayable() then
        icon = "pkg:/images/folder.jpg"
    endif

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

Function itemGetSubItems()
    return m.rss.GetSongListFromFeed(m.GetMedia())
End Function

