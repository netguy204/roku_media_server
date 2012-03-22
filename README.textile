h1. My Media

h2. Roku DVP Personal Media Server and Channel

A simple media server and a channel designed for the Roku set-top box.

h1(#install). INSTALLATION

# "Add the private channel to your Roku":https://owner.roku.com/Account/ChannelCode/?code=mymedia

# Start the channel and then visit "the MyMedia registration page":http://rokumm.appspot.com/ to enter the registration code you were given.

# Continue by downloading, installing, starting, and configuring the MyMedia server as detailed by the "installation guide":http://rokumm.appspot.com/walkthrough

# Enjoy!

h2. License

The server code in this package is to be distributed under the terms of the GPL. The client code is also GPL but with a special attribution exception for the Roku business entity (per their SDK license agreement.)

Some third party code is also included in the web, simplejson, and eyeD3 folders. Each of these are distributed under their author's original license (look in their source to see what they are.)

The folder icon is distributed under the creative commons. All other channel theming artwork is Copyright 2010 _umbighouse_. Channel artwork is free for non-commercial use. Contact the original author if you would like to use the art under different terms.

h2. Security Warning

The way the server works allows external devices (like your Roku) to access files in specific directories on your computer without authenticating.  Definitely don't run this unless your local network is somehow isolated from the internet at large -- ie, you're behind a router.  

In other words: If your IP address isn't something like 192. ? . ? . ? or 10 . ? . ? . ? -- you're running the risk of exposing data on your computer to people who don't have your consent.

Bottom line: I think I've done a reasonable job of making this secure for isolated home network use but I make no promises and imply no warranty.

h2. Disclaimer

I don't think it will happen but following these instructions could break your computer or your Roku. Don't hold me responsible if they do. If this breaks something for you, I'm sorry, and if you ask nice I may try to help you. No promises, no warranty, good luck. (No one, to my knowledge, has damaged their computer or Roku by using this software so far.)

h1. Troubleshooting

* Make sure you can get to your server from your server. Point a browser at "http://localhost:8001/feed":http://localhost:8001/feed . If you changed the port number in your configuration then adjust the link appropriately. If this doesn't work then the server probably isn't running. Did you start it? Windows users can press alt+ctrl+delete and make sure python is under the process tab.
* Make sure you can get to your server from another computer. Change localhost in the link above to the ip address of your server. If this doesn't work then you almost definitely have a firewall in the way.
* Make sure the new channel appears on your home screen. If it doesn't you need to add the private channel (link at the top of this document) and open and close the channel store to make it appear.

h2. For more help

There's an active and growing community of users eager to help you. Drop by the forum "http://forums.rokulabs.com/viewtopic.php?p=330401":http://forums.rokulabs.com/viewtopic.php?p=159473 or shoot me an email and hopefully we can work through whatever ails you.

h1. Epilogue

This is a work in progress. I welcome feedback from your experiences. Let's make this readme file much better.

*With contributions from*

(alphabetized)

_all testers_ - Thank you for installing this code and providing feedback and suggestions. You make building this fun!

_el.wubo_

_hammerpocket_ - mac PIL install guide

_hoffmcs_ - server side improvements

_renojim_ - massive contributions to the functionality of the channel

_onecaribou_ - testing. contributing the DNS323 NAS installation guide.

_umbighouse_ - helping debug the windows client and providing excellent beta testing feedback. Windows installation tips and scripts. Channel icon and theming.

_witmar_ (tdurrant420@gmail.com) - high contrast theme

Initial development by:
Brian Taylor (el.wubo@gmail.com)
Copyright 2010


-B

