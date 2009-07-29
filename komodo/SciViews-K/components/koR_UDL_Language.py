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
# The Original Code is SciViews-K by Philippe Grosjean & Romain Francois.
#
# Portions created by ActiveState Software Inc are Copyright (C) 2000-2008
# ActiveState Software Inc. All Rights Reserved.
#
# Contributor(s):
#   Philippe Grosjean
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
# TODO: we still need to build a decent linter for R. Currently, this is code
# adapted from ActionScript, but it does not work because no linter is found!
#

import logging
from koLanguageServiceBase import *
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

    # ??? I don't understand this... could someone explain me?
    lang_from_udl_family = {'SSL': 'R' }    # R - might be - a server side language (yet all this works with CSL too), and can contain only R

    # Code from koJavaScriptLanguage.py

    # Only line comments in R
    commentDelimiterInfo = {
        "line": [ "#" ]
    }
    # TODO: we probably have to rework and complete these lists!
    _dedenting_statements = ['return', 'break', 'else', 'next']
    _indenting_statements = ['switch', 'if', 'ifelse', 'while', 'for', 'repeat']
    #searchURL = "http://wiki.r-project.org/rwiki/rhelp.php?id=%W"
    searchURL = "javascript: sv.r.help('%w');"
    namedBlockDescription = 'R functions'

    # TODO: I need to change this!
    # this matches R function now, but I cannot see any effect / KB
    namedBlockRE = r'^[ \t]*(?:[\.\w\x80-\xff][_\.\w\x80-\xff]+|(`).+\1)\s*<-\s*function\s*\(.*$'
    supportsSmartIndent = "brace"

    # Bypass KoUDLLanguage.get_linter, which doesn't know how to find
    # the R linter.  The base class does.
    ### What should I do with this???
    get_linter = KoLanguageBase.get_linter

    sample = """`cube`<- function(x, na.rm = FALSE) {
    if (na.rm) x <- x[!is.na(x)]
    return(x^3)
} # A comment
a <- data.frame(x = 1:10, y = rnorm(10))
cube(a$x)
plot(y ~ x, data = a, col = 'blue', main = "Plot of \\"a\\"")
a$y <- NULL; a"""

from xpcom import components, nsError, ServerException
from koLintResult import *
from koLintResults import koLintResults
import os, re, sys, string
import os.path
import tempfile
import process
import koprocessutils

# TODO: all this should be reworked when a R linter will be ready
def RWarnsToLintResults(warns, filename, code, status):
    defaultSeverity = ((status == 0 and KoLintResult.SEV_WARNING)
                       or KoLintResult.SEV_ERROR)
    lintResults = koLintResults()
    warnRe = re.compile(r'(?P<fileName>.*?):(?P<lineNum>\d+): (?:characters (?P<rangeStart>\d+)-(?P<rangeEnd>\d+))\s*:\s*(?P<message>.*)')
    for warn in warns:
        match = warnRe.search(warn)
        if match and match.group('fileName') == filename:
            lineNum = int(match.group('lineNum'))
            rangeStart = match.groupdict().get('rangeStart', None)
            rangeEnd = match.groupdict().get('rangeEnd', None)
            lr = KoLintResult()
            lr.description = match.group('message')
            lr.lineStart = lineNum
            lr.lineEnd = lineNum
            if rangeStart and rangeEnd:
                lr.columnStart = int(rangeStart) + 1
                lr.columnEnd = int(rangeEnd) + 1
            else:
                lr.columnStart = 1
                lr.columnEnd = len(lines[lr.lineStart - 1]) + 1
            lr.severity = defaultSeverity
            lintResults.addResult(lr)
        else:
            log.debug("%s: no match", warn)
    log.debug("returning %d lint results", lintResults.getNumResults())
    return lintResults

# TODO: rework when the R linter is done
class koRLinter:
    _com_interfaces_ = [components.interfaces.koILinter]
    _reg_desc_ = "Komodo R Linter"
    _reg_clsid_ = "{49af7a6c-850e-4f34-8c7a-294324a42g85}"
    _reg_contractid_ = "@activestate.com/koLinter?language=R;1"
    _reg_categories_ = [ ("komodo-linter", "R Linter"), ]

    def __init__(self):
        log.debug("Created the R Linter object")
        # Copied and pasted from KoPerlCompileLinter
        self.sysUtils = components.classes["@activestate.com/koSysUtils;1"].\
            getService(components.interfaces.koISysUtils)
        self.infoSvc = components.classes["@activestate.com/koInfoService;1"].\
                       getService()
        self._lastErrorSvc = components.classes["@activestate.com/koLastErrorService;1"].\
            getService(components.interfaces.koILastErrorService)
        self._koVer = self.infoSvc.version

    def _getInterpreter(self, prefset):
        if prefset.hasStringPref("RDefaultInterpreter") and\
           prefset.getStringPref("RDefaultInterpreter"):
            return prefset.getStringPref("RDefaultInterpreter")
        return None

    def lint(self, request):
        text = request.content.encode(request.encoding.python_encoding_name)
        cwd = request.cwd
        prefset = request.document.getEffectivePrefs()
        ascExe = self._getInterpreter(prefset)
        if ascExe is None:
            log.debug('no interpreter')
            return
        tmpFileName = None
        if cwd:
            tmpFileName = os.path.join(cwd,
                                       "tmp_ko_Rlint_ko%s.R" % (self._koVer.replace(".","_").replace("-","_")))
            try:
                fout = open(tmpFileName, 'wb')
                fout.write(text)
                fout.close()
            except (OSError, IOError), ex:
                tmpFileName = None
        if not tmpFileName:
            # Fallback to using a tmp dir if cannot write in cwd.
            try:
                tmpFileName = tempfile.mktemp()
                cwd = os.path.dirname(tmpFileName)
            except OSError, ex:
                # Sometimes get this error but don't know why:
                # OSError: [Errno 13] Permission denied: 'C:\\DOCUME~1\\trentm\\LOCALS~1\\Temp\\~1324-test'
                errmsg = "error determining temporary filename for "\
                         "R content: %s" % ex
                self._lastErrorSvc.setLastError(3, errmsg)
                raise ServerException(nsError.NS_ERROR_UNEXPECTED)
            fout = open(tmpFileName, 'wb')
            fout.write(text)
            fout.close()

        try:
            argv = [ascExe, "-strict"]
            # mtasc gets confused by pathnames
            R_filename = os.path.basename(tmpFileName)
            argv += [R_filename]
            cwd = cwd or None # convert '' to None (cwd=='' for new files)
            log.debug("Run cmd %s in dir %s", " ".join(argv), cwd)
            env = koprocessutils.getUserEnv()
            p = process.ProcessOpen(argv, cwd=cwd, env=env)
            results = p.stderr.readlines()
            log.debug("results: %s", "\n".join(results))
            p.close()
            status = None
            try:
                raw_status = p.wait(timeout=3.0)
                if sys.platform.startswith("win"):
                    status = raw_status
                else:
                    status = raw_status >> 8

                lintResults = RWarnsToLintResults(results, R_filename, text, status)
            except process.ProcessError:
                # Don't do anything with this exception right now.
                lintResults = None
                log.debug("Waiting for R linter, got a ProcessError")

        finally:
            os.unlink(tmpFileName)

        return lintResults
