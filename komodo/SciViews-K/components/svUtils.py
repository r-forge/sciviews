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
#import tempfile
import string
#import process
#import koprocessutils
from xpcom.server.enumerator import SimpleEnumerator
import socket
#from threading import Thread
import threading


import logging
log = logging.getLogger('svUtils')

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
		pass

	def _asSString(self, s):
		ret = components.classes["@mozilla.org/supports-string;1"] \
			.createInstance(components.interfaces.nsISupportsString)
		ret.data = str(s)
		return(ret)

	def getproc(self, propertyName):
#		TODO: error handling here
#		TODO: checking for correct propertyName
		ret = []
		if sys.platform.startswith('win'):
			from win32com.client import GetObject
			WMI = GetObject('winmgmts:')
			processes = WMI.ExecQuery('select ' + propertyName + \
				' from Win32_Process where Name="Rgui.exe" or Name="R.exe" or Name="Rterm.exe"')
			if len(processes) > 0 :
				for p in processes:
					#ret.append([p.Properties_('Name').Value, p.Properties_('ProcessId').Value])
					##ret.append(p.Properties_('ExecutablePath').Value) 'CommandLine'
					elem = components.classes["@mozilla.org/supports-string;1"] \
						.createInstance(components.interfaces.nsISupportsString)
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


	def execInR(self, command, host, port):
		"""
		This should send command to R through a socket connection and return the
		output
		"""
		s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		s.connect((host, port))
		s.settimeout(5)
		# TODO: allow for <<<h>>>
		s.send('<<<id=SciViewsK>>><<<e>>>' + command)
		s.shutdown(socket.SHUT_WR) # does not work without shutdown, why?
		result = ''
		while 1:
			data = s.recv(1024)
			if not data: break
			result += data
		s.close()
		return unicode(result)

	def execInRBgr(self, command, host='localhost', port=8888):
		t = threading.Thread(target=self.rconnect, args=(command, host, port))
		#t.setDaemon(True)
		t.start()

	def rconnect(self, command, host, port):
		self.lastCommand = unicode(command)
		s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		s.connect((host, port))
		s.settimeout(None)
		s.send('<<<id=SciViewsK>>><<<e>>>' + command)
		s.shutdown(socket.SHUT_WR) # does not work without shutdown, why?
		result = ''
		# notify after each chunk, and at the end
		while 1:
			data = s.recv(1024)
			if not data: break
			self._proxiedObsSvc.notifyObservers(None, 'r-command-chunk', data)
			result += data
		self._proxiedObsSvc.notifyObservers(None, 'r-command-finished', result)
		s.close()
		self.lastResult = unicode(result)
		#try:
		self._proxiedObsSvc.notifyObservers(None, 'r-command-executed', result)
		#except Exception:
			#log.exception("r-command-executed notification failed")
