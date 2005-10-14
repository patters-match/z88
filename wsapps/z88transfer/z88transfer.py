#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Copyright 2005 (C) Raster Software Vigo (Sergio Costas)

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

import sys
import os
import pygtk # for testing GTK version number
pygtk.require ('2.0')
import gtk
import gtk.glade
import struct
import gobject
import dircache
import StringIO
import time

import pipex
import z88access

def set_status(text):
	global status

	status.set_text(text)
	while gtk.events_pending():
		gtk.main_iteration()

def fill_paths(args="",doz88=True):
	"""Reads the files in the current paths and fills both GtkTreeView widgets"""
	global listz88
	global listPC
	global z88path
	global pcpath
	global z88
	global arbol
	global status
	global main
	global windows

	set_status("Reading directory")
	if doz88:
		listz88.clear()
	listPC.clear()

	if doz88:
		content=z88.get_content(z88path)
		if content!=[]:
			if (z88path!="")&(z88path!="/"):
				entrada=listz88.insert_before(None,None)
				listz88.set_value(entrada,1,"../")
			for elemento in content:
				if (elemento[0]=="") | (elemento[0]=="./") | (elemento[0]==".")|(elemento[0][:2]==".."):
					continue
				nombre=elemento[0]
				if (elemento[1]=="DIR")|(elemento[1]=="DEV"):
					nombre=nombre+"/"
				entrada=listz88.insert_before(None,None)
				listz88.set_value(entrada,1,nombre)

	if windows and (len(pcpath)>1):
		if pcpath[0]=="/":
			pcpath=pcpath[1:]
		

	if(pcpath=="") | (pcpath[-1]!="/"):
		pcpath+="/"
	
	if pcpath!="/":
		entrada=listPC.insert_before(None,None)
		listPC.set_value(entrada,1,"../")
		
	foldererror=False
	try:
		content2=dircache.listdir(pcpath)
	except OSError:
		foldererror=True
	
	foldererror=False
	
	try:
		content2=dircache.listdir(pcpath)
	except OSError:
		foldererror=True
	
	if foldererror==False:
		content=content2[:] # we must copy it to ensure that ANNOTATE works fine and don't add more than one /
		dircache.annotate(pcpath,content)
	
		if (pcpath=="/") and windows:
			for letra in "ACDEFGHIJKLMNOPQRSTUVWXYZ":
				foldererror=False
				try:
					content2=dircache.listdir(letra+":\\")
				except OSError:
					foldererror=True
	
				if foldererror==False:
					entrada=listPC.insert_before(None,None)
					listPC.set_value(entrada,1,letra+":/")
		else:
			for elemento in content:
				if (elemento[0]=="") | (elemento[0]=="./") | (elemento[0]==".")|(elemento[0][:2]==".."):
					continue
				entrada=listPC.insert_before(None,None)
				listPC.set_value(entrada,1,elemento)

	if doz88:
		thepathz88=arbol.get_widget("z88path")
		thepathz88.set_text(z88path)
	thepathpc=arbol.get_widget("pcpath")
	thepathpc.set_text(pcpath)
	set_status("idle")

def search_upper_path(path):

	global windows

	if (path=="")|(path=="/"):
		return ("/")

	if windows and (len(path)==3):
		return "/"

	if(path[-1]=="/"):
		path=path[:-1]
	if (path[0]!="/") and (windows):
		path="/"+path
	position=-1
	pos2=0;
	while(pos2!=-1):
		pos2=path.find("/",pos2+1)
		if pos2!=-1:
			position=pos2
	if(position==-1):
		return "/"
	else:
		return path[:position+1]
		

def z88click(view,button):
	global viewz88
	global z88path

	if button.type!=gtk.gdk._2BUTTON_PRESS:
		return

	tree,iter=viewz88.get_selection().get_selected()
	entrada=tree.get_value(iter,1)

	if z88path=="":
		z88path="/"

	if z88path[-1]!="/":
		z88path+="/"

	if (entrada[-1]=="/"):
		if (entrada=="../"):
			z88path=search_upper_path(z88path)
		else:
			z88path+=entrada
		fill_paths()
		

def pcclick(view,button):
	global viewPC
	global pcpath
	global windows

	if button.type!=gtk.gdk._2BUTTON_PRESS:
		return

	tree,iter=viewPC.get_selection().get_selected()
	entrada=tree.get_value(iter,1)
	if pcpath=="":
		pcpath="/"
	
	if pcpath[-1]!="/":
		pcpath+="/"
		
	if windows:
		if pcpath=="/":
			pcpath=""
		else:
			if pcpath[0]=="/":
				pcpath=pcpath[1:]

	if (entrada[-1]=="/"):
		if (entrada=="../"):
			pcpath=search_upper_path(pcpath)
		else:
			pcpath+=entrada
		fill_paths("",False)

def getfile(arg,whatdo=""):

	global warning
	global ask_label
	global ask
	global viewz88
	global z88path
	global pcpath
	global answer
	global callback_yes
	global callback_no
	global z88
	global pseudospanish
	global exporting
	global translator_dictionary

	z88.disable_conversion()

	if pseudospanish=="yes":
		allok,frompipe,topipe=pipex.read_translations(translator_dictionary)
		if allok==False:
			show_error("Error reading translation file\n"+translator_dictionary+"\nAborting")
			return
	else:
		frompipe={}
		topipe={}

	if (z88.protocol=="IMP-EXPORT"):
		set_status("Waiting for file")
		entrada=z88.receive_file("")
		if entrada=="":
			set_status("Idle")
			show_error("Timeout while waiting for Z88 to start transmision")
			
			return
		entrada2=search_upper_path(entrada)
		if entrada2[0]=="/":
			entrada2=entrada2[1:]
		if entrada2[-1]!="/":
			entrada2+="/"
		name=entrada[len(entrada2):]
		nficheror=pcpath
		if nficheror[-1]!="/":
			nficheror+="/"
		nficheror+=name
	else:
		tree,iter=viewz88.get_selection().get_selected()
		entrada=tree.get_value(iter,1)
		entradapc=entrada

		if entrada[-1]=="/":
			show_error("Can't download directories")
			
			return

		content2=dircache.listdir(pcpath)
		content=content2[:]
		dircache.annotate(pcpath,content)

		if exporting=="abiword":
			if (".ppd"==entradapc[-4:].lower()) | (".pdd"==entradapc[-4:].lower()):
				entradapc=(entradapc[:-4]+".abw")

		if exporting=="rtf":
			if (".ppd"==entradapc[-4:].lower()) | (".pdd"==entradapc[-4:].lower()):
				entradapc=(entradapc[:-4]+".rtf")

		if (whatdo=="") | (whatdo=="N"):
			for element in content:
				if entradapc==element:
					ask_label.set_text("File already exists.\nOverwrite?")
					ask.show()
					callback_yes=getfile
					callback_no=stub
					return
	
		if z88path[-1]=="/":
			nfichero=z88path+entrada
		else:
			nfichero=z88path+"/"+entrada
	
		if nfichero[0]=="/":
			nfichero=nfichero[1:]
	
		if -1==z88.receive_file(nfichero):
			show_error("Can't connect to the Z88")
			
			return
	
		if pcpath[-1]=="/":
			nficheror=pcpath+entrada
		else:
			nficheror=pcpath+"/"+entrada

	doexport=False
	if exporting=="abiword":
		if (".ppd"==nficheror[-4:].lower()) | (".pdd"==nficheror[-4:].lower()):
			nficheror=(nficheror[:-4]+".abw")
			doexport=True
	
	if exporting=="rtf":
		if (".ppd"==nficheror[-4:].lower()) | (".pdd"==nficheror[-4:].lower()):
			nficheror=(nficheror[:-4]+".rtf")
			doexport=True
	
	if doexport:
		if exporting=="abiword":
			fichero=pipex.abiword(nficheror,"w",pseudospanish,frompipe)
		else:
			fichero=pipex.rtf(nficheror,"w",pseudospanish,frompipe)
	else:
		fichero=open(nficheror,"w")

	contador=0
	while True:
		if 0==(contador%24):
			set_status("Downloaded "+str(contador)+"bytes")
			while gtk.events_pending():
				gtk.main_iteration()
		contador+=1
		nerr,charac=z88.receive_byte_file()		
		if nerr==-1: # error
			fichero.close()
			show_error("An error occurred during the transfer")
			fill_paths()
			
			set_status("Idle")
			return
		if charac=="":
			fichero.close()
			show_error("File transferred successfully")
			fill_paths()
			
			set_status("Idle")
			return
		fichero.write(charac)
			

def sendfile(arg,whatdo=""):

	global warning
	global ask_label
	global ask
	global viewz88
	global z88path
	global pcpath
	global answer
	global callback_yes
	global callback_no
	global z88
	global allowed_letters
	global pseudospanish
	global exporting
	global translator_dictionary
	global warning_label

	z88.disable_conversion()

	if pseudospanish=="yes":
		allok,frompipe,topipe=pipex.read_translations(translator_dictionary)
		if allok==False:
			show_error("Error reading translation file\n"+translator_dictionary+"\nAborting")
			
			return
	else:
		frompipe={}
		topipe={}

	tree,iter=viewPC.get_selection().get_selected()
	entrada=tree.get_value(iter,1)

	if entrada[-1]=="/":
		show_error("Can't send directories")
		
		return

	if len(entrada)>16:
		show_error("File name too long")
		
		return
		
	for letra in entrada.lower():
		if -1==allowed_letters.find(letra):
			show_error("File name contains invalid characters")
			
			return

	if pcpath[-1]=="/":
		nficheror=pcpath+entrada
	else:
		nficheror=pcpath+"/"+entrada

	usexport=False
	if exporting=="abiword": # if we want to translate with Abiword converter
		if ".abw"==(entrada[-4:]).lower(): # if extension is .ABW
			abiclass=pipex.abiword(nficheror,"r",pseudospanish,topipe)
			if 0==abiclass.export():
				entrada=entrada[:-4]+".pdd"
				usexport=True
			else:
				show_error("File "+nfichero+" isn't a valid Abiword file. Aborting")
				return

	elif exporting=="rtf": # if we want to translate with RTF converter
		if ".rtf"==(entrada[-4:]).lower(): # if extension is .RTF
			abiclass=pipex.rtf(nficheror,"r",pseudospanish,topipe)
			if 0==abiclass.export():
				entrada=entrada[:-4]+".pdd"
				usexport=True
			else:
				show_error("File "+nfichero+" isn't a valid RTF file. Aborting")
				return

	if (z88.protocol=="IMP-EXPORT"):
		nfichero=entrada
	else:
		content=z88.get_content(z88path)
	
		if content==[]:
			show_error("Can't connect to Z88")
			
			return
	
		if (whatdo=="") | (whatdo=="N"):
			for element in content:
				if entrada.lower()==(element[0]).lower():
					ask_label.set_text("File already exists.\nOverwrite?")
					ask.show()
					callback_yes=sendfile
					callback_no=stub
					return
	
		if z88path[-1]=="/":
			nfichero=z88path+entrada
		else:
			nfichero=z88path+"/"+entrada
	
		if nfichero[0]=="/":
			nfichero=nfichero[1:]
	
	if -1==z88.send_file(nfichero):
		show_error("Can't connect to the Z88")
		
		return


	if usexport:
		fichero=StringIO.StringIO(abiclass.text) # emulate a file with converted text
	else:
		fichero=open(nficheror,"r")
	contador=0
	while True:
		if 0==(contador%24):
			set_status("Uploaded "+str(contador)+"bytes")
			while gtk.events_pending():
				gtk.main_iteration()
		contador+=1
		charac=fichero.read(1)
		nerr=z88.send_byte_file(charac)
		if nerr==-1: # error
			fichero.close()
			show_error("An error occurred during the transfer")
			fill_paths()
			
			set_status("Idle")
			return
		if charac=="":
			fichero.close()
			show_error("File transferred successfully")
			fill_paths()
			
			set_status("Idle")
			return

def show_error(message):
	global warning_label
	global warning
	
	warning_label.set_text(message)
	warning.show()

def asked_yes(args):
	global answer
	global ask
	global callback_yes

	answer="Y"
	ask.hide()
	callback_yes("","Y")

def asked_no(args):
	global answer
	global ask
	global callback_no

	answer="N"
	ask.hide()
	callback_no("","N")


def hide_warning(args=""):
	global warning

	warning.hide()

def stub(args="",param=""):

	h=5

def save_config():

	global serial_speed
	global serial_port
	global serial_protocol
	global exporting
	global pseudospanish
	global translator_dictionary
	global windows
	global instaldir

	if windows:
		nfile=instaldir
	else:
		nfile=os.environ.get("HOME")
	if nfile[-1]!="/":
		nfile+="/"
	nfile+=".z88transfer"
	conffile=open(nfile,"w")
	conffile.write("speed "+str(serial_speed)+"\n")
	conffile.write("port "+serial_port+"\n")
	conffile.write("protocol "+serial_protocol+"\n")
	conffile.write("exporting "+exporting+"\n")
	conffile.write("pseudospanish "+pseudospanish+"\n")
	conffile.write("translatefile "+translator_dictionary+"\n")
	conffile.close()
	show_params()

def read_config():

	global serial_speed
	global serial_port
	global serial_protocol
	global exporting
	global pseudospanish
	global z88
	global translator_dictionary
	global windows
	global instaldir

	if windows:
		nfile=instaldir
	else:
		nfile=os.environ.get("HOME")
	if nfile[-1]!="/":
		nfile+="/"
	nfile+=".z88transfer"
	try:
		conffile=open(nfile,"r")
	except IOError:
		show_params()
		return

	while True:
		linea=conffile.readline()
		if linea=="":
			break
		if linea[-1]=="\n":
			linea=linea[:-1]
		pos=linea.find(" ")
		if linea[:pos]=="speed":
			serial_speed=int(linea[pos+1:])
		elif linea[:pos]=="port":
			serial_port=linea[pos+1:]
		elif linea[:pos]=="protocol":
			serial_protocol=linea[pos+1:]
		elif linea[:pos]=="exporting":
			exporting=linea[pos+1:]
		elif linea[:pos]=="pseudospanish":
			pseudospanish=linea[pos+1:]
		elif linea[:pos]=="translatefile":
			translator_dictionary=linea[pos+1:]
	conffile.close()
	z88.set_params(serial_speed,serial_port,serial_protocol)
	show_params()

def configure(args):
	global preferences
	global serial_speed
	global serial_port
	global serial_protocol
	global exporting
	global pseudospanish
	global arbol
	global translator_dictionary

	speed=arbol.get_widget("entry_speed").child
	port=arbol.get_widget("entry_port")
	protocol=arbol.get_widget("entry_protocol").child
	pseudo=arbol.get_widget("pseudospanish")
	export=arbol.get_widget("abiword")
	export2=arbol.get_widget("rtfconv")
	entry=arbol.get_widget("transentry")
	
	entry.set_filename(translator_dictionary)
	entry.set_filename(translator_dictionary)
	
	port.set_text(serial_port)
	speed.set_editable(False)
	protocol.set_editable(False)
	speed.set_text(str(serial_speed))
	protocol.set_text(serial_protocol)
	
	if pseudospanish=="yes":
		pseudo.set_active(True)
	else:
		pseudo.set_active(False)
	
	if exporting=="abiword":
		export.set_active(True)
		pseudo.set_sensitive(True)
	elif exporting=="rtf":
		export2.set_active(True)
		pseudo.set_sensitive(True)
	else:
		export.set_active(False)
		pseudo.set_sensitive(False)
	
	preferences.show()	

def pref_ok(args):
	global preferences
	global serial_speed
	global serial_port
	global serial_protocol
	global arbol
	global z88
	global exporting
	global pseudospanish
	global translator_dictionary

	print translator_dictionary

	speed=arbol.get_widget("entry_speed").child
	port=arbol.get_widget("entry_port")
	protocol=arbol.get_widget("entry_protocol").child
	pseudo=arbol.get_widget("pseudospanish")
	export=arbol.get_widget("abiword")
	export2=arbol.get_widget("rtfconv")
	entry=arbol.get_widget("transentry")
	
	translator_dictionary=entry.get_filename()

	serial_port=port.get_text()
	serial_protocol=protocol.get_text()
	serial_speed=int(speed.get_text())
	
	if export.get_active():
		exporting="abiword"
	elif export2.get_active():
		exporting="rtf"
	else:
		exporting="disabled"
	
	if pseudo.get_active():
		pseudospanish="yes"
	else:
		pseudospanish="no"

	z88.set_params(serial_speed,serial_port,serial_protocol)
	save_config()
	preferences.hide()


def pref_cancel(args):
	global preferences

	preferences.hide()

def show_params():
	global arbol
	global z88
	global exporting
	global pseudospanish
	global translator_dictionary
	
	port=arbol.get_widget("label_port")
	speed=arbol.get_widget("label_speed")
	protocol=arbol.get_widget("label_protocol")
	export=arbol.get_widget("importexport")
	
	speed.set_text(str(z88.speed))
	port.set_text(z88.serial_dev)
	protocol.set_text(z88.protocol)
	
	if exporting=="abiword":
		if pseudospanish=="no":
			export.set_text("Abiword")
		else:
			export.set_text("Abiword (pseudotranslation)")
	elif exporting=="rtf":
		if pseudospanish=="no":
			export.set_text("RTF")
		else:
			export.set_text("RTF (pseudotranslation)")
	else:
		export.set_text("None")
		
	setclock=arbol.get_widget("setclock")
	freemem=arbol.get_widget("freemem")
	z88_newfolder=arbol.get_widget("z88_newfolder")
	z88_deletefile=arbol.get_widget("z88_deletefile")
	z88_renamefile=arbol.get_widget("z88_renamefile")
	
	if z88.protocol=="EAZYLINK":
		setmode=True
	else:
		setmode=False
	setclock.set_sensitive(setmode)
	freemem.set_sensitive(setmode)
	z88_newfolder.set_sensitive(setmode)
	z88_deletefile.set_sensitive(setmode)
	z88_renamefile.set_sensitive(setmode)
		
	while gtk.events_pending():
		gtk.main_iteration()

def about_p(args):
	global arbol
	
	about_w=arbol.get_widget("about_window")
	about_w.show()
	
def close_about(args):
	about_w=arbol.get_widget("about_window")
	about_w.hide()

def set_clock(args="",params=""):

	global z88
	global ask
	global ask_label
	global callback_no
	global callback_yes
	global warning_label
	global warning
	
	fecha=time.localtime()
	if fecha[2]<10:
		mydate="0"
	else:
		mydate=""
	mydate+=str(fecha[2])+"/"
	if fecha[1]<10:
		mydate+="0"
	mydate+=str(fecha[1])+"/"+str(fecha[0])
	if fecha[3]<10:
		mytime="0"
	else:
		mytime=""
	mytime+=str(fecha[3])+":"
	if fecha[4]<10:
		mytime+="0"
	mytime+=str(fecha[4])+":"
	if fecha[5]<10:
		mytime+="0"
	mytime+=str(fecha[5])
	if params=="":
		ask_label.set_text("Set clock to\n"+mydate+"\n"+mytime)
		ask.show()
		callback_yes=set_clock
		callback_no=stub
	else:
		if 0==z88.setclock(mydate,mytime):
			cadena="Clock set"
		else:
			cadena="Couldn't set clock"
		warning_label.set_text(cadena)
		warning.show()
	return

	
	
def free_mem(args):

	global z88
	global arbol
	global warning_label
	global warning
	
	mem0=z88.get_free_mem("0")
	if mem0!=-1:
		mem1=z88.get_free_mem("1")
		mem2=z88.get_free_mem("2")
		mem3=z88.get_free_mem("3")
		memv=z88.get_free_mem("-")
		salida="Available memory:\nRAM.0: "+str(mem0)
		if mem1!=-1:
			salida+="\nRAM.1: "+str(mem1)
		if mem2!=-1:
			salida+="\nRAM.2: "+str(mem2)
		if mem3!=-1:
			salida+="\nRAM.3: "+str(mem3)
		if memv!=-1:
			salida+="\nRAM.-: "+str(memv)
	else:
		salida="No Z88 found"
	warning_label.set_text(salida)
	warning.show()
	
	

def z88newfolder(args="",other=""):

	global z88
	global askdata
	global namelabel
	global nameentry
	global callback_yes
	global callback_no
	global z88path
	global pcpath
	global warning
	global warning_label
	
	if z88path=="/":
		warning_label.set_text("Can't create a folder at root level")
		warning.show()
		return
	
	if other!="Y":
		nameentry.set_text("")
		namelabel.set_text("Type a name for new folder")
		callback_yes=z88newfolder
		callback_no=stub
		askdata.show()
	else:
		path=z88path[:]
		if path[0]=="/":
			path=path[1:]
		if path[-1]!="/":
			path=path+"/"
		if -1==z88.create_folder(path+nameentry.get_text()):
			warning_label.set_text("Error creating folder")
			warning.show()
	fill_paths()
	set_status("Idle")
	
	
def z88erasefile(args="",other=""):
	
	global z88
	global viewz88
	global ask
	global ask_label
	global callback_yes
	global callback_no
	
	tree,iter=viewz88.get_selection().get_selected()
	entrada=tree.get_value(iter,1)
	
	if (entrada=="") or (entrada=="../"):
			return
	
	if z88path=="/":
		warning_label.set_text("Can't delete a drive")
		warning.show()
		return
	
	if other=="":
		if entrada[-1]=="/":
			texto="Delete folder:\n"
			entrada=entrada[:-1]
		else:
			texto="Delete file:\n"
		ask_label.set_text(texto+entrada)
		ask.show()
		callback_yes=z88erasefile
		callback_no=stub
		return
	else:
		path=z88path[:]
		if path[0]=="/":
			path=path[1:]
		if path[-1]!="/":
			path=path+"/"
		path=path+entrada
		if -1==z88.delete_file(path):
			warning_label.set_text("Error deleting file/folder")
			warning.show()
	fill_paths()
	set_status("Idle")
		
def z88rename_file(args="",other=""):

	global z88
	global viewz88
	global askdata
	global namelabel
	global nameentry
	global callback_yes
	global callback_no
	global z88path
	global pcpath
	global warning
	global warning_label
	global filename_memorized
	
	if other!="Y":
		tree,iter=viewz88.get_selection().get_selected()
		entrada=tree.get_value(iter,1)
	
		if (entrada=="") or (entrada=="../"):
			return
	
	if z88path=="/":
		warning_label.set_text("Can't rename a drive")
		warning.show()
		return
	
	if other!="Y":
		nameentry.set_text("")
		namelabel.set_text("Type a new name for file\n"+entrada)
		callback_yes=z88rename_file
		callback_no=stub
		askdata.show()
		filename_memorized=entrada
	else:
		path=z88path[:]
		if path[0]=="/":
			path=path[1:]
		if path[-1]!="/":
			path=path+"/"
		if -1==z88.rename_file(path+filename_memorized,nameentry.get_text()):
			warning_label.set_text("Error renaming file")
			warning.show()
	fill_paths()
	set_status("Idle")
	
def name_yes(args):
	global answer
	global askdata
	global callback_yes

	answer="Y"
	askdata.hide()
	callback_yes("","Y")

def name_no(args):
	global answer
	global askdata
	global callback_no

	answer="N"
	askdata.hide()
	callback_no("","N")

def init_all():
	global listz88
	global listPC
	global z88path
	global pcpath
	global z88
	global arbol
	global status
	global main
	global warning
	global ask
	global preferences
	global askdata

	main.connect('destroy',gtk.main_quit)
	
	ok=arbol.get_widget("mok")
	ok.connect("clicked",hide_warning)

	about=arbol.get_widget("about")
	about.connect("clicked",about_p)
	about_ok=arbol.get_widget("about_ok")
	about_ok.connect("clicked",close_about)
	
	setclock=arbol.get_widget("setclock")
	setclock.connect("clicked",set_clock)

	freemem=arbol.get_widget("freemem")
	freemem.connect("clicked",free_mem)
	
	z88_newfolder=arbol.get_widget("z88_newfolder")
	z88_newfolder.connect("clicked",z88newfolder)
	#pc_newfolder=arbol.get_widget("pc_newfolder")
	#pc_newfolder.connect("clicked",pcnewfolder)
	
	z88_erasefile=arbol.get_widget("z88_deletefile")
	z88_erasefile.connect("clicked",z88erasefile)
	#pc_erasefile=arbol.get_widget("pc_deletefile")
	#pc_erasefile.connect("clicked",pcerasefile)

	z88_renamefile=arbol.get_widget("z88_renamefile")
	z88_renamefile.connect("clicked",z88rename_file)

	yes=arbol.get_widget("askyes")
	yes.connect("clicked",asked_yes)
	no=arbol.get_widget("askno")
	no.connect("clicked",asked_no)
	
	nameyes=arbol.get_widget("nameyes")
	nameyes.connect("clicked",name_yes)
	nameno=arbol.get_widget("nameno")
	nameno.connect("clicked",name_no)
	
	config=arbol.get_widget("preferences_buton")
	config.connect("clicked",configure)

	prefcancel=arbol.get_widget("prefcancel")
	prefcancel.connect("clicked",pref_cancel)
	prefok=arbol.get_widget("prefok")
	prefok.connect("clicked",pref_ok)

	viewz88.set_model(listz88)
	viewPC.set_model(listPC)
	
	rendererz88 = gtk.CellRendererText()
	columnz88 = gtk.TreeViewColumn("File", rendererz88, text=1)
	viewz88.append_column(columnz88)
	
	rendererpc = gtk.CellRendererText()
	columnpc = gtk.TreeViewColumn("File", rendererpc, text=1)
	viewPC.append_column(columnpc)
	freload=arbol.get_widget("reload")
	freload.connect("clicked",fill_paths)

	viewz88.connect("button_press_event",z88click)
	viewPC.connect("button_press_event",pcclick)
	set_status("idle")
	get=arbol.get_widget("getz88")
	send=arbol.get_widget("sendz88")
	get.connect("clicked",getfile)
	send.connect("clicked",sendfile)
	
	export=arbol.get_widget("notrans")
	export.connect("toggled",notrans_toggled)

def notrans_toggled(args):

	global arbol
	
	pseudo=arbol.get_widget("pseudospanish")
	export=arbol.get_widget("notrans")
	
	if (export.get_active()):
		pseudo.set_sensitive(False)
	else:
		pseudo.set_sensitive(True)
		

def find_drive():
	
	letters="CDEFGHIJKLMNOPQRSTUVWXYZ"
	found_drive=""
	for letra in letters:
	
		foldererror=False
		try:
			content2=dircache.listdir(letra+":\\")
		except OSError:
			foldererror=True
	
		if foldererror==False:
			content=content2[:] # we must copy it to ensure that ANNOTATE works fine and don't add more than one /
			dircache.annotate(letra+":\\",content)
	
			for elemento in content:
				if (elemento[0]=="") | (elemento[0]=="./") | (elemento[0]==".")|(elemento[0][:2]==".."):
					continue
				if elemento.lower()=="z88transfer/":
					found_drive=letra
					break
			
			if found_drive!="":
				break
		
	if found_drive!="":
		return (found_drive+":/z88transfer")
	else:
		return ""

allowed_letters="abcdefghijklmnopqrstuvwxyz0123456789."

listz88=gtk.TreeStore(gobject.TYPE_PYOBJECT,gobject.TYPE_STRING)
listPC=gtk.TreeStore(gobject.TYPE_PYOBJECT,gobject.TYPE_STRING)
debug=False
local=False
windows=False

if len(sys.argv)==2:
	if sys.argv[1]=="debug":
		debug=True
	elif sys.argv[1]=="local":
		local=True
	elif sys.argv[1]=="windows":
		windows=True
	else:
		print "Usage: z88transfer.py [local|windows]"
elif len(sys.argv)!=1:
	print "Usage: z88transfer.py [local|windows]"

if windows:
	serial_port="com1"
else:
	serial_port="/dev/ttyS0"

z88=z88access.z88access(device=serial_port)

if windows:
        home=find_drive()
        if home=="":
        	print "Can't find program's directory. Aborting"
        	sys.exit(1)
else:
        home=os.environ.get("HOME")

if home[-1]!="/":
	home+="/"

translator_dictionary="/usr/share/z88transfer/pseudotranslation"
if debug:
	arbol=gtk.glade.XML("./z88transfer.glade")
elif local:
	arbol=gtk.glade.XML(home+".bin/z88transfer.glade")
	translator_dictionary=home+".bin/pseudotranslation"
elif windows:
	instaldir2=home
	if (instaldir2[-1]!="/") and (instaldir2[-1]!="\\"):
		instaldir2+="/"
	instaldir=""
	for letra in instaldir2:
		if letra!="/":
			instaldir+=letra
		else:
			instaldir+="\\"
	arbol=gtk.glade.XML(instaldir+"z88transfer.glade")
	translator_dictionary=instaldir+"pseudotranslation"
else:
	arbol=gtk.glade.XML("/usr/share/z88transfer/z88transfer.glade")

viewz88=arbol.get_widget("treez88")
viewPC=arbol.get_widget("treepc")
status=arbol.get_widget("status")
main=arbol.get_widget("main")
warning=arbol.get_widget("warning")
warning_label=arbol.get_widget("warning_label")
ask=arbol.get_widget("asking")
ask_label=arbol.get_widget("ask_label")
preferences=arbol.get_widget("preferences")
askdata=arbol.get_widget("data")
namelabel=arbol.get_widget("namelabel")
nameentry=arbol.get_widget("nameentry")

serial_speed=9600

serial_protocol="PCLINK"
pseudospanish="no"
exporting="disabled"

read_config()

callback_yes=stub
callback_no=stub

answer=""

init_all()

z88path="/"
if windows:
	pcpath="/"
else:
	pcpath=os.environ.get("HOME")
fill_paths()

gtk.main()

z88.quit()
