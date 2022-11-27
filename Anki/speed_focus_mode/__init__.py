# -*- coding: utf-8 -*-

# Speed Focus Mode Add-on for Anki
#
# Copyright (C) 2017-2019  Aristotelis P. <https://glutanimate.com/>
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
Module-level entry point for the add-on into Anki 2.0/2.1
"""

from aqt import gui_hooks

from ._version import __version__  # noqa: F401
from .options import initialize_options
from .reviewer import initialize_reviewer

_initialized: bool = False

# Delay add-on initialization to work around conflicts with add-ons such as
# Advanced Review Bottom Bar
def initialize_addon():
    global _initialized
    if _initialized:
        return
    initialize_options()
    initialize_reviewer()
    _initialized = True


gui_hooks.profile_did_open.append(initialize_addon)  # type: ignore[attr-defined]
