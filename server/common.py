import os
import sys
import ConfigParser
import httplib, mimetypes

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

def ext2mime(ext):
  "get the mimetype for an extension"
  ext = ext[-3:].lower()
  if ext == "mp3":
    return "audio/mpeg"
  elif ext in ("m4v", "mp4"):
    return "video/mp4"
  elif ext == "wma":
    return "audio/x-ms-wma"
  elif ext == "jpg" or ext == "peg":
    return "image/jpeg"
  elif ext == "png":
    return "image/png"
  else:
    return None

def to_unicode(obj, encoding='utf-8'):
  "convert to unicode if not already and it's possible to do so"

  if isinstance(obj, basestring):
    if not isinstance(obj, unicode):
      obj = unicode(obj, encoding)
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
  return None

def is_video(path):
  return ext2mime(path) in ("video/mp4",)

