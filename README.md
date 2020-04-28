# LargeImages

The app shows images from its Documents directory available to upload from Finder.

Issues:
1. Couldn't find a notification about finishing data writting to a file, hence the app tries to read incomplete files, what utilizes a lot of CPU.
2. There is no semaphore yet, to limit amount of parallel image processing tasks.
3. There is no list of invalid image files, so the app will try to load them infinitely.
