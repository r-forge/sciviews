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


## This is interface for communication with R through socket connection

from xpcom import components, nsError, COMException
from xpcom._xpcom import getProxyForObject, PROXY_SYNC, PROXY_ALWAYS, PROXY_ASYNC
import os, sys, re
import string
from xpcom.server.enumerator import SimpleEnumerator
import socket
import threading
import logging
log = logging.getLogger('svUtils')
#log.setLevel(logging.INFO)
log.setLevel(logging.DEBUG)


class svUtils:
	_com_interfaces_ = [components.interfaces.svIUtils]
	_reg_desc_ = "SciViews-K utilities"
	_reg_clsid_ = "{5f82d460-37b6-11e0-b897-0002a5d5c51b}"
	_reg_contractid_ = "@sciviews.org/svUtils;1"

	def __init__(self):
		observerSvc = components.classes["@mozilla.org/observer-service;1"].\
			getService(components.interfaces.nsIObserverService)

		self._proxiedObsSvc = getProxyForObject(1, \
			components.interfaces.nsIObserverService, \
			observerSvc, PROXY_ALWAYS | PROXY_SYNC)

		self.lastCommand = u''
		self.lastResult = u''
		self.id = 'svpy'
		self.runServer = False
		self.serverIsUp = False
		pass


	def execFun(self, stuffLlistener):
		listenerProxy = getProxyForObject(1,
			components.interfaces.svIStuffListener,
			stuffLlistener, PROXY_ALWAYS | PROXY_SYNC)
		ret = listenerProxy.onStuff("test 123")
		return ret

	def execFunInBgr(self, requestHandler):
		t = threading.Thread(target=self._doExecFn, kwargs={
			'requestHandler': requestHandler
			})
		t.start()

	def _doExecFn(self, requestHandler):
		listenerProxy = getProxyForObject(1,
			components.interfaces.svIStuffListener,
			requestHandler, PROXY_ALWAYS | PROXY_SYNC)
		listenerProxy.onStuff("test 12345...")

	def _asSString(self, s):
		ret = components.classes["@mozilla.org/supports-string;1"] \
			.createInstance(components.interfaces.nsISupportsString)
		ret.data = str(s)
		return(ret)

	def getproc(self, propertyName):
#		TODO: error handling here
#		TODO: checking for correct propertyName, return several properties at a time
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


	def execInR(self, command, host, port, mode):
		s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		s.settimeout(.5) # increase if not localhost
		try:
			s.connect((host, port))
		except BaseException, e:
			return unicode(e.args[0]);

		# TODO: allow for <<<h>>>
		s.send('<<<id=' + self.id + '>>><<<' + mode + '>>>' + command)
		s.shutdown(socket.SHUT_WR) # does not work without shutdown, why?
		result = ''
		while True:
			data = s.recv(1024)
			if not data: break
			result += data
		s.close()
		return unicode(result)

	def execInRBgr(self, command, host, port, mode):
		t = threading.Thread(target=self.rconnect, args=(command, host, port, mode))
		#t.daemon = True
		t.start()

	def rconnect(self, command, host, port, mode):
		self.lastCommand = unicode(command)
		s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		s.connect((host, port))
		s.settimeout(None)
		s.send('<<<id=' + self.id + '>>><<<' + mode + '>>>' + command)
		s.shutdown(socket.SHUT_WR) # does not work without shutdown, why?
		result = ''
		# notify after each chunk and at the end
		while 1:
			data = s.recv(1024)
			if not data: break
			self._proxiedObsSvc.notifyObservers(None, 'r-command-chunk', data)
			result += data
		s.close()
		self.lastResult = unicode(result)
		self._proxiedObsSvc.notifyObservers(None, 'r-command-executed', result)
		#try:
		#self._proxiedObsSvc.notifyObservers(None, 'r-command-executed', result)
		#except Exception:
			#log.exception("r-command-executed notification failed")

	def startSocketServer(self, host, port, requestHandler):
		# TODO: do not run two! use semaphore
		if(self.serverIsUp): return False
		self.runServer = True
		t = threading.Thread(target=self._SocketServer, kwargs={
			'host': host,
			'port': port,
			'requestHandler': requestHandler
			})
		t.start()
		log.debug('Started socket server at port %d' % port)
		return True

	def stopSocketServer(self):
		self.runServer = False
		log.debug('Told socket server to stop')


	def _SocketServer(self, host, port, requestHandler):
		# requestHandler is a Javascript object with component 'onStuff'
		# which is a function accepting one argument (string), and returning
		# a string
		requestHandlerProxy = getProxyForObject(1,
			components.interfaces.svIStuffListener,
			requestHandler, PROXY_ALWAYS | PROXY_SYNC)
		s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		s.settimeout(5)
		try:
			s.bind((host, port))
		except Exception, e:
			log.exception(e)
			return
		self.serverIsUp = True
		s.listen(1)
		log.debug('Socket server listening at %d' % port)
		count = 0
		connected = False
		while self.runServer:
			while self.runServer:
				connected = False
				try:
					conn, addr = s.accept()
					connected = True
					conn.setblocking(1)
					count += 1
					break
				except Exception, e:
					#print(e)
					continue
			if not connected: continue
			data_all = ''
			while connected:
				log.debug('Connected by %s : %d' % addr)
				data = conn.recv(1024)
				data_all += data
				if (not data) or (data[-1] == '\n'): break
			#print "Sending:", data_all + "."
			## Process data here
			#result = data_all # echo request
			#unicode(data_all) ?????
			try:
				result = requestHandlerProxy.onStuff(data_all)
			except BaseException, e:
				result = e.args[0]
				log.debug('JS request exception: %s' % result)
			if (result == None): conn.send('\n')
			else: conn.send(result + '\n')
			conn.shutdown(socket.SHUT_RDWR)
			conn.close()
			log.debug('conn closed')
		#s.shutdown(socket.SHUT_RDWR) #  Is it necessarry?
		s.close()
		self.serverIsUp = False
		log.debug("Exiting after %d connections" % count)
		pass


#    conn.setblocking(1)
#  File "<string>", line 1, in setblocking
#  File "/home/kamil/Komodo-Edit-6/lib/python/lib/python2.6/socket.py", line 165, in _dummy
#    raise error(EBADF, 'Bad file descriptor')
#error: [Errno 9] Bad file descriptor


	#def Run(self, command, env, console):
	#	pass
	#
	#def _WaitNotifyAndCleanUp(self, child, command, scriptFileName=None):
