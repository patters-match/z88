#!/usr/bin/python
# -*- coding: UTF-8 -*-

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

import serial
import time

class z88access:

	def __init__(this,speed=9600,device="/dev/ttyS0",protocol="PCLINK"):
		"""Initializates the variables in the class"""

		this.protocol=protocol
		this.speed=speed
		this.serial_dev=device
		this.myserial=serial.Serial()
		this.myserial.bytesize=8
		this.myserial.parity='N'
		this.myserial.stopbits=1
		this.myserial.timeout=1
		this.myserial.xonxoff=0
		this.myserial.rtscts=1

	def set_params(this,speed=9600,device="/dev/ttyS0",protocol="PCLINK"):
		this.protocol=protocol
		this.speed=speed
		this.serial_dev=device
		
	def quit(this):
		if (this.protocol=="PCLINK")|(this.protocol=="EAZYLINK"):
			if -1==this.open_serial():
				return
			this.send_char("\033")
			if (this.protocol=="PCLINK"):
				this.send_char("Q")
			else:
				this.send_char("q")
			this.receive_char()
			this.receive_char()
			this.close_serial()

	def open_serial(this):
		"""Open the serial port, sets its speed and sends the handsake string.
		If it fails, it returns -1 and closes serial port; if all goes fine, it returns 0"""

		if this.myserial.isOpen():
			this.myserial.close()
		this.myserial.port=this.serial_dev
		this.myserial.baudrate=this.speed
		this.myserial.open()
		if this.protocol=="IMP-EXPORT":
			return 0
		watifor=""
		if this.protocol=="PCLINK":
			this.myserial.write("\005\005\006")
			waitfor="\006"
		if this.protocol=="EAZYLINK":	
			this.myserial.write("\001\001\002")
			waitfor="\002"
		recibido=""
		while recibido!=waitfor:
			recibido=this.myserial.read(1)
			if recibido=="":
				this.myserial.close()
				return -1 # failed
		return 0

	def close_serial(this):
		this.myserial.close()

	def send_char(this,character):
		"""Sends a character over the serial line, and returns a 0 character if succesfull"""
		this.myserial.write(character)
		if (this.protocol=="PCLINK"):
			received=this.myserial.read(1)
			if received=="\000":
				return 0
			else:
				return -1
		return 0

	def receive_char(this):
		"""Receives a character over the serial line, and returns it, or "" if there's an error"""
		received=this.myserial.read(1)
		if (received!="") & (this.protocol=="PCLINK"):
			this.myserial.write("\000")
		return received

	def receive_list_names(this,tipo):
		lista=[]
		modo=0
		cadena=""
		while True:
			caracter=this.receive_char()
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


	def send_string(this,the_string):
		for char in the_string:
			received=this.send_char(char)
			if received!=0:
				return -1
		return 0
	
	def hello(this):
		if -1==this.open_serial():
			return -1
		this.send_char("\033")
		if this.protocol=="EAZYLINK":
			this.send_char("a")
		else:
			this.send_char("A")
		c1=this.receive_char()
		if c1=="":
			this.close_serial()
			return -2
		c2=this.receive_char()
		this.close_serial()
		if c2=="":
			return -2
		if (c1=="\033") & (c2=="Y"):
			return 0
		else:
			return -3

	def create_folder(this,namefolder):
		if this.protocol!="EAZYLINK":
			return -1
		if -1==this.open_serial():
			return -1
		this.send_char("\033")
		this.send_char("y")
		this.send_string(namefolder)
		this.send_char("\033")
		this.send_char("Z")
		c1=this.receive_char()
		c2=this.receive_char()
		if (c1!="\033") or (c2!="Y"):
			return -1
		else:
			return 0
		
	def delete_file(this,filename):
		if this.protocol!="EAZYLINK":
			return -1
		if -1==this.open_serial():
			return -1
		this.send_char("\033")
		this.send_char("r")
		this.send_string(filename)
		this.send_char("\033")
		this.send_char("Z")
		c1=this.receive_char()
		c2=this.receive_char()
		if (c1!="\033") or (c2!="Y"):
			return -1
		else:
			return 0
	
	def rename_file(this,filename,newfilename):
		if this.protocol!="EAZYLINK":
			return -1
		if -1==this.open_serial():
			return -1
		this.send_char("\033")
		this.send_char("w")
		this.send_string(filename)
		this.send_char("\033")
		this.send_char("N")
		this.send_string(newfilename)
		this.send_char("\033")
		this.send_char("Z")
		c1=this.receive_char()
		c2=this.receive_char()
		if (c1!="\033") or (c2!="Y"):
			return -1
		else:
			return 0
	
	def disable_conversion(this):
		if this.protocol!="EAZYLINK":
			return 0
		if -1==this.open_serial():
			return -1
		this.send_char("\033")
		this.send_char("T") # disable translation
		this.close_serial()
		if -1==this.open_serial():
			return -1
		this.send_char("\033")
		this.send_char("C") # disable line-feed conversion
		this.close_serial()
		return 0

	def get_free_mem(this,drive):
		if this.protocol!="EAZYLINK":
			return -1
		if -1==this.open_serial():
			return -1
		
		if (drive!="0") and (drive!="1") and (drive!="2") and (drive!="3") and (drive!="-"):
			return -1
		this.send_char("\033")
		this.send_char("M")
		this.send_char(drive)
		this.send_char("\033")
		this.send_char("Z")
		c1=this.receive_char()
		if (c1=="") or (c1!="\033"):
			this.close_serial()
			return -1
		c1=this.receive_char()
		if (c1=="") or (c1!="N"):
			this.close_serial()
			return -1
		cadena=""
		while True:
			c1=this.receive_char()
			if c1=="\033":
				break
			cadena+=c1
		c1=this.receive_char()
		return int(cadena)
		
	def setclock(this,thedate,thetime):
		if this.protocol!="EAZYLINK":
			return -1
		if -1==this.open_serial():
			return -1
		
		this.send_char("\033")
		this.send_char("p")
		this.send_string(thedate)
		this.send_char("\033")
		this.send_char("N")
		this.send_string(thetime)
		this.send_char("\033")
		this.send_char("Z")
		time.sleep(1)
		c1=this.receive_char()
		c2=this.receive_char()
		if (c1!="\033") or (c2!="Y"):
			return -1
		else:
			return 0

	def get_devices(this):
		if -1==this.open_serial():
			return []
		this.send_char("\033")
		if this.protocol=="EAZYLINK":
			this.send_char("h")
		else:
			this.send_char("H")
		salida=this.receive_list_names("DEV")
		this.close_serial()
		return salida

	def get_directories(this,path):
		if -1==this.open_serial():
			return []
		if path[-1]=="*":
			path=path[:-1]
		if path[-1]!="/":
			path=path+"/"
		this.send_char("\033")
		if this.protocol=="EAZYLINK":
			this.send_char("d")
		else:
			this.send_char("D")
		this.send_string(path)
		if this.protocol=="EAZYLINK":
			this.send_char("*")
		this.send_char("\033")
		this.send_char("Z")
		salida=this.receive_list_names("DIR")
		this.close_serial()
		return salida

	def get_files(this,path):
		if -1==this.open_serial():
			return []
		if path[-1]=="*":
			path=path[:-1]
		if path[-1]!="/":
			path=path+"/"
		this.send_char("\033")
		if this.protocol=="EAZYLINK":
			this.send_char("n")
		else:
			this.send_char("N")
		this.send_string(path)
		if this.protocol=="EAZYLINK":
			this.send_char("*")
		this.send_char("\033")
		this.send_char("Z")
		salida=this.receive_list_names("FILE")
		this.close_serial()
		return salida

	def get_content(this,path):
		"""Gets all the files and directories from a global path that starts in '/' """
		if path=="":
			path="/"
		elif path[-1]!="/":
			path=path+"/"

		if path=="/":
			return this.get_devices()
		else:
			if path[0]=="/":
				path=path[1:]
			lista=this.get_directories(path)
			if lista==[]:
				return []
			lista2=this.get_files(path)
			if lista2==[]:
				return []
			return lista+lista2

	def receive_file(this,path):
		"""Starts the reception of a file"""
		if (this.protocol=="IMP-EXPORT"):
			this.myserial.timeout=30
		if -1==this.open_serial():
			this.myserial.timeout=1
			return -1
		if (this.protocol=="IMP-EXPORT"):
			name=""
			error=0
			while True:
				caracter=this.receive_char()
				if caracter=="":
					error=1
					break
				elif caracter=="\033":
					esc_char=this.receive_char()
					if (esc_char==""):
						error=1
						break
					elif (esc_char=="F"):
						break
				else:
					name+=caracter
			this.myserial.timeout=1
			if error==0:
				return name
			else:
				return ""
		else:
			this.send_char("\033")
			if (this.protocol=="EAZYLINK"):
				this.send_char("s")
			else:
				this.send_char("G")
			this.send_string(path)
			this.send_char("\033")
			this.send_char("Z")	
			return 0

	def send_file(this,path):
		"""Starts the sending of a file"""
		if -1==this.open_serial():
			return -1
		if (this.protocol!="IMP-EXPORT"):
			this.send_char("\033")
			if (this.protocol=="EAZYLINK"):
				this.send_char("b")
			else:
				this.send_char("S")
		this.send_char("\033")
		this.send_char("N")
		this.send_string(path)
		this.send_char("\033")
		this.send_char("F")
		return 0

	def invert_hexa(this,char):
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


	def send_byte_file(this,charac):

		if charac=="": # end of file
			this.send_char("\033")
			this.send_char("E")
			if this.protocol!="IMP-EXPORT":
				this.send_char("\033")
				this.send_char("Z")
			this.close_serial()
			return 0
		if (ord(charac)>31) & ((ord(charac)<128)|(this.protocol!="IMP-EXPORT")):
				if 0==this.send_char(charac):
					return 0
				else:
					this.close_serial()
				return -1
		else:
			if (this.protocol=="PCLINK")|(this.protocol=="IMP-EXPORT"):
				if 0!=this.send_char("\033"):
					this.close_serial()
					return -1
				if 0!=this.send_char("B"):
					this.close_serial()
					return -1
				v1,v2=this.invert_hexa(charac)
				if 0!=this.send_char(v1):
					this.close_serial()
					return -1
				if 0==this.send_char(v2):
					return 0
				else:
					this.close_serial()
					return -1
			else: # EAZYLINK
				if charac=="\033":
					if 0!=this.send_char("\033"):
						this.close_serial()
						return -1
					if 0==this.send_char("\033"): # two ESCs
						return 0
					else:
						this.close_serial()
						return -1
				else:
					if 0==this.send_char(charac):
						return 0
					else:
						this.close_serial()
						return -1


	def hexa(this,carac):
		v=ord(carac)
		if v>64:
			v-=55
		else:
			v-=48
		return v

	def receive_byte_file(this):
		"""Receives one byte of the current receiving file and returns it"""
		while True:
			status,caracter=this.receive_byte_file_middle()
			if ((status==0)|(status==-1)):
				break
			if (status==1):
				if caracter=="N":
					while ((status!=1)|(caracter!="F")): # jump over filename
						status,caracter=this.receive_byte_file_middle()
		return status,caracter

	def receive_byte_file_middle(this):
		"""Receives one byte of the current receiving file and returns it"""

		value=this.receive_char()
		if value=="": # no char received
			this.close_serial()
			return -1,""

		if value!="\033":
			return 0,value

		value=this.receive_char()
		if value=="": # no char received
			this.close_serial()
			return -1,""

		if (value=="E"): # end of file
			return 1,"E"
		elif (value=="Z"): # end of file
			this.close_serial()
			return 0,""
		elif value=="\033":
			return 0,"\033"
		elif value=="B":
			value=this.receive_char()
			if value=="": # no char received
				this.close_serial()
				return -1,""
			value2=this.receive_char()
			if value2=="": # no char received
				this.close_serial()
				return -1,""
			return 0,chr(this.hexa(value2)+16*this.hexa(value))
		elif value=="N": # filename
			return 1,"N"
		elif value=="F": # file start
			return 1,"F"
		else:
			print "ESC sequence extrange "+str(ord(value))
			return 0," "
