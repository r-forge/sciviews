# ***** BEGIN LICENSE BLOCK *****
# Version: MPL 1.1/GPL 2.0/LGPL 2.1
#
# The contents of this file are subject to the Mozilla Public License
# Version 1.1 (the "License"); you may not use this file except in
# compliance with the License. You may obtain a copy of the License at
# http://www.mozilla.org/MPL/
#
# Software distributed under the License is distributed on an "AS IS"
# basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
# License for the specific language governing rights and limitations
# under the License.
#
# The Original Code is SciViews-K by Philippe Grosjean et al.
#
# Portions created by ActiveState Software Inc are Copyright (C) 2000-2008
# ActiveState Software Inc. All Rights Reserved.
#
# Contributor(s):
#   Philippe Grosjean
#   Kamil Barton
#   ActiveState Software Inc (code inspired from)
#
# Alternatively, the contents of this file may be used under the terms of
# either the GNU General Public License Version 2 or later (the "GPL"), or
# the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
# in which case the provisions of the GPL or the LGPL are applicable instead
# of those above. If you wish to allow use of your version of this file only
# under the terms of either the GPL or the LGPL, and not to allow others to
# use your version of this file under the terms of the MPL, indicate your
# decision by deleting the provisions above and replace them with the notice
# and other provisions required by the GPL or the LGPL. If you do not delete
# the provisions above, a recipient may use your version of this file under
# the terms of any one of the MPL, the GPL or the LGPL.
#
# ***** END LICENSE BLOCK *****

# Komodo R language service.

import logging
from koUDLLanguageBase import KoUDLLanguage


log = logging.getLogger("koRLanguage")
#log.setLevel(logging.DEBUG)


def registerLanguage(registry):
    log.debug("Registering language R")
    registry.registerLanguage(KoRLanguage())


class KoRLanguage(KoUDLLanguage):
    name = "R"
    lexresLangName = "R"
    _reg_desc_ = "%s Language" % name
    _reg_contractid_ = "@activestate.com/koLanguage?language=%s;1" % name
    _reg_clsid_ = "{4cc23d3b-52e2-426d-8a22-6d7eb2ba81ae}"
    defaultExtension = '.R'

    lang_from_udl_family = {
        'SSL': 'R'
    }

    commentDelimiterInfo = {
        "line": [ "#", ],
    }

    variableIndicators = '$'
    _dedenting_statements = [u'return', u'break', u'else', u'next']
    _indenting_statements = [u'switch', u'if', u'ifelse', u'while', u'for', u'repeat']
    supportsSmartIndent = "brace"

    sample = """`cube`<- function(x, na.rm = FALSE) {
    if (isTRUE(na.rm))
        x <- x[!is.na(x)]
    return(x^3)
} # A comment
a <- data.frame(x = 1:10, y = rnorm(10))
cube(a$x)
plot(y ~ x, data = a, col = 'blue', main = "Plot of \\"a\\"\\0")
a$y <- NULL; a"""

    # Overriding these base methods to work around bug 81066.
    def get_linter(self):
        return None
    def get_interpreter(self):
        None
