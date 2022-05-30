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
JS libs
"""

from aqt import mw

from .consts import ADDON
from .libaddon.platform import MODULE_ADDON


# jQuery-migrate is required on 2.1.40+ to fix compatibility conflcits between
# qtip2 and jQuery 3.x
# cf. https://github.com/qTip2/qTip2/issues/797
popup_integrator = f"""
<link rel="stylesheet" href="/_addons/{MODULE_ADDON}/web/jquery.qtip.css">
<link rel="stylesheet" href="/_addons/{MODULE_ADDON}/web/popup.css">
<script>
    const _pDictVersion = "{ADDON.VERSION}";
    const _pDictLink = "{ADDON.LINKS['bepatron']}";
</script>
<script src="/_addons/{MODULE_ADDON}/web/jquery-migrate-3.0.0.min.js"></script>
<script src="/_addons/{MODULE_ADDON}/web/jquery.qtip.min.js"></script>
<script src="/_addons/{MODULE_ADDON}/web/jquery.highlight.min.js"></script>
<script src="/_addons/{MODULE_ADDON}/web/popup.js"></script>
"""


def initialize_web():
    # TODO: either fix on Anki#s end or use re.escape(os.path.sep)
    mw.addonManager.setWebExports(__name__, r"web.*")
