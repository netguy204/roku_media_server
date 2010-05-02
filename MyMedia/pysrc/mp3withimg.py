#!/usr/bin/env python

import os
import sys
from common import *

if len(sys.argv) != 2:
  sys.exit(1)

base = sys.argv[1]
num = 0
print "searching %s" % base
for root, dirs, files in os.walk(base):
  for file in files:
    fp = os.path.join(root, file)
    p,ext = os.path.splitext(fp)
    if ext.lower() == ".mp3":
      data, type = getimg(fp)
      if data:
        print("%s: type = %s" % (fp,type))

        f = open(fp + "." + type, "wb")
        f.write(data)
        f.close()
        sys.exit(1)


