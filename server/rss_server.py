#!/usr/bin/env python
# Copyright 2010, Brian Taylor
# Distribute under the terms of the GNU General Public License
# Version 2 or better


# this file contains the configurable variables
config_file = "config.ini"

# main webapp
import os
import re
import web
from PyRSS2Gen import *
import eyeD3
import urllib
import ConfigParser
import common

class RSSImageItem(RSSItem):
  "extending rss items to support a per item image"
  def __init__(self, **kwargs):
    if 'image' in kwargs:
      self.image = kwargs['image']
      del kwargs['image']
    else:
      self.image = None

    RSSItem.__init__(self, **kwargs)

  def publish_extensions(self, handler):
    if self.image:
      handler.startElement('image', {})
      handler.characters(self.image)
      handler.endElement('image')

def file2item(fname, config, image=None):
  tag = eyeD3.Tag()
  if not tag.link(fname):
    return None

  size = os.stat(fname).st_size

  link="%s/song?%s" % (common.server_base(config), urllib.urlencode({'name':fname}))
  
  if image:
    image = "%s/image?%s" % (common.server_base(config), urllib.urlencode({'name':image}))

  print link

  return RSSImageItem(
      title=tag.getTitle() or "none",
      link = link,
      enclosure = Enclosure(
        url = link,
        length = size,
        type = "audio/mpeg"),
      description=tag.getArtist(),
      guid = Guid(link, isPermaLink=0),
      pubDate = datetime.datetime.now(),
      image = image)

def dir2item(dname, config):
  link = "%s/feed?%s" % (common.server_base(config), urllib.urlencode({'dir':dname}))
  name = os.path.split(dname)[1]

  return RSSItem(
      title = name,
      link = link,
      description = "Folder",
      guid = Guid(link, isPermaLink=0),
      pubDate = datetime.datetime.now())

def getdoc(path, config, recurse=False):
  items = []
  for base, dirs, files in os.walk(path):
    if not recurse:
      for dir in dirs:
        items.append(dir2item(os.path.join(base,dir), config))

      del dirs[:]

    # first pass to find images
    curr_image = None
    img_re = re.compile(".jpg|.jpeg|.png")
    for file in files:
      ext = os.path.splitext(file)[1]
      if ext and img_re.match(ext):
        curr_image = os.path.join(base,file)

    for file in files:
      if not os.path.splitext(file)[1].lower() == ".mp3":
        print "rejecting %s" % file
        continue

      items.append(file2item(os.path.join(base,file), config, curr_image))

  doc = RSS2(
      title="A Personal Music Feed",
      link="%s/feed?dir=%s" % (common.server_base(config), path),
      description="My music.",
      lastBuildDate=datetime.datetime.now(),
      items = items )

  return doc

def doc2m3u(doc):
  lines = []
  for item in doc.items:
    lines.append(item.link)
  return "\n".join(lines)

def range_handler(fname):
  f = open(fname, "rb")

  bytes = None

  # is this a range request?
  # looks like: 'HTTP_RANGE': 'bytes=41017-'
  if 'HTTP_RANGE' in web.ctx.environ:
    regex = re.compile('bytes=(\d+)-$')
    start = int(regex.match(web.ctx.environ['HTTP_RANGE']).group(1))
    print "player issued range request starting at %d" % start
    f.seek(start)
    bytes = f.read()
  else:
    # write the whole thing
    bytes = f.read()
  
  f.close()
  return bytes

class SongHandler:
  "retrieve a song"

  def GET(self):
    song = web.input(name = None)
    if not song.name:
      return

    size = os.stat(song.name).st_size
    web.header("Content-Type", "audio/mpeg")
    web.header("Content-Length", "%d" % size)
    return range_handler(song.name)

class ImageHandler:
  "retrieve album art"

  def GET(self):
    img = web.input(name = None)
    if not img.name:
      return

    size = os.stat(img.name).st_size
    web.header("Content-Type", "image/jpeg")
    web.header("Content-Length", "%d" % size)
    return range_handler(img.name)

class RssHandler:
  def GET(self):
    "retrieve a specific feed"

    config = common.parse_config(config_file)
    collapse_collections = config.get("DEFAULT", "collapse_collections").lower() == "true"

    web.header("Content-Type", "application/rss+xml")
    feed = web.input(dir = None)
    if feed.dir:
      return getdoc(feed.dir, config, collapse_collections).to_xml()
    else:
      return getdoc(config.get("DEFAULT", 'music_dir'), config).to_xml()

class M3UHandler:
  def GET(self):
    "retrieve a feed in m3u format"

    config = common.parse_config(config_file)

    web.header("Content-Type", "text/plain")
    feed = web.input(dir = None)
    if feed.dir:
      return doc2m3u(getdoc(feed.dir, config, True))
    else:
      return doc2m3u(getdoc(config.get("DEFAULT", 'music_dir'), config, True))

urls = (
    '/feed', 'RssHandler',
    '/song', 'SongHandler',
    '/m3u', 'M3UHandler',
    '/image', 'ImageHandler')

app = web.application(urls, globals())

if __name__ == "__main__":
  import sys

  config = common.parse_config(config_file)

  sys.argv.append(config.get("DEFAULT","server_port"))
  app.run()
