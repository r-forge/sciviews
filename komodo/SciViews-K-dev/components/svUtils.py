#!python
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
# Author:
# Kamil Barton <kamil.barton@go2.pl>

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


## This is an interface for communication with R through socket connection
## and additional utilities

from xpcom import components, nsError, COMException
from xpcom._xpcom import getProxyForObject, PROXY_SYNC, PROXY_ALWAYS, PROXY_ASYNC
from xpcom.server import WrapObject #, UnwrapObject
import os, sys, re
import string
from xpcom.server.enumerator import SimpleEnumerator
import socket
import threading
import json
from uuid import uuid1
import logging
log = logging.getLogger('svUtils')
#log.setLevel(logging.INFO)
log.setLevel(logging.DEBUG)


def _makeStyledText(text, styles = {chr(2): chr(0), chr(3): chr(23)},
    curStyle = chr(0)):
    ctrlChars = styles.keys()
    text8 = text.encode('utf-8')
    #curStyle = styles.values()[0]
    ret = u''
    for ch in text8:
        if ch in ctrlChars:
            curStyle = styles[ch]
            log.debug(ord(ch))
        else:
            ret += ch + curStyle
    return ret


class svUtils:
    _com_interfaces_ = [components.interfaces.svIUtils]
    _reg_desc_ = "SciViews-K utilities"
    _reg_clsid_ = "{22A6C234-CC35-D374-2F01-FD4C605C905C}"
    _reg_contractid_ = "@sciviews.org/svUtils;1"

    def __init__(self):
        observerSvc = components.classes["@mozilla.org/observer-service;1"].\
            getService(components.interfaces.nsIObserverService)

        self._proxiedObsSvc = getProxyForObject(1, \
            components.interfaces.nsIObserverService, \
            observerSvc, PROXY_ALWAYS | PROXY_SYNC)

        self.lastCommand = u''
        self.lastResult = u''
        self.lastMessage = u''
        self.runServer = False
        self.socketOut = ('localhost', 8888L)
        self.socketIn = ('localhost', 7777L)
        self.serverConn = None
        #self.myUID = uuid1().hex
        #self.id = 'sv'
        pass

    class _CommandInfo:
        _com_interfaces_ = components.interfaces.svICommandInfo
        def __init__(self, cmd_id, cmd, mode, message = '', result = ''):
            self.commandId = cmd_id
            self.command = cmd
            self.mode = mode
            self.message = message
            self.result = result
        def styledResult(self):
            return _makeStyledText(self.result)


    def makeStyledText(self, text):
        return _makeStyledText(text)

    def setSocketInfo(self, host, port, outgoing):
        log.debug("setSocketInfo (%s): %s:%d" % ('outgoing' if outgoing else 'incoming', host, port))
        if outgoing: self.socketOut = (host, port)
        else: self.socketIn = (host, port)
        pass

    def _asSString(self, s):
        ret = components.classes["@mozilla.org/supports-string;1"] \
            .createInstance(components.interfaces.nsISupportsString)
        ret.data = unicode(s)
        return(ret)

    def _asSInt(self, n):
        ret = components.classes["@mozilla.org/supports-PRInt32;1"] \
            .createInstance(components.interfaces.nsISupportsPRInt32);
        ret.data = long(n)
        return(ret)

    def getproc(self, propertyName):
#       TODO: error handling here
#       TODO: checking for correct propertyName, return several properties at a time
        ret = []
        if sys.platform.startswith('win'):
            from win32com.client import GetObject
            WMI = GetObject('winmgmts:')
            processes = WMI.ExecQuery('select ' + propertyName + \
                ' from Win32_Process where Name="Rgui.exe" or Name="R.exe" or Name="Rterm.exe"')
            if len(processes) > 0 :
                for p in processes:
                    ret.append(p.Properties_(propertyName).Value)
        else:
            propertyName = {
                'Handle': 'pid',
                'ProcessId': 'pid',
                'CommandLine': 'cmd'
                }[propertyName]

            import subprocess
            ret = subprocess.Popen(['ps', '--no-header', '-o', propertyName, '-C', 'R'],
                stdout=subprocess.PIPE).communicate()[0].split("\n")
            ret = [el for el in ret if el != '']

        ret = map(self._asSString, ret);
        return SimpleEnumerator(ret)

    def execInR(self, command, mode, timeout = .5):
        return self.rconnect(command, mode, False, timeout, self.uid())

    def execInRBgr(self, command, mode, uid):
        log.debug("execInRBgr: %s..." % command[0:10])
        t = threading.Thread(target=self.rconnect, args=(command, mode, True, None, uid))
        t.daemon = True
        t.start()

    def rconnect(self, command, mode, notify, timeout, uid):
        pretty_command = self.pushLeft(command, indent=3L, eol='\n', tabwidth=4)[3:]
        self.lastCommand = unicode(command)
        ssLastCmd = self._asSString(command)
        log.debug("rconnect: %s... (%d)" % (command[0:10], notify))

        modeArr = mode.split(' ')
        useJSON = modeArr.count('json')

        s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        s.settimeout(timeout)
        try: s.connect(self.socketOut)
        except Exception, e: return unicode(e.args[0])

        cmdInfo = self._CommandInfo(uid, pretty_command, mode, 'Not ready')

        #wrappedCmdInfo = WrapObject(cmdInfo, components.interfaces.svICommandInfo)
        if notify:
            self._proxiedObsSvc.notifyObservers(
                WrapObject(cmdInfo, components.interfaces.svICommandInfo),
                'r-command-sent', None)


        rMode = 'h' if modeArr.count('h') else 'e'

        if useJSON:
            command = '\x01' \
                + rMode \
                + '<' + uid + '>' \
                + command.replace("\\", "\\\\"). \
                replace("\n", "\\n").replace("\r", "\\r").replace("\f", "\\f")
        else:
            command = '<<<id=' + uid + '>>><<<' + mode + '>>>' + \
                re.sub("(\r?\n|\r)", '<<<n>>>', command)
            #command.replace(os.linesep,  '<<<n>>>')
        s.send(command + os.linesep)
        ## SOLVED: command must end with newline
        ## TODO: replace all newlines by R
        s.shutdown(socket.SHUT_WR)
        result = u''
        try:
            while True:
                data = s.recv(1024L)
                if not data: break
                if notify:
                    #self._proxiedObsSvc.notifyObservers(cmdInfo, 'r-command-chunk', data)
                    self._proxiedObsSvc.notifyObservers(
                        WrapObject(cmdInfo, components.interfaces.svICommandInfo),
                        'r-command-chunk', data)
                result += unicode(data)
        except Exception, e:
            log.debug(e)
            pass
        s.close()
        result = result.rstrip()
        message = ''
        if useJSON:
            # Fix bad JSON: R escapes nonprintable characters as octal numbers
            # (\OOO), but json needs unicode notation (\uHHHH).
            result = re.sub('(?<=\\\\)[0-9]{3}', lambda x: ("u%04x" % int(x.group(0), 8)), result)
            try:
                resultObj = json.loads(result)
                if(isinstance(resultObj, dict)):
                    if (resultObj.has_key('message')): message = resultObj['message']
                    if (resultObj.has_key('result')):
                        if isinstance(resultObj['result'], list):
                            result = os.linesep.join(resultObj['result'])
                        else: # isinstance(x, unicode)
                            result = resultObj['result']
                            #log.debug(type(result)) # <-- should be: <type 'unicode'>
                            #log.debug(result)
                    cmdInfo.message = unicode(message)
                    cmdInfo.result = unicode(result)

            except Exception, e:
                log.debug(e)

        if notify:

            #self._proxiedObsSvc.notifyObservers(cmdInfo, 'r-command-executed',
            #                                    result)

            self._proxiedObsSvc.notifyObservers(
                WrapObject(cmdInfo, components.interfaces.svICommandInfo),
                'r-command-executed',
                result)

            log.debug("rconnect notify: %s..." % result[0:10])
            return
        log.debug("rconnect return: %s..." % result[0:10])
        self.lastMessage = message
        self.lastResult = result
        return unicode(result)


#  File "components\svUtils.py", line 126, in execInR
#    return self.rconnect(command, mode, False, .5, "")
#  File "components\svUtils.py", line 153, in rconnect
#    data = s.recv(1024)
#timeout: timed out

    def __del__(self):
        try:
            log.debug("destructor called: closing server")
            self.serverConn.close()
        except:
            pass

    def serverIsUp(self):
        try:
            self.serverConn.fileno()
            return True
        except:
            return False

    def startSocketServer(self, requestHandler):
        if(self.serverIsUp()): return -1L
        self.runServer = True
        host = self.socketIn[0L]
        port = self.socketIn[1L]
        if(port > 70000L): port = 10000L
        port_max = port + 32L
        while port < port_max:
            try:
                self.serverConn = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                self.serverConn.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 0)
                self.serverConn.settimeout(5)
                log.debug('trying socket (%s, %d) ' % (host, port))
                self.serverConn.bind((host, port))
                break
            except Exception, e:
                log.error(e.args)   # ERROR 10048, ERROR 98: Address already in use
                self.serverConn.close()
                port += 1L
        if (port >= port_max): return 0L # TODO: fix this
        self.socketIn = (host, port)
        log.debug('startSocketServer: starting thread')
        t = threading.Thread(target=self._Serve,
                             kwargs={ 'requestHandler': requestHandler })
        t.start()
        log.debug('Serving on port %d' % port)
        self._proxiedObsSvc.notifyObservers(self._asSInt(port), 'r-server-started', None)
        return port

    def stopSocketServer(self):
        try:
            self.serverConn.close()
        except:
            pass
        self.runServer = False
        log.debug('Told socket server to stop')

    def _Serve(self, requestHandler):
        # requestHandler is a Javascript object with component 'onStuff'
        # which is a function accepting one argument (string), and returning
        # a string
        requestHandlerProxy = getProxyForObject(1L,
            components.interfaces.svIStuffListener,
            requestHandler, PROXY_ALWAYS | PROXY_SYNC)
        try:
            self.serverConn.listen(1)
            log.debug('Socket server listening at %d' % self.socketIn[1])
            count = 0
            connected = False
            while self.runServer:
                while self.runServer and self.serverIsUp():
                    connected = False
                    try:
                        conn, addr = self.serverConn.accept()
                        connected = True
                        conn.setblocking(1)
                        self.serverConn.settimeout(10)
                        count += 1L
                        break
                    except Exception: continue
                if not connected: continue
                data_all = ''
                try:
                    while connected:
                        log.debug('Connected by %s : %d' % addr)
                        data = conn.recv(1024L)  # TODO: error: [Errno 10054]
                        data_all += data
                        if (not data) or (data[-1] == '\n'): break
                except Exception, e:
                    log.error(e.args)
                    conn.close()
                    break
                conn.shutdown(socket.SHUT_RD)
                log.debug('conn finished reading')
                try:
                    result = requestHandlerProxy.onStuff(data_all)
                except Exception, e:
                    result = e.args[0]
                    log.debug('JS request exception: %s' % result)
                if (result == None): conn.send('\n')
                else: conn.send(result + '\n')
                conn.shutdown(socket.SHUT_RDWR)
                conn.close()
                log.debug('conn closed')
        except Exception, e:
            log.debug(e.args)
        self.stopSocketServer()
        #self.serverConn.close()
        log.debug("Exiting after %d connections" % count)
        try:
            self._proxiedObsSvc.notifyObservers(None, 'r-server-stopped', None)
        except Exception, e:
            log.debug(e)
            pass
        pass

    #import string, re, os, sys
    def pushLeft(self, text, eol=os.linesep, indent=0, tabwidth = 4):
        text = text.lstrip("\r\n\f")
        if not text: return ''
        re_line = re.compile('(^[\t ]*)(?=\S)(.*$)', re.MULTILINE)
        if type(indent) in (str, unicode):
           indentstr = indent
           indent = len(indentstr)
        else:
           indentstr = ' ' * indent
        lines = re.findall(re_line, text)
        indent_len = map(lambda line: len(string.expandtabs(line[0], tabwidth)), lines)
        ## XXX: indent_len = [ len(string.expandtabs(line[0], tabwidth)) for line in lines ]
        baseind = min(indent_len)
        if (baseind == 0 and indent == 0): return text
        return eol.join(map(lambda nspaces, line: \
                indentstr + (' ' * (nspaces - baseind)) + \
                line[1], indent_len, lines))

    def _get_code_frag(self, scimoz):
        # Get sensible code fragment
        cur_pos = scimoz.currentPos
        cur_line = scimoz.lineFromPosition(cur_pos)
        pos_start = scimoz.positionFromLine(scimoz.getFoldParent(cur_line))
        pos_end = max(scimoz.anchor, cur_pos)
        text = scimoz.getTextRange(pos_start, pos_end)
        return text

    def uid(self):
        return(uuid1().hex)

    def complete(self, text):
        kvSvc = components.classes["@activestate.com/koViewService;1"] \
            .getService(components.interfaces.koIViewService)
        try: scimoz = kvSvc.currentView.document.getView().scimoz
        except: return

        text = self._get_code_frag(scimoz)

        if not text.strip(): return
        cmd = 'completion("%s", print=TRUE, types="scintilla", field.sep="?")' \
            % text.replace('"', '\\"')
        autoCstring = self.execInR(cmd, "h") \
            .replace('\x03', '').replace('\x02', '')

        if (re.search("^\d+[\r\n]", autoCstring) == None): return
        #scimoz.autoCSeparator = 9
        #scimoz.autoCSetFillUps(" []{}<>/():;%+-*@!\t\n\r=$`")
        #autoCSeparatorChar = chr(ke.autoCSeparator)
        if not autoCstring: return
        autoCstring = re.split("[\r\n]+", autoCstring.replace('\r\n', \
            chr(scimoz.autoCSeparator)), 1)
        trigLen = int(autoCstring[0])
        autoCstring = autoCstring[1]

        #if trigLen == len(text): trigLen = 0
        #scimoz.autoCChooseSingle = false
        #Delta = scimoz.anchor - pos_end
        #if Delta >= 0 and Delta < 5:
        scimoz.autoCShow(trigLen, autoCstring)
        return

    def calltip(self, text):
        kvSvc = components.classes["@activestate.com/koViewService;1"] \
            .getService(components.interfaces.koIViewService)
        try: scimoz = kvSvc.currentView.document.getView().scimoz
        except: return

        text = self._get_code_frag(scimoz)

        cmd = 'cat(callTip("%s", location=TRUE, description=TRUE, methods=TRUE, width=80))' \
            % text.replace('"', '\\"')
        result = self.execInR(cmd, "h") \
            .replace('\x03', '').replace('\x02', '')
        scimoz.callTipCancel()
        scimoz.callTipShow(scimoz.anchor, result.replace('[\r\n]+', '\n'))
        return

    def escape(self):
        self.execInR('invisible()', 'esc')
        pass
