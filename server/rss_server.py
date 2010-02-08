#!/usr/bin/env python
# Copyright 2009, Brian Taylor
# Distributed under the GNU General Public License

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

portno = 8001
hostname = "http://buster:%d" % portno
stddesc = "a song"

testsong = "testsng.mp3"
testmusic = "/home/asunbeam/dropbox/roku/"

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
      title="my test feed",
      link="http://wubo.org/tf.xml",
      description="stuff",
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
      self.write(getdoc(testmusic).to_xml())

application = tornado.web.Application([
    (r"/feed", RssHandler),
    (r"/song", SongHandler),
])

if __name__ == "__main__":
  http_server = tornado.httpserver.HTTPServer(application)
  http_server.listen(portno)
  tornado.ioloop.IOLoop.instance().start()
