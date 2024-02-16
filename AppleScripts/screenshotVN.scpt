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
    tell application id (id of application appName2) to activate
else if manageWindows is equal to 2 then
    tell application "System Events" to key code 124 using control down
else
    delay appName2
end if

screencapture()

tell application id (id of application appName) to activate

on screencapture()
    do shell script "/opt/homebrew/bin/python3 <<'EOF' - 

import sys, time, os, configparser, json, base64
import Quartz.CoreGraphics as CoreGraphics
from AppKit import NSImage, NSBitmapImageRep, NSDeviceRGBColorSpace, NSSize, NSRect, NSZeroPoint, NSZeroRect, NSCompositingOperationCopy, NSGraphicsContext, NSImageInterpolationHigh, NSBitmapImageFileTypeJPEG, NSImageCompressionFactor
import urllib.request
from datetime import datetime


def request(action, **params):
    return {'action': action, 'params': params, 'version': 6}

def anki_connect(action, **params):
    requestJson = json.dumps(request(action, **params)).encode('utf-8')
    response = json.load(urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:8765', requestJson)))
    if len(response) != 2:
        raise Exception('response has an unexpected number of fields')
    if 'error' not in response:
        raise Exception('response is missing required error field')
    if 'result' not in response:
        raise Exception('response is missing required result field')
    if response['error'] is not None:
        raise Exception(response['error'])
    return response['result']


def resize_image(original_image_rep, max_width, max_height):
    original_image = NSImage.alloc().init()
    original_image.addRepresentation_(original_image_rep)
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
        new_width = int(original_width / width_ratio)
        new_height = int(original_height / width_ratio)
    else:
        new_width = int(original_width / height_ratio)
        new_height = int(original_height / height_ratio)

    resized_image = NSBitmapImageRep.alloc().initWithBitmapDataPlanes_pixelsWide_pixelsHigh_bitsPerSample_samplesPerPixel_hasAlpha_isPlanar_colorSpaceName_bytesPerRow_bitsPerPixel_(
        None,  # Set to None to create a new bitmap
        new_width,
        new_height,
        8,  # Bits per sample
        4,  # Samples per pixel (R, G, B, A)
        True,  # Has alpha
        False,  # Is not planar
        NSDeviceRGBColorSpace,
        0,  # Automatically compute bytes per row
        32  # Bits per pixel (8 bits per sample * 4 samples per pixel)
    )

    context = NSGraphicsContext.graphicsContextWithBitmapImageRep_(resized_image)
    context.setImageInterpolation_(NSImageInterpolationHigh)
    NSGraphicsContext.setCurrentContext_(context)

    original_rect = NSRect(NSZeroPoint, NSSize(new_width, new_height))
    original_image.drawInRect_fromRect_operation_fraction_(
        original_rect,
        NSZeroRect,
        NSCompositingOperationCopy,
        1.0
    )

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

    ns_imagerep = NSBitmapImageRep.alloc().initWithCGImage_(img)

    if config['config']['resize'] == 'true':
        ns_imagerep = resize_image(ns_imagerep, float(config['config']['max_width']), float(config['config']['max_height']))

    options = {NSImageCompressionFactor: float(config['config']['jpeg_quality'])}
    jpg_image = ns_imagerep.representationUsingType_properties_(NSBitmapImageFileTypeJPEG, options)
    encoded_image = base64.b64encode(jpg_image).decode('ascii')
    filename = 'screenshot-' + datetime.now().strftime('%Y-%m-%d-%H.%M.%S') + '.jpg'

    added_notes = anki_connect('findNotes', query='added:1')
    if len(added_notes) == 0:
        return
    added_notes.sort()
    anki_connect('guiBrowse', query='nid:1')
    note_index = -1
    updated_list = []
    while True:
        if abs(note_index) > len(added_notes):
            break
        note_id = added_notes[note_index]
        note_data = anki_connect('notesInfo', notes=[note_id])
        if note_data[0]['fields']['Picture']['value'] != '':
            break
        note = {'id': note_id, 
                'fields': {},
                'picture': {'filename': filename,
                            'data': encoded_image,
                            'fields': ['Picture']
                           }
               }
        anki_connect('updateNoteFields', note=note)
        updated_list.append(note_id)
        note_index -= 1
    with open('/tmp/last_edited_cards.json', 'w') as fp:
        json.dump(updated_list, fp)

    anki_connect('guiBrowse', query='added:1', reorderCards={'order': 'descending', 'columnId': 'noteCrt'})

main()
EOF"
end screencapture