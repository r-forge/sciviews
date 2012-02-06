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

# Komodo R language service

import logging
from koUDLLanguageBase import KoUDLLanguage
from xpcom import components #, nsError, COMException, ServerException


log = logging.getLogger("koRLanguage")
log.setLevel(logging.DEBUG)


def registerLanguage(registry):
    log.debug("Registering language R")
    registry.registerLanguage(KoRLanguage())


class KoRLanguage(KoUDLLanguage):
    name = "R"
    lexresLangName = "R"
    _reg_desc_ = "%s Language" % name
    _reg_contractid_ = "@activestate.com/koLanguage?language=%s;1" % name
    _reg_clsid_ = "{4cc23d3b-52e2-426d-8a22-6d7eb2ba81ae}"
    _reg_categories_ = [("komodo-language", name)]
    defaultExtension = '.R'
    primary = 1
    lang_from_udl_family = {
        'SSL': 'R'
    }

    commentDelimiterInfo = {
        "line": [ "#", ],
    }

    #downloadURL = "http://cran.r-project.org"
    #searchURL = "http://www.rseek.org/"

    variableIndicators = '$'
    _dedenting_statements = [u'return', u'break', u'else', u'next']
    _indenting_statements = [u'switch', u'if', u'ifelse', u'while', u'for', u'repeat', u'break']
    supportsSmartIndent = "brace"

    #styleStdin = components.interfaces.ISciMoz.SCE_C_STDIN
    #styleStdout = components.interfaces.ISciMoz.SCE_C_STDOUT
    #styleStderr = components.interfaces.ISciMoz.SCE_C_STDERR

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
        return self._get_linter_from_lang("R")
    def get_interpreter(self):
        None


    #if 1:
    #    # The new autocomplete/calltip functionality based on the codeintel
    #    # system.
    #    def get_codeintelcompleter(self):
    #        if self._codeintelcompleter is None:
    #            self._codeintelcompleter =\
    #                components.classes["@sciviews.org/koRCodeIntelCompletionLanguageService;1"]\
    #                .getService(components.interfaces.koICodeIntelCompletionLanguageService)
    #            self._codeintelcompleter.initialize(self)
    #            # Ensure the service gets finalized when Komodo shutsdown.
    #            finalizeSvc = components.classes["@activestate.com/koFinalizeService;1"]\
    #                .getService(components.interfaces.koIFinalizeService)
    #            finalizeSvc.registerFinalizer(self._codeintelcompleter)
    #        return self._codeintelcompleter
    #else:
    #    def get_completer(self):
    #        if self._completer is None:
    #            self._completer = components.classes["@sciviews.org/koRCompletionLanguageService;1"] \
    #                .getService(components.interfaces.koICompletionLanguageService)
    #    return self._completer

    #def get_lexer(self):
    #    return None
    #    if self._lexer is None:
    #        self._lexer = KoLexerLanguageService()
    #        self._lexer.setLexer(components.interfaces.ISciMoz.SCLEX_CPP)
    #        self._lexer.setKeywords(0, lang_r.keywords)
    #        self._lexer.setKeywords(1, lang_r.builtins)
    #        self._lexer.supportsFolding = 1
    #    return self._lexer


# import re
# from koLanguageServiceBase import *

# iface = components.interfaces.koICodeIntelCompletionUIHandler

# #log = logging.getLogger("koRCompletion")
# class KoRCompletion(KoCompletionLanguageService):
    # _com_interfaces_ = [components.interfaces.koICompletionLanguageService]
    # _reg_desc_       = "R Calltip/AutoCompletion Service"
    # _reg_clsid_      = "{DF19E793-ECC2-6571-7CC1-D7F02D1C94C7}"
    # _reg_contractid_ = "@sciviews.org/koRCompletionLanguageService;1"

    # #useCharSet = "_: " + string.ascii_uppercase + string.ascii_lowercase + string.digits

    # def __init__(self):
        # self._ok = 1
        # self.triggersCallTip = '('
        # self.triggers = ''
        # self.completionSeparator = ord('\n')
        # self._scintilla = None
        # self._lastlComplete = []
        # self._lastcompletion = None
        # self.sv_utils = components.classes["@sciviews.org/svUtils;1"].\
            # getService(components.interfaces.svIUtils)
        # log.debug("KoRCompletion __init__")


    # def _get_code_frag(self, scimoz):
        # # Get sensible code fragment
        # cur_pos = scimoz.currentPos
        # cur_line = scimoz.lineFromPosition(cur_pos)
        # pos_start = scimoz.positionFromLine(scimoz.getFoldParent(cur_line))
        # pos_end = max(scimoz.anchor, cur_pos)
        # text = scimoz.getTextRange(pos_start, pos_end)
        # return text


    # def _getCompletions(self, text):
        # if not text.strip(): return 0, None
        # cmd = 'completion("%s", print=TRUE, types="scintilla", field.sep="?")' \
            # % text.replace('"', '\\"')
        # compl_str = self.sv_utils.execInR(cmd, "h")

        # if ((compl_str == '') or (re.search("^\d+[\r\n]", compl_str) == None)):
            # return 0, None

        # compl_str = re.split("[\r\n]+", compl_str.replace('\r\n', chr(self.completionSeparator)), 1)
        # trig_len = int(compl_str[0])
        # compl_str = compl_str[1]
        # return trig_len, compl_str

    # def _getTip(self, text):
        # cmd = 'cat(callTip("%s", location=TRUE, description=TRUE, methods=TRUE, width=80))' \
            # % text.replace('"', '\\"')
        # result = self.sv_utils.execInR(cmd, "h").strip()
        # #if not result: return None
        # result = result.replace('[\r\n]+', '\n')
        # return result

    # def _DoTipComplete(self):
        # s = self._scintilla
        # #s.autoCCancelAtStart = 0
        # text = self._get_code_frag(s)
        # if len(text) < 3:
            # if s.autoCActive(): s.autoCCancel()
            # return
        # tip_str = self._getTip(text)
        # if tip_str:
            # self._scintilla.callTipShow(s.currentPos, tip_str)
        # elif s.autoCActive():
            # s.autoCCancel()

    # def AutoComplete(self, ch, scimoz):
        # log.debug("KoRCompletion AutoComplete")
        # if not self._ok: return
        # s = self._scintilla = scimoz
        # text = self._get_code_frag(s)
        # trig_len, completions =self._getCompletions(text)
        # if not completions: return

        # if s.callTipActive():
            # s.callTipCancel()
        # scimoz.autoCShow(trig_len, completions)

    # def StartCallTip(self, ch, scimoz):
        # log.debug("KoRCompletion StartCallTip")
        # if not self._ok: return
        # s = self._scintilla = scimoz

        # #s.SCE_UDL_SSL_COMMENT, s.SCE_UDL_SSL_STRING, SCE_UDL_SSL_DEFAULT

        # # Only do this if we have no selection
        # if s.selectionStart == s.selectionEnd and s.selectionStart > 0:
            # curPos = s.positionBefore(s.currentPos)
            # style  = s.getStyleAt(curPos)
            # if style == s.SCE_UDL_SSL_COMMENT: return
            # if style == s.SCE_UDL_SSL_STRING: return

            # if s.callTipActive(): return
            # else:
                # self._DoTipComplete()
                # return

        # if s.autoCActive(): s.autoCCancel()


# class KoRCodeIntelCompletionLanguageService(KoCodeIntelCompletionLanguageService):
    # _com_interfaces_ = [components.interfaces.koICodeIntelCompletionLanguageService]
    # _reg_desc_ = "R CodeIntel Calltip/AutoCompletion Service"
    # _reg_clsid_ = "{E9C1237A-D3F4-2AE2-EF66-02D3C30D3678}"
    # _reg_contractid_ = "@sciviews.org/koRCodeIntelCompletionLanguageService;1"

    # # Characters that should automatically invoke the current completion item
    # # - cannot be '-' for "autocomplete-*-subs" because:
    # #       attributes::->import(__PACKAGE__, \$x, 'Bent');
    # # - cannot be '{' for "autocomplete-object-subs" because:
    # #       my $d = $self->{'escape'};
    # # - shouldn't be ')' because:
    # #       $dumper->dumpValue(\*::);
    # completionFillups = "@$([]"

    # def __init__(self):
        # KoCodeIntelCompletionLanguageService.__init__(self)
        # log.debug("KoRCICompletion... __init__")

    # def triggerPrecedingCompletionUI(self, path, scimoz, startPos,
                                     # ciCompletionUtriggerPrecedingCompletionUI):
        # log.debug("KoRCICompletion... triggerPrecedingCompletionUI")
        # KoCodeIntelCompletionLanguageService(self, path, scimoz, startPos,
                                     # ciCompletionUtriggerPrecedingCompletionUI)
        # pass
