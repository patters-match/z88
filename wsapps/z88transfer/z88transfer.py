#!/usr/bin/python
# -*- coding: UTF-8 -*-

# Copyright 2005-2007 (C) Raster Software Vigo (Sergio Costas)
#
# This file is part of Z88Transfer
#
# Z88Transfer is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 3
# of the License, or (at your option) any later version.

# Z88Transfer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

import sys
import os
import dircache
import StringIO
import time
import gettext
import locale

import pygtk # for testing GTK version number
pygtk.require ('2.0')
import gtk
import gtk.glade
import struct
import gobject

try:
	import psyco
	psyco.full()
except ImportError:
	print 'Psyco not installed, the program will just run slower'

gladepath=""
textpath=""

if sys.platform!="win32":
	try:
		f=open("/usr/share/z88transfer/z88transfer.glade","r")
		f.close()
		gladepath="/usr/share/z88transfer/"
		textpath="/usr/share/locale/"
	except:
		pass

	try:
		f=open("/usr/local/share/z88transfer/z88transfer.glade","r")
		f.close()
		gladepath="/usr/local/share/z88transfer/"
		textpath="/usr/share/locale/"
	except:
		pass

	if gladepath!="":
		sys.path.append(gladepath)

try:
	current=os.getcwd()
	if current[-1]!=os.sep:
		current+=os.sep
	f=open(current+"files"+os.sep+"z88transfer.glade","r")
	f.close()
	gladepath=current+"files"+os.sep
	textpath=current
	textpath+="po"+os.sep
except:
	pass

if (gladepath=="") or (textpath==""):
	print "Can't find the base files. Aborting."
	sys.exit(1)

import z88_pipex
import z88_access

gettext.bindtextdomain('z88transfer',textpath)
locale.setlocale(locale.LC_ALL,"")
gettext.textdomain('z88transfer')
gettext.install("z88transfer",localedir=textpath)
_ = gettext.gettext

gtk.glade.bindtextdomain("z88transfer",textpath)

class copy_base:
	
	def __init__(self,gladepath,nfiles,z88transfer,z88path,pcpath,exporting,translator_dictionary,pseudospanish):
		
		self.gladepath = gladepath
		self.z88 = z88transfer
		self.z88path = z88path
		self.pcpath = pcpath
		self.nfiles = nfiles
		self.exporting = exporting
		self.translator_dictionary = translator_dictionary
		self.pseudospanish = pseudospanish
		
		self.arbol = gtk.glade.XML(self.gladepath+"z88transfer.glade","transfer_window",domain="z88transfer")
		self.arbol.signal_autoconnect(self)
		self.main_window = self.arbol.get_widget("transfer_window")
		self.main_window.show()
		
		self.filename_label = self.arbol.get_widget("transfer_filename")
		
		self.counter = 0
		
		self.partial = self.arbol.get_widget("transfer_partial")
		self.total = self.arbol.get_widget("transfer_total")
		
		self.total.set_text("0/"+str(self.nfiles))

		self.refresh = (self.z88.speed / 100)
		if self.z88.protocol == "PCLINK":
			self.refresh /= 2
		
		self.cancel_transfer = False

		self.trans_error = False		
		if self.pseudospanish=="yes":
			allok,self.frompipe,self.topipe=z88_pipex.read_translations(self.translator_dictionary)
			if allok==False:
				self.trans_error = True
		else:
			self.frompipe={}
			self.topipe={}
		
	
	def on_cancel_clicked(self,widget):
		
		self.cancel_transfer = True
		self.filename_label.set_text(_("Aborting"))


	def next_file(self):
		
		self.counter += 1
		self.total.set_fraction((float(self.counter)) / (float(self.nfiles)))
		self.total.set_text(str(self.counter)+"/"+str(self.nfiles))


	def destroy(self):

		self.main_window.hide()
		self.main_window.destroy()
		self.main_window = None
		self.arbol = None


class copy_z88(copy_base):
	
	def __init__(self,gladepath,nfiles,z88transfer,z88path,pcpath,exporting,translator_dictionary,pseudospanish):
		
		copy_base.__init__(self,gladepath,nfiles,z88transfer,z88path,pcpath,exporting,translator_dictionary,pseudospanish)


	def receive_filename(self,filename):
		
		if self.z88.protocol!="IMP-EXPORT":
			self.filename = self.z88path+filename
		else:
			self.filename = self.z88.receive_file("")
			
		if self.filename == "":
			return None
		
		while True:
			pos = self.filename.find("/")
			if (pos == -1):
				break
			self.filename = self.filename[pos+1:]

		self.filename_z88 = self.filename
		
		self.filename_label.set_text(self.filename)

		self.doexport = False
		if self.exporting == "abiword":
			if (".ppd"==self.filename[-4:]) | (".pdd"==self.filename[-4:]):
				self.filename = self.filename[:-3]+"abw"
				self.doexport = True
				
		if self.exporting == "rtf":
			if (".ppd"==self.filename[-4:]) | (".pdd"==self.filename[-4:]):
				self.filename = self.filename[:-3]+"rtf"
				self.doexport = True

		return self.filename


	def do_copy(self):

		self.z88.disable_conversion()

		filesize=self.z88.file_size(self.z88path+self.filename_z88)

		if self.z88.protocol != "IMP-EXPORT":
			self.handler = self.z88.receive_file(self.z88path+self.filename_z88)
			if self.handler == -1:
				return -1
		
		if self.doexport:
			if self.pseudospanish=="no":
				use_pseudo = "n"
			else:
				use_pseudo = "y"
			if self.exporting == "abiword":
				fichero = z88_pipex.abiword(self.pcpath+self.filename,"w",use_pseudo,self.frompipe)
			else:
				fichero = z88_pipex.rtf(self.pcpath+self.filename,"w",use_pseudo,self.frompipe)
		else:
			fichero = open(self.pcpath+self.filename,"wb")

		counter = 0.0
		while True:
			if 0 == (counter%self.refresh):
				self.partial.set_text(_("Downloaded %(bytes)d bytes") % {"bytes":counter})
				if (filesize <= 0):
					self.partial.pulse()
				else:
					self.partial.set_fraction(counter/(float(filesize)))
				while gtk.events_pending():
					gtk.main_iteration()

			counter += 1.0
			nerr,charac=self.z88.receive_byte_file()		
			if nerr == -1: # error
				fichero.close()
				return -2

			if charac == "":
				fichero.close()
				if self.cancel_transfer:
					return -3
				else:
					return 0
			fichero.write(charac)


class copy_pc(copy_base):
	
	def __init__(self,gladepath,nfiles,z88transfer,z88path,pcpath,exporting,translator_dictionary,pseudospanish):
		
		copy_base.__init__(self,gladepath,nfiles,z88transfer,z88path,pcpath,exporting,translator_dictionary,pseudospanish)
	
	
	def send_filename(self,filename):
		
		self.filename = filename

		if self.filename == "":
			return None
		
		self.filename_z88 = self.z88path+self.filename
		
		self.filename_label.set_text(self.filename)

		self.doexport = False
		
		if self.exporting == "abiword": # if we want to translate with Abiword converter
			if ".abw" == (self.filename[-4:]).lower(): # if extension is .ABW
				self.abiclass = z88_pipex.abiword(self.pcpath+filename,"r",self.pseudospanish,self.topipe)
				if 0==self.abiclass.export():
					self.filename_z88 = self.filename_z88[:-3]+"pdd"
					self.doexport=True
				else:
					return -1

		elif self.exporting=="rtf": # if we want to translate with RTF converter
			if ".rtf" == (self.filename[-4:]).lower(): # if extension is .RTF
				self.abiclass = z88_pipex.rtf(self.pcpath+filename,"r",self.pseudospanish,self.topipe)
				if 0==self.abiclass.export():
					self.filename_z88 = self.filename_z88[:-3]+"pdd"
					self.doexport=True
				else:
					return -2
		return 0
		

	def do_copy(self):
		
		self.z88.disable_conversion()
		filesize=os.stat(self.pcpath+self.filename)[6]

		nfichero=self.filename_z88

		if -1==self.z88.send_file(nfichero):
			return -1

		if self.doexport:
			fichero=StringIO.StringIO(self.abiclass.text) # emulate a file with converted text
		else:
			fichero=open(self.pcpath+self.filename,"rb")		
		
		counter = 0.0
		while True:
			if 0 == (counter%self.refresh):
				self.partial.set_text(_("Uploaded %(bytes)d bytes") % {"bytes":counter})
				if (filesize <= 0):
					self.partial.pulse()
				else:
					self.partial.set_fraction(counter/(float(filesize)))
				while gtk.events_pending():
					gtk.main_iteration()

			counter += 1.0
			charac=fichero.read(1)
			nerr=self.z88.send_byte_file(charac)
			if nerr!=0:
				print "Error "+str(nerr)
			if nerr == -1: # error
				fichero.close()
				return -2
			if charac == "":
				fichero.close()
				if self.cancel_transfer:
					return -3
				else:
					return 0


class ask_window:
	
	def __init__(self,gladepath,text,title=""):
		
		self.gladepath=gladepath
		self.arbol = gtk.glade.XML(self.gladepath+"z88transfer.glade","data_dialog",domain="z88transfer")
		self.arbol.signal_autoconnect(self)
		self.main_window = self.arbol.get_widget("data_dialog")
		self.main_window.show()
		
		self.arbol.get_widget("data_ok").set_sensitive(False)
		
		self.arbol.get_widget("data_label").set_text(text)
		self.status=False
		
		if (title != ""):
			self.main_window.set_title(title)

	
	def run(self):
		
		retval = self.main_window.run()
		self.value = self.arbol.get_widget("data_entry").get_text()
		return retval

		
	def destroy(self):
		
		self.main_window.hide()
		self.main_window.destroy()
		self.main_window = None
		self.arbol = None
		self.gladepath = None

		
	def on_data_entry_changed(self,widget):
		
		if widget.get_text() == "":
			self.arbol.get_widget("data_ok").set_sensitive(False)
			self.status = False
		else:
			self.arbol.get_widget("data_ok").set_sensitive(True)
			self.status = True
			
			
	def on_data_entry_activate(self,widget):
		
		if self.status:
			self.main_window.response(-5)


class pref_window:
	
	def __init__(self,z88,gladepath,serial_port,serial_protocol,serial_speed,exporting,pseudospanish,dictionary):
		
		self.gladepath = gladepath
		self.serial_port = serial_port
		self.serial_protocol = serial_protocol
		self.serial_speed = serial_speed
		self.exporting = exporting
		self.pseudospanish = pseudospanish
		self.dictionary = dictionary
		
		self.arbol = gtk.glade.XML(self.gladepath+"z88transfer.glade","pref_dialog",domain="z88transfer")
		self.arbol.signal_autoconnect(self)
		self.main_window = self.arbol.get_widget("pref_dialog")
		self.main_window.show()
		
		self.port = self.arbol.get_widget("entry_serial_port")
		self.speed = self.arbol.get_widget("entry_speed").child
		self.protocol = self.arbol.get_widget("entry_protocol").child
		self.pseudo = self.arbol.get_widget("pseudospanish")
		self.export = self.arbol.get_widget("abiword")
		self.export2 = self.arbol.get_widget("rtfconv")
		self.export3 = self.arbol.get_widget("notrans")
		self.entry = self.arbol.get_widget("transentry")
	
		self.entry.set_filename(self.dictionary)

		self.port.set_text(self.serial_port)
		self.speed.set_editable(False)
		self.speed.set_text(str(serial_speed))
		self.protocol.set_editable(False)
		self.protocol.set_text(serial_protocol)
	
		if self.pseudospanish == "yes":
			self.pseudo.set_active(True)
		else:
			self.pseudo.set_active(False)
	
		if exporting == "abiword":
			self.export.set_active(True)
			self.pseudo.set_sensitive(True)
			self.entry.set_sensitive(True)
		elif exporting == "rtf":
			self.export2.set_active(True)
			self.pseudo.set_sensitive(True)
			self.entry.set_sensitive(True)
		else:
			self.export3.set_active(True)
			self.pseudo.set_sensitive(False)
			self.entry.set_sensitive(False)
	
		self.main_window.show()
		
		
	def run(self):
		
		retval = self.main_window.run()
		self.serial_port = self.port.get_text()
		self.serial_speed = int(self.speed.get_text())
		self.serial_protocol = self.protocol.get_text()
		if self.pseudo.get_active():
			self.pseudospanish = "yes"
		else:
			self.pseudospanish = "no"
			
		if self.export.get_active():
			self.exporting = "abiword"
		elif self.export2.get_active():
			self.exporting = "rtf"
		else:
			self.exporting = "disabled"

		self.dictionary = self.entry.get_filename()
		return retval
			
		
	def destroy(self):
		
		self.main_window.hide()
		self.main_window.destroy()
		self.main_window = None
		self.arbol = None
		self.gladepath = None


	def on_group_changed(self,widget):

		if (self.export.get_active()) or (self.export2.get_active()):
			self.pseudo.set_sensitive(True)
			self.entry.set_sensitive(True)
		else:
			self.pseudo.set_active(False)
			self.pseudo.set_sensitive(False)
			self.entry.set_sensitive(False)
			

class main_window:
	
	def get_home(self):

		if sys.platform == "win32":
			return os.getcwd()
		else:
			return os.environ.get("HOME")


	def save_config(self):

		if sys.platform == "win32":
			nfile = os.getcwd()
		else:
			nfile = os.environ.get("HOME")
			
		if nfile[-1] != os.sep:
			nfile += os.sep
		
		nfile += ".config_z88transfer"
		conffile = open(nfile,"wb")
		conffile.write("speed "+str(self.serial_speed)+"\n")
		conffile.write("port "+self.serial_port+"\n")
		conffile.write("protocol "+self.serial_protocol+"\n")
		conffile.write("exporting "+self.exporting+"\n")
		conffile.write("pseudospanish "+self.pseudospanish+"\n")
		conffile.write("translatefile "+self.translator_dictionary+"\n")
		conffile.close()
		

	def read_config(self):
		
		if sys.platform == "win32":
			self.serial_port = "com1"
		else:
			self.serial_port = "/dev/ttyS0"

		self.serial_speed = 9600
		self.serial_protocol = "PCLINK"
		self.pseudospanish = "no"
		self.exporting = "disabled"
		self.translator_dictionary = self.glade_path+"pseudotranslation"
		
		if sys.platform == "win32":
			nfile = os.getcwd()
		else:
			nfile = os.environ.get("HOME")
		
		if nfile[-1] != os.sep:
			nfile += os.sep
		nfile += ".config_z88transfer"
		
		try:
			conffile = open(nfile,"rb")
		except IOError:
			return

		while True:
			linea = conffile.readline()
			if linea == "":
				break
			if linea[-1] == "\n":
				linea = linea[:-1]
			pos = linea.find(" ")
			if linea[:pos] == "speed":
				self.serial_speed = int(linea[pos+1:])
			elif linea[:pos] == "port":
				self.serial_port = linea[pos+1:]
			elif linea[:pos] == "protocol":
				self.serial_protocol = linea[pos+1:]
			elif linea[:pos] == "exporting":
				self.exporting = linea[pos+1:]
			elif linea[:pos] == "pseudospanish":
				self.pseudospanish = linea[pos+1:]
			elif linea[:pos] == "translatefile":
				self.translator_dictionary = linea[pos+1:]
		conffile.close()


	def __init__(self,glade_path):

		self.glade_path = glade_path
			
		self.read_config()
		self.z88 = z88_access.z88access(device=self.serial_port)
		self.z88.set_params(self.serial_speed,self.serial_port,self.serial_protocol)
		
		self.z88path = "/"
		self.pcpath = self.get_home()
		if self.pcpath == "":
			print "Can't find program's directory. Aborting"
			sys.exit(1)

		if self.pcpath[-1] != os.sep:
			self.pcpath += os.sep

		self.arbol = gtk.glade.XML(self.glade_path+"z88transfer.glade","main_window",domain="z88transfer")
		self.arbol.signal_autoconnect(self)
		self.main_window = self.arbol.get_widget("main_window")
		self.main_window.show()
		
		self.show_params()

		self.pc_model = gtk.ListStore (gobject.TYPE_STRING)
		self.z88model = gtk.ListStore (gobject.TYPE_STRING)

		self.pc_tree = self.arbol.get_widget("pctree")
		self.z88tree = self.arbol.get_widget("z88tree")
		self.pc_tree.get_selection().set_mode(gtk.SELECTION_MULTIPLE)
		self.z88tree.get_selection().set_mode(gtk.SELECTION_MULTIPLE)
		self.pc_tree.set_model(self.pc_model)
		self.z88tree.set_model(self.z88model)
		pc_column = gtk.TreeViewColumn(_("Filename"),gtk.CellRendererText(),text=0)
		z88column = gtk.TreeViewColumn(_("Filename"),gtk.CellRendererText(),text=0)
		self.pc_tree.append_column(pc_column)
		self.z88tree.append_column(z88column)

		self.z88files = []
		self.z88folders = []
		self.pcfiles = []
		self.pcfolders = []

		self.fill_paths()


	def set_status(self,text):

		self.arbol.get_widget("status").set_text(text)
		while gtk.events_pending():
			gtk.main_iteration()
		while gtk.events_pending():
			gtk.main_iteration()


	def on_about_clicked(self,widget):
		
		new_arbol = gtk.glade.XML(self.glade_path+"z88transfer.glade","about_dialog",domain="z88transfer")
		w = new_arbol.get_widget("about_dialog")
		w.show()
		w.run()
		w.hide()
		w.destroy()
		w = None
		new_arbol = None


	def do_question(self,question_text,question_title=""):
		
		new_arbol = gtk.glade.XML(self.glade_path+"z88transfer.glade","question_dialog",domain="z88transfer")
		w = new_arbol.get_widget("question_dialog")
		label = new_arbol.get_widget("question_label")
		label.set_text(question_text)
		if question_title != "":
			w.set_title(question_title)
		w.show()
		retval = w.run()
		label = None
		w.hide()
		w.destroy()
		w = None
		new_arbol = None
		return retval


	def show_message(self,message_text,message_title=""):
		
		new_arbol = gtk.glade.XML(self.glade_path+"z88transfer.glade","message_dialog",domain="z88transfer")
		w = new_arbol.get_widget("message_dialog")
		label = new_arbol.get_widget("message_label")
		label.set_text(message_text)
		if message_title != "":
			w.set_title(message_title)
		w.show()
		w.run()
		label = None
		w.hide()
		w.destroy()
		w = None
		new_arbol = None


	def on_preferences_clicked(self,widget):
		
		pref = pref_window(self.z88,self.glade_path,self.serial_port,self.serial_protocol,self.serial_speed,self.exporting,self.pseudospanish,self.translator_dictionary)
		ret_val = pref.run()
		if ret_val == -5:
			self.serial_port = pref.serial_port
			self.serial_protocol = pref.serial_protocol
			self.serial_speed = pref.serial_speed
			self.exporting = pref.exporting
			self.pseudospanish = pref.pseudospanish
			self.translator_dictionary = pref.dictionary
			self.z88=z88_access.z88access(device=self.serial_port)
			self.z88.set_params(self.serial_speed,self.serial_port,self.serial_protocol)
			self.show_params()
			self.save_config()
		pref.destroy()
		pref = None
		

	def on_setclock_clicked(self,widget):
		
		current_date = time.localtime()
		if current_date[2] < 10:
			mydate = "0"
		else:
			mydate = ""
		mydate += str(current_date[2])+"/"
		if current_date[1] < 10:
			mydate += "0"
		mydate += str(current_date[1])+"/"+str(current_date[0])
		if current_date[3] < 10:
			mytime = "0"
		else:
			mytime = ""
		mytime += str(current_date[3])+":"
		if current_date[4] < 10:
			mytime += "0"
		mytime += str(current_date[4])+":"
		if current_date[5] < 10:
			mytime += "0"
		mytime += str(current_date[5])
		
		if 0 == self.z88.setclock(mydate,mytime):
			self.show_message(_("The clock has been set"),_("Clock set"))
		else:
			self.show_message(_("Couldn't set clock. Please, try again."),_("Error"))


	def on_main_window_delete_event(self,widget,event):
		
		retval = self.do_question(_("Exit Z88Transfer?"),_("Exit?"))
		if retval == -5: # OK
			self.z88.quit()
			gtk.main_quit()
			return False
		return True


	def on_freemem_clicked(self,widget):
		
		mem0 = self.z88.get_free_mem("0")
		if mem0 != -1:
			mem1 = self.z88.get_free_mem("1")
			mem2 = self.z88.get_free_mem("2")
			mem3 = self.z88.get_free_mem("3")
			memv = self.z88.get_free_mem("-")
			output = _("The available memory is:\n")
			output += "RAM.0: "+str(mem0)
			if mem1 != -1:
				output += "\nRAM.1: "+str(mem1)
			if mem2 != -1:
				output += "\nRAM.2: "+str(mem2)
			if mem3 != -1:
				output += "\nRAM.3: "+str(mem3)
			if memv != -1:
				output += "\nRAM.-: "+str(memv)
			self.show_message(output, _("Available memory"))
		else:
			self.show_message(_("Can't connect to the Z88"),_("Error"))


	def on_reload_clicked(self,widget):
		
		self.fill_paths(True)


	def on_z88_newfolder_clicked(self,widget):
		
		if self.z88path == "/":
			return
		
		ask = ask_window(self.glade_path,_("Name for the new folder?"),_("New folder"))
		retval = ask.run()
		name = ask.value
		ask.destroy()
		ask = None
		
		if retval != -5:
			return
		
		retstr=self.z88.check_name(name,True)
		if retstr!="":
			self.show_message(retstr,_("Error"))
			return

		if self.z88.create_folder(self.z88path+name) != 0:
			self.show_message(_("Failed to create the folder"),_("Error"))
		else:
			self.fill_paths()


	def on_z88_renamefile_clicked(self,widget):
		
		if self.z88path == "/":
			return
		
		files = self.get_z88_marked()
		if len(files) == 0:
			return
		
		if len(files) > 1:
			self.show_message(_("Select only one file/folder"), _("Error"))
			return
	
		file_name = files[0]
		if file_name[-1] == "/":
			file_name = file_name[:-1]

		ask = ask_window(self.glade_path,_('New name for file or folder "%(filename)s"?') % {'filename':file_name},_("Rename file/folder"))
		retval = ask.run()
		name = ask.value
		ask.destroy()
		
		ask = None
		
		if retval != -5:
			return
		
		retstr=self.z88.check_name(name,False)
		if retstr!="":
			self.show_message(retstr,_("Error"))
			return

		if self.z88.rename_file(self.z88path+file_name,name) != 0:
			self.show_message(_("Failed to rename the file/folder"),_("Error"))
		else:
			self.fill_paths()
		

	def on_z88_deletefile_clicked(self,widget):
		
		if self.z88path == "/":
			return
		
		files = self.get_z88_marked()
		if len(files) == 0:
			return
		
		retval = self.do_question(_("Delete the marked files/folders?"),_("Delete files"))
		if retval != -5:
			return
		
		failed = False
		for nfile in files:
			if self.z88.delete_file(nfile) == -1:
				failed = True
				
		if failed:
			self.show_message(_("Failed to delete all files/folders"),_("Error"))
			
		self.fill_paths()


	def on_copy_from_z88_clicked(self,widget):
		
		files = self.get_z88_marked()

		if (self.z88.protocol=="IMP-EXPORT"):
			files = [""]
			impexp = True
		else:
			impexp = False

		if (len(files) == 0) or ((self.z88path == "/") and (impexp == False)):
			return
		
		mode = "ask"
		
		copyclass = copy_z88(self.glade_path,len(files),self.z88,self.z88path,self.pcpath,self.exporting,self.translator_dictionary,self.pseudospanish)
		if copyclass.trans_error:
			self.show_message(_("Can't load the file with the rules for the pseudotranslation. Aborting."), _("Error"))
			return
		
		had_error = False
		for element in files:
			if element[-1]=="/":
				continue
			filename = copyclass.receive_filename(element)
			errorm = False
			for item in self.pcfolders:
				if item == filename:
					self.show_message(_("Skipping the file %(filename)s because there's a folder with that name.") % {"filename":filename},_("Error"))
					copyclass.next_file()
					errorm = True
					break
			if errorm:
				continue
			
			errorm = False
			
			if mode !="overwrite":
				for item in self.pcfiles:
					if item == filename:
						errorm = True
						if mode != "skip":
							retval = self.ask_overwrite(filename)
							# retval:
							# 1 = overwrite this one
							# 2 = overwrite all
							# 3 = skip all
							# other = skip this one
							
							if retval == 1: # overwrite this
								errorm = False
							elif retval == 2: # overwrite all
								errorm = False
								mode = "overwrite"
							elif retval == 3: # skip all
								mode = "skip"
						break
			if errorm:
				copyclass.next_file()
				continue

			retval = copyclass.do_copy()
			copyclass.next_file()
			if retval == -1:
				self.show_message(_("Failed to connect with the Z88. Aborted"), _("Error"))
				had_error = True
				break
			elif retval == -2:
				self.show_message(_("An error ocurred during transfer. Aborted."), _("Error"))
				had_error = True
				break
			elif retval == -3:
				self.show_message(_("Aborted by the user"), _("Aborted"))
				had_error = True
				break
				
		if had_error == False:
			self.show_message(_("All files copied sucesfully"),_("Job done"))

		copyclass.destroy()
		self.fill_paths(False)


	def on_copy_to_z88_clicked(self,widget):
		
		files = self.get_pc_marked()
		if (self.z88.protocol=="IMP-EXPORT"):
			if len(files)>1:
				self.show_message(_("With IMP-EXPORT protocol you can't select more than one file"),_("Error"))
				return

		if (len(files) == 0) or (self.z88path == "/"):
			return
		
		files2 = []
		for element in files:
			if element[-1] == os.sep:
				continue
			retstr=self.z88.check_name(element.lower(),False)
			if retstr!="":
				self.show_message(retstr,_("Error"))
				return
			else:
				files2.append(element)

		if len(files2) == 0:
			return

		copyclass = copy_pc(self.glade_path,len(files),self.z88,self.z88path,self.pcpath,self.exporting,self.translator_dictionary,self.pseudospanish)
		if copyclass.trans_error:
			self.show_message(_("Can't load the file with the rules for the pseudotranslation. Aborting."), _("Error"))
			return

		mode = "ask"

		for filename in files2:
			
			had_error = False
			if len(filename) > 16:
				self.show_message(_("Skipping the file %(filename)s because the filename is too long.") % {"filename":filename},_("Error"))
				had_error = True
				continue
			
			errorm = False
			for item in self.z88folders:
				if item == filename:
					self.show_message(_("Skipping the file %(filename)s because there's a folder with that name.") % {"filename":filename},_("Error"))
					errorm = True
					break
			if errorm:
				continue
			
			retval = copyclass.send_filename(filename)
			if retval == -1:
				self.show_message(_("%(filename)s is not a valid AbiWord file. Skipping.") % {"filename":filename}, _("Warning"))
				continue
			elif retval == -2:
				self.show_message(_("%(filename)s is not a valid RTF file. Skipping.") % {"filename":filename}, _("Warning"))
				continue
			
			errorm = False
			
			if mode !="overwrite":
				for item in self.z88files:
					if item.lower() == filename:
						errorm = True
						if mode != "skip":
							retval = self.ask_overwrite(filename)
							# retval:
							# 1 = overwrite this one
							# 2 = overwrite all
							# 3 = skip all
							# other = skip this one
							
							if retval == 1: # overwrite this
								errorm = False
							elif retval == 2: # overwrite all
								errorm = False
								mode = "overwrite"
							elif retval == 3: # skip all
								mode = "skip"
						break
			if errorm:
				continue

			retval = copyclass.do_copy()
			copyclass.next_file()
			if retval == -1:
				self.show_message(_("Failed to connect with the Z88. Aborted"), _("Error"))
				had_error = True
				break
			elif retval == -2:
				self.show_message(_("An error ocurred during transfer. Aborted."), _("Error"))
				had_error = True
				break
			elif retval == -3:
				self.show_message(_("Aborted by the user"), _("Aborted"))
				had_error = True
				break
				
		if had_error == False:
			self.show_message(_("All files copied sucesfully"),_("Job done"))

		copyclass.destroy()
		self.fill_paths(True)


	def ask_overwrite(self,filename):
		
		new_arbol = gtk.glade.XML(self.glade_path+"z88transfer.glade","overwrite_dialog",domain="z88transfer")
		w = new_arbol.get_widget("overwrite_dialog")
		label = new_arbol.get_widget("overwrite_label")
		label.set_text(_("The file %(filename)s already exists. What should I do?"))
		w.show()
		retval = w.run()
		label = None
		w.hide()
		w.destroy()
		w = None
		new_arbol = None
		return retval


	def fill_paths(self,doz88=True):
		
		""" Fills the paths in the main window """
		
		self.set_status("Reading directory")
		
		if doz88:
			self.z88model.clear()
			self.z88files = []
			self.z88folders = []
		self.pc_model.clear()
		self.pcfiles = []
		self.pcfolders = []

		show_hidden = False

		if doz88:
			content = self.z88.get_content(self.z88path)
			if (len(content) == 0) or (self.z88path == "/") or (self.z88.protocol != "EAZYLINK"):
				status = False
			else:
				status = True
				
			self.arbol.get_widget("z88_newfolder").set_sensitive(status)
			self.arbol.get_widget("z88_deletefile").set_sensitive(status)
			self.arbol.get_widget("z88_renamefile").set_sensitive(status)
				
			if len(content) != 0:
				counter = 0
				if (self.z88path != "") and (self.z88path != "/"):
					iterator = self.z88model.insert(counter)
					self.z88model.set_value(iterator,0,"../")
					counter += 1
				lpaths = []
				lfiles = []
				for element in content:
					if (element[0] == "") or (element[0] == "./") or (element[0] == ".") or (element[0][:2] == ".."):
						continue
					name = element[0]
					if (element[1] == "DIR") or (element[1] == "DEV"):
						name = name+"/"
						lpaths.append(name)
					else:
						lfiles.append(name)
				
				lpaths.sort(key=str.lower)
				lfiles.sort(key=str.lower)
				
				for element in lpaths:
					iterator = self.z88model.insert(counter)
					self.z88model.set_value(iterator,0,element)
					self.z88folders.append(element[:-1])
					counter += 1
				for element in lfiles:
					iterator = self.z88model.insert(counter)
					self.z88model.set_value(iterator,0,element)
					self.z88files.append(element)
					counter += 1

		if (sys.platform == "win32") and (len(self.pcpath) > 1):
			if self.pcpath[0] == os.sep:
				self.pcpath = self.pcpath[1:]

		if(self.pcpath == "") or (self.pcpath[-1] != os.sep):
			self.pcpath += os.sep
	
		counter=0
		if self.pcpath != os.sep:
			iterator = self.pc_model.insert(counter)
			self.pc_model.set_value(iterator,0,".."+os.sep)
			counter += 1

		foldererror = False
		try:
			content2 = dircache.listdir(self.pcpath)
		except OSError:
			foldererror = True
	
		if foldererror == False:
			content2 = content2[:] # we must copy it to ensure that ANNOTATE works fine and don't add more than one /
			dircache.annotate(self.pcpath,content2)
			if sys.platform == "win32":
				content = []
				for element in content2:
					if element[-1] == "/":
						content.append(element[:-1]+os.sep)
					else:
						content.append(element)
			else:
				content = content2
			lpaths = []
			lfiles = []

			if (self.pcpath == os.sep) and (sys.platform=="win32"):
				for letra in "ACDEFGHIJKLMNOPQRSTUVWXYZ":
					foldererror = False
					try:
						content2 = dircache.listdir(letra+":\\")
					except OSError:
						foldererror = True
	
					if foldererror == False:
						iterator = self.pc_model.insert(counter)
						self.pc_model.set_value(iterator,0,letra+":"+os.sep)
						counter += 1
			else:
				for element in content:
					if (element == "") or (element == "."+os.sep) or (element == ".") or (element[:2] == "..") or (element[-1]=="~"):
						continue
					if (show_hidden == False) and (element[0] == "."):
						continue

					if (element[-1] == os.sep):
						lpaths.append(element)
					else:
						lfiles.append(element)
				
				lpaths.sort(key=str.lower)
				lfiles.sort(key=str.lower)
				
				for element in lpaths:
					iterator = self.pc_model.insert(counter)
					self.pc_model.set_value(iterator,0,element)
					self.pcfolders.append(element[:-1])
					counter += 1
				for element in lfiles:
					iterator = self.pc_model.insert(counter)
					self.pc_model.set_value(iterator,0,element)
					self.pcfiles.append(element)
					counter += 1

		if doz88:
			thepathz88 = self.arbol.get_widget("z88path")
			thepathz88.set_text(self.z88path)
		thepathpc = self.arbol.get_widget("pcpath")
		thepathpc.set_text(self.pcpath)
		self.set_status("idle")


	def z88click(self,view,button):
		
		if button.type != gtk.gdk._2BUTTON_PRESS:
			return

		entrada = self.get_z88_marked()
		if len(entrada) == 0:
			return

		if self.z88path == "":
			self.z88path = "/"

		if self.z88path[-1] != "/":
			self.z88path += "/"

		if (entrada[0][-1] == "/"):
			if (entrada[0] == "../"):
				self.z88path = self.search_upper_path_z88(self.z88path)
			else:
				self.z88path += entrada[0]
		
		if (len(self.z88path) > 1) and (self.z88path[0] == "/"):
			self.z88path = self.z88path[1:]
		
		self.fill_paths()
		

	def pcclick(self,view,button):

		# si no es doble click, no hacemos nada
		if button.type != gtk.gdk._2BUTTON_PRESS:
			return

		entrada = self.get_pc_marked()

		if len(entrada) == 0:
			return

		if self.pcpath == "":
			self.pcpath = os.sep
	
		if self.pcpath[-1] != os.sep:
			self.pcpath += os.sep
		
		if sys.platform == "win32":
			if self.pcpath == os.sep:
				self.pcpath = ""
			else:
				if self.pcpath[0] == os.sep:
					self.pcpath = self.pcpath[1:]

		if (entrada[0][-1] == os.sep):
			if (entrada[0] == ".."+os.sep):
				self.pcpath = self.search_upper_path_pc(self.pcpath)
			else:
				self.pcpath += entrada[0]
		self.fill_paths(False)


	def get_z88_marked(self):
		
		tree,iter = self.z88tree.get_selection().get_selected_rows()
		if iter == None:
			return []

		ret = []
		for item in iter:
			ret.append(tree.get_value(tree.get_iter(item),0))
		return ret


	def get_pc_marked(self):
		
		tree,iter = self.pc_tree.get_selection().get_selected_rows()
		if iter == None:
			return []

		ret = []
		for item in iter:
			ret.append(tree.get_value(tree.get_iter(item),0))
		return ret


	def search_upper_path_z88(self,path):

		if (path == "") or (path == "/"):
			return "/"

		comps = path.split("/")

		while comps[-1] == "":
			comps = comps[:-1]
		
		out = ""
		for item in comps[:-1]:
			out += item+"/"
			
		if out=="":
			out = "/"
		return out
	

	def search_upper_path_pc(self,path):

		if (path == "") or (path == os.sep):
			return sep

		if (sys.platform == "win32") and (len(path) == 3):
			return os.sep

		comps = path.split(os.sep)
		while comps[-1] == "":
			comps = comps[:-1]

		out = ""
		for item in comps[:-1]:
			out += item+os.sep
			
		if out=="":
			out = os.sep
			
		return out


	def show_params(self):
		
		port = self.arbol.get_widget("label_port")
		speed = self.arbol.get_widget("label_speed")
		protocol = self.arbol.get_widget("label_protocol")
		export = self.arbol.get_widget("importexport")
	
		speed.set_text(str(self.z88.speed))
		port.set_text(self.z88.serial_dev)
		protocol.set_text(self.z88.protocol)
	
		if self.exporting == "abiword":
			if self.pseudospanish == "no":
				export.set_text(_("Abiword"))
			else:
				export.set_text(_("Abiword (pseudotranslation)"))
		elif self.exporting == "rtf":
			if self.pseudospanish == "no":
				export.set_text(_("RTF"))
			else:
				export.set_text(_("RTF (pseudotranslation)"))
		else:
			export.set_text(_("No conversion"))
		
		setclock = self.arbol.get_widget("setclock")
		freemem = self.arbol.get_widget("freemem")
		z88_newfolder = self.arbol.get_widget("z88_newfolder")
		z88_deletefile = self.arbol.get_widget("z88_deletefile")
		z88_renamefile = self.arbol.get_widget("z88_renamefile")
	
		if self.z88.protocol == "EAZYLINK":
			setmode = True
		else:
			setmode = False
		
		setclock.set_sensitive(setmode)
		freemem.set_sensitive(setmode)
		z88_newfolder.set_sensitive(setmode)
		z88_deletefile.set_sensitive(setmode)
		z88_renamefile.set_sensitive(setmode)


mwindow = main_window(gladepath)

gtk.main()
