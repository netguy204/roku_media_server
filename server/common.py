import os
import sys
import ConfigParser
import httplib, mimetypes, urllib
import logging
import types
import socket

import imghdr
from eyeD3 import *

def get_version():
  return 2

def server_base(config):
  return "http://%s:%s" % (config.get("config", "server_ip"), config.get("config", "server_port"))

def parse_config(cfile):
  c = ConfigParser.ConfigParser({})
  c.read(cfile)

  return c

# handy writer that we'll use occasionally
def write_config(config_file, config):
  f = open(config_file, "w")
  config.write(f)
  f.close()

def ensure_configuration(config):
  # ensure that everything we expect is at least get'able
  def ensure(varname, default):
    if not config.has_option("config", varname):
      config.set("config", varname, default)

  ensure("roku_ip", "ROKU IP ADDRESS")
  ensure("server_ip", socket.gethostbyname(socket.gethostname()))
  ensure("server_port", "8001")
  ensure("collapse_collections", "False")
  ensure("max_folders_before_split", "10")
  ensure("theme", "default")

  # make a reasonable guess at where the user keeps their music
  default_music_path = "Music"
  default_video_path = "Video"
  home = os.path.expanduser("~")

  if sys.platform == "win32":
    default_music_path = os.path.join(home, "My Documents", "My Music")
    default_video_path = os.path.join(home, "My Documents", "My Videos")
    default_photo_path = os.path.join(home, "My Documents", "My Pictures")
  elif sys.platform == "darwin":
    default_music_path = os.path.join(home, "Music", "iTunes", "iTunes Music")
    default_video_path = os.path.join(home, "Movies")
    default_photo_path = os.path.join(home, "Pictures", "iPhoto Library")
  elif sys.platform == "linux2":
    default_music_path = os.path.join(home, "Music")
    default_video_path = os.path.join(home, "Videos")
    default_photo_path = os.path.join(home, "Pictures")
  else:
    # This is to handle the freebsd case (and possibly
    # others). Suggestions on good defaults are always welcome.
    default_music_path = home
    default_video_path = home
    default_photo_path = home

  ensure("music_dir", default_music_path)
  ensure("video_dir", default_video_path)
  ensure("photo_dir", default_photo_path)

  ensure("python_path", sys.executable)

# 3rd party stuff i grabbed
# os.path.relpath backported from python2.6
# curtesy of ryles
# http://mail.python.org/pipermail/python-list/2009-August/1215220.html
def relpath26(path, start=os.curdir):
    """Return a relative version of a path"""

    if not path:
        raise ValueError("no path specified")
    start_list = os.path.abspath(start).split(os.path.sep)
    path_list = os.path.abspath(path).split(os.path.sep)
    if start_list[0].lower() != path_list[0].lower():
        unc_path, rest = splitunc(path)
        unc_start, rest = splitunc(start)
        if bool(unc_path) ^ bool(unc_start):
            raise ValueError("Cannot mix UNC and non-UNC paths (%s and %s)" % (path, start))
        else:
            raise ValueError("path is on drive %s, start on drive %s" % (path_list[0], start_list[0]))
    # Work out how much of the filepath is shared by start and path.
    for i in range(min(len(start_list), len(path_list))):
        if start_list[i].lower() != path_list[i].lower():
            break
    else:
        i += 1

    rel_list = [os.path.pardir] * (len(start_list)-i) + path_list[i:]
    if not rel_list:
        return os.path.curdir
    return os.path.join(*rel_list)

# cross platform python2.5 terminator found on stackoverflow
def terminate(process):
    """
    Kills a process, useful on 2.5 where subprocess.Popens don't have a
    terminate method.


    Used here because we're stuck on 2.5 and don't have Popen.terminate
    goodness.
    """

    def terminate_win(process):
        import win32process
        return win32process.TerminateProcess(process._handle, -1)

    def terminate_nix(process):
        import os
        import signal
        return os.kill(process.pid, signal.SIGTERM)

    terminate_default = terminate_nix

    handlers = {
        "win32": terminate_win,
        "linux2": terminate_nix
    }

    return handlers.get(sys.platform, terminate_default)(process)

# from code.activestate.com
# Recipe #146306
def post_multipart(host, selector, fields, files):
    """
    Post fields and files to an http host as multipart/form-data.
    fields is a sequence of (name, value) elements for regular form fields.
    files is a sequence of (name, filename, value) elements for data to be uploaded as files
    Return the server's response page.
    """
    content_type, body = encode_multipart_formdata(fields, files)
    h = httplib.HTTP(host)
    h.putrequest('POST', selector)
    h.putheader('content-type', content_type)
    h.putheader('content-length', str(len(body)))
    h.endheaders()
    print content_type
    h.send(body)
    errcode, errmsg, headers = h.getreply()
    return h.file.read()

def http_post(host, url, params):
  params = urllib.urlencode(params)
  headers = {'Content-Type': 'application/x-www-form-urlencoded',
             'Accept': 'text/plain'}
  conn = httplib.HTTPConnection(host)
  conn.request("POST", url, params, headers)
  response = conn.getresponse()
  if not response.status in (200, 302):
    raise Exception("%s %s" % (response.status, response.reason))
  data = response.read()
  conn.close()
  return data

def encode_multipart_formdata(fields, files):
    """
    fields is a sequence of (name, value) elements for regular form fields.
    files is a sequence of (name, filename, value) elements for data to be uploaded as files
    Return (content_type, body) ready for httplib.HTTP instance
    """
    BOUNDARY = '----------ThIs_Is_tHe_bouNdaRY_$'
    CRLF = '\r\n'
    L = []
    for (key, value) in fields:
        L.append('--' + BOUNDARY)
        L.append('Content-Disposition: form-data; name="%s"' % key)
        L.append('')
        L.append(value)
    for (key, filename, value) in files:
        L.append('--' + BOUNDARY)
        L.append('Content-Disposition: form-data; name="%s"; filename="%s"' % (key, filename))
        L.append('Content-Type: %s' % get_content_type(filename))
        L.append('')
        L.append(value)
    L.append('--' + BOUNDARY + '--')
    L.append('')
    body = CRLF.join(L)
    content_type = 'multipart/form-data; boundary=%s' % BOUNDARY
    return content_type, body

def get_content_type(filename):
    return mimetypes.guess_type(filename)[0] or 'application/octet-stream'


# from recipe 52201
# code.activestate.com
class Memoize:
    """Memoize(fn) - an instance which acts like fn but memoizes its arguments
       Will only work on functions with non-mutable arguments
    """
    def __init__(self, fn):
        self.fn = fn
        self.memo = {}
    def __call__(self, *args):
        if not self.memo.has_key(args):
            self.memo[args] = self.fn(*args)
        return self.memo[args]

def ext2mime(ext2):
  "get the mimetype for an extension"

  ext = ext2[-4:].lower()
  if ext == "m3u8":
    return "application/vnd.apple.mpegurl"

  ext = ext2[-3:].lower()
  if ext == "mp3":
    return "audio/mpeg"
  elif ext == "m3u":
    return "audio/x-mpegurl"
  elif ext in ("m4v", "mp4", "mov"):
    return "video/mp4"
  elif ext in ("mkv"):
    return "video/x-matroska"
  elif ext == "wma":
    return "audio/x-ms-wma"
  elif ext in ("jpg", "peg"):
    return "image/jpeg"
  elif ext == "png":
    return "image/png"
  elif ext == "gif":
    return "image/gif"
  elif ext == "wmv":
    return "video/x-ms-wmv"
  elif ext == "srt":
    return "text/plain"
  elif ext == "bif":
    return "application/binary"

  ext = ext2[-2:].lower()
  if ext == "ts":
    return "video/MP2T"
  else:
    return None

def to_unicode(obj, encoding='utf-8'):
  "convert to unicode if not already and it's possible to do so"

  try:
    if isinstance(obj, basestring):
      if not isinstance(obj, unicode):
        obj = unicode(obj, encoding)
  except:
    logging.debug("failed to convert some string")
  finally:
    return obj

def to_utf8(obj):
  "convert back to utf-8 if we're in unicode"

  if isinstance(obj, unicode):
    obj = obj.encode('utf-8')
  return obj

def is_letter(c):
  if c >= 'a' and c <= 'z':
    return True
  return False

def is_number(c):
  if c >= '0' and c <= '9':
    return True
  return False

def first_letter(str):
  return str[0].lower()

def music_dir(config):
  return config.get("config", "music_dir")

def video_dir(config):
  "this is an optional variable so we're more careful about retrieving it"
  if config.has_option("config", "video_dir"):
    path = config.get("config", "video_dir")
    if os.path.exists(path):
      return path
    else:
      logging.warning("Video directory %s was configured but does not exist" % path)
  return None

def photo_dir(config):
  "this is an optional variable so we're more careful about retrieving it"
  if config.has_option("config", "photo_dir"):
    path = config.get("config", "photo_dir")
    if os.path.exists(path):
      return path
    else:
      logging.warning("Photo directory %s was configured but does not exist" % path)
  return None

def client_dir(config):
  "path to the client code"
  return os.path.join(os.path.pardir, "client")

def is_video(path):
  return ext2mime(path) in ("video/mp4", "video/x-ms-wmv", "application/vnd.apple.mpegurl", "video/x-matroska")

def is_photo(path):
  return ext2mime(path) in ("image/jpeg", "image/png", "image/gif")

def is_music(path):
  return ext2mime(path) in ("audio/mpeg", "audio/x-ms-wma", "audio/x-mpegurl")

def file2key(path):
  if is_video(path):
    return "video"
  elif is_photo(path):
    return "photo"
  elif is_music(path):
    return "music"
  else:
    return None

def key_to_path(config, key, base=None):
  if key == "music":
    base_dir = music_dir(config)
  elif key == "video":
    base_dir = video_dir(config)
  elif key == "client":
    base_dir = client_dir(config)
  elif key == "photo":
    base_dir = photo_dir(config)
  else:
    return None

  if not base:
    return base_dir
  else:
    return os.path.join(base_dir, base)

def getimg(file):
  try:
    tag = Tag()
    tag.link(file)
    imgs = tag.getImages()
    valid_tags = (
        ImageFrame.ICON,
        ImageFrame.FRONT_COVER,
        ImageFrame.BACK_COVER,
        ImageFrame.OTHER_ICON)

    fimgs = []
    min_img = (None, None)
    for imgtg in imgs:
      if imgtg.imageData and (imgtg.pictureType in valid_tags):
        fimgs.append(imgtg)

        if (not min_img[0]) or min_img[1] > len(imgtg.imageData):
          min_img = (imgtg, len(imgtg.imageData))

    if min_img[0]:
      r = imghdr.what(None, h=min_img[0].imageData)
      return min_img[0].imageData, r
    else:
      return None, None
  except Exception, e:
    logging.debug("Error while looking for images in %s: %s" % (file, str(e)))
    return None, None

# from the roku component reference
THB_SD_DIM = (223,200)
THB_HD_DIM = (300,300)

FULL_SD_DIM = (720,480)
FULL_HD_DIM = (1280,720)

THB_DIM = THB_SD_DIM
FULL_DIM = FULL_SD_DIM

def scaleimg(data, type, res=THB_DIM):
  try:
    import Image
    import StringIO

    logging.debug("Scaling the image to %s", str(res))
    file = StringIO.StringIO(data)
    im = Image.open(file)
    im.thumbnail(res)

    out = StringIO.StringIO()
    im.save(out, type)

    out.seek(0)
    data = out.read()
    return data, type
  except:
    # need to figure out what format the data was in
    # since we won't be converting it to what the caller
    # wanted
    logging.debug("Passing on image unmodified")
    r = imghdr.what(None, h=data)
    return data, r

def tuple2str(tup):
  return ",".join(map(str,tup))

def str2tuple(str):
  return tuple(map(int, str.split(",")))

def stringify_num(num):
  if type(num) in (types.IntType, types.LongType, types.FloatType):
    return str(num)
  return num
