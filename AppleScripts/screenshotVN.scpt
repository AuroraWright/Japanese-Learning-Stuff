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
from Quartz import CGGetActiveDisplayList, CGMainDisplayID, CGRectMake, CGWindowListCopyWindowInfo, kCGWindowListExcludeDesktopElements, kCGNullWindowID, kCGWindowName
from AppKit import NSImage, NSBitmapImageRep, NSDeviceRGBColorSpace, NSSize, NSRect, NSZeroPoint, NSZeroRect, NSCompositingOperationCopy, NSGraphicsContext, NSImageInterpolationHigh, NSBitmapImageFileTypeJPEG, NSImageCompressionFactor
from ScreenCaptureKit import SCContentFilter, SCScreenshotManager, SCShareableContent, SCStreamConfiguration, SCCaptureResolutionBest
import objc
import urllib.request
from datetime import datetime
import psutil
import queue


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


def capture_macos_screenshot(screencapture_mode, window_display_id, screen_capture_coords=None):
    def shareable_content_completion_handler_display(shareable_content, error):
        if error:
            screencapturekit_queue.put(None)
            return

        target_display = None
        for display in shareable_content.displays():
            if display.displayID() == window_display_id:
                target_display = display
                break

        if not target_display:
            screencapturekit_queue.put(None)
            return

        with objc.autorelease_pool():
            content_filter = SCContentFilter.alloc().initWithDisplay_excludingApplications_exceptingWindows_(
                target_display, [], []
            )
            configuration = SCStreamConfiguration.alloc().init()

            if screencapture_mode == 0:
                frame = content_filter.contentRect()
                width = frame.size.width
                height = frame.size.height
            else:
                x, y, width, height = [float(c.strip()) for c in screen_capture_coords.split(',')]
                configuration.setSourceRect_(CGRectMake(x, y, width, height))

            scale = content_filter.pointPixelScale()
            configuration.setWidth_(width * scale)
            configuration.setHeight_(height * scale)
            configuration.setShowsCursor_(False)
            configuration.setCaptureResolution_(SCCaptureResolutionBest)

            SCScreenshotManager.captureImageWithFilter_configuration_completionHandler_(
                content_filter, configuration, capture_image_completion_handler
            )

    def shareable_content_completion_handler_window(shareable_content, error):
        if error:
            screencapturekit_queue.put(None)
            return

        target_window = None
        for window in shareable_content.windows():
            if window.windowID() == window_display_id:
                target_window = window
                break

        if not target_window:
            screencapturekit_queue.put(None)
            return

        with objc.autorelease_pool():
            content_filter = SCContentFilter.alloc().initWithDesktopIndependentWindow_(target_window)
            configuration = SCStreamConfiguration.alloc().init()

            frame = content_filter.contentRect()
            if not screen_capture_coords:
                x = 0
                y = 0
                width = frame.size.width
                height = frame.size.height
            elif screen_capture_coords == 'menubar':
                fixed_menubar = False
                if frame.origin.x == 0:
                    for display in shareable_content.displays():
                        display_frame = display.frame()
                        if display_frame.size.width == frame.size.width and display_frame.size.height == frame.origin.y + frame.size.height:
                            x = 0
                            y = frame.origin.y
                            width = frame.size.width
                            height = frame.size.height - frame.origin.y
                            fixed_menubar = True
                            break
                if not fixed_menubar:
                    x = 0
                    y = 0
                    width = frame.size.width
                    height = frame.size.height
            else:
                cut_left, cut_right, cut_top, cut_bottom = [float(c.strip()) for c in screen_capture_coords.split(',')]
                x = cut_left
                y = cut_top
                width = frame.size.width - cut_left - cut_right
                height = frame.size.height - cut_top - cut_bottom

            scale = content_filter.pointPixelScale()
            configuration.setSourceRect_(CGRectMake(x, y, width, height))
            configuration.setWidth_(width * scale)
            configuration.setHeight_(height * scale)
            configuration.setShowsCursor_(False)
            configuration.setCaptureResolution_(SCCaptureResolutionBest)
            configuration.setIgnoreGlobalClipSingleWindow_(True)

            SCScreenshotManager.captureImageWithFilter_configuration_completionHandler_(
                content_filter, configuration, capture_image_completion_handler
            )

    def capture_image_completion_handler(image, error):
        if error:
            screencapturekit_queue.put(None)
            return

        screencapturekit_queue.put(image)

    if screencapture_mode == 2:
        SCShareableContent.getShareableContentWithCompletionHandler_(
            shareable_content_completion_handler_window
        )
    else:
        SCShareableContent.getShareableContentWithCompletionHandler_(
            shareable_content_completion_handler_display
        )


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
        return original_image_rep

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

    screen_capture_coords = config['config']['screen_capture_coords']
    if screen_capture_coords == '':
        screencapture_mode = 0
    elif len(screen_capture_coords.split(',')) == 4:
        screencapture_mode = 1
    else:
        screencapture_mode = 2

    if screencapture_mode != 2:
        if config['config']['second_screen'] == 'true':
            (err, online_displays, number_of_online_displays) = CGGetActiveDisplayList(2, None, None)
            if number_of_online_displays == 2:
                if online_displays[0] == CGMainDisplayID():
                    display_id = online_displays[1]
                else:
                    display_id = online_displays[0]
            else:
                sys.exit(1)
        else:
            display_id = CGMainDisplayID()

    time.sleep(float(config['config']['delay']))

    global screencapturekit_queue
    screencapturekit_queue = queue.Queue()

    if screencapture_mode == 0:
        capture_macos_screenshot(0, display_id)
    elif screencapture_mode == 1:
        capture_macos_screenshot(1, display_id, screen_capture_coords)
    else:
        window_list = CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID)
        window_titles = []
        window_ids = []
        window_id = 0
        for i, window in enumerate(window_list):
            window_title = window.get(kCGWindowName, '')
            if psutil.Process(window['kCGWindowOwnerPID']).name() not in ('Terminal', 'iTerm2'):
                window_titles.append(window_title)
                window_ids.append(window['kCGWindowNumber'])

        if screen_capture_coords in window_titles:
            window_id = window_ids[window_titles.index(screen_capture_coords)]
        else:
            for t in window_titles:
                if screen_capture_coords in t:
                    window_id = window_ids[window_titles.index(t)]
                    break

        if not window_id:
            sys.exit(1)

        CGMainDisplayID()
        capture_macos_screenshot(2, window_id, config['config']['cutting_coords'])

    try:
        cg_image = screencapturekit_queue.get(timeout=0.5)
    except queue.Empty:
        sys.exit(1)

    ns_imagerep = NSBitmapImageRep.alloc().initWithCGImage_(cg_image)

    if config['config']['resize'] == 'true':
        ns_imagerep = resize_image(ns_imagerep, float(config['config']['max_width']), float(config['config']['max_height']))

    options = {NSImageCompressionFactor: float(config['config']['jpeg_quality'])}
    jpg_image = ns_imagerep.representationUsingType_properties_(NSBitmapImageFileTypeJPEG, options)
    encoded_image = base64.b64encode(jpg_image).decode('ascii')
    filename = 'screenshot-' + datetime.now().strftime('%Y-%m-%d-%H.%M.%S') + '.jpg'

    added_notes = anki_connect('findNotes', query='added:1 deck:current')
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

    if len(updated_list) > 0:
        with open('/tmp/last_edited_cards.json', 'w') as fp:
            json.dump(updated_list, fp)

    anki_connect('guiBrowse', query='added:1 deck:current', reorderCards={'order': 'descending', 'columnId': 'noteCrt'})

main()
EOF"
end screencapture