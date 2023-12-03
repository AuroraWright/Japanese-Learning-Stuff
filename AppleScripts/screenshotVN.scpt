set appName to "Anki"
if application appName is not running then
    return
end if

set configFile to ((path to home folder) & ".config:vnscreenshotscript.conf") as string
set theFileContents to paragraphs of (read file configFile)
set manageWindows to item 1 of theFileContents as integer
set appName2 to item 2 of theFileContents as string

if manageWindows is equal to 1 then
    if application appName2 is not running then
        set process_running to false
        try
            do shell script "/usr/bin/pgrep -q " & appName2
            set process_running to true
        end try
        
        if not process_running then
            return
        end if
    end if
    tell application "System Events"
        tell process appName2 to set frontmost to true
    end tell
else if manageWindows is equal to 2 then
    tell application "System Events" to key code 124 using control down
else
    delay appName2
end if

screencapture()

tell application "System Events"
    tell process appName to set frontmost to true
    keystroke "r" using {command down}
end tell

on screencapture()
    do shell script "/opt/homebrew/bin/python3 <<'EOF' - 

import sys, time, os, configparser, io
import Quartz.CoreGraphics as CoreGraphics
from AppKit import NSPasteboard, NSArray, NSImage, NSSize, NSRect, NSBitmapImageRep, NSGraphicsContext
import AppKit

def resize_image(original_image, max_width, max_height):
    original_width = original_image.size().width
    original_height = original_image.size().height

    if max_width == 0:
        max_width = sys.maxsize
    if max_height == 0:
        max_height = sys.maxsize

    if original_width <= max_width and original_height <= max_height:
        return original_image

    width_ratio = original_width / max_width
    height_ratio = original_height / max_height
    if width_ratio > height_ratio:
        new_width = original_width / width_ratio
        new_height = original_height / width_ratio
    else:
        new_width = original_width / height_ratio
        new_height = original_height / height_ratio

    new_size = NSSize(new_width, new_height)

    bitmap = NSBitmapImageRep.alloc().initWithBitmapDataPlanes_pixelsWide_pixelsHigh_bitsPerSample_samplesPerPixel_hasAlpha_isPlanar_colorSpaceName_bytesPerRow_bitsPerPixel_(
        None,  # Set to None to create a new bitmap
        int(new_size.width),
        int(new_size.height),
        8,  # Bits per sample
        4,  # Samples per pixel (R, G, B, A)
        True,  # Has alpha
        False,  # Is not planar
        AppKit.NSDeviceRGBColorSpace,
        0,  # Automatically compute bytes per row
        32  # Bits per pixel (8 bits per sample * 4 samples per pixel)
    )

    context = NSGraphicsContext.graphicsContextWithBitmapImageRep_(bitmap)
    context.setImageInterpolation_(AppKit.NSImageInterpolationHigh)
    NSGraphicsContext.setCurrentContext_(context)

    original_rect = NSRect((0, 0), new_size)
    original_image.drawInRect_fromRect_operation_fraction_(
        original_rect,
        AppKit.NSZeroRect,
        AppKit.NSCompositeSourceOver,
        1.0
    )

    resized_image = NSImage.alloc().init()
    resized_image.addRepresentation_(bitmap)

    return resized_image


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

    time.sleep(float(config['config']['delay']))

    if config['config']['whole_screen'] == 'true':
        img = CoreGraphics.CGDisplayCreateImage(display_id)
    else:
        coords = config['config']['rectangle_coords']
        x, y, w, h = [float(x) for x in coords.split(' ')]
        img = CoreGraphics.CGDisplayCreateImageForRect(display_id, CoreGraphics.CGRectMake(x, y, w, h))

    ns_image = NSImage.alloc().initWithCGImage_(img)

    if config['config']['resize'] == 'true':
        ns_image = resize_image(ns_image, float(config['config']['max_width']), float(config['config']['max_height']))

    pb = NSPasteboard.generalPasteboard()
    pb.clearContents()
    a = NSArray.arrayWithObject_(ns_image)
    pb.writeObjects_(a)

main()
EOF"
end screencapture