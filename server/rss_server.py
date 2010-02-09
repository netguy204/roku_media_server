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
import subprocess
import tornado.httpserver
import tornado.ioloop
import tornado.web
import tornado.escape
import re
import math
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

  print doc.to_xml()
  return doc

class SongHandler(tornado.web.RequestHandler):
  def get(self):
    song = self.get_argument('name', None)
    if not song:
      return

    self.set_header("Content-Type", "audio/mpeg")
    self.write(open(song).read())

class RssHandler(tornado.web.RequestHandler):
  def get(self):
    "retrieve a specific feed"

    feed = self.get_argument('dir', None)
    if feed:
      self.write(getdoc(feed, True).to_xml())
    else:
      self.write(getdoc(musicdir).to_xml())

application = tornado.web.Application([
    (r"/feed", RssHandler),
    (r"/song", SongHandler),
])

if __name__ == "__main__":
  http_server = tornado.httpserver.HTTPServer(application)
  http_server.listen(portno)
  tornado.ioloop.IOLoop.instance().start()
