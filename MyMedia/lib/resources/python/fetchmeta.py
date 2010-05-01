import sys
import parsemeta

url = "http://66.225.205.8:80/"
#url = "http://scfire-mtc-aa01.stream.aol.com:80/stream/1048"
resp = parsemeta.getstream(url)
print resp.status, resp.reason
print str(resp.getheaders())

stream = parsemeta.Stream(resp)
print str(stream.hdr)

f = open("output_w_metadata4.mp3", "wb")

last_meta = None
for data, meta in stream.stream():
  if meta != last_meta:
    print "Got new meta: ", str(meta)
    last_meta = meta
  f.write(data)

f.close()
