Asphyre Sphinx Framework v4.0.0

---------------------------------------------------------------
This release provides unified support of DirectX 7, DirectX 9,
DirectX 10, DirectX 11, OpenGL 2.1 and OpenGL 1.4 (in legacy
mode).

DirectX 9 implementation uses either Direct3D 9 Ex on Windows
Vista and later, or Direct3D 9 on Windows XP and earlier,
switching automatically.

DirectX 10 implementation uses either Direct3D 10.1, when such
support is available (including Windows WARP software device),
or Direct3D 10.0 on unpatched Windows Vista, switching between
the two automatically.

DirectX 11 implementation uses fallback mechanism to earlier
feature levels, so it should work on hardware that is capable
of Direct3D 9 and later.

OpenGL implementation uses programmable pipeline by default
and uses OpenGL 2.1 features.

Minimal requirements:

1) Embarcadero Delphi XE 2 or later for Desktop platform.
2) Embarcadero Delphi XE 4 or later for Mobile platform.

Installation in Delphi involves adding Asphyre source folder
along with each one of its subfolders in Delphi's library
path. In latest Delphi versions you can locate library
path at the following location:
"Tools – Options – Environment Options – Delphi Options –
Library Path". That is, the line should look like this:
 $(BDS)\lib;$(BDS)\Imports;$(BDS)\Lib\Indy10;c:\Asphyre\Source

In order to use Asphyre documentation, locate "Help" folder and
in this folder find and open "index.html". Alternatively, you
can create a shortcut to this file on your desktop.

In this release, Asphyre tools are divided in two categories:
32-bit and 64-bit versions. You can find them in their
respective sub-folders inside "Tool" folder.

Also, you can discuss the development of Asphyre Framework on
our forums at:
 http://www.afterwarp.net/forum

Remember that this library and its source code are protected
by Mozilla Public License 2.0. You must agree to use this
package under the terms of Mozilla Public License 2.0 or
permamently remove the package from your hard drive.

---------------------------------------------------------------
Asphyre is copyright (c) 2000 - 2013  Yuriy Kotsarenko

Some of the included artwork was made by Humberto Andrade
and is copyright protected. Any distribution of this artwork
is strictly prohibited.