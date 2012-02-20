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

#from SilverCity import find_lexer_module_by_id, PropertySet, WordList

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
log = logging.getLogger("R-codeintel")
log.setLevel(logging.DEBUG)

# These keywords and builtin functions are copied from "Rlex.udl".
# Reserved keywords
keywords = [
    "...", "break", "else", "FALSE", "for", "function", "if", "in", "Inf", "NA",
    "NaN", "next", "NULL", "repeat", "TRUE", "while",
]


#---- Lexer class
class RLexer(UDLLexer):
    lang = lang

    #def __init__(self):
    #self._properties = SilverCity.PropertySet()
    #self._keyword_lists = [
        #SilverCity.WordList(SilverCity.Keywords.perl_keywords),
        #SilverCity.WordList("")
    #]
    #SilverCity.WordList("fsfsd fsfsdf")



# possible R triggers:
# library|require(<|>     available packages
# detach(<|>      loaded namespaces
# data(<|>        available datasets
# func(<|>        calltip or argument names
# func(arg,<|>    argument names
# func(firstar<|>    argument names
# func(arg, secondar<|>    argument names
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

# TODO: skip if completion is none, i.e. equals the text


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
    word_styles      = ( variable_style, identifier_style, keyword_style)

    type_sep = u'\u001e'


    #def __init__:
    #    CitadelLangIntel.__init__(self)
    #    ParenStyleCalltipIntelMixin.__init__(self)
    #    ProgLangTriggerIntelMixin.__init__(self)
    #


    ##
    # Implicit triggering event, i.e. when typing in the editor.
    #
    # TODO: trigger positions
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

        accessor = buf.accessor
        last_pos = pos - 1
        char = accessor.char_at_pos(last_pos)
        style = accessor.style_at_pos(last_pos)
        if style == self.operator_style:
            if char in '(':
                in_fun = self._in_func(pos, accessor)
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

    def _unquote(self, text, quotes = '`"\''):
        if(text[0] in quotes and text[-1] == text[0]):
            return text[1:len(text) - 1]
        return text

    def _is_bquoted(self, text):
        return len(text) > 1 and text.startswith('`') and text.endswith(text[0])


    ##
    # Explicit triggering event, i.e. Ctrl+J.
    #
    def preceding_trg_from_pos(self, buf, pos, curr_pos,
                               preceding_trg_terminators=None, DEBUG=False):
        if pos < 3:
            return None

        acc = buf.accessor
        last_pos = pos - 1

        style = acc.style_at_pos(last_pos)
        s, e, w = self._get_word_back(last_pos, acc)

        ch = acc.char_at_pos(pos)
        prv_ch = acc.char_at_pos(last_pos)
        #print 'w = "%s", ' % (w, ch, )
        log.debug('w = "%s", ch = "%s", prv_ch = "%s", pos = %d, curr_pos = %d ' % (w, ch, prv_ch, pos, curr_pos, ))
        if style in self.word_styles:
            if self._is_bquoted(w):
                return None
            s2, e2, w2 = self._get_word_back(s - 1, acc)
            #print 'w2 = "%s" ' % (w2, )
            log.debug( 'w2 = "%s" ' % (w2, ) )

            if w2[-1] in ',(':
                infun = self._in_func(last_pos, acc)
                if infun is not None:
                    print 'complete variable or argument "%s" for "%s"' % ( w, infun[2], )
                    s2, e2, funcname, nargs, argnames, firstarg = infun
                    return Trigger(self.lang, TRG_FORM_CPLN, "args", s, False,
                        funcname = funcname, firstarg = firstarg, nargs = nargs,
                        argnames = argnames)
                else:
                    return None
            else:
                vr = self._get_var_back(last_pos, acc)
                if vr is not None:
                    print 'complete variable "%s"' % ( ''.join(vr[2]), )
                    return Trigger(self.lang, TRG_FORM_CPLN, "variable", vr[4],
                        False, obj_name = ''.join(vr[2]), cutoff = vr[3])
        if w[-1] in ',(':
            infun = self._in_func(s + 1, acc)
            if infun is not None:
                s2, e2, funcname, nargs, argnames, firstarg = infun
                print 'arguments for "%s"' % ( infun[2], )
                return Trigger(self.lang, TRG_FORM_CPLN, "args", \
                    pos, False, funcname = funcname, firstarg = firstarg,
                    nargs = nargs, argnames = argnames)

        elif w[-1] in '@$:' or style in self.word_styles:
            vr = self._get_var_back(last_pos, acc)
            if vr is not None:
                v = ''.join(vr[2])
                print 'complete "%s"' % ( v, )
                return Trigger(self.lang, TRG_FORM_CPLN, "variable", vr[4],
                    False, obj_name = v, cutoff = vr[3])
        elif w in ('[', '[['):
            infun = self._in_func(pos, acc)
            if infun is not None:
                s2, e2, funcname, nargs, argnames, firstarg = infun
                log.debug('arguments for "%s"' % ( infun[2], ))
                return Trigger(self.lang, TRG_FORM_CPLN, "args", \
                    pos, False, funcname = funcname, firstarg = firstarg,
                    nargs = nargs, argnames = argnames)

        log.debug( 'None? w = "%s" ' % (w, ) )

        return None

# TODO: "variable-or-args" return also variables
    def async_eval_at_trg(self, buf, trg, ctlr):
        if _xpcom_:
            trg = UnwrapObject(trg)
            ctlr = UnwrapObject(ctlr)
        pos = trg.pos
        ctlr.start(buf, trg)

        if trg.id == (self.lang, TRG_FORM_CPLN, "args") or \
            trg.id == (self.lang, TRG_FORM_CPLN, "variable-or-args") :
            completions = self._get_completions_args(trg.extra.get('funcname'),
                trg.extra.get('firstarg'), trg.extra.get('nargs'),
                trg.extra.get('argnames'))
        elif trg.id == (self.lang, TRG_FORM_CPLN, "variable") or \
            trg.id == (self.lang, TRG_FORM_CPLN, "sub-items") :
            completions = self._get_completions_default(
                trg.extra.get('obj_name'), trg.extra.get('cutoff'))
        else:
            ctlr.error("Unknown trigger type: %r" % (trg, ))
            ctlr.done("error")
            return

        if completions == None or completions[0] != "success":
            ctlr.error("Nothing found" if completions is None else completions[1])
            ctlr.done("error")
        else:
            completions[1].sort(key = lambda x: x[1].lower() )
            ctlr.set_cplns(completions[1])
            ctlr.done(completions[0])
            return
            #ctlr.info("Not found for %r" % (trg, ))
            #ctlr.done("none found")
            #return

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

    def _get_completions_args(self, fname, frstarg, nargs, argnames):
        fname = self._unquote(fname)
        log.debug("fname = '%s'" % (fname, ) )
        if fname in ('library', 'require', 'base::library', 'base::require') \
            and nargs == 1:
            #cmd = "cat(unique(unlist(lapply(.libPaths(), dir, pattern='%s'))), sep='\\n')" \
                #% (('^' + frstarg if(frstarg) else ''), )
            cmd = 'completeSpecial("library")'
            types = 'module'
            sfx = ''
            argnames = ''
        elif fname in ('detach', 'base::detach') and nargs == 1:
            #cmd = "cat(unique(unlist(lapply(.libPaths(), dir, pattern='%s'))), sep='\\n')" \
                #% (('^' + frstarg if(frstarg) else ''), )
            cmd = 'completeSpecial("search")'
            types = 'namespace'
            sfx = ''
            argnames = ''

        else:
            cmd = 'cat(getFunArgs("%s", %s), sep = "\\\n")' % (fname, frstarg, )
            types = 'argument'
            sfx = ' ='
        res = R.execInR(cmd, "json h", .5)
        if res.startswith(u'\x03') or not len(res.strip()):
            return ('error', res.strip("\x02\x03\r\n"))

        if len(argnames):
            return ('success', [(types, x + sfx) for x in res.splitlines()
                if not x in argnames ])
        else:
            return ('success', [(types, x + sfx) for x in res.splitlines() ])


    def _get_completions_default(self, text, cutoff):
        if not text.strip(): return None
        cmd = 'completion("%s")' % text.replace('"', '\\"')
        res = R.execInR(cmd, "json h", 2)
        #TODO: on timeout an empty string is returned
        #u'\x03Error: could not find function "completion"\r\n\x02'
        if res.startswith(u'\x03'):
            return ('error', res.strip("\x02\x03\r\n"))
        cplstr = res.replace('\x03', '').replace('\x02', '')
        if not cplstr: return None

        cpl = [ (y[1], y[0][cutoff: ] ) for y in [ x.rstrip().split(self.type_sep, 1)
            for x in cplstr.rsplit('\n')[1:]] if len(y[0]) > cutoff ]
        if len(cpl):
            return ('success', cpl)

        return ('none found', 'No completions found')

    def _skip_back_ws(self, pos, acc):
        if acc.style_at_pos(pos) == self.whitespace_style:
            return acc.contiguous_style_range_from_pos(pos)[0] - 1
        return pos

    def _get_word_back(self, pos, acc):
        pos = self._skip_back_ws(pos, acc)
        s, e = acc.contiguous_style_range_from_pos(pos)
        e = min(pos + 1, e)
        return (s, e, acc.text_range(s, e))

    # TODO: identifier_style @ `identifier_style` @ variable_style
    def _get_var_back(self, pos, acc):
        token = []
        # variable [$@]? <|>
        s, e0, w = self._get_word_back(pos, acc)
        print 'w = %r' % (w, )
        style = acc.style_at_pos(s)
        if style in self.word_styles:
            token += [ w ]
            cutoff = e0 - s
            trg_pos = s
            s, e, w = self._get_word_back(s - 1, acc)
        elif style == self.operator_style:
            cutoff = 0
            trg_pos = pos + 1

        while True:
            if w in '$@':
                s, e, w2 = self._get_word_back(s - 1, acc)
                print 'w = %r, w2 = %r' % (w, w2, )
                style = acc.style_at_pos(s)
                if style in self.word_styles:
                    token += [ w, w2 ]
                else:
                    break
            else:
                break
            s, e, w = self._get_word_back(s - 1, acc)
            if not (style == self.variable_style or self._is_bquoted(w2)):
                break

        if w in ('::', ':::'):
            s, e, w2 = self._get_word_back(s - 1, acc)
            style = acc.style_at_pos(s)
            if style == self.variable_style:
                token += [ w, w2 ]
            else:
                return None
        elif not style in ( self.identifier_style, self.keyword_style ):
            return None
        token.reverse()

        cutoff = reduce(lambda v, x: v + len(x), token, 0) - cutoff

        return (s, e0, token, cutoff, trg_pos)


    def _in_func(self, pos, acc):
        p = pos - 1
        p_min = max(0, pos - 200)
        scimoz = acc.scimoz()
        arg_count = 1
        argnames = list()
        commapos = -1
        while p > p_min:
            ch = acc.char_at_pos(p)
            if acc.style_at_pos(p) == self.string_style:
               p = acc.contiguous_style_range_from_pos(p)[0] - 1
            elif ch in ")]}":
                p = scimoz.braceMatch(p) - 1
            #elif ch in "[{":
            elif ch == "{":
                return None
            elif ch == "[":
                fn_start, fn_end, fn_word = self._get_word_back(p, acc)
                # TODO: _get_var_back ===> (s, e0, token, cutoff, trg_pos)
                start, end, word, x_, x_ = self._get_var_back(fn_start - 1, acc)
                #start, end, word = self._get_word_back(fn_start - 1, acc)
                if acc.style_at_pos(start) in self.word_styles:
                    argnames.reverse()
                    return (fn_start, p, fn_word, arg_count, argnames, ''.join(word) )
                return None
            elif ch == "(":
                # function name:
                fn_start, fn_end, fn_word = self._get_word_back(p - 1, acc)
                if acc.style_at_pos(fn_start) in self.word_styles:
                    # namespace ::[:] function:
                    start, end, op_word = self._get_word_back(fn_start - 1, acc)
                    if op_word in ('::', ':::'):
                        start, end, ns_word = self._get_word_back(start - 1, acc)
                        if acc.style_at_pos(start) == self.variable_style:
                            fn_word = ns_word + op_word + fn_word
                            fn_start = start
                    argnames.reverse()
                    return (fn_start, p, fn_word, arg_count, argnames,
                                acc.text_range(p + 1, commapos).strip()
                                    if commapos > 0 else None)
                break
            else:
                if ch == ',':
                    commapos = p
                    arg_count += 1
                elif ch == '=':
                    start, end, word = self._get_word_back(p - 1, acc)
                    if acc.style_at_pos(start) == self.variable_style:
                        argnames += [ word ]
                p1 = self._skip_back_ws(p, acc);
                if p1 == p:
                    p -= 1
                else:
                    p = p1
        return None

#u"\x03Error in formals(bb) : object 'bb' not found\r\n\x02"
#u'\x03Error in loadNamespace(name) : there is no package called \u2018pkg\u2019\r\n\x02'


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
