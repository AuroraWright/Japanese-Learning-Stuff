screencapture()

on screencapture()
    do shell script "/opt/homebrew/bin/python3 <<'EOF' - 

import subprocess
import asyncio
import websockets
from AppKit import NSPasteboard, NSPasteboardTypePNG, NSPasteboardItem, NSMutableArray

def backup_from_pasteboard(pasteboard):
    pasteboard_items = NSMutableArray.array()
    for item in pasteboard.pasteboardItems():
        data_holder = NSPasteboardItem.alloc().init()
        for type in item.types():
            data = item.dataForType_(type).mutableCopy()
            if data:
                data_holder.setData_forType_(data, type)

        pasteboard_items.addObject_(data_holder)

    return pasteboard_items

def get_image_from_pasteboard(pasteboard):
    if NSPasteboardTypePNG in pasteboard.types():
        image_data = pasteboard.dataForType_(NSPasteboardTypePNG)
        return bytes(image_data)

    return None

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
    pasteboard_backup = backup_from_pasteboard(pb)
    count = pb.changeCount()
    cmd = ['screencapture', '-i', '-c']
    subprocess.run(cmd)

    restore_pasteboard = False

    if count != pb.changeCount():
        img = get_image_from_pasteboard(pb)
        if img:
            restore_pasteboard = asyncio.run(ws_client(img))

    if restore_pasteboard:
        pb.clearContents()
        pb.writeObjects_(pasteboard_backup)

main()
EOF"
end screencapture