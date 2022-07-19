set appName to "Parallels Desktop"
if application appName is not running then
	return
end if
set appName to "Anki"
if application appName is not running then
	return
end if

screencapture()

tell application "System Events"
	tell process appName to set frontmost to true
	keystroke "r" using {command down}
end tell

on screencapture()
	do shell script "/opt/homebrew/bin/python3 <<'EOF' - 

import sys, os, configparser
import Quartz.CoreGraphics as CoreGraphics
from AppKit import NSPasteboard, NSArray, NSImage

def main():
    home_path = os.path.expanduser('~')
    config_path = os.path.join(home_path,'.config','vnscreenshotscript.ini')
    config = configparser.ConfigParser()
    config.read(config_path)

    if config['config']['second_screen'] == 'true':
        (err, online_displays, number_of_online_displays) = CoreGraphics.CGGetActiveDisplayList(2, None, None)
        if number_of_online_displays == 2:
            if online_displays[0] == CoreGraphics.CGMainDisplayID():
                display_id = online_displays[1]
            else:
                display_id = online_displays[0]
        else:
            sys.exit(1)
    else:
        display_id = CoreGraphics.CGMainDisplayID()

    if config['config']['whole_screen'] == 'true':
        img = CoreGraphics.CGDisplayCreateImage(display_id)
    else:
        coords = config['config']['rectangle_coords']
        x, y, w, h = [float(x) for x in coords.split(' ')]
        img = CoreGraphics.CGDisplayCreateImageForRect(display_id, CoreGraphics.CGRectMake(x, y, w, h))

    brep = NSImage.alloc().initWithCGImage_(img)
    pb = NSPasteboard.generalPasteboard()
    pb.clearContents()
    a = NSArray.arrayWithObject_(brep)
    pb.writeObjects_(a)

main()
EOF"
end screencapture