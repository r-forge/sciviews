# Example R client
import socket, os, sys, re, string

#s.send("1:100\r\n")

def conn1(port):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(1)
    s.connect(('localhost', port))
    return s

#data = s.recv(1024)
#s.shutdown(socket.SHUT_WR)
#data = s.recv(1024)
# s.close()
#s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
