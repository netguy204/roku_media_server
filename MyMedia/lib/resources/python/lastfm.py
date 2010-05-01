#!/usr/bin/env/python

import httplib
import urllib
import urlparse
import re
from BeautifulSoup import *

def fetch_art(artist, album):
  url = "http://www.last.fm/search?%s" % urllib.urlencode({"q" : artist + " " + album})

  print "url: %s" % url
  p = urlparse.urlparse(url)

  resp = None

  try:
    resp = urllib.urlopen(url)
    
  except e:
    print str(e)
    return None

  soup = None
  try:
    # remove a troublesome line
    lines = []
    doc_re = re.compile("^document\.write")
    for line in resp.readlines():
      if not doc_re.match(line):
        lines.append(line)
    data = "\n".join(lines)

    f = open("data.html", "w")
    f.write(data + "\nDONE")
    f.close()
    soup = MinimalSoup(data)
  except Exception, e:
    print str(e)
    print "horrible soup!"
    return None

  top_tag = soup.find("div", "topResult")
  print str(top_tag)
  if top_tag:
    img_tag = soup.find("div", "topResult").find("img")
  else:
    print "didn't find topResult"

  print str(img_tag)
  return img_tag

if __name__ == "__main__":
  fetch_art("Jars of Clay", "Good Monsters")
