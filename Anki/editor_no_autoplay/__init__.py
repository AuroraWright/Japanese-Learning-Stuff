import html
import urllib.parse
from threading import Timer
from aqt.sound import av_player
from aqt.editor import Editor, pics

def stop():
    av_player.shutdown()

def myFnameToLink(self, fname: str) -> str:
    ext = fname.split(".")[-1].lower()
    if ext in pics:
        name = urllib.parse.quote(fname.encode("utf8"))
        return f'<img src="{name}">'
    else:
        av_player.play_file(fname)
        Timer(2, stop).start()
        return f"[sound:{html.escape(fname, quote=False)}]"

Editor.fnameToLink = myFnameToLink