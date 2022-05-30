
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
Addon-wide constants
"""

from ._version import __version__

try:
    from .data.patrons import MEMBERS_CREDITED, MEMBERS_TOP
except ImportError:
    MEMBERS_CREDITED = MEMBERS_TOP = ()

__all__ = [
    "ADDON"
]

# PROPERTIES DESCRIBING ADDON


class ADDON(object):
    """Class storing general add-on properties
    Property names need to be all-uppercase with no leading underscores
    """
    NAME = "Pop-up Dictionary"
    MODULE = "popup_dictionary"
    ID = "153625306"
    VERSION = __version__
    LICENSE = "GNU AGPLv3"
    AUTHORS = (
        {"name": "Aristotelis P. (Glutanimate)", "years": "2018-2019",
         "contact": "https://glutanimate.com"},
    )
    AUTHOR_MAIL = "ankiglutanimate@gmail.com"
    LIBRARIES = (
        {"name": "qTip2", "version": "v3.0.3",
         "author": "Craig Michael Thompson", "license": "MIT license",
         "url": "http://qtip2.com/"},
        {"name": "jquery-migrate", "version": "3.0.0",
         "author": "jquery", "license": "MIT license",
         "url": "https://github.com/jquery/jquery-migrate"},
        {"name": "jQuery.highlight", "version": "5",
         "author": "Johann Burkard", "license": "MIT license",
         "url": "https://johannburkard.de/blog/programming/javascript/highlight-javascript-text-higlighting-jquery-plugin.html"},
    )
    CONTRIBUTORS = ()
    SPONSORS = ()
    MEMBERS_CREDITED = MEMBERS_CREDITED
    MEMBERS_TOP = MEMBERS_TOP
    LINKS = {
        "patreon": "https://www.patreon.com/glutanimate",
        "bepatron": "https://www.patreon.com/bePatron?u=7522179",
        "coffee": "http://ko-fi.com/glutanimate",
        "description": "https://ankiweb.net/shared/info/{}".format(ID),
        "rate": "https://ankiweb.net/shared/review/{}".format(ID),
        "twitter": "https://twitter.com/glutanimate",
        "youtube": "https://www.youtube.com/c/glutanimate",
        "help": ""
    }
