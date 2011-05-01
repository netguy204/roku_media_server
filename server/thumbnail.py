#!/usr/bin/env python
# Copyright 2011, Michael Ihde
# Distribute under the terms of the GNU General Public License
# Version 2 or better

# A python module that helps implement the thumbnail management standard
# http://jens.triq.net/thumbnail-spec/index.html

import os
import sys
import hashlib
import random
import binascii
import mimetypes
import re
import tempfile
import StringIO
from PIL import Image
from PIL import PngImagePlugin

try:
    import pyffmpeg
except ImportError:
    pyffmpeg = None

# Per the specification, this is the only place but if you really
# want to change THUMBNAIL_DIRECTORY, go ahead
THUMBNAIL_DIRECTORY = os.path.expanduser("~/.thumbnails")
NORMAL_SIZE = (128, 128)
LARGE_SIZE = (256, 256)

# Add some types that don't appear in the default list on some systems
mimetypes.add_type("video/mp4", ".m4v")

def create_thumbnail(filename, size="normal"):
    # TODO If path is in THUMBNAIL_DIRECTORY, don't create a thumbnail

    mimetype = mimetypes.guess_type(filename)[0]

    uri = "file://%s" % os.path.normpath(os.path.abspath(filename))
    m = hashlib.md5()
    m.update(uri)
    hashedname = binascii.hexlify(m.digest())
    if size == "normal":
      res = NORMAL_SIZE
    elif size == "large":
      res = LARGE_SIZE
    else:
        raise ValueError, "Invalid Size"

    outfile = os.path.join(THUMBNAIL_DIRECTORY, size, hashedname + ".png")

    # Determine if we really need to recreate a thumbnail
    if os.path.exists(outfile):
        stat = os.stat(filename)
        im = Image.open(outfile)
        try:
            thmb_mtime = int(im.info["Thumb::MTime"])
        except KeyError:
            pass
        except ValueError:
            pass
        else:
            if (int(stat.st_mtime) == thmb_mtime):
                return outfile


    data = None
    if re.match("video/\.*", mimetype):
        data = create_video_thumbnail(filename)

    if data == None:
        return
    # The temporary file should be placed into the same directory as the final
    # thumbnail, because then you are sure that they lay on the same
    # filesystem. This guarantees a fast renaming of the temporary file.
    tmp_output = None
    try:
        if data != None:
	    tmp_fd, tmp_path = tempfile.mkstemp(prefix=hashedname, suffix="-tmp.png" , dir=THUMBNAIL_DIRECTORY)
	    tmp_output = os.fdopen(tmp_fd, "w")
            tmp_output.write(data)
    finally:
        if tmp_output != None:
	    tmp_output.close()

    stat = os.stat(filename)

    info = {"Thumb::URI": uri,
            "Thumb::MTime": int(stat.st_mtime),
            "Thumb::Size": stat.st_size,
            "Thumb::Mimetype": mimetype}
 
    if not os.path.exists(tmp_path):
        print "Failure to create thumbnail"
        return None

    generate_png_thumb(tmp_path, res, info=info)

    if os.path.exists(tmp_path):
        os.rename(tmp_path, outfile)

    return outfile

def create_video_thumbnail(filename):
    if pyffmpeg == None:
        return None
    reader = pyffmpeg.FFMpegReader(False)
    reader.open(filename, pyffmpeg.TS_VIDEO_PIL)
    vt=reader.get_tracks()[0]
    # Pick something near the middle, the very start and very ends aren't
    # usually very interesting
    s = int(vt.duration() * 0.25)
    f = int(vt.duration() * 0.75)
    i = random.randint(s, f)
    vt.seek_to_pts(i)
    image=vt.get_current_frame()[2]
    output = StringIO.StringIO()
    image.save(output, "PNG")
    return output.getvalue()

def generate_png_thumb(filename, res, info={}):
    """                                                                                                                                      
    Uses code from public domain, Nick Galbreath
    http://blog.modp.com/2007/08/python-pil-and-png-metadata-take-2.html
    """
    print filename
    im = Image.open(filename)
    im.thumbnail(res)

    # these can be automatically added to Image.info dict                                                                              
    # they are not user-added metadata
    reserved = ('interlace', 'gamma', 'dpi', 'transparency', 'aspect')

    meta = PngImagePlugin.PngInfo()
    for k,v in info.items():
        meta.add_text(k, str(v), 0)

    # 8-bit, non-interlaced, PNG with full alpha transparency
    im.save(filename, "PNG", pnginfo=meta)
   
if __name__ == "__main__":
    for f in sys.argv[1:]:
        outfile = create_thumbnail(os.path.abspath(f))
        print "Created", outfile
