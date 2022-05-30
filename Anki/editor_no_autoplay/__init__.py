import html
import urllib.parse

from aqt.editor import Editor, pics

def myFnameToLink(self, fname: str) -> str:
    ext = fname.split(".")[-1].lower()
    if ext in pics:
        name = urllib.parse.quote(fname.encode("utf8"))
        return f'<img src="{name}">'
    else:
        return f"[sound:{html.escape(fname, quote=False)}]"

Editor.fnameToLink = myFnameToLink