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
  "extending rss items to support our extended tags"
  TAGS = ('image', 'filetype')
  def __init__(self, **kwargs):
    for name in RSSImageItem.TAGS:
      if name in kwargs:
        setattr(self, name, kwargs[name])
        del kwargs[name]
      else:
        setattr(self, name, None)

    RSSItem.__init__(self, **kwargs)

  def publish_extensions(self, handler):
    for name in RSSImageItem.TAGS:
      val = getattr(self, name)
      if val:
        handler.startElement(name, {})
        handler.characters(val)
        handler.endElement(name)

def file2item(fname, config, image=None):
  # guess the filetype based on the extension
  ext = os.path.splitext(fname)[1].lower()

  title = "None"
  description = "None"
  filetype = None
  mimetype = None

  if ext == ".mp3":
    # use the ID3 tags to fill out the mp3 data

    try:
      tag = eyeD3.Tag()
      if not tag.link(fname):
        return None
    except:
      print "library failed to parse ID3 tags for %s. Skipping." % fname
      return None

    title = tag.getTitle()
    description = tag.getArtist()
    filetype = "mp3"
    mimetype = "audio/mpeg"

  elif ext == ".wma":
    # use the filename as the title

    basename = os.path.split(fname)[1]
    title = os.path.splitext(basename)[0]
    description = ""
    filetype = "wma"
    mimetype = "audio/x-ms-wma"

  else:
    # don't know what this is

    return None

  size = os.stat(fname).st_size
  link="%s/song?%s" % (common.server_base(config), urllib.urlencode({'name':fname}))

  if image:
    image = "%s/image?%s" % (common.server_base(config), urllib.urlencode({'name':image}))

  print link

  return RSSImageItem(
      title = title,
      link = link,
      enclosure = Enclosure(
        url = link,
        length = size,
        type = mimetype),
      description = description,
      guid = Guid(link, isPermaLink=0),
      pubDate = datetime.datetime.now(),
      image = image,
      filetype = filetype)

def dir2item(dname, config, image):
  link = "%s/feed?%s" % (common.server_base(config), urllib.urlencode({'dir':dname}))
  name = os.path.split(dname)[1]

  if image:
    image = "%s/image?%s" % (common.server_base(config), urllib.urlencode({'name':image}))

  description = "Folder"
  #if image:
  #  description += "<img src=\"%s\" />" % image

  return RSSImageItem(
      title = name,
      link = link,
      description = description,
      guid = Guid(link, isPermaLink=0),
      pubDate = datetime.datetime.now(),
      image = image)

def getart(path):
  curr_image = None
  img_re = re.compile(".jpg|.jpeg|.png")

  for base, dirs, files in os.walk(path):
    # don't recurse when searching for artwork
    del dirs[:]

    for file in files:
      ext = os.path.splitext(file)[1]
      if ext and img_re.match(ext):
        curr_image = os.path.join(base,file)
        break

  return curr_image

def getdoc(path, config, recurse=False):
  items = []
  music_re = re.compile("\.mp3|\.wma")

  for base, dirs, files in os.walk(path):
    if not recurse:
      for dir in dirs:
        subdir = os.path.join(base,dir)
        items.append(dir2item(subdir, config, getart(subdir)))

      del dirs[:]

    # first pass to find images
    curr_image = getart(base)

    for file in files:
      if not music_re.match(os.path.splitext(file)[1].lower()):
        print "rejecting %s" % file
        continue
      
      item = file2item(os.path.join(base,file), config, curr_image)
      if item:
        items.append(item)

  doc = RSS2(
      title="A Personal Music Feed",
      link="%s/feed?dir=%s" % (common.server_base(config), path),
      description="My music.",
      lastBuildDate=datetime.datetime.now(),
      items = items )

  return doc

def doc2m3u(doc):
  "convert an rss feed document into an m3u playlist"

  lines = []
  for item in doc.items:
    lines.append(item.link)
  return "\n".join(lines)

def get_entropy(entries):
  "return an xml document full of random numbers since roku can't make them itself"
  import xml.dom.minidom as dom
  import random

  impl = dom.getDOMImplementation()
  doc = impl.createDocument(None, "entropy", None)
  top = doc.documentElement

  for ii in range(entries):
    el = dom.Element("entry")
    el.setAttribute("value", str(random.randrange(0,1000000)))
    top.appendChild(el)

  return doc

def range_handler(fname):
  "return all or part of the bytes of a fyle depending on whether we were called with the HTTP_RANGE header set"
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
    collapse_collections = config.get("config", "collapse_collections").lower() == "true"

    web.header("Content-Type", "application/rss+xml")
    feed = web.input(dir = None)
    if feed.dir:
      return getdoc(feed.dir, config, collapse_collections).to_xml()
    else:
      return getdoc(config.get("config", 'music_dir'), config).to_xml()

class M3UHandler:
  def GET(self):
    "retrieve a feed in m3u format"

    config = common.parse_config(config_file)

    web.header("Content-Type", "text/plain")
    feed = web.input(dir = None)
    if feed.dir:
      return doc2m3u(getdoc(feed.dir, config, True))
    else:
      return doc2m3u(getdoc(config.get("config", 'music_dir'), config, True))

class EntropyHandler:
  def GET(self):
    "get an xml document full of random integers"

    return get_entropy(100).toxml()

urls = (
    '/feed', 'RssHandler',
    '/song', 'SongHandler',
    '/m3u', 'M3UHandler',
    '/image', 'ImageHandler',
    '/entropy', 'EntropyHandler')

app = web.application(urls, globals())

if __name__ == "__main__":
  import sys

  config = common.parse_config(config_file)

  sys.argv.append(config.get("config","server_port"))
  app.run()
