#!/usr/bin/env python
"""R support for codeintel.

This file will be imported by the codeintel system on startup and the
register() function called to register this language with the system. All
Code Intelligence for this language is controlled through this module.
"""
import os, sys, re
import logging
import operator

from codeintel2.common import *
from codeintel2.citadel import CitadelBuffer, CitadelLangIntel
from codeintel2.langintel import LangIntel
from codeintel2.langintel import ParenStyleCalltipIntelMixin, ProgLangTriggerIntelMixin
from codeintel2.udl import UDLLexer, UDLBuffer, UDLCILEDriver
from codeintel2.util import CompareNPunctLast
from codeintel2.accessor import AccessorCache, KoDocumentAccessor


from SilverCity.ScintillaConstants import (
    SCE_UDL_SSL_DEFAULT, SCE_UDL_SSL_IDENTIFIER, SCE_UDL_SSL_OPERATOR,
    SCE_UDL_SSL_VARIABLE, SCE_UDL_SSL_WORD, SCE_UDL_SSL_COMMENT,
    SCE_UDL_SSL_COMMENTBLOCK, SCE_UDL_SSL_STRING
)

try:
    from xpcom.server import UnwrapObject
    _xpcom_ = True
except ImportError:
    _xpcom_ = False

from xpcom import components
R = components.classes["@sciviews.org/svUtils;1"].\
    getService(components.interfaces.svIUtils)


#---- Globals
lang = "R"
log = logging.getLogger("codeintel.r")
log.setLevel(logging.DEBUG)

# These keywords and builtin functions are copied from "Rlex.udl".
# Reserved keywords
keywords = [
    "...", "break", "else", "FALSE", "for", "function", "if", "in", "Inf", "NA",
    "NaN", "next", "NULL", "repeat", "TRUE", "while",
]


# Non reserved keywords
builtins = [
    ".Alias", ".ArgsEnv", ".AutoloadEnv", ".BaseNamespaceEnv", ".C",
]

#---- Lexer class
class RLexer(UDLLexer):
    lang = lang


# possible R triggers
# library|require(<|>     available packages (ok)
# detach(<|>      loaded namespaces
# data(<|>        available datasets
# func(<|>        calltip or argument names
# func(arg,<|>    argument names
# list $ <|>        list elements
# s4object @ <|>    slots
# namespace:: <|>  objects within namespace
# namespace::: <|>  objects within namespace
# variab<|>       complete variable names
# "<|>            file paths
# Note that each name may be single, double or backtick quoted, or in multiple
# lines
## completion for 'library(' or 'require(' R command :
## 'unique(unlist(lapply(.libPaths(), dir)))'




#---- LangIntel class
# Dev Notes:
# All language should define a LangIntel class. (In some rare cases it
# isn't needed but there is little reason not to have the empty subclass.)
#
# One instance of the LangIntel class will be created for each codeintel
# language. Code browser functionality and some buffer functionality
# often defers to the LangIntel singleton.
#
# This is especially important for multi-lang files. For example, an
# HTML buffer uses the JavaScriptLangIntel and the CSSLangIntel for
# handling codeintel functionality in <script> and <style> tags.
#
# See other lang_*.py files in your Komodo installation for examples of
# usage.
class RLangIntel(CitadelLangIntel, ParenStyleCalltipIntelMixin,
                   ProgLangTriggerIntelMixin):
    lang = lang

    # Used by ProgLangTriggerIntelMixin.preceding_trg_from_pos()
    #trg_chars = tuple('$@[( ')
    #calltip_trg_chars = tuple('(,')

    # named styles used by the class
    whitespace_style = SCE_UDL_SSL_DEFAULT
    operator_style   = SCE_UDL_SSL_OPERATOR
    identifier_style = SCE_UDL_SSL_IDENTIFIER
    keyword_style    = SCE_UDL_SSL_WORD
    variable_style   = SCE_UDL_SSL_VARIABLE
    string_style     = SCE_UDL_SSL_STRING
    comment_styles   = (SCE_UDL_SSL_COMMENT, SCE_UDL_SSL_COMMENTBLOCK)
    comment_styles_or_whitespace = comment_styles + (whitespace_style, )

    #def __init__:
    #    CitadelLangIntel.__init__(self)
    #    ParenStyleCalltipIntelMixin.__init__(self)
    #    ProgLangTriggerIntelMixin.__init__(self)
    #


    def _functionCalltipTrigger(self, ac, pos, DEBUG=False):
    # Implicit calltip triggering from an arg separator ",", we trigger a
    # calltip if we find a function open paren "(" and function identifier
    #   http://bugs.activestate.com/show_bug.cgi?id=70470
        DEBUG = True
        if DEBUG: r_logfile.writelines("Arg separator found, looking for start of function\n")
        # Move back to the open paren of the function
        paren_count = 0
        p = pos
        min_p = max(0, p - 200) # look back max 200 chars
        while p > min_p:
            p, c, style = ac.getPrecedingPosCharStyle(ignore_styles=self.comment_styles)
            if style == self.operator_style:
                if c == ")":
                    paren_count += 1
                elif c == "(":
                    if paren_count == 0:
                        # We found the open brace of the func
                        trg_from_pos = p+1
                        p, ch, style = ac.getPrevPosCharStyle()
                        start, text = ac.getTextBackWithStyle(style, self.comment_styles, max_text_len = 32)
                        #if DEBUG: r_logfile.writelines("Function start found, pos: %d (%s)\n" % (p, text))
                        if style in self.comment_styles_or_whitespace:
                            # Find previous non-ignored style then
                            p, c, style = ac.getPrecedingPosCharStyle(style, self.comment_styles_or_whitespace)
                        if style in (self.identifier_style, self.keyword_style):
                            return Trigger(lang, TRG_FORM_CALLTIP,
                                           "call-signature",
                                           trg_from_pos, implicit=True)
                    else:
                        paren_count -= 1
                elif c in ";{}":
                    # Gone too far and nothing was found
                    #if DEBUG:
                        #r_logfile.writelines("No function found, hit stop char: %s at p: %d\n" % (c, p))
                    return None
        # Did not find the function open paren
        #if DEBUG:
            #print "No function found, ran out of chars to look at, p: %d" % (p,)
        return None


    ##
    # Implicit triggering event, i.e. when typing in the editor.
    #
    def trg_from_pos(self, buf, pos, implicit=True, DEBUG=False, ac=None):
        """If the given position is a _likely_ trigger point, return a
        relevant Trigger instance. Otherwise return the None.
            "pos" is the position at which to check for a trigger point.
            "implicit" (optional) is a boolean indicating if this trigger
                is being implicitly checked (i.e. as a side-effect of
                typing). Defaults to true.
        """
        if pos < 3:
            return None

        self._log("trg_from_pos: %d" % (pos))
        accessor = buf.accessor
        last_pos = pos - 1
        char = accessor.char_at_pos(last_pos)
        style = accessor.style_at_pos(last_pos)
        if style == self.operator_style:
            if char in '(':
                in_fun = self._is_function(pos, accessor)
                if in_fun != None and in_fun[2] in ('library', 'require'):
                    if(style == self.whitespace_style):
                         text = ''
                    else:
                        start, end, text = self._get_word_back(last_pos, accessor)
                    # lang, form, type, pos, implicit,
                    return Trigger(self.lang, TRG_FORM_CPLN, "installed-pkgs", \
                        pos, implicit=True)
            else:
                lw_start, lw_end, last_word = self._get_word_back(last_pos, accessor)
                if last_word in ('@', '$', '::', ':::'):
                    start, end, objname = self._get_word_back(lw_start - 1, accessor)
                    style2 = accessor.style_at_pos(end - 1)
                    if style2 in (self.keyword_style, self.identifier_style, self.variable_style):
                        return Trigger(self.lang, TRG_FORM_CPLN, "list-elements", \
                            start, False, obj_name = objname + last_word)
            return None

        return None


    def _log(self, text):
        if False:
            logfile = open("c:/temp/codeintel_r.log", "a")
            logfile.writelines(text + "\n")
            logfile.close()
        else:
            pass



    ##
    # Explicit triggering event, i.e. Ctrl+J.
    #
    def preceding_trg_from_pos(self, buf, pos, curr_pos,
                               preceding_trg_terminators=None, DEBUG=False):
        self._log("preceding_trg_from_pos: %d" % (pos))
        if pos < 3:
            return None

        accessor = buf.accessor
        last_pos = pos - 1
        char = accessor.char_at_pos(last_pos)
        style = accessor.style_at_pos(last_pos)
        self._log("char: %r, style: %d, pos: %d" % (char, style, pos))

        #if(style != self.whitespace_style):
            #self._log("Triggered: test-elements")
            #start, end = accessor.contiguous_style_range_from_pos(last_pos)
            #return Trigger(self.lang, TRG_FORM_CPLN, "test-elements", start, False)
        #return None
        lw_start, lw_end, last_word = self._get_word_back(last_pos, accessor)
        if last_word in ('@', '$', '::', ':::'):
            start, end, objname = self._get_word_back(lw_start - 1, accessor)
            style2 = accessor.style_at_pos(end - 1)
            if style2 in (self.keyword_style, self.identifier_style, self.variable_style):
                return Trigger(self.lang, TRG_FORM_CPLN, "list-elements", \
                    start, False, obj_name = objname + last_word) #acc.text_range(start, lw_end)
        else:
            in_fun = self._is_function(pos, accessor)
            if in_fun != None and (in_fun[2] in ('library', 'require')):
                self._log("(in_function) last_word: %r " % (last_word))
                text = ''
                if style == self.identifier_style and lw_end >= pos: # started word
                    text = accessor.text_range(lw_start, pos)
                    pos = lw_start
                return Trigger(self.lang, TRG_FORM_CPLN, "installed-pkgs", \
                    pos, False, arg_name = text)
        return None

    def async_eval_at_trg(self, buf, trg, ctlr):
        if _xpcom_:
            trg = UnwrapObject(trg)
            ctlr = UnwrapObject(ctlr)
        pos = trg.pos
        ctlr.start(buf, trg)
        #ctlr.set_desc("completing...")

        if trg.id == (self.lang, TRG_FORM_CPLN, "installed-pkgs") :
            if(trg.extra.has_key('arg_name')):
                text = trg.extra['arg_name']
            else:
                text = ''
            completions = self._get_completions_available_pkgs(text)
            if completions != None:
                ctlr.set_cplns(completions)
                ctlr.done("success")
                return
            else:
                ctlr.info("Not found for %r" % (trg, ))
                ctlr.done("none found")
                return
        if trg.id == (self.lang, TRG_FORM_CPLN, "list-elements") \
                and trg.extra.has_key('obj_name'):
            completions = self._get_completions(trg.extra['obj_name'])
            if(completions[0] == 'error'):
                ctlr.error(completions[1])
                ctlr.done("error")
            if completions == None or completions[1] == None:
                ctlr.debug("No completions found for '%s'" % (trg.extra['obj_name'], ))
                ctlr.done("nothing found")
                return
            ctlr.set_cplns(completions[1])
            ctlr.done(completions[0])
            return

        #if trg.id == (self.lang, TRG_FORM_CPLN, "test-elements") :
        #    ctlr.set_cplns([('keyword', "Bababa"), ('keyword', "Umpapa")])
        #    ctlr.done("success")
        #    return

        ctlr.error("Unknown trigger type: %r" % (trg, ))
        ctlr.done("error")


        #
        #   Rules for implementation:
        #- Must call ctlr.start(buf, trg) at start.
        #- Should call ctlr.set_desc(desc) near the start to provide a
        #  short description of the evaluation.
        #- Should log eval errors via ctlr.error(msg, args...).
        #- Should log other events via ctlr.{debug|info|warn}.
        #- Should respond to ctlr.abort() in a timely manner.
        #- If successful, must report results via one of
        #  ctlr.set_cplns() or ctlr.set_calltips().
        #- Must call ctlr.done(some_reason_string) when done.


    def _get_completions(self, text):
        if not text.strip(): return None
        cmd = 'completion("%s", print=TRUE, sep=";;", field.sep="?")' \
            % text.replace('"', '\\"')
        res = R.execInR(cmd, "json h", 2)
        #TODO: on timeout an empty string is returned
        #u'\x03Error: could not find function "completion"\r\n\x02'
        if res.startswith(u'\x03'):
            return ('eval error', res.strip("\x02\x03\r\n"))
        cplstr = res.replace('\x03', '').replace('\x02', '')
        if not cplstr: return None
        if (re.search("^\d+;;", cplstr) == None): return None
        cpl = [re.split("\\?", x) for x in re.split(";;", cplstr)[1:]]
        [x.reverse() for x in cpl]
        cpl = [tuple(x) for x in cpl]
        return ('success', cpl)

    def _skip_back_ws(self, pos, acc):
        if acc.style_at_pos(pos) == self.whitespace_style:
            return acc.contiguous_style_range_from_pos(pos)[0] - 1
        return pos

    def _get_word_back(self, pos, acc):
        pos = self._skip_back_ws(pos, acc)
        text_range = acc.contiguous_style_range_from_pos(pos)
        return text_range + (acc.text_range(text_range[0], text_range[1]), )

    def _is_function(self, pos, acc):
        p = pos - 1
        p_min = max(0, pos - 200)
        scimoz = acc.scimoz()
        arg_count = 0
        while p > p_min:
            ch = acc.char_at_pos(p)
            if ch in ")]}":
                p = scimoz.braceMatch(p) - 1
            elif ch == "(":
                start, end, word = self._get_word_back(p - 1, acc)
                if acc.style_at_pos(start) in (self.keyword_style, \
                                self.identifier_style, self.string_style):
                    return (start, p, word, arg_count)
                break
            else:
                if ch == ',':
                    arg_count += 1
                p -= 1
        return None

    def _get_completions_available_pkgs(self, text):
        res = R.execInR("cat(unique(unlist(lapply(.libPaths(), dir, pattern='%s'))), sep='\\n')" \
            % (('^' if(text) else '') + text, ), "json h", .5)
        if len(res.strip()):
            return [('variable', x) for x in res.splitlines()]
        return None


#---- Buffer class

class RBuffer(UDLBuffer):
    lang = lang
    cb_show_if_empty = True
    cpln_fillup_chars = "\t" #"~`!$@#%^&*()-=+{}[]|\\;:'\",<>?/\t\n\r"
    cpln_stop_chars = "~`!$@#%^&*()-=+{}[]|\\;:'\",<>?/ "

    # Dev Note: many details elided.

    def trg_from_pos(self, pos, implicit=True):
        if pos == 0:
            return None
        #RLangIntel().trg_from_pos(self, pos, implicit=implicit)

        try:
            langintel = self.mgr.langintel_from_lang(self.lang)
        except KeyError:
            return None
        return langintel.trg_from_pos(self, pos, implicit=implicit)


    def preceding_trg_from_pos(self, pos, curr_pos,
                               preceding_trg_terminators=None):
        if pos == 0:
            return None

        #RLangIntel().preceding_trg_from_pos(self, pos, curr_pos,
                                            #preceding_trg_terminators)
        try:
            langintel = self.mgr.langintel_from_lang(self.lang)
        except KeyError:
            return None
        return langintel.preceding_trg_from_pos(self, pos, curr_pos,
                                                preceding_trg_terminators)

#---- CILE Driver class
# Dev Notes:
# A CILE (Code Intelligence Language Engine) is the code that scans
# R content and returns a description of the code in that file.
# See "cile_r.py" for more details.
#
# The CILE Driver is a class that calls this CILE.
class RCILEDriver(UDLCILEDriver):
    lang = lang
    ssl_lang = 'R'


#---- Registration
def register(mgr):
    """Register language support with the Manager."""
    mgr.set_lang_info(
        lang,
        silvercity_lexer=RLexer(),
        buf_class=RBuffer,
        langintel_class=RLangIntel,
        import_handler_class=None,
        cile_driver_class=None, # RCILEDriver,
        is_cpln_lang=True)
