#!/usr/bin/env python
# Copyright 2010, Brian Taylor
# Distribute under the terms of the GNU General Public License
# Version 2 or better

# these are the variables you should configure to your
# liking.
portno = 8001
hostname = "http://your_servers_ip_or_hostname:%d" % portno
musicdir = "/where/your/music/lives"

# main webapp
import os
import re
import web
from PyRSS2Gen import *
import eyeD3
import urllib


def file2item(fname):
  tag = eyeD3.Tag()
  if not tag.link(fname):
    return None

  size = os.stat(fname).st_size

  link="%s/song?%s" % (hostname, urllib.urlencode({'name':fname}))

  print link

  return RSSItem(
      title=tag.getTitle() or "none",
      link = link,
      enclosure = Enclosure(
        url = link,
        length = size,
        type = "audio/mpeg"),
      description=tag.getArtist(),
      guid = Guid(link, isPermaLink=0),
      pubDate = datetime.datetime.now())

def dir2item(dname):
  link = "%s/feed?%s" % (hostname, urllib.urlencode({'dir':dname}))
  name = os.path.split(dname)[1]

  return RSSItem(
      title = name,
      link = link,
      description = "Folder",
      guid = Guid(link, isPermaLink=0),
      pubDate = datetime.datetime.now())

def getdoc(path, recurse=False):
  items = []
  for base, dirs, files in os.walk(path):
    if not recurse:
      for dir in dirs:
        items.append(dir2item(os.path.join(base,dir)))

      del dirs[:]

    for file in files:
      if not os.path.splitext(file)[1].lower() == ".mp3":
        print "rejecting %s" % file
        continue

      items.append(file2item(os.path.join(base,file)))

  doc = RSS2(
      title="A Personal Music Feed",
      link="%s/feed?dir=%s" % (hostname,path),
      description="My music.",
      lastBuildDate=datetime.datetime.now(),
      items = items )

  return doc

def doc2m3u(doc):
  lines = []
  for item in doc.items:
    lines.append(item.link)
  return "\n".join(lines)

class SongHandler:
  def GET(self):
    song = web.input(name = None)
    if not song.name:
      return

    size = os.stat(song.name).st_size

    web.header("Content-Type", "audio/mpeg")
    web.header("Content-Length", "%d" % size)
    f = open(song.name, "rb")

    # is this a range request?
    # looks like: 'HTTP_RANGE': 'bytes=41017-'
    if 'HTTP_RANGE' in web.ctx.environ:
      regex = re.compile('bytes=(\d+)-$')
      start = int(regex.match(web.ctx.environ['HTTP_RANGE']).group(1))
      print "player issued range request starting at %d" % start
      f.seek(start)
      return f.read()
    else:
      # write the whole thing
      return f.read()

class RssHandler:
  def GET(self):
    "retrieve a specific feed"

    web.header("Content-Type", "application/rss+xml")
    feed = web.input(dir = None)
    if feed.dir:
      return getdoc(feed.dir, True).to_xml()
    else:
      return getdoc(musicdir).to_xml()

class M3UHandler:
  def GET(self):
    "retrieve a feed in m3u format"

    web.header("Content-Type", "text/plain")
    feed = web.input(dir = None)
    if feed.dir:
      return doc2m3u(getdoc(feed.dir, True))
    else:
      return doc2m3u(getdoc(musicdir, True))

urls = (
    '/feed', 'RssHandler',
    '/song', 'SongHandler',
    '/m3u', 'M3UHandler')

app = web.application(urls, globals())

if __name__ == "__main__":
  import sys
  sys.argv.append("%d"%portno)
  app.run()
