#!/usr/bin/env python
# Copyright 2010, Brian Taylor
# Distribute under the terms of the GNU General Public License
# Version 2 or better

config_file = "config.ini"

import os
import sys
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
ensure("server_ip", "SERVER IP ADDRESS")
ensure("server_port", "8001")
ensure("collapse_collections", "False")
ensure("music_dir", "C:\Music")
ensure("python_path", "C:\Python26\python.exe")

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

  for base, dirs, files in os.walk(client_path):
    for file in files:
      # exclude the makefile
      if file == 'Makefile':
        pass

      fullpath = os.path.join(base, file)

      fname = fullpath
      tf = tempfile.NamedTemporaryFile(mode="w")

      if os.path.splitext(fullpath)[1] == ".brs":
        print "rewriting %s" % fullpath
        # rewrite doing the necessary substitutions
        f = open(fullpath)
        for ln in f:
          url = server_base(config)
          nln = re.sub('SERVER_NAME', url, ln)
          tf.write(nln)

        tf.flush()
        fname = tf.name

      relpath = relpath26(fullpath, client_path)
      zip.write(fname, arcname=relpath)
      print "added %s to zip as %s" % (fullpath, relpath)

  zip.close()

# build the user interface
from Tkinter import *

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

  def _make_entry(self, parent, name, value):
    if not hasattr(self, 'row_num'):
      self.row_num = 0
    if not hasattr(self, 'configvars'):
      self.configvars = {}

    w = Label(parent, text=name)
    w.grid(row=self.row_num, sticky=W)

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
    terminate(self.server)
    os.waitpid(self.server.pid, 0)
    self.root.destroy()

root = Tk()
panel = ConfigPanel(root)
root.mainloop()

print "terminated"

