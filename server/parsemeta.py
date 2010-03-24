import StringIO
import urlparse
import sys
import re
import httplib

class StreamMeta:
  def __init__(self, str):
    # looks like:
    # StreamTitle='Live - Turn My Head';StreamUrl='http://www.radioparadise.com/graphics/covers/m/B000003BRW.jpg';
    
    data = {}
    lines = str.split(';')
    item_re = re.compile("^([^=]*)='?([^']*)'?$")

    for ln in lines:
      m = item_re.match(ln)
      if m:
        data[m.group(1)] = m.group(2)

    self.data = data

  def song(self):
    return self.data['StreamTitle']

  def img_url(self):
    return self.data['StreamUrl']
    
  def __str__(self):
    return "song: '%s' img: %s" % (self.song(), self.img_url())

class Stream:
  def __init__(self, resp):
    self.resp = resp

    # parse out the initial header
    buffer = resp.read(1024 * 10)
    sio = StringIO.StringIO(buffer)

    self.hdr = {}
    relayhdrs = []
    for ln in sio:
      ln = ln.rstrip()
      if ln == "": break

      name, mid, value = ln.partition(":")
      if mid:
        self.hdr[name.lower()] = value.lstrip().rstrip()
        if name.lower() != 'icy-metaint':
          relayhdrs.append(ln)
      else:
        print >>sys.stderr, "missed mid character, got", ln
    
    try:
      self.meta_interval = int(self.hdr['icy-metaint'])
    except:
      # assume no meta
      self.meta_interval = -1

    relayhdrs.extend(("",""))
    self.sent_since_meta = 0

    # everything else should be data. repack the headers
    # we'll be relaying to the client
    self.data = "\r\n".join(relayhdrs) + sio.read()
    self.last_meta = None
    self.has_data = True

  def _extend_buffer(self, data, req, f, min_to_read = 1024):
    "use the f to extend the length of data to at-least req if necessary"

    if len(data) < req:
      new_data = f.read(max(req-len(data), min_to_read))
      if new_data == "":
        self.has_data = False
      return data + new_data
    else:
      return data

  def stream(self, cs = 1024):
    while self.has_data:
      # does the requested chunk span metadata?
      next_meta = self.meta_interval - self.sent_since_meta
      if next_meta < cs and self.meta_interval != -1:
        # make sure we have the metadata
        self.data = self._extend_buffer(self.data, next_meta+1, self.resp)

        # how big is the chunk?
        msz = ord(self.data[next_meta]) * 16

        # how much do we need to have for the meta and what the user wanted?
        fullsz = cs + 1 + msz

        # ensure we have it
        self.data = self._extend_buffer(self.data, fullsz, self.resp)

        # splice out the meta
        meta = self.data[next_meta+1:msz]
        if len(meta) > 0:
          self.last_meta = StreamMeta(meta)
        
        before = self.data[0:next_meta]
        after = self.data[next_meta+1+msz:]

        self.data = before + after

        # how far past the meta did the user want?
        self.sent_since_meta = cs - next_meta
      else:
        self.sent_since_meta += cs

      # make sure the data is available
      self.data = self._extend_buffer(self.data, cs, self.resp)

      # give the user what they wanted
      udata = self.data[0:cs]
      self.data = self.data[cs:]
      yield udata, self.last_meta

def getstream(url):
  purl = urlparse.urlparse(url)
  conn = httplib.HTTPConnection(purl.netloc)
  conn.request("GET", purl.path, None, {'Icy-MetaData' : '1' })
  resp = conn.getresponse()
  return resp


if __name__ == "__main__":
  f = open("output_w_metadata.mp3")
  of = open("out.mp3", "wb")
  stream = Stream(f)
  print str(stream.hdr)

  for data, meta in stream.stream(1024):
    if meta:
      print "found metadata: ", meta
    of.write(data)
    if len(data) != 1024:
      print "weird... got %d bytes" % len(data)
