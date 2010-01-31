The simplevideoplayer example is the barebones 
application that plays a video. It has hardcoded 
content parameters that allow for quick modification
to test any of your own content for playablility.

If you want to quickly test your own content: open
the source/appMain.brs file; in the function
displayVideo(), change the urls, bitrates, qualities, 
and videoclip.StreamFormat to match your content.

With the modifed script pointing to your content, load
the channel and navigate to the "Play" button. When
you hit "Play" you can view your video playing on 
the Roku DVP.

Please see Section 4.5 of the Component Reference Guide
for more information on the Video Screen Object and 
Section 3.3 for more information on setting the 
content meta-data parameters about your video.

**************************************************************
This example uses videos streamed directly from the TED Talks 
website (www.ted.com). Please visit the TED website to see the
full lineup of talks made available by TED. 

Please see the following for license details:
http://creativecommons.org/licenses/by-nc-nd/3.0/




