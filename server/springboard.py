#!/usr/bin/env python
# Copyright 2010, Brian Taylor
# Distribute under the terms of the GNU General Public License
# Version 2 or better

config_file = "config.ini"
installClient = True

import os
import sys
import socket
import ConfigParser
from common import *

# help the user write their first configuration file. if the
# file exists we'll use that as a starting point and fill out all of
# our values from that

config = ConfigParser.ConfigParser({})

if os.path.exists(config_file):
  config.read(config_file)
else:
  config.add_section("config")

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

ensure("music_dir", default_music_path)
ensure("video_dir", default_video_path)
ensure("photo_dir", default_photo_path)

ensure("python_path", sys.executable)

# upload a zip file to the roku
def upload_client_zip(config, the_zip):
  fields = [
      ('mysubmit', 'Install'),
      ('passwd', '') ]

  files = [
      ('archive', the_zip, open(the_zip, 'rb').read())]

  roku_ip = "%s:80" % config.get("config", "roku_ip")

  print "uploading %s to http://%s/plugin_install" % (the_zip, roku_ip)
  post_multipart(roku_ip, "/plugin_install", fields, files)

# build up the client zip file
def build_client_zip(config, client_path, target_zip):
  import zipfile
  import tempfile
  import re

  # make sure the zips directory exists
  zipsdir = os.path.split(target_zip)[0]
  if zipsdir and not os.path.isdir(zipsdir):
    os.mkdir(zipsdir)

  zip = zipfile.ZipFile(target_zip, "w")

  # if a theme was selected, override those images
  theme = config.get("config", "theme")
  image_override = {}
  if theme != "default":
    theme_path = os.path.join(client_path, "themes", theme)
    if os.path.exists(theme_path):
      for base, dirs, files in os.walk(theme_path):
        # no subdirs
        del dirs[:]

        # override the default theme images in the zip file
        for file in files:
          realpath = os.path.join(base, file)
          fakepath = os.path.join("images", file)
          image_override[fakepath] = realpath
    else:
      print "Theme path %s does not exist. Did you remove it while springboard was running?" % theme_path

  for base, dirs, files in os.walk(client_path):
    if "themes" in dirs:
      # don't include the themes directory
      dirs.remove("themes")

    for file in files:
      # exclude the makefile
      if file == 'Makefile':
        pass

      fullpath = os.path.join(base, file)
      relpath = relpath26(fullpath, client_path)

      f = None
      
      if os.path.splitext(fullpath)[1] == ".brs":
        print "rewriting %s" % fullpath
        tf = tempfile.TemporaryFile()

        # rewrite doing the necessary substitutions
        f = open(fullpath)
        for ln in f:
          url = server_base(config)
          nln = re.sub('SERVER_NAME', url, ln)
          tf.write(nln)

        tf.seek(0)
        f = tf
      else:
        # override theme images
        if relpath in image_override:
          fullpath = image_override[relpath]

        f = open(fullpath, 'rb')
        
      zip.writestr(relpath, f.read())
      f.close()
      print "added %s to zip as %s" % (fullpath, relpath)

  zip.close()

class terminalConfigPanel:
  def __init__(self):
    for item in config.items("config"):
      self._make_entry(self, item[0], item[1])

  def _get_themes(self):
    theme_dir = os.path.join(os.path.pardir, "client", "themes")
    return os.listdir(theme_dir)

  def _make_entry(self, parent, name, value):
    if not hasattr(self, 'configvars'):
      self.configvars = {}
    self.configvars[name] = value

  def ensure_config(self):
    print "writing configuration"
    for name, value in self.configvars.items():
      config.set("config", name, value)
    write_config(config_file, config)

  def launch_server(self):
    self.ensure_config()
    self.serverproc = self.spawn_server()

  def install_client(self):
    self.ensure_config()

    client_src = os.path.join(os.path.pardir, "client")
    client_zip = os.path.join(os.path.pardir, "zips", "client.zip")
    build_client_zip(config, client_src, client_zip)

    # upload the zip file
    upload_client_zip(config, client_zip)

  def spawn_server(self):
    import subprocess
    cmd = "%s rss_server.py" % config.get("config", "python_path")
    return subprocess.Popen([cmd], shell=True)

  def stop_server(self):
    print "stopping server"
    if sys.version_info[0:2] >= (2,6):
      self.server.kill()
    else:
      terminate(self.serverproc)
      os.waitpid(self.serverproc.pid, 0)

class ConfigPanel:
  def __init__(self, root):
    self.root = root

    self.frame = Frame(root)
    self.frame.pack(expand=YES)

    w = Label(self.frame, text="Roku-Box Media Server Configuration")
    w.grid(row=0, columnspan=2, sticky=NSEW)
    self.row_num = 1

    for item in config.items("config"):
      self._make_entry(self.frame, item[0], item[1])

    self.launch_server = Button(self.frame, \
        text="Launch Server", command=self.launch_server)
    self.launch_server.grid(row=self.row_num, column=0, sticky=W)

    self.install_client = Button(self.frame, \
        text="Install Client", command=self.install_client)
    self.install_client.grid(row=self.row_num, column=1, sticky=E)

  def _get_themes(self):
    theme_dir = os.path.join(os.path.pardir, "client", "themes")
    return os.listdir(theme_dir)

  def _make_entry(self, parent, name, value):
    if not hasattr(self, 'row_num'):
      self.row_num = 0
    if not hasattr(self, 'configvars'):
      self.configvars = {}

    w = Label(parent, text=name)
    w.grid(row=self.row_num, sticky=W)

    if name=="theme":
      # make the theme combo box instead
      v = StringVar(parent)
      theme = config.get("config", "theme")
      v.set(theme)
      w = apply(OptionMenu, (parent, v, "default") + tuple(self._get_themes()))
      w.grid(row=self.row_num, column=1, sticky=NSEW)
      self.configvars[name] = v

    else:
      w = Entry(parent)
      w.insert(0, value)
      w.grid(row=self.row_num, column=1, sticky=NSEW)
      self.configvars[name] = w

    self.row_num += 1

  def ensure_config(self):
    print "writing configuration"
    for name, w in self.configvars.items():
      config.set("config", name, w.get())
    write_config(config_file, config)

  def launch_server(self):
    self.ensure_config()

    self.root.destroy()
    root = Tk()
    panel = ServerPanel(root, self.spawn_server())
    root.mainloop()

  def install_client(self):
    self.ensure_config()

    client_src = os.path.join(os.path.pardir, "client")
    client_zip = os.path.join(os.path.pardir, "zips", "client.zip")
    build_client_zip(config, client_src, client_zip)

    # upload the zip file
    upload_client_zip(config, client_zip)

  def spawn_server(self):
    import subprocess
    cmd = "%s rss_server.py" % config.get("config", "python_path")
    return subprocess.Popen([cmd], shell=True)


class ServerPanel:
  def __init__(self, root, server):
    self.root = root
    self.server = server

    self.frame = Frame(root)
    self.frame.pack(expand=YES)

    w = Button(self.frame, text="Stop Server", command=self.stop_server)
    w.pack()

  def stop_server(self):
    print "stopping server"
    if sys.version_info[0:2] >= (2,6):
      self.server.kill()
    else:
      terminate(self.server)
      os.waitpid(self.server.pid, 0)
    self.root.destroy()
# build the user interface
try:
	from Tkinter import *
	root = Tk()
except:
	import signal
	#no Tkinter compiled in, command line only
	commandLineOnly = True
	tcp = terminalConfigPanel()
	if installClient:
		tcp.install_client()
	tcp.launch_server()

	def handler(signum, frame):
		print 'Signal handler called with signal', signum
		tcp.stop_server()
		sys.exit()

	signal.signal(signal.SIGTERM, handler)
	while True:
		time.sleep(1000)
else:
	panel = ConfigPanel(root)
	root.mainloop()


print "Springboard Terminating"

