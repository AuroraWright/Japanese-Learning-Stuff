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
#

from typing import TYPE_CHECKING, Union

import aqt
from aqt import mw
from aqt.browser import Browser
from aqt.qt import *
from anki.utils import pointVersion
from aqt.previewer import Previewer
from .config import config

if TYPE_CHECKING:
    from anki.notes import NoteId

try:  # 2.1.41+
    from anki.collection import SearchNode

    NEW_SEARCH_SUPPORT = True
except (ImportError, ModuleNotFoundError):
    NEW_SEARCH_SUPPORT = False


def browse_to_nid(note_id: Union["NoteId", int]):
    """Open browser and find cards by nid"""

    if NEW_SEARCH_SUPPORT:
        aqt.dialogs.open("Browser", mw, search=(SearchNode(nid=note_id),))
    else:
        browser: Browser = aqt.dialogs.open("Browser", mw)
        browser.form.searchEdit.lineEdit().setText(f"nid:{note_id}")
        browser.onSearchActivated()

def browse_to_kanji(kanji: str):
    """Open browser and find cards by kanji"""

    conf = config["local"]
    sorting_column = conf["wordSearchSortingColumn"]

    window = QApplication.activeWindow()
    if isinstance(window, Previewer):
        fieldName = window._parent.current_card.model()['flds'][0]['name']
    else:
        fieldName = mw.reviewer.card.model()['flds'][0]['name']

    if NEW_SEARCH_SUPPORT:
        browser = aqt.dialogs.open("Browser", mw, search=("deck:current", f"{fieldName}:*{kanji}*"))
    else:
        browser: Browser = aqt.dialogs.open("Browser", mw)
        browser.form.searchEdit.lineEdit().setText(f"deck:current {fieldName}:{kanji}")
        browser.onSearchActivated()

    if pointVersion() >= 45:
        # Workaround Anki issue
        if browser.table._model.is_empty():
            browser._lastSearchTxt = ""
        col_index = browser.table._model.active_column_index(sorting_column)
        browser.table._on_sort_column_changed(col_index, Qt.SortOrder.DescendingOrder)
    else:
        col_index = browser.model.activeCols.index(sorting_column)
        browser.onSortChanged(col_index, True)