#!/usr/bin/env python
# Copyright 2010, Brian Taylor
# Distribute under the terms of the GNU General Public License
# Version 2 or better


# this file contains the configurable variables
config_file = "config.ini"
log_file = "my_media_log.txt"
rendezvous_server = "rokumm.appspot.com"

# main webapp
import os
import re
import web
import urllib
import ConfigParser
import math
import logging
import pickle
import simplejson
import socket

from eyeD3 import *
from common import *
from PyRSS2Gen import *
from time import time

from django.template import Template, Context
from django.conf import settings

def with_template(name, data = {}):
  "render a django template based in the working directory"

  tmpl = os.path.join(os.path.dirname(__file__), name)
  f = open(tmpl)
  contents = f.read()
  f.close()

  t = Template(contents)
  return t.render(Context(data))

logging.basicConfig(filename=log_file, level=logging.DEBUG)
MY_STREAMS = "my_streams.pickle"
DEFAULT_STREAMS = "default_streams.pickle"

class PublishMixin:
  def publish_extensions(self, handler):
    for name in self.TAGS:
      val = getattr(self, name)
      if val:
        val = stringify_num(val)
        handler.startElement(name, {})
        handler.characters(val)
        handler.endElement(name)

  def set_variables(self, kwargs):
    for name in self.TAGS:
      if name in kwargs:
        setattr(self, name, kwargs[name])
        del kwargs[name]
      else:
        setattr(self, name, None)

class RSSImageItem(PublishMixin, RSSItem):
  "extending rss items to support our extended tags"
  def __init__(self, **kwargs):
    self.TAGS = ('image', 'filetype', 'tracknum', 'ContentType', 'StreamFormat', 'playtime', 'album', 'bitrate', 'release_date')
    self.set_variables(kwargs)
    RSSItem.__init__(self, **kwargs)

class RSSDoc(PublishMixin, RSS2):
  "extending rss document to provide theme tags, etc"
  def __init__(self, **kwargs):
    self.TAGS = ('theme',)
    self.set_variables(kwargs)
    RSS2.__init__(self, **kwargs)

def base_url(config, hdlr, params):
  return "%s/%s?%s" % (server_base(config), hdlr, urllib.urlencode(params))

def media_url(config, params):
  return base_url(config, "media", params)

def feed_url(config, params):
  return base_url(config, "feed", params)

def main_menu_feed(config):
  "create the root feed for the main menu"

  def get_themed_image(name):
    client = client_dir(config)

    theme = config.get("config", "theme")
    if theme != "default":
      theme_img = os.path.join(client, "themes", theme, name)
      if os.path.exists(theme_img):
        return "themes/%s/%s" % (theme, name)
      else:
        return "images/%s" % name
    else:
      return "images/%s" % name

  items = []
  items.append({
      'title': 'My Music',
      'type': 'Folder',
      'image': media_url(config, {'name': get_themed_image('music_square.jpg'),
                                  'key': 'client',
                                  'res': tuple2str(THB_DIM)}),
      'link': feed_url(config, {'dir': '.', 'key': 'music'})})

  dir = video_dir(config)
  if dir and os.path.exists(dir):
    items.append({
        'title': 'My Videos',
        'type': 'Folder',
        'image': media_url(config, {'name': get_themed_image('videos_square.jpg'),
                                    'key': 'client',
                                    'res': tuple2str(THB_DIM)}),
        'link': feed_url(config, {'dir': '.', 'key': 'video'})})

  dir = photo_dir(config)
  if dir and os.path.exists(dir):
    items.append({
        'title': 'My Photos',
        'type': 'Folder',
        'image': media_url(config, {'name': get_themed_image('photos_square.jpg'),
                                    'key': 'client',
                                    'res': tuple2str(THB_DIM)}),
        'link': feed_url(config, {'dir': '.', 'key': 'photo'})})

  return with_template('rss_template.xml', {'items': items})

def call_protected(f, default):
  v = default
  try:
    v = f()
  except:
    logging.debug("failed to call function %s, using default %s", str(f), str(default))
  return v

def file2item(key, fname, base_dir, config, image=None):
  if not os.path.exists(fname):
    logging.warning("WARNING: Tried to create feed item for `%s' which does not exist. This shouldn't happen" % fname)
    return None

  # guess the filetype based on the extension
  ext = os.path.splitext(fname)[1].lower()

  title = "None"
  description = "None"
  album = None
  playtime = None
  bitrate = None

  filetype = None
  mimetype = None
  tracknum = None
  release_date = None

  if ext == ".mp3":
    # use the ID3 tags to fill out the mp3 data

    try:
      mp3 = Mp3AudioFile(fname)
      tag = mp3.getTag()
    except:
      logging.warning("library failed to parse ID3 tags for %s. Skipping." % fname)
      return None

    title = call_protected(tag.getTitle, "Error Reading Title")
    if title == "":
      basename = os.path.split(fname)[1]
      title = os.path.splitext(basename)[0]
    description = call_protected(tag.getArtist, "Error Reading Artist")
    album = call_protected(tag.getAlbum, "Error Reading Album")
    playtime = call_protected(mp3.getPlayTime, "0")
    bitrate = call_protected(mp3.getBitRateString, "Error Reading Bitrate")
    tracknum = call_protected(tag.getTrackNum, ( 0, ))[0]
    release_date = call_protected(tag.getYear, "Error Reading Release Date")

    filetype = "mp3"
    ContentType = "audio"

  elif ext == ".wma":
    # use the filename as the title

    basename = os.path.split(fname)[1]
    title = os.path.splitext(basename)[0]
    description = ""
    filetype = "wma"
    ContentType = "audio"

  elif ext in (".m4v", ".mp4", ".mov"):
    # this is a video file

    basename = os.path.split(fname)[1]
    title = os.path.splitext(basename)[0]
    description = "Video"
    filetype = "mp4"
    ContentType = "movie"

  elif ext == ".wmv":
    # a windows movie file

    basename = os.path.split(fname)[1]
    title = os.path.splitext(basename)[0]
    description = "Video"
    filetype = "wmv"
    ContentType = "movie"

  elif ext in (".jpg", ".jpeg", ".gif", ".png"):

    basename = os.path.split(fname)[1]
    title = os.path.splitext(basename)[0]
    description = "Picture"
    filetype = "image"
    ContentType = "image"

  elif ext == ".m3u":

    basename = os.path.split(fname)[1]
    title = os.path.splitext(basename)[0]
    description = "Playlist"
    filetype = "m3u"
    ContentType = "playlist"

  elif ext == ".m3u8":

    basename = os.path.split(fname)[1]
    title = os.path.splitext(basename)[0]
    description = "HLS Playlist"
    filetype = "hls"
    ContentType = "movie"

  else:
    # don't know what this is

    return None

  size = os.stat(fname).st_size
  path = relpath26(fname, base_dir)
  if ContentType == "playlist":
    link = base_url(config, "m3u", {'name':to_utf8(path), 'key': key})
  else:
    link = media_url(config, {'name':to_utf8(path), 'key': key})

  if image:
    image = relpath26(image, base_dir)
    image = media_url(config, {'name':to_utf8(image), 'key': key, 'res': tuple2str(THB_DIM)})

  logging.debug(link)

  return RSSImageItem(
      title = title,
      link = link,
      enclosure = Enclosure(
        url = link,
        length = size,
        type = ext2mime(ext)),
      description = description,
      guid = Guid(link, isPermaLink=0),
      pubDate = datetime.datetime.now(),
      image = image,
      filetype = filetype,
      tracknum = tracknum,
      ContentType = ContentType,
      StreamFormat = filetype,
      playtime = playtime,
      release_date = release_date,
      album = album,
      bitrate = bitrate)

def dir2item(key, dname, base_dir, config, image, name=None):
  path = relpath26(dname, base_dir)

  link = feed_url(config, {'dir':to_utf8(path), 'key': key})

  if not name:
    name = os.path.split(dname)[1]

  if image:
    image = relpath26(image, base_dir)
    image = media_url(config, {'name':to_utf8(image), 'key': key, 'res': tuple2str(THB_DIM)})

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
  path = to_unicode(path)

  # is path a full path to a video?
  if is_video(path):
    no_ext = os.path.splitext(path)[0]

    # look for a corresponding image
    for test_ext in (".jpg", ".jpeg", ".png"):
      if os.path.exists(no_ext + test_ext):
        return no_ext + test_ext
    return None

  if is_photo(path):
    return path

  img_re = re.compile("\.jpg|\.jpeg|\.png")
  curr_image = None

  if is_music(path):
    ext = os.path.splitext(path)[1].lower()
    if ext == ".mp3":
      # First see if there's an embedded image
      data, type = getimg(path)
      if data:
        curr_image = path + ".image"
        return curr_image
      # No embedded image, check for albumName.jpg
      album = None
      try:
        mp3 = Mp3AudioFile(path)
        tag = mp3.getTag()
      except:
        logging.warning("library failed to parse ID3 tags for %s. Skipping." % path)
        tag = None

      if tag:
        album = call_protected(tag.getAlbum, "Error Reading Album")
        if album:
          base = os.path.split(path)[0]
          fp = os.path.join(base,album)

          # look for a corresponding image
          for test_ext in (".jpg", ".jpeg", ".png"):
            if os.path.exists(fp + test_ext):
              return fp + test_ext

  for base, dirs, files in os.walk(path):
    # don't recurse when searching for artwork
    del dirs[:]

    for file in files:
      fp = os.path.join(base,file)
      ext = os.path.splitext(file)[1].lower()
      if ext and img_re.match(ext):
        curr_image = fp
        break
      elif ext == ".mp3":
        data, type = getimg(os.path.join(base,file))
        if data:
          curr_image = fp + ".image"
          break

  return curr_image

# we could memoize getart as a primitive form of caching since
# the return value if this is unlikely to change

def item_sorter(lhs, rhs):
  "folders first, sort on artist, then track number (prioritize those with), then track name"

  # folders always come before non folders
  if lhs.description == "Folder" and rhs.description != "Folder":
    return -1
  if rhs.description == "Folder" and lhs.description != "Folder":
    return 1

  if lhs.album == rhs.album:
    # if both have a track number, sort on that
    if lhs.tracknum and rhs.tracknum:
      if int(lhs.tracknum) < int(rhs.tracknum):
        return -1
      elif int(lhs.tracknum) > int(rhs.tracknum):
        return 1

  # first sort by artist
  if lhs.description.lower() < rhs.description.lower():
    return -1
  if rhs.description.lower() < lhs.description.lower():
    return 1

  # things with track numbers always come first
  if lhs.tracknum and not rhs.tracknum:
    return -1
  if rhs.tracknum and not lhs.tracknum:
    return 1

  # if both have a track number, sort on that
  if lhs.tracknum and rhs.tracknum:
    if int(lhs.tracknum) < int(rhs.tracknum):
      return -1
    elif int(lhs.tracknum) > int(rhs.tracknum):
      return 1

  # if the track numbers are the same or both don't
  # exist then sort by title
  if lhs.title.lower() < rhs.title.lower():
    return -1
  elif rhs.title.lower() < lhs.title.lower():
    return 1
  else:
    return 0 # they must be the same

def partition_by_firstletter(key, subdirs, basedir, minmax, config):
  "based on config, change subdirs into alphabet clumps if there are too many"

  max_dirs = 10
  if config.has_option("config", "max_folders_before_split"):
    max_dirs = int(config.get("config", "max_folders_before_split"))

  # handle the trivial case
  if len(subdirs) <= max_dirs or max_dirs <= 0 or not minmax:
    return subdirs

  # figure out if we're doing a letter or number partition
  minl, maxl = minmax

  if is_letter(minl):
    min_of_class = 'a'
  elif is_number(minl):
    min_of_class = '0'
  else:
    # this must be a special character. give up
    return subdirs

  # presort
  subdirs.sort(key=lambda x: x.title.lower())

  # how many pivots? (round up)
  pivots = int(math.ceil(float(len(subdirs))/max_dirs))
  newsubdirs = []

  def get_letter(item):
    return first_letter(item.title)

  last_index_ord = len(subdirs) - 1
  last_end = 0

  # try to divide the list evenly
  for sublist in range(pivots):
    if last_end == last_index_ord:
      break # we're done

    last_letter = get_letter(subdirs[last_end])
    if last_end == 0:
      last_letter = minl

    next_end = min(last_end + max_dirs, len(subdirs) - 1)

    while get_letter(subdirs[next_end]) == last_letter and next_end != last_index_ord:
      next_end += 1

    first_unique = get_letter(subdirs[next_end])

    while get_letter(subdirs[next_end]) == first_unique and next_end != last_index_ord:
      next_end += 1

    next_letter = chr(max(ord(min_of_class), ord(get_letter(subdirs[next_end]))-1))
    if next_end == last_index_ord:
      next_letter = maxl

    # create the item
    reldir = relpath26(basedir, key_to_path(config, key))
    logging.debug("built %s from %s relative to %s" % (reldir, basedir, key_to_path(config, key)))
    link = "%s/feed?%s" % (server_base(config), urllib.urlencode({'dir':reldir, 'range': last_letter+next_letter, 'key': key}))

    newsubdirs.append(RSSImageItem(
      title = "%s - %s" % (last_letter.upper(), next_letter.upper()),
      link = link,
      description = "Folder",
      guid = Guid(link, isPermaLink=0)))

    last_end = next_end

  if len(newsubdirs) > 1:
    return newsubdirs
  else:
    return subdirs

def getdoc(key, path, base_dir, dirrange, config, recurse=False):
  "get a media feed document for path"

  # make sure we're unicode
  path = to_unicode(path)

  number_subdirs = []
  letter_subdirs = []
  special_subdirs = []

  items = []

  if dirrange:
    minl, maxl = dirrange
    minl = minl.lower()
    maxl = maxl.lower()

  media_re = re.compile("\.m3u|.m3u8|\.mp3|\.wma|\.m4v|\.mp4|\.mov|\.wmv|\.jpg|\.jpeg|\.png|\.gif")

  for base, dirs, files in os.walk(path):
    if not recurse:
      for dir in dirs:

        # skip directories not in our range
        first_chr = first_letter(dir)
        if dirrange and (first_chr < minl or first_chr > maxl):
          continue

        subdir = os.path.join(base,dir)
        item = dir2item(key, subdir, base_dir, config, getart(subdir))
        if is_number(first_chr):
          number_subdirs.append(item)
        elif is_letter(first_chr):
          letter_subdirs.append(item)
        else:
          special_subdirs.append(item)

      del dirs[:]

    # first pass to find images
    curr_image = getart(base)

    for file in files:
      if not media_re.match(os.path.splitext(file)[1].lower()):
        logging.debug("rejecting %s" % file)
        continue

      fpath = os.path.join(base, file)

      image_icon = getart(fpath) or curr_image

      # filter out items that don't match our current key
      if not file2key(fpath) == key:
        continue

      item = file2item(key, fpath, base_dir, config, image_icon)
      if item:
        items.append(item)

  # include our partitioned folders
  if dirrange:
    # the range must either have only letters or only numbers
    if len(number_subdirs) > 0:
      items.extend(partition_by_firstletter(key, \
          number_subdirs, path, (minl,maxl), config))
    elif len(letter_subdirs) > 0:
      items.extend(partition_by_firstletter(key, \
          letter_subdirs, path, (minl,maxl), config))
  else:
    items.extend(partition_by_firstletter(key, number_subdirs, path, ('0','9'), config))
    items.extend(partition_by_firstletter(key, letter_subdirs, path, ('a','z'), config))

  items.extend(special_subdirs)

  # sort the items
  items.sort(item_sorter)

  if dirrange:
    range = "&range=%s" % (minl + maxl)
  else:
    range = ""

  doc = RSSDoc(
      title="A Personal Music Feed",
      link = feed_url(config, {'key': key, 'dir': relpath26(path, base_dir) + range}),
      description="My Media",
      lastBuildDate=datetime.datetime.now(),
      items = items,
      theme = key)

  return doc

def pl2songs(pl):
  filein = open(pl)
  lines = [ ln.rstrip() for ln in filein if ln[0] != '#' ]
  filein.close()
  return lines

def getpl(name, key, path, config):
  "create a media feed document from an m3u playlist"
  items = []

  lpath = os.path.join(path, name)
  for line in pl2songs(lpath):
    base = os.path.dirname(line)
    file = os.path.basename(line)
    if base == "":
      base = os.path.dirname(lpath)
    fpath = os.path.join(base, file)
    image_icon = getart(fpath)
    item = file2item(key, fpath, path, config, image_icon)
    if item:
      items.append(item)

  doc = RSSDoc(
      title="A Personal Music Feed",
      link = feed_url(config, {'key': key, 'dir': relpath26(path, path) + range}),
      description="My Media",
      lastBuildDate=datetime.datetime.now(),
      items = items,
      theme = key)

  return doc

def pickle2doc(name):
  "convert a pickle file into a document"
  items = []
  config = parse_config(config_file)
  f = open(name, "rb")
  records = pickle.load(f)
  for record in records:
    if record['type'] == "mp3audio":
      sf = "mp3"
      ct = "audio"
      ft = ext2mime(sf)
    elif record['type'] == "wmaaudio":
      sf = "wma"
      ct = "audio"
      ft = ext2mime(sf)
    else:
      # can't handle this yet
      continue

    img = "pkg:/images/livestream_square.jpg"

    items.append(RSSImageItem(
      title=record['title'],
      link=record['url'],
      enclosure = Enclosure(
        url=record['url'],
        type=ft,
        length=None),
      guid=Guid(record['url'], isPermaLink=0),
      pubDate = datetime.datetime.now(),
      filetype=ft,
      image = img,
      tracknum = 0,
      release_date = "",
      ContentType = ct,
      StreamFormat = sf,
      album = "None"))

  doc = RSSDoc(
      title="A Personal Music Feed",
      link="%s/remotes" % (server_base(config)),
      description="My Media",
      lastBuildDate=datetime.datetime.now(),
      items = items,
      theme = "streams")
  return doc

def doc2m3u(doc):
  "convert an rss feed document into an m3u playlist"

  lines = []
  for item in doc.items:
    lines.append(item.link)
  return "\n".join(lines)

def range_handler(fname):
  "return all or part of the bytes of a file depending on whether we were called with the HTTP_RANGE header set"
  logging.debug("serving %s" % fname)
  f = open(fname, "rb")

  bytes = None
  CHUNK_SIZE = 10 * 1024;
  size = os.stat(fname).st_size

  # is this a range request?
  # looks like: 'HTTP_RANGE': 'bytes=41017-'
  if 'HTTP_RANGE' in web.ctx.environ:
    logging.debug("server issued range query: %s" % web.ctx.environ['HTTP_RANGE'])

    # try a start only regex
    regex = re.compile('bytes=(\d+)-$')
    grp = regex.match(web.ctx.environ['HTTP_RANGE'])
    if grp:
      start = int(grp.group(1))
      logging.debug("player issued range request starting at %d" % start)

      f.seek(start)

      # we'll stream it
      web.header("Content-Length","%d" % (size - start))
      web.header("Content-Range","bytes %d-%d/%d" % (start,size-1,size))
      web.header("Accept-Ranges","bytes")
      web.ctx.status = "206 Partial Content"
      bytes = f.read(CHUNK_SIZE)
      while not bytes == "":
        yield bytes
        bytes = f.read(CHUNK_SIZE)

      f.close()

    # try a span regex
    regex = re.compile('bytes=(\d+)-(\d+)$')
    grp = regex.match(web.ctx.environ['HTTP_RANGE'])
    if grp:
      start,end = int(grp.group(1)), int(grp.group(2))
      logging("player issued range request starting at %d and ending at %d" % (start, end))

      web.header("Content-Length","%d" % (end - start + 1))
      web.header("Content-Range","bytes %d-%d/%d" % (start,end,size))
      web.header("Accept-Ranges","bytes")
      web.ctx.status = "206 Partial Content"
      f.seek(start)
      bytes_remaining = end-start+1 # +1 because range is inclusive
      chunk_size = min(bytes_remaining, chunk_size)
      bytes = f.read(chunk_size)

      while not bytes == "":
        yield bytes

        bytes_remaining -= chunk_size
        chunk_size = min(bytes_remaining, chunk_size)
        bytes = f.read(chunk_size)

      f.close()

    # try a tail regex
    regex = re.compile('bytes=-(\d+)$')
    grp = regex.match(web.ctx.environ['HTTP_RANGE'])
    if grp:
      end = int(grp.group(1))
      logging.debug("player issued tail request beginning at %d from end" % end)
      web.header("Content-Length","%d" % (end))
      web.header("Content-Range","bytes %d-%d/%d" % (size-end,size-1,size))
      web.header("Accept-Ranges","bytes")
      web.ctx.status = "206 Partial Content"

      f.seek(-end, os.SEEK_END)
      bytes = f.read()
      yield bytes
      f.close()

  else:
    # write the whole thing
    # we'll stream it
    bytes = f.read(CHUNK_SIZE)
    while not bytes == "":
      yield bytes
      bytes = f.read(CHUNK_SIZE)

    f.close()

class MediaHandler:
  "retrieve a song"

  def GET(self):
    song = web.input(name = None, key = None, res = tuple2str(FULL_DIM))
    if not song.name:
      return

    config = parse_config(config_file)

    # refuse anything that isn't in the media directory
    # IE, refuse anything containing pardir
    fragments = song.name.split(os.sep)
    if os.path.pardir in fragments:
      logging.warning("SECURITY WARNING: Someone was trying to access %s. The MyMedia client shouldn't do this" % song.name)
      return

    name = song.name
    name = key_to_path(config, song.key, name)
    ext = os.path.splitext(os.path.split(name)[1] or "")[1].lower()
    logging.debug("serving request for %s" % name)

    # the .image extension means the image is embedded in an mp3
    if ext == ".image":
      mp3name = os.path.splitext(name)[0]
      logging.debug("retrieving image data from mp3 %s" % mp3name)

      data, type = getimg(mp3name)
      data, type = scaleimg(data, type, str2tuple(song.res))
      web.header("Content-Type", "image/" + type)
      web.header("Content-Length", "%d" % len(data))
      yield data
      return

    # in all other cases if the file doesn't exist, bail
    if not (name and os.path.exists(name)):
      logging.debug("file %s doesn't exist" % name)
      return

    size = os.stat(name).st_size

    # make a guess at mime type
    mimetype = ext2mime(ext)
    if not mimetype:
      logging.debug("couldn't determine mimetype for %s" % name)
      return

    logging.debug("guessing mimetype of %s for %s. filesize is %d" % (mimetype, name, size))

    # if it's an image, give scaling a try
    if is_photo(name):
      f = open(name, "rb")
      data, type = scaleimg(f.read(), "jpeg", str2tuple(song.res))
      f.close()

      web.header("Content-Type", "image/" + type)
      web.header("Content-Length", "%d" % len(data))
      yield data
      return

    # otherwise return the data as is
    web.header("Content-Type", mimetype)
    web.header("Content-Length", "%d" % size)
    for data in range_handler(name):
      yield data
    return

class RssHandler:
  def GET(self):
    "retrieve a specific feed"

    config = parse_config(config_file)
    collapse_collections = config.get("config", "collapse_collections").lower() == "true"

    web.header("Content-Type", "application/rss+xml")
    feed = web.input(dir = None, range=None, key=None)

    if not feed.key in ("music", "video", "photo"):
      return main_menu_feed(config)

    # get the range for partitioning
    range = feed.range
    if range: range = tuple(range)

    base_dir = key_to_path(config, feed.key)

    if feed.dir:
      # the user has navigated to dir
      path = os.path.join(base_dir, feed.dir)
      return getdoc(feed.key, path, base_dir, range, config, collapse_collections).to_xml()
    else:
      # if no dir was given we return the index view for this base_dir
      return getdoc(feed.key, base_dir, base_dir, range, config).to_xml()

class M3UHandler:
  def GET(self):
    "retrieve a feed in m3u format"

    config = parse_config(config_file)
    web.header("Content-Type", "application/rss+xml")
    feed = web.input(dir = None, name=None, key=None)

    base_dir = key_to_path(config, feed.key)
    return getpl(feed.name, feed.key, base_dir, config).to_xml()

class TimestampHandler:
  def GET(self):
    "serve up the unix timestamp"
    web.header("Content-Type", "text/plain")
    ts = "%d" % (time() + 0.5)
    return ts

class IndexHandler:
  def GET(self):
    "serve up the index page"
    web.header("Content-Type", "text/html")

    config = parse_config(config_file)
    if not config.has_option("config", "regId"):
      raise web.seeother('/register')

    regId = config.get("config", "regId")
    return with_template("index.html", { 'code': regId })

class RegisterHandler:
  def GET(self):
    "go through the registration process"
    web.header("Content-Type", "text/html")
    config = parse_config(config_file)
    regId = "not registered"
    if config.has_option("config", "regId"):
      regId = config.get("config", "regId")
    return with_template("register.html", { 'regId': regId })

class RegisterSubmitHandler:
  def POST(self):
    "user submitted registration, send to master server"
    web.header("Content-Type", "text/html")
    config = parse_config(config_file)
    inputs = web.input(regId = None)
    if not inputs.regId:
      raise web.seeother("/register")

    server = "http://%s:%s" % (socket.gethostbyname(socket.gethostname()), config.get("config", "server_port"))
    http_post(rendezvous_server, '/register', { 'code': inputs.regId,
                                                'type': 'server',
                                                'server': server })
    config.set('config', 'regId', inputs.regId)
    write_config(config_file, config)

    return with_template('complete.html', { 'code': inputs.regId,
                                            'server': server })
    
class ReadmeTextileHandler:
  def GET(self):
    "serve up the readme textile"
    web.header("Content-Type", "text/plain")
    return open("../README.textile").read()

class StylesheetHandler:
  def GET(self):
    web.header("Content-Type", "text/rss")
    return open("../hosted-server/stylesheets/main.css").read()

class DynamicPlaylist:
  def GET(self):
    "serve the current dynamic playlist"
    web.header("Content-Type", "text/javascript")

    if os.path.exists(MY_STREAMS):
      f = open(MY_STREAMS, "rb")
    elif os.path.exists(DEFAULT_STREAMS):
      f = open(DEFAULT_STREAMS, "rb")
    else:
      return "[]" # empty list

    return simplejson.dumps(pickle.load(f))

  def POST(self):
    "update the dynamic playlist"
    args = web.input(title = [], type = [], url = [])
    logging.debug("got arguments: %s" % str(args))

    # repack the arguments
    data = []
    for i in range(len(args.title)):
      data.append({
        'title': args.title[i],
        'type': args.type[i],
        'url': args.url[i]})


    f = open(MY_STREAMS, "wb")
    pickle.dump(data, f)
    f.close()

    return "<b>done</b>";

class DynamicPlaylistDoc:
  def GET(self):
    "the user created dynamic playlist in rss form"
    web.header("Content-Type", "application/rss+xml")

    if os.path.exists(MY_STREAMS):
      return pickle2doc(MY_STREAMS).to_xml()
    else:
      return pickle2doc(DEFAULT_STREAMS).to_xml()

configuration_variables = [
  { 'variable': 'music_dir',
    'text': 'Music Folder',
    'description': 'The directory that MyMedia should search for music.'},
  { 'variable': 'video_dir',
    'text': 'Video Folder',
    'description': 'The directory that MyMedia should search for videos.'},
  { 'variable': 'photo_dir',
    'text': 'Photo Folder',
    'description': 'The directory that MyMedia should search for photos.'},
  { 'variable': 'server_ip',
    'text': 'Server IP',
    'description': 'EXPERT: The internal IP address of your MyMedia server.'},
  { 'variable': 'server_port',
    'text': 'Server Port',
    'description': 'EXPERT: The port that your MyMedia server should listen on.'} ]

class ConfigurationHandler:
  def GET(self):
    web.header("Content-Type", "text/html")
    config = parse_config(config_file)
    for var in configuration_variables:
      if config.has_option('config', var['variable']):
        var['value'] = config.get('config', var['variable'])
    return with_template('configuration.html', {'variables': configuration_variables})

  def POST(self):
    web.header("Content-Type", "text/html")
    config = parse_config(config_file)

    argdict = {}
    for var in configuration_variables:
      argdict[var['variable']] = None

    values = web.input(**argdict)
    print values

    for var in configuration_variables:
      if values[var['variable']]:
        config.set('config', var['variable'], values[var['variable']])
    write_config(config_file, config)
    raise web.seeother("/")

urls = (
    '/feed', 'RssHandler',
    '/media', 'MediaHandler',
    '/m3u', 'M3UHandler',
    '/', 'IndexHandler',
    '/readme', 'ReadmeTextileHandler',
    '/dynplay', 'DynamicPlaylist',
    '/remotes', 'DynamicPlaylistDoc',
    '/timestamp','TimestampHandler',
    '/register', 'RegisterHandler',
    '/register_submit', 'RegisterSubmitHandler',
    '/main.css', 'StylesheetHandler',
    '/configure', 'ConfigurationHandler')

app = web.application(urls, globals())

if __name__ == "__main__":
  import sys

  settings.configure()
  
  if os.path.exists(config_file):
	config = parse_config(config_file)
  else:
	config = ConfigParser.ConfigParser({})
	config.add_section("config")
	
  ensure_configuration(config)
  write_config(config_file, config)

  # re-submit ip info
  server = "http://%s:%s" % (socket.gethostbyname(socket.gethostname()), config.get("config", "server_port"))
  regid = None
  if config.has_option("config", "regId"):
    regid = config.get("config", "regId")
  try:
    if regid:
      print "submitting ip information to server as " + regid
      http_post(rendezvous_server, '/register', { 'code': regid,
                                                  'type': 'server',
                                                  'server': server })
    else:
      print "warning: this server has not completed rendezvous"

  except Exception as e:
    print "error contacting %s" % rendezvous_server
    print e

  sys.argv.append(config.get("config","server_port"))
  app.run()
