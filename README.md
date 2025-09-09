To recreate a valid 7zip file compile rejoiner.zig

Then run the command :
```./rejoiner FabledCacheError_reformed.7z FabledCacheError__split_0.7z FabledCacheError__split_1.7z```

This will "rejoin" them into a single file that can then be unzipped. I apologize for the jankiness of this however I do not know another way (without trying to upload every subfolder inside .zig-cache directly. Also, I tried that first.)

I may try to upload the global cache as well; which will be even more massive as I did not know it existed before this problem occoured, and so I haven't cleaned it out.
