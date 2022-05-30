# -*- coding: utf-8 -*-

"""
Anki Add-on: Refresh Browser List

Refreshes browser view and optionally changes the sorting column
(e.g. to show newly added cards since last search)

Copyright: (c) Glutanimate 2016-2017 <https://glutanimate.com/>
2018 Arthur Milchior <arthur@milchior.fr> (porting to 2.1)
License: GNU AGPLv3 or later <https://www.gnu.org/licenses/agpl.html>
"""

# Do not modify the following line
from __future__ import unicode_literals
from anki.utils import pointVersion
from anki import version as anki_version
anki21 = anki_version.startswith("2.1.")

######## USER CONFIGURATION START ########

SORTING_COLUMN = "noteCrt"
# Custom column sorting applied on hotkey toggle
#   - only works if that column is active in the first place
#   - set to note creation time by default ("noteCrt")
#   - can be disabled by setting SORTING_COLUM = ""
#
# Valid Values (regular browser):
#
# 'question' 'answer' 'template' 'deck' 'noteFld' 'noteCrt' 'noteMod'
# 'cardMod' 'cardDue' 'cardIvl' 'cardEase' 'cardReps' 'cardLapses'
# 'noteTags' 'note'
#
# Additional values (advanced browser):
#
# 'cfirst' 'clast' 'cavgtime' 'ctottime' 'ntags' 'coverdueivl' 'cprevivl'


######## USER CONFIGURATION END ########

from aqt.qt import *
from aqt.browser import Browser
from aqt.browser.table import Table
from anki.hooks import addHook
def debug(t):
    #print(t)
    pass

def refreshView(self):
    debug("Calling refreshView()")
    if anki21:
        self.onSearchActivated()
    else:
        self.onSearch(reset=True)

    if anki21 and pointVersion() >= 45:
        col_index = self.table._model.active_column_index(SORTING_COLUMN)
        self.table._on_sort_column_changed(col_index, Qt.SortOrder.DescendingOrder)
        self.form.tableView.clearSelection()
        self.form.tableView.selectRow(0)
    else:
        col_index = self.model.activeCols.index(SORTING_COLUMN)
        self.onSortChanged(col_index, True)
        self.form.tableView.selectRow(0)

def setupMenu(self):
    menu = self.form.menuEdit
    menu.addSeparator()
    a = menu.addAction('Refresh View')
    a.setShortcut(QKeySequence("CTRL+R" if anki21 else "F5"))
    a.triggered.connect(self.refreshView)

Browser.refreshView = refreshView
addHook("browser.setupMenus", setupMenu)
