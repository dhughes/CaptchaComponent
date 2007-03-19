Alagad Captcha for ColdFusion ReadMe Notes

http://www.alagad.com/index.cfm/name-captcha/cd-1

==========================================================================
Table of Contents
This read me file contains the following information.

  Installation Instructions
  Registration Instructions
  CD-ROM Contents
  Known Issues

Installation Instructions
====================
Instructions for installing and using the Alagad Captcha can be found in the
documentation folder.

CD-ROM Contents
====================
This CD-ROM contains a trial version of the Alagad Captcha and related 
materials.  The folders on this CD-ROM contain the following items.

ColdFusion MX, MX 6.1 Version
The Alagad Captcha for ColdFusion MX, MX 6.1 or later.

Documentation
Documentation for the Alagad Captcha  Documentation provided in Acrobat, HTML 
FlashPaper and Microsoft Word formats.

Example
A fully functional example application.

Known Issues
====================

Some Users get an error like this: "This graphics environment can be used only 
in the software emulation"

This error was addressed in Macromedia technote 18747 
(http://www.macromedia.com/support/coldfusion/ts/documents/graphics_unix_141jvm.htm) 
and is addressed in the documentation.

Another good resource for resolving this problem can be found at: 
http://www.doughughes.net/index.cfm/page-blogLink/entryId-29

----------------------------------------------------------------------

Some users have reported errors on very minimal RedHat installations.

Some systems with very minimal (router-like) installations can not use the 
component.  They get messages like:
/opt/coldfusionmx/runtime/jre/lib/i386/libawt.so: libXp.so.6: cannot open shared 
object file: No such file or directory

This appears to be due to dependencies which Java.awt has on the underlying 
system.

I reproduced this error.  I have a barebones minimal installation of RedHat 9.  
This install added absolutely none of the X server libraries.  When I tried to 
use the AIC on this server I produced the error.

Because the system is "headless" I followed the instructions from macromedia 
technote 18747 at 
http://www.macromedia.com/support/coldfusion/ts/documents/graphics_unix_141jvm.htm 
which shows how to fix another error which seemed related.  (This is the fabled 
"headless system" error messages.)  This did not fix the problem.

All in all, it appears that even when Java is running in a headless mode it 
still relies on some libraries from the underlying system.  Without these calls 
to java.awt classes will error out.  

Only one users has reported this problem.  Last I knew this user was attempting 
to fix the problem by installing a virtual frame buffer.  I was not able to 
solve the problem.

Users who experience this problem may want to try installing PJA as documented 
here: http://www.doughughes.net/index.cfm/page-blogLink/entryId-29

=======================================================================

Copyright (c) 2004 Alagad Inc. All rights reserved. 

=======================================================================