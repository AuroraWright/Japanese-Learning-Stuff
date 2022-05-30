set {x, y, w, h} to {1, 384, 1025, 578}

set appName to "Parallels Desktop"
if application appName is not running then
	return
end if
set appName to "Anki"
if application appName is not running then
	return
end if

screencapture(x, y, w, h)

tell application "System Events"
	tell process appName to set frontmost to true
	keystroke "r" using {command down}
end tell

on screencapture(x, y, w, h)
	set args to ""
	repeat with a in {x, y, w, h}
		set args to args & space & ("" & a)'s quoted form
	end repeat
	do shell script "/opt/homebrew/bin/python3 <<'EOF' - " & args & "

import sys, os
import Quartz.CoreGraphics as CoreGraphics
from AppKit import NSPasteboard, NSArray, NSImage

def usage():
    sys.stderr.write('Usage: %s x y w h\\n' % os.path.basename(sys.argv[0]))
    sys.exit(1)

def main():
    if not len(sys.argv) == 5: usage()
    x, y, w, h = [ float(a) for a in sys.argv[1:5] ]
    
    img = CoreGraphics.CGDisplayCreateImageForRect(CoreGraphics.CGMainDisplayID(), CoreGraphics.CGRectMake(x, y, w, h))
    brep = NSImage.alloc().initWithCGImage_(img)
    pb = NSPasteboard.generalPasteboard()
    pb.clearContents()
    a = NSArray.arrayWithObject_(brep)
    pb.writeObjects_(a)

main()
EOF"
end screencapture