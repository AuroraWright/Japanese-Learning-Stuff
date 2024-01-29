screencapture()

on screencapture()
    do shell script "/opt/homebrew/bin/python3 <<'EOF' - 

import subprocess
import asyncio
import io
import websockets
from AppKit import NSPasteboard, NSPasteboardItem, NSMutableArray
from PIL import ImageGrab, Image

def image_to_byte_array(img):
    image_bytes = io.BytesIO()
    img.save(image_bytes, format='png', compress_level=1)
    return image_bytes.getvalue()

def read_from_pasteboard(pasteboard):
    pasteboard_items = NSMutableArray.array()

    for item in pasteboard.pasteboardItems():
        data_holder = NSPasteboardItem.alloc().init()
        for type in item.types():
            data = item.dataForType_(type).mutableCopy()
            if data:
                data_holder.setData_forType_(data, type)

        pasteboard_items.addObject_(data_holder)

    return pasteboard_items

async def ws_client(img):
    url = 'ws://127.0.0.1:7331'
    try:
        async with websockets.connect(url) as ws:
            await ws.send(img)
            response = await ws.recv()
        return response == 'True'
    except Exception:
        return False

def main():
    pb = NSPasteboard.generalPasteboard()
    pasteboard_backup = read_from_pasteboard(pb)
    count = pb.changeCount()
    cmd = ['screencapture', '-i', '-c']
    subprocess.run(cmd)

    restore_pasteboard = False

    if count != pb.changeCount():
        try:
            img = ImageGrab.grabclipboard()
        except OSError as error:
            pass
        else:
            restore_pasteboard = asyncio.run(ws_client(image_to_byte_array(img)))

    if restore_pasteboard:
        pb.clearContents()
        pb.writeObjects_(pasteboard_backup)

main()
EOF"
end screencapture