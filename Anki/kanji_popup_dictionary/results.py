# -*- coding: utf-8 -*-

# Pop-up Dictionary Add-on for Anki
#
# Copyright (C)  2018-2021 Aristotelis P. <https://glutanimate.com/>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version, with the additions
# listed at the end of the license file that accompanied this program.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# NOTE: This program is subject to certain additional terms pursuant to
# Section 7 of the GNU Affero General Public License.  You should have
# received a copy of these additional terms immediately following the
# terms and conditions of the GNU Affero General Public License that
# accompanied this program.
#
# If not, please request a copy through one of the means of contact
# listed here: <https://glutanimate.com/contact/>.
#
# Any modifications to this file must keep this entire header intact.

"""
Parses collection for pertinent notes and generates result list
"""

import re
from typing import TYPE_CHECKING, List, Optional, Sequence, Union
import string

from aqt import mw
from aqt.utils import askUser
from aqt.qt import QApplication
from aqt.previewer import Previewer

from .config import config
from .libaddon.debug import logger

if TYPE_CHECKING:
    from anki.collection import Collection
    from anki.notes import Note, NoteId

from anki.utils import stripHTML

PYCMD_IDENTIFIER: str = "popupDictionary"

# UI messages

WRN_RESCOUNT: str = (
    "<b>{}</b> relevant notes found.<br>"
    "The tooltip could take a lot of time to render and <br>"
    "temporarily slow down Anki.<br><br>"
    "<b>Are you sure you want to proceed?</b>"
)

# HTML format strings for results

html_reslist: str = """<div class="pdict-reslist">{}</div>"""

html_res_normal: str = f"""\
<div class="pdict-res" data-nid={{}}>{{}}<div title="Browse..." class="pdict-brws"
onclick='pycmd("{PYCMD_IDENTIFIER}BrowseNid:" + this.parentNode.dataset.nid)'>&rarr;</div><div title="Browse words by kanji..." class="pdict-brws2"
onclick='pycmd("{PYCMD_IDENTIFIER}BrowseKanji:" + "{{}}")'>&rarr;</div></div>\
"""

html_field: str = """<div class="pdict-fld">{}</div>"""

# RegExes for cloze marker removal

cloze_re_str = r"\{\{c(\d+)::(.*?)(::(.*?))?\}\}"
cloze_re = re.compile(cloze_re_str)

# Anki API shims


def get_note(collection: "Collection", note_id: "NoteId") -> "Note":
    try:
        return collection.get_note(note_id)
    except AttributeError:
        return collection.getNote(note_id)


def find_notes(collection: "Collection", query: str, **kwargs) -> Sequence["NoteId"]:
    try:
        return collection.find_notes(query, **kwargs)
    except AttributeError:
        return collection.findNotes(query, **kwargs)  # type:ignore[attr-defined]

def process_note(note: "Note", excluded_flds: str, kanji: str) -> str:
    valid_flds = [
        html_field.format(i[1]) for i in note.items() if i[0] not in excluded_flds
    ]
    joined_flds = "".join(valid_flds)
    # remove cloze markers
    filtered_flds = cloze_re.sub(r"\2", joined_flds)
    return html_res_normal.format(note.id, filtered_flds, kanji)    


# Functions that compose tooltip content


def get_content_for(term: str) -> str:
    """Compose tooltip content for search term.
    Returns HTML string."""
    conf = config["local"]

    dict_entry = None
    note_content = None
    content = []

    note_content = get_note_snippets_for(term)
    if note_content:
        content.extend(note_content)  # type: ignore

    if content:
        return html_reslist.format("".join(content))
    elif note_content is False:
        return ""
    elif note_content is None and conf["generalConfirmEmpty"]:
        return "No other results found."

    return ""


def get_note_snippets_for(term: str) -> Union[List[str], bool, None]:
    """Find relevant note snippets for search term.
    Returns list of HTML strings."""

    conf = config["local"]
    rtk_deck_name = conf["RTKDeckName"]
    kanji_field_name = conf["kanjiFieldName"]
    keyword_field_name = conf["keywordFieldName"]

    logger.debug("getNoteSnippetsFor called")

    if term == "useQuestionField":
        window = QApplication.activeWindow()
        if isinstance(window, Previewer):
            return False
        fieldName = mw.reviewer.card.model()['flds'][0]['name']
        term = mw.reviewer.card.note()[fieldName]
        term = stripHTML(term).strip()

    query = ""
    kanji_list = re.findall(r'[㐀-䶵一-鿋豈-頻]', term)
    for kanji in kanji_list:
        if not query:
            query = "(" + kanji_field_name + ":"
        else:
            query += " OR " + kanji_field_name + ":"
        query += '"' + kanji + '"'
    if kanji_list:
        query += ")"
    elif all(c.isalnum() or c.isspace() for c in term):
        query = keyword_field_name + ':"*' + term + '*"'
    else:
        return False

    query += ' deck:"' + rtk_deck_name + '"'

    # NOTE: performing the SQL query directly might be faster
    res = sorted(find_notes(collection=mw.col, query=query))
    logger.debug("getNoteSnippetsFor query finished.")

    if not res:
        return None

    # Prevent slowdowns when search term is too common
    res_len = len(res)
    warn_limit = conf["snippetsResultsWarnLimit"]
    if warn_limit > 0 and res_len > warn_limit:
        if not askUser(WRN_RESCOUNT.format(res_len), title="Popup Dictionary"):
            return False

    notes = []
    note_content: List[str] = []
    excluded_flds = conf["snippetsExcludedFields"]

    for nid in res:
        note = get_note(collection=mw.col, note_id=nid)
        notes.append(note)

    if kanji_list:
        for kanji in kanji_list:
            for note in notes:
                if kanji in note[kanji_field_name]:
                    note_content.append(process_note(note, excluded_flds, kanji))
                    notes.remove(note)
                    break
    else:
        for note in notes:
            kanji = note[kanji_field_name]
            kanji = stripHTML(kanji).strip()
            note_content.append(process_note(note, excluded_flds, kanji))

    return note_content
