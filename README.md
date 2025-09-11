
The Source Code for the file is available inside the SourceCodeWithoutCache file, do note that the bkups are files that are not used in the "main" version, but they were at some point scripts that produced the same problem. (Although I may have edited them a bit, as I was experimenting, it has been a few days.)


To recreate the local cache I stored it into a 7zip (which was too big) so I then created a program to split it up and another to rejoin it. To make a valid 7zip file compile rejoiner.zig.
Then run the command :
```./rejoiner FabledCacheError_reformed.7z FabledCacheError__split_0.7z FabledCacheError__split_1.7z```

This will "rejoin" them into a single file that can then be unzipped. I apologize for the jankiness of this however I do not know another way (without trying to upload every subfolder inside .zig-cache directly. Also, I tried that first.)

I may try to upload the global cache as well; which will be even more massive as I did not know it existed before this problem occoured, and so I haven't cleaned it out.
