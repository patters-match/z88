#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Copyright 2005-2007 (C) Raster Software Vigo (Sergio Costas)
#
# This file is part of Z88Transfer
#
# Z88Transfer is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# Z88Transfer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import serial
import time

class z88access:

	def __init__(self,speed=9600,device="/dev/ttyS0",protocol="PCLINK"):
		"""Initializates the variables in the class"""

		self.protocol=protocol
		self.speed=speed
		self.serial_dev=device
		self.myserial=serial.Serial()
		self.myserial.bytesize=8
		self.myserial.parity='N'
		self.myserial.stopbits=1
		self.myserial.timeout=1
		self.myserial.xonxoff=0
		self.myserial.rtscts=1


	def check_name(self,name,isdir):
		
		allowed_letters="abcdefghijklmnopqrstuvwxyz0123456789.-"
		
		lenname=len(name)

		for letter in name.lower():
			if allowed_letters.find(letter) == -1:
				return _("The Name contains no valid characters")
		
		if (isdir and (lenname>12)):
			return _("The directory name is longer than 12 characters")
		
		if ((isdir==False) and (lenname>16)):
			return _("The filename is longer than 16 characters")
		
		if (name.count(".")>1):
			return _("Names can't contain more than one dot")
		
		pos=name.find(".")
		if (pos!=-1):
			if (pos==0):
				return _("Names can't start with a dot")
			if ((lenname-pos)>4):
				return _("The extension can't be bigger than three characters")
			if (pos>12):
				return _("The name before a dot can't be bigger than 12 characters")

		return ""


	def set_params(self,speed=9600,device="/dev/ttyS0",protocol="PCLINK"):
		self.protocol=protocol
		self.speed=speed
		self.serial_dev=device

		
	def quit(self):
		if (self.protocol=="PCLINK")|(self.protocol=="EAZYLINK"):
			if -1==self.open_serial():
				return
			self.send_char("\033")
			if (self.protocol=="PCLINK"):
				self.send_char("Q")
			else:
				self.send_char("q")
			self.receive_char()
			self.receive_char()
			self.close_serial()


	def open_serial(self):
		"""Open the serial port, sets its speed and sends the handsake string.
		If it fails, it returns -1 and closes serial port; if all goes fine, it returns 0"""

		if self.myserial.isOpen():
			self.myserial.close()
			
		self.myserial.port=self.serial_dev
		self.myserial.baudrate=self.speed
		try:
			self.myserial.open()
		except:
			return -1

		if self.protocol=="IMP-EXPORT":
			return 0
		watifor=""
		if self.protocol=="PCLINK":
			self.myserial.write("\005\005\006")
			waitfor="\006"
		if self.protocol=="EAZYLINK":	
			self.myserial.write("\001\001\002")
			waitfor="\002"
		recibido=""
		while recibido!=waitfor:
			recibido=self.myserial.read(1)
			if recibido=="":
				self.myserial.flushOutput()
				self.myserial.flushInput()
				self.myserial.close()
				return -1 # failed
		return 0


	def close_serial(self):
		self.myserial.close()


	def send_char(self,character):
		"""Sends a character over the serial line, and returns a 0 character if succesfull"""
		self.myserial.write(character)
		if (self.protocol=="PCLINK"):
			received=self.myserial.read(1)
			if received=="\000":
				return 0
			else:
				return -1
		return 0


	def receive_char(self):
		"""Receives a character over the serial line, and returns it, or "" if there's an error"""
		received=self.myserial.read(1)
		if (received!="") & (self.protocol=="PCLINK"):
			self.myserial.write("\000")
		return received


	def receive_list_names(self,tipo):
		lista=[]
		modo=0
		cadena=""
		while True:
			caracter=self.receive_char()
			if caracter=="": # error receiving
				return []
			if modo==0:
				if caracter=="\033":
					modo=1
				if (caracter=="/") | (caracter=="\\"):
					cadena=""
			elif modo==1:
				if caracter=="N":
					if cadena!="":
						lista.append([cadena,tipo])
						cadena=""
					modo=2
				elif caracter=="Z":
					lista.append([cadena,tipo])
					return lista
			elif modo==2:
				if caracter=="\033":
					modo=1
				elif (caracter=="/") | (caracter=="\\"):
					cadena=""
				else:
					cadena=cadena+caracter


	def send_string(self,the_string):
		for char in the_string:
			received=self.send_char(char)
			if received!=0:
				return -1
		return 0

	
	def hello(self):
		if -1==self.open_serial():
			return -1
		self.send_char("\033")
		if self.protocol=="EAZYLINK":
			self.send_char("a")
		else:
			self.send_char("A")
		c1=self.receive_char()
		if c1=="":
			self.close_serial()
			return -2
		c2=self.receive_char()
		self.close_serial()
		if c2=="":
			return -2
		if (c1=="\033") & (c2=="Y"):
			return 0
		else:
			return -3


	def create_folder(self,namefolder):
		if self.protocol!="EAZYLINK":
			return -1
		
		if -1==self.open_serial():
			return -1
		
		self.send_char("\033")
		self.send_char("y")
		self.send_string(namefolder)
		self.send_char("\033")
		self.send_char("Z")
		c1=self.receive_char()
		c2=self.receive_char()
		if (c1!="\033") or (c2!="Y"):
			return -1
		else:
			return 0

		
	def delete_file(self,filename):
		if self.protocol!="EAZYLINK":
			return -1
		
		if -1==self.open_serial():
			return -1
		
		self.send_char("\033")
		self.send_char("r")
		self.send_string(filename)
		self.send_char("\033")
		self.send_char("Z")
		c1=self.receive_char()
		c2=self.receive_char()
		if (c1!="\033") or (c2!="Y"):
			return -1
		else:
			return 0


	def file_size(self,filename):
		if self.protocol!="EAZYLINK":
			return -1
		
		if -1==self.open_serial():
			return -1
		
		self.send_char("\033")
		self.send_char("x")
		self.send_string(filename)
		self.send_char("\033")
		self.send_char("Z")
		size = ""
		while True:
			c1 = self.receive_char()
			if c1 == "":
				return -1
			if c1 == "\033":
				c1 = self.receive_char()
				if c1 == "":
					return -1
				if c1 == "Z":
					break
			else:
				size += c1
		if size == "":
			return -1
		
		try:
			retval = int(size)
		except:
			retval = -1

		return retval

	
	def rename_file(self,filename,newfilename):
		if self.protocol!="EAZYLINK":
			return -1
		
		if -1==self.open_serial():
			return -1
		
		self.send_char("\033")
		self.send_char("w")
		self.send_string(filename)
		self.send_char("\033")
		self.send_char("N")
		self.send_string(newfilename)
		self.send_char("\033")
		self.send_char("Z")
		c1=self.receive_char()
		c2=self.receive_char()
		if (c1!="\033") or (c2!="Y"):
			return -1
		else:
			return 0

	
	def disable_conversion(self):
		if self.protocol!="EAZYLINK":
			return 0
		if -1==self.open_serial():
			return -1
		self.send_char("\033")
		self.send_char("T") # disable translation
		self.close_serial()
		if -1==self.open_serial():
			return -1
		self.send_char("\033")
		self.send_char("C") # disable line-feed conversion
		self.close_serial()
		return 0


	def get_free_mem(self,drive):
		if self.protocol!="EAZYLINK":
			return -1
		if -1==self.open_serial():
			return -1
		
		if (drive!="0") and (drive!="1") and (drive!="2") and (drive!="3") and (drive!="-"):
			return -1
		self.send_char("\033")
		self.send_char("M")
		self.send_char(drive)
		self.send_char("\033")
		self.send_char("Z")
		c1=self.receive_char()
		if (c1=="") or (c1!="\033"):
			self.close_serial()
			return -1
		c1=self.receive_char()
		if (c1=="") or (c1!="N"):
			self.close_serial()
			return -1
		cadena=""
		while True:
			c1=self.receive_char()
			if c1=="\033":
				break
			cadena+=c1
		c1=self.receive_char()
		return int(cadena)

		
	def setclock(self,thedate,thetime):
		if self.protocol!="EAZYLINK":
			return -1
		if -1==self.open_serial():
			return -1
		
		self.send_char("\033")
		self.send_char("p")
		self.send_string(thedate)
		self.send_char("\033")
		self.send_char("N")
		self.send_string(thetime)
		self.send_char("\033")
		self.send_char("Z")
		time.sleep(1)
		c1=self.receive_char()
		c2=self.receive_char()
		if (c1!="\033") or (c2!="Y"):
			return -1
		else:
			return 0


	def get_devices(self):
		if -1==self.open_serial():
			return []
		self.send_char("\033")
		if self.protocol=="EAZYLINK":
			self.send_char("h")
		else:
			self.send_char("H")
		salida=self.receive_list_names("DEV")
		self.close_serial()
		return salida


	def get_directories(self,path):
		if -1==self.open_serial():
			return []
		if path[-1]=="*":
			path=path[:-1]
		if path[-1]!="/":
			path=path+"/"
		self.send_char("\033")
		if self.protocol=="EAZYLINK":
			self.send_char("d")
		else:
			self.send_char("D")
		self.send_string(path)
		if self.protocol=="EAZYLINK":
			self.send_char("*")
		self.send_char("\033")
		self.send_char("Z")
		salida=self.receive_list_names("DIR")
		self.close_serial()
		return salida


	def get_files(self,path):
		if -1==self.open_serial():
			return []
		if path[-1]=="*":
			path=path[:-1]
		if path[-1]!="/":
			path=path+"/"
		self.send_char("\033")
		if self.protocol=="EAZYLINK":
			self.send_char("n")
		else:
			self.send_char("N")
		self.send_string(path)
		if self.protocol=="EAZYLINK":
			self.send_char("*")
		self.send_char("\033")
		self.send_char("Z")
		salida=self.receive_list_names("FILE")
		self.close_serial()
		return salida


	def get_content(self,path):
		"""Gets all the files and directories from a global path that starts in '/' """
		if path=="":
			path="/"
		elif path[-1]!="/":
			path=path+"/"

		if path=="/":
			return self.get_devices()
		else:
			if path[0]=="/":
				path=path[1:]
			lista=self.get_directories(path)
			if lista==[]:
				return []
			lista2=self.get_files(path)
			if lista2==[]:
				return []
			return lista+lista2


	def receive_file(self,path):
		
		"""Starts the reception of a file"""
		
		if (self.protocol=="IMP-EXPORT"):
			self.myserial.timeout=30
		
		if -1==self.open_serial():
			self.myserial.timeout=1
			return -1
		
		if (self.protocol=="IMP-EXPORT"):
			name=""
			error=0
			while True:
				caracter=self.receive_char()
				if caracter=="":
					error=1
					break
				elif caracter=="\033":
					esc_char=self.receive_char()
					if (esc_char==""):
						error=1
						break
					elif (esc_char=="F"):
						break
				else:
					name+=caracter
			self.myserial.timeout=1
			if error==0:
				return name
			else:
				return ""
		else:
			self.send_char("\033")
			if (self.protocol=="EAZYLINK"):
				self.send_char("s")
			else:
				self.send_char("G")
			self.send_string(path)
			self.send_char("\033")
			self.send_char("Z")	
			return 0


	def send_file(self,path):
		"""Starts the sending of a file"""
		if -1==self.open_serial():
			return -1
		if (self.protocol!="IMP-EXPORT"):
			self.send_char("\033")
			if (self.protocol=="EAZYLINK"):
				self.send_char("b")
			else:
				self.send_char("S")
		self.send_char("\033")
		self.send_char("N")
		self.send_string(path)
		self.send_char("\033")
		self.send_char("F")
		return 0


	def invert_hexa(self,char):
		v=ord(char)
		v1=(v>>4)&15
		v2=v&15
		if v1<10:
			v1=chr(v1+48)
		else:
			v1=chr(v1+55)
		if v2<10:
			v2=chr(v2+48)
		else:
			v2=chr(v2+55)
		return v1,v2


	def send_byte_file(self,charac):

		if charac=="": # end of file
			self.send_char("\033")
			self.send_char("E")
			if self.protocol!="IMP-EXPORT":
				self.send_char("\033")
				self.send_char("Z")
			self.close_serial()
			return 0
		if (ord(charac)>31) & ((ord(charac)<128)|(self.protocol!="IMP-EXPORT")):
				if 0==self.send_char(charac):
					return 0
				else:
					self.close_serial()
				return -1
		else:
			if (self.protocol=="PCLINK")|(self.protocol=="IMP-EXPORT"):
				if 0!=self.send_char("\033"):
					self.close_serial()
					return -1
				if 0!=self.send_char("B"):
					self.close_serial()
					return -1
				v1,v2=self.invert_hexa(charac)
				if 0!=self.send_char(v1):
					self.close_serial()
					return -1
				if 0==self.send_char(v2):
					return 0
				else:
					self.close_serial()
					return -1
			else: # EAZYLINK
				if charac=="\033":
					if 0!=self.send_char("\033"):
						self.close_serial()
						return -1
					if 0==self.send_char("\033"): # two ESCs
						return 0
					else:
						self.close_serial()
						return -1
				else:
					if 0==self.send_char(charac):
						return 0
					else:
						self.close_serial()
						return -1


	def hexa(self,carac):
		v=ord(carac)
		if v>64:
			v-=55
		else:
			v-=48
		return v


	def receive_byte_file(self):
		"""Receives one byte of the current receiving file and returns it"""
		while True:
			status,caracter=self.receive_byte_file_middle()
			if ((status==0)|(status==-1)):
				break
			if (status==1):
				if caracter=="N":
					while ((status!=1)|(caracter!="F")): # jump over filename
						status,caracter=self.receive_byte_file_middle()
				if caracter=="E":
					return 0,""
		return status,caracter


	def receive_byte_file_middle(self):
		"""Receives one byte of the current receiving file and returns it"""

		value=self.receive_char()
		if value=="": # no char received
			self.close_serial()
			return -1,""

		if value!="\033":
			return 0,value

		value=self.receive_char()
		if value=="": # no char received
			self.close_serial()
			return -1,""

		if (value=="E"): # end of file
			return 1,"E"
		
		elif (value=="Z"): # end of file
			self.close_serial()
			return 0,""

		elif value=="\033":
			return 0,"\033"

		elif value=="B":
			value=self.receive_char()
			if value=="": # no char received
				self.close_serial()
				return -1,""
			value2=self.receive_char()
			if value2=="": # no char received
				self.close_serial()
				return -1,""
			return 0,chr(self.hexa(value2)+16*self.hexa(value))
		elif value=="N": # filename
			return 1,"N"
		elif value=="F": # file start
			return 1,"F"
		else:
			print "ESC sequence extrange "+str(ord(value))
			return 0," "
