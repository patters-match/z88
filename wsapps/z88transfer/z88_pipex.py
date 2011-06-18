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
# Z88transfer is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# This code contains the TEXT FORMAT CONVERTERS, to import and export
# PIPEDREAM files to/from Abiword or RTF files

import binascii

def read_translations(filename):
	"""Read the translation table and returs it as two dictionaries"""
	
	translatefrompipe={}
	translatetopipe={}
	
	try:
		dictionary=open(filename,"rb")
	except IOError:
		return False,{},{}
	primera=True
	utf8=True
	for linea in dictionary:
		if primera==True:
			if linea=="latin1":
				utf8=False
		if linea[-1]=="\n":
			linea=linea[:-1]
		if (len(linea)>2):
			char_utf=linea[1:]
			char_pseudo=linea[0]
			if utf8:
				if len(char_utf)==2: # only double-byte chars are allowed
					# check that it's a true UTF-8 sequence
					if (((ord(char_utf[0]))&252)==192) & (((ord(char_utf[1]))&192)==128):
						# and transform it to LATIN1 chars
						if ord(char_utf[0])==195:
							char2=chr(64+ord(char_utf[1]))
						else:
							char2=char_utf[1]
							# Only valid ASCII chars
						if (ord(char_pseudo)<128) & (ord(char_pseudo)>31):
							translatefrompipe[char_pseudo]=char2
							translatetopipe[char2]=char_pseudo
			else:
				if len(char_utf)==1: # it must be a LATIN1 character
					if ((ord(char_utf))>127):
						# Only valid ASCII chars
						if (ord(char_pseudo)<128) & (ord(char_pseudo)>31):
							translatefrompipe[char_pseudo]=char_utf
							translatetopipe[char_utf]=char_pseudo
	if (translatetopipe.has_key("'"))==False:
		translatetopipe["'"]="'"
		translatefrompipe["'"]="'"
	dictionary.close()
	return True,translatefrompipe,translatetopipe


class rtf:
	"""This class contains the RTF importer/exporter"""
	
	def __init__(this,filename,mode,translation,dictfile={}):
		"""FILENAME contains the disk file where we will read or write the RTF document.
		   MODE can be 'R' to convert from RTF to PipeDream, or 'W' for PipeDream to RTF.
		   TRANSLATION can be 'Y' to use the Pseudotranslation, or 'N' to not use it.
		   WITHPIPE is a dictionary with the Pseudotranslation sequences."""
		   
		if (translation=="n") | (translation=="N"):
			this.ctranslate=False
			this.dictfile=""
		else:
			this.ctranslate=True
			this.dictfile=dictfile
		
		this.conversor=pddutilities()
		
		if (mode=="r")|(mode=="R"):
			this.fmode="r"
			this.tmpmode="rb"
		else:
			this.fmode="w"
			this.tmpmode="wb"
			
		this.fichero=open(filename,this.tmpmode)
		this.last_read=""
		
		this.creturnD="\015" # 0x0D
		this.creturnA="\012" # 0x0A
		
		if this.fmode=="r":
			this.text=""
			this.wrap_len=72
			this.creturn="\015" # 0x0D, newline code for PipeDream
		else:
			this.fichero.write("{\\rtf1\\ansi\\ansicpg1252\\deff0\n")
			this.fichero.write("{\\fonttbl\n")
			this.fichero.write("{\\f0\\fnil\\fcharset0\\fprq0\\fttruetype Times New Roman;}\n")
			this.fichero.write("{\\f1\\fnil\\fcharset0\\fprq0\\fttruetype Arial;}\n")
			this.fichero.write("{\\f2\\fnil\\fcharset0\\fprq0\\fttruetype Dingbats;}\n")
			this.fichero.write("{\\f3\\fnil\\fcharset0\\fprq0\\fttruetype Symbol;}\n")
			this.fichero.write("{\\f4\\fnil\\fcharset0\\fprq0\\fttruetype Courier New;}}\n")
			this.fichero.write("{\\colortbl\n")
			this.fichero.write("\\red0\\green0\\blue0;\n")
			this.fichero.write("\\red255\\green255\\blue255;}\n")
			this.fichero.write("{\\stylesheet\n")
			this.fichero.write("{\\s1\\fi-431\\li720\\sbasedon28\\snext28 Contents 1;}\n")
			this.fichero.write("{\\s2\\fi-431\\li1440\\sbasedon28\\snext28 Contents 2;}\n")
			this.fichero.write("{\\s3\\fi-431\\li2160\\sbasedon28\\snext28 Contents 3;}\n")
			this.fichero.write("{\\s8\\fi-431\\li720\\sbasedon28 Lower Roman List;}\n")
			this.fichero.write("{\\s5\\tx431\\sbasedon24\\snext28 Numbered Heading 1;}\n")
			this.fichero.write("{\\s6\\tx431\\sbasedon25\\snext28 Numbered Heading 2;}\n")
			this.fichero.write("{\\s7\\fi-431\\li720 Square List;}\n")
			this.fichero.write("{\\*\\cs11\\sbasedon28 Endnote Text;}\n")
			this.fichero.write("{\\s4\\fi-431\\li2880\\sbasedon28\\snext28 Contents 4;}\n")
			this.fichero.write("{\\s9\\fi-431\\li720 Diamond List;}\n")
			this.fichero.write("{\\s10\\fi-431\\li720 Numbered List;}\n")
			this.fichero.write("{\\*\\cs12\\fs20\\super Endnote Reference;}\n")
			this.fichero.write("{\\s13\\fi-431\\li720 Triangle List;}\n")
			this.fichero.write("{\\s14\\tx431\\sbasedon26\\snext28 Numbered Heading 3;}\n")
			this.fichero.write("{\\s15\\fi-431\\li720 Dashed List;}\n")
			this.fichero.write("{\\s16\\fi-431\\li720\\sbasedon10 Upper Roman List;}\n")
			this.fichero.write("{\\s17\\sb440\\sa60\\f1\\fs24\\b\\sbasedon28\\snext28 Heading 4;}\n")
			this.fichero.write("{\\s18\\fi-431\\li720 Heart List;}\n")
			this.fichero.write("{\\s34\\fi-431\\li720 Box List;}\n")
			this.fichero.write("{\\s20\\fi-431\\li720\\sbasedon10 Upper Case List;}\n")
			this.fichero.write("{\\s21\\fi-431\\li720 Bullet List;}\n")
			this.fichero.write("{\\s22\\fi-431\\li720 Hand List;}\n")
			this.fichero.write("{\\*\\cs23\\fs20\\sbasedon28 Footnote Text;}\n")
			this.fichero.write("{\\s24\\sb440\\sa60\\f1\\fs34\\b\\sbasedon28\\snext28 Heading 1;}\n")
			this.fichero.write("{\\s25\\sb440\\sa60\\f1\\fs28\\b\\sbasedon28\\snext28 Heading 2;}\n")
			this.fichero.write("{\\s19\\qc\\sb240\\sa120\\f1\\fs32\\b\\sbasedon28\\snext28 Contents Header;}\n")
			this.fichero.write("{\\s27\\fi-431\\li720 Tick List;}\n")
			this.fichero.write("{\\s26\\sb440\\sa60\\f1\\fs24\\b\\sbasedon28\\snext28 Heading 3;}\n")
			this.fichero.write("{\\s29\\fi-431\\li720\\sbasedon10 Lower Case List;}\n")
			this.fichero.write("{\\s30\\li1440\\ri1440\\sa120\\sbasedon28 Block Text;}\n")
			this.fichero.write("{\\s36\\f4\\sbasedon28 Plain Text;}\n")
			this.fichero.write("{\\s32\\tx1584\\sbasedon5\\snext28 Section Heading;}\n")
			this.fichero.write("{\\s33\\fi-431\\li720 Implies List;}\n")
			this.fichero.write("{\\s28\\f0\\fs24\\lang1034 Normal;}\n")
			this.fichero.write("{\\s35\\fi-431\\li720 Star List;}\n")
			this.fichero.write("{\\*\\cs31\\fs20\\super Footnote Reference;}\n")
			this.fichero.write("{\\s37\\tx1584\\sbasedon5\\snext28 Chapter Heading;}}\n")
			this.fichero.write("\\kerning0\\cf0\\ftnbj\\fet2\\ftnstart1\\ftnnar\\aftnnar\\ftnstart1\\aftnstart1\\aenddoc\\facingp\\titlepg\\revprop3{\\info}\\deftab720\\viewkind1\\paperw11905\\paperh16837\\margl1440\\margr1440\\widowctl\n")
			this.fichero.write("\\sectd\\sbknone\\colsx360\\pgncont\\ltrsect\n")
	
	def add_char(this,caracter):
		if (caracter!=this.creturnA) & (caracter!=this.creturnD):
			this.parrafo+=caracter
			this.pstyles+=chr(this.style)
	
	def add_paragraph(this):
		if this.parrafo!="":
			this.texto.append([this.pformat,this.parrafo,this.pstyles])
			this.pformat&=3
		this.parrafo=""
		this.pstyles=""

	def proccess_rtf(this,caracter):
		
		if this.mode==2:
			if caracter=="}":
				this.mode=0
		
		if this.mode==1:
			if (caracter=='\\')|(caracter=="{")|(caracter=="}"):
				this.add_char(caracter)
				caracter=""
				this.mode=0
				return
			elif caracter=='*':
				this.mode=101 # wait for an end of block
				return
			else:
				this.command=caracter
				if this.command=="'":
					this.param=""
					this.mode=24
					return
				else:
					this.mode=3 # wait for a command
				return
		
		if this.mode==3:
			if caracter.isalpha():
				this.command+=caracter
				return
			elif (caracter.isdigit())|(caracter=='-'):
				this.param=caracter
				this.mode=4
				return
			elif caracter==" ":
				caracter=""
				this.mode=this.run_comand(this.command,"")
				return
			else:				
				this.mode=this.run_comand(this.command,"")
		
		if this.mode==4:
			if (caracter.isdigit())|(caracter.isalpha()):
				this.param+=caracter
				return
			else:
				this.mode=this.run_comand(this.command,this.param)
				if caracter==" ":
					return
		
		if this.mode==24:
			this.param=caracter
			this.mode=25
			return
			
		if this.mode==25:
			this.param+=caracter
			this.mode=this.run_comand(this.command,this.param)
			return
		
		if this.mode==100: # jump over mode
			if caracter=='{':
				this.contador+=1
				this.mode=101
			elif caracter=='}':
				this.mode=0
		elif this.mode==101:
			if caracter=='{':
				this.contador+=1
			elif caracter=='}':
				this.contador-=1
				if this.contador==0:
					this.mode=0
			elif caracter=='\\':
				this.mode=102
		elif this.mode==102:
			this.mode=101
		
		if this.mode==0: # letter mode
			if caracter=='{':
				this.style_stack.append(this.style)
				this.style_stack.append(this.pformat&3)
				this.style_stack.append(this.jump)
			elif caracter=='}':
				stacklen=len(this.style_stack)
				if stacklen>0:
					this.jump=this.style_stack[-1]
					this.pformat=(this.style_stack[-2])+(this.pformat&4)
					this.style=this.style_stack[-3] # take out from the stack
					if stacklen>3:
						this.style_stack=this.style_stack[:-3]
					else:
						this.style_stack=[]
			elif caracter=='\\':
				this.mode=1
			elif caracter!="":
				if ((caracter!=this.creturnA)&(caracter!=this.creturnD)) | (this.saltos!=0):
					if this.must_jump==0:
						this.add_char(caracter)
					else:
						this.must_jump-=1
					this.saltos=1

	def run_comand(this,command,parameter):
	
		this.contador=1
		
		if (command=="fonttbl"):
			return 100
		if (command=="filetbl"):
			return 100
		if (command=="colortbl"):
			return 101
		if (command=="stylesheet"):
			return 100
		if (command=="listtables"):
			return 100
		if (command=="revtbl"):
			return 100
		if (command=="info"):
			return 100
			
		if (command=="pntxta"):
			return 100
		if (command=="pntxtb"):
			return 100

		if (command=="page"):
			this.pformat|=4
			
		if (command=="ql"):
			this.pformat&=4
		if (command=="qc"):
			this.pformat&=4
			this.pformat|=1
		if (command=="qr"):
			this.pformat&=4
			this.pformat|=2
			
		if (command=="plain"):
			this.style=0
		
		if (command=="b"):
			if (parameter=="0"):
				this.style&=253
			else:
				this.style|=2

		if (command=="i"):
			if (parameter=="0"):
				this.style&=251
			else:
				this.style|=4

		if (command=="ul"):
			if (parameter=="0"):
				this.style&=254
			else:
				this.style|=1

		if (command=="uc"):
			this.jump=int(parameter)
			
		if (command=="u"):
			this.add_char(chr(int(parameter)))
			this.must_jump=this.jump
			
		if (command=="'"):
			if this.must_jump!=0:
				this.must_jump-=1
			else:
				this.add_char(binascii.a2b_hex(parameter))

		if (command=="par"):
			this.add_paragraph()

		return 0

	def close(this):
		if this.fmode=="w":
			this.conversor.close()
			if this.ctranslate:
				texto=this.conversor.pseudo2latin(this.conversor.ctext,this.dictfile)
			else:
				texto=this.conversor.ctext
			this.inicio=False
			for elemento in texto:
				if (this.inicio) & ((elemento[0]&4)==0):
					this.fichero.write("\\pard\\plain\\ltrpar\\ql\\s28\\itap0{\\s28\\f0\\fs24\\lang1034{\\*\\listtag0}\\par}\n")
				this.inicio=True
				this.fichero.write('\\pard\\plain\\ltrpar\\q')
				align=elemento[0]&0x03
				if align==2: # right
					this.fichero.write('r')
				elif align==1: # center
					this.fichero.write('c')
				else: # left
					this.fichero.write('l')
				this.fichero.write('\\s28\\itap0')
				current_style=ord(elemento[2][0])
				this.set_style(current_style,False)
				if (elemento[0]&4)!=0:
					this.fichero.write('\\page ')
				for posicion in range(len(elemento[1])):
					style=ord(elemento[2][posicion])
					if style!=current_style:
						current_style=style
						this.set_style(current_style,True)
					this.fichero.write(this.translate2(elemento[1][posicion]))
				this.fichero.write("}{\\s28\\f0\\fs24\\lang1034{\\*\\listtag0}\\par}\n")
			this.fichero.write('}')
		this.fichero.close()

	def translate2(this,caracter):
		if ((ord(caracter))<128):
			return caracter
		else:
			return ("\\'"+binascii.b2a_hex(caracter))

	def set_style(this,style,ending):

		if ending:
			this.fichero.write('}')
		this.fichero.write('{\\s28\\f0\\fs24')
		if (style&2)!=0:
			this.fichero.write('\\b')
		if (style&1)!=0:
			this.fichero.write('\\ul')
		if (style&4)!=0:
			this.fichero.write('\\i')
		this.fichero.write('\\lang1034{\\*\\listtag0}\\abinodiroverride\\ltrch ')

	def export(this):
	
		this.style_stack=[]
		this.jump_stack=[]
		this.jump=0
		this.must_jump=0
		this.style=0
		this.mode=0
		this.contador=0
		this.saltos=0
		this.texto=[]
		this.parrafo=""
		this.pstyles=""
		this.pformat=0
	
		while(1):
			caracter=this.fichero.read(1)
			if caracter=="":
				break
			this.proccess_rtf(caracter)
		this.proccess_rtf("\n")
		
		if this.ctranslate:
			this.texto=this.conversor.latin2pseudo(this.texto,this.dictfile)
		this.conversor.convert2pdd(this.texto,this.wrap_len)
		this.text=this.conversor.text
		return 0
		
	def write(this,caracter):
		this.conversor.write(caracter)

class abiword:
	"""This class contains the Abiword importer/exporter"""
	
	def __init__(this,filename,mode,translation,dictfile={}):
		"""FILENAME contains the disk file where we will read or write the Abiword document.
		   MODE can be 'R' to convert from Abiword to PipeDream, or 'W' for PipeDream to Abiword.
		   TRANSLATION can be 'Y' to use the Pseudotranslation, or 'N' to not use it.
		   WITHPIPE is a dictionary with the Pseudotranslation sequences."""
	
		if (translation=="n") | (translation=="N"):
			this.ctranslate=False
			this.dictfile=""
		else:
			this.ctranslate=True
			this.dictfile=dictfile
		
		this.conversor=pddutilities()
		
		if (mode=="r")|(mode=="R"):
			this.fmode="r"
			this.tmpmode="rb"
		else:
			this.fmode="w"
			this.tmpmode="wb"
			
		this.fichero=open(filename,this.tmpmode)
		this.last_read=""
		
		if this.fmode=="r":
			this.text=""
			this.wrap_len=72
			this.creturn="\015" # 0x0D, newline code for PipeDream
		else:
			this.fichero.write('<?xml version="1.0" encoding="UTF-8"?>\n')
			this.fichero.write('<!DOCTYPE abiword PUBLIC "-//ABISOURCE//DTD AWML 1.0 Strict//EN" "http://www.abisource.com/awml.dtd">\n')
			this.fichero.write('<abiword template="false" styles="unlocked" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:svg="http://www.w3.org/2000/svg" xmlns:dc="http://purl.org/dc/elements/1.1/" fileformat="1.1" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:awml="http://www.abisource.com/awml.dtd" xmlns="http://www.abisource.com/awml.dtd" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.9.1" xml:space="preserve" props="dom-dir:ltr; document-footnote-restart-section:0; document-endnote-type:numeric; document-endnote-place-enddoc:1; document-endnote-initial:1; lang:es-ES; document-endnote-restart-section:0; document-footnote-restart-page:0; document-footnote-type:numeric; document-footnote-initial:1; document-endnote-place-endsection:0">\n')
			this.fichero.write('<!-- ======================================================================== -->\n')
			this.fichero.write('<!-- This file is an AbiWord document.                                        -->\n')
			this.fichero.write('<!-- AbiWord is a free, Open Source word processor.                           -->\n')
			this.fichero.write('<!-- More information about AbiWord is available at http://www.abisource.com/ -->\n')
			this.fichero.write('<!-- You should not edit this file by hand.                                   -->\n')
			this.fichero.write('<!-- ======================================================================== -->\n')
			this.fichero.write('\n')
			this.fichero.write('<metadata>\n')
			this.fichero.write('<m key="dc.format">application/x-abiword</m>\n')
			this.fichero.write('<m key="abiword.generator">AbiWord</m>\n')
			this.fichero.write('</metadata>\n')
			this.fichero.write('<styles>\n')
			this.fichero.write('<s type="P" name="Normal" followedby="Current Settings" props="text-indent:0in; margin-top:0pt; margin-left:0pt; font-stretch:normal; line-height:1.0; text-align:left; bgcolor:transparent; lang:es-ES; dom-dir:ltr; margin-bottom:0pt; font-weight:normal; text-decoration:none; font-variant:normal; color:000000; text-position:normal; font-size:12pt; margin-right:0pt; font-style:normal; widows:2; font-family:Times New Roman"/>\n')
			this.fichero.write('</styles>\n')
			this.fichero.write('<pagesize pagetype="A4" orientation="portrait" width="210.000000" height="297.000000" units="mm" page-scale="1.000000"/>\n')
			this.fichero.write('<section props="page-margin-footer:0.5000in; page-margin-header:0.5000in; page-margin-right:1.0000in; page-margin-left:1.0000in; page-margin-top:1.0000in; page-margin-bottom:1.0000in">\n')
			this.inicio=False
	
	def write(this,caracter):
		this.conversor.write(caracter)
	
	def close(this):
		if this.fmode=="w":
			this.conversor.close()
			if this.ctranslate:
				texto=this.conversor.pseudo2latin(this.conversor.ctext,this.dictfile)
			else:
				texto=this.conversor.ctext
			for elemento in texto:
				if this.inicio:
					this.fichero.write('</c></p>\n<p style="Normal"></p>\n')
				this.inicio=True
				this.fichero.write('<p style="Normal" props="text-align:')
				align=elemento[0]&0x03
				if align==2: # right
					this.fichero.write('right')
				elif align==1: # center
					this.fichero.write('center')
				else: # left
					this.fichero.write('left')
				this.fichero.write('">')
				if (elemento[0]&4)!=0:
					this.fichero.write('<pbr/>')
				current_style=ord(elemento[2][0])
				this.set_style(current_style,False)
				for posicion in range(len(elemento[1])):
					style=ord(elemento[2][posicion])
					if style!=current_style:
						current_style=style
						this.set_style(current_style,True)
					this.fichero.write(this.translate2(elemento[1][posicion]))
			this.fichero.write('</c></p>\n</section>\n</abiword>')
		this.fichero.close()
		
	def translate2(this,caracter):
		ncaracter=ord(caracter)
		if caracter=="<":
			return "&lt;"
		elif caracter==">":
			return "&gt;"
		elif caracter=="&":
			return "&amp;"
		elif ncaracter>127:
			if ncaracter<192:
				return "\302"+caracter
			else:
				return "\303"+chr(ncaracter-64)
		else:
			return caracter

	def set_style(this,style,ending):
		if ending:
			this.fichero.write('</c>')
		this.fichero.write('<c props="font-weight:')
		if (style&2)!=0:
			this.fichero.write('bold')
		else:
			this.fichero.write('normal')
		this.fichero.write('; text-decoration:')
		if (style&1)!=0:
			this.fichero.write('underline')
		else:
			this.fichero.write('none')
		this.fichero.write('; font-style:')
		if (style&4)!=0:
			this.fichero.write('italic')
		else:
			this.fichero.write('normal')
		this.fichero.write('">')

	def read_tag_or_line(this):
		"""reads a tag or a line from the currently open file and translates
		the characters"""
		
		while True:
			retorno=this.read2()
			if (len(retorno)!=1):
				return retorno
			if retorno[0]!="\n":
				return retorno
		
	def read2(this):
		
		if (this.last_read=="") | (this.last_read==">"):
			caracter=this.fichero.read(1)
		else:
			caracter=this.last_read
		if caracter=="":
			return []
		if caracter=="<": #a tag
			elementos=[]
			while (caracter!=">") & (caracter!=""):
				linea=""
				while (caracter!=">") & (caracter!=" ") & (caracter!=""):
					linea=linea+caracter
					caracter=this.fichero.read(1)
				elementos.append(linea)
				if caracter!=">":
					caracter=this.fichero.read(1)
			this.last_read=caracter
			return elementos # return TAG type, the tag and all the parameters inside
		else:
			linea=caracter
			while (caracter!="<") & (caracter!=""):
				caracter=this.fichero.read(1)
				if caracter!="<":
					linea+=caracter
			this.last_read=caracter
			return [this.translate(linea)]

	def translate(this,linea):
		"""Translates UTF-8 characters to Latin1"""

		retorno=""
		extendido=0
		for letra in linea:
			if extendido==5: # jump until next valid UTF-8 character
				v=ord(letra)
				if (v<128) | ((v&254)==254):
					extendido=0
		
			if extendido==0:
				if letra=="%":
					retorno+="%%"
				elif ord(letra)>127:
					v=ord(letra)
					if v==195:
						extendido=3
					elif v==194:
						extendido=4
					else:
						extendido=5 # not valid UTF-8 character. Jump it.
				elif letra=="&":
					extendido=1
				else:
					retorno+=letra
			elif extendido==1:
				if letra=="a":
					retorno+="&"
				elif letra=="g":
					retorno+=">"
				elif letra=="l":
					retorno+="<"
				extendido=2
			elif extendido==2:
				if letra==";":
					extendido=0
			elif extendido==3:
				extendido=0
				# transform to a LATIN1 character
				retorno+=chr(64+ord(letra))
			elif extendido==4:
				extendido=0
				# transform to a LATIN1 character
				retorno+=letra
		return retorno

	def search_start(this):
		""" Searchs the text for the SECTION tag, and returns True when found, or
		false if it doesn't exists """
		
		while True:
			leido=this.read_tag_or_line()
			if len(leido)==0:
				return False
			if leido[0]=="<section":
				return True
	
	def proccess_c(this,params):

		for elemento2 in params:
			elemento=elemento2[:]
			if (elemento[-1]=='"') | (elemento[-1]==';'):
				elemento=elemento[:-1]
			if elemento[:7]=='props="':
				elemento=elemento[7:]
			if elemento=="font-weight:normal":
				this.current_style&=5
			elif elemento=="font-weight:bold":
				this.current_style|=2
			elif elemento=="text-decoration:none":
				this.current_style&=6
			elif elemento=="text-decoration:underline":
				this.current_style|=1
			elif elemento=="font-style:normal":
				this.current_style&=3
			elif elemento=="font-style:italic":
				this.current_style|=4
		
	def eval_p(this,elemento):
		
		if elemento[:18]=='props="text-align:':
			if elemento[18:22]=='left':
				return 0
			elif elemento[18:24]=='center':
				return 1
			elif elemento[18:23]=='right':
				return 2
			else:
				return 3
		return 3
	
	def export(this):
	
		if this.search_start()==False:
			return -1; # no start
		leido="<"
		
		texto=[]
		parrafo=0 # default: left
		contenido=""
		formato=""
		this.current_style=0
		lista=this.read_tag_or_line()
		while leido!="</abiword":
			if leido=="<p":
				for elemento in lista:
					valor=this.eval_p(elemento)
					if valor!=3:
						parrafo=(parrafo&252)|valor
						this.current_align=valor
			elif leido=="</p":
				if contenido!="":
					texto.append([parrafo,contenido,formato])
					parrafo=0
				else:
					parrafo&=4; # maintain the "new page" bit
				contenido=""
				formato=""
				this.current_style=0
			elif leido=="<c":
				this.proccess_c(lista)
			elif leido=="<pbr/":
				if contenido!="":
					texto.append([parrafo,contenido,formato])
				parrafo=0
				contenido=""
				formato=""
				this.current_style=0
				parrafo=(parrafo&251)|4
			else:
				if leido[0]!="<":
					for caracter in leido:
						if caracter=="\n":
							contenido+=" "
						else:
							contenido+=caracter
						formato+=chr(this.current_style)
			lista=this.read_tag_or_line()
			leido=lista[0]
		if this.ctranslate:
			texto=this.conversor.latin2pseudo(texto,this.dictfile)
		this.conversor.convert2pdd(texto,this.wrap_len)
		this.text=this.conversor.text
		return 0

class pddutilities:
	"""This class contains the functions that converts between intermediate and PDD format"""

	# First we read the text and convert it to an intermediate format
	# TEXTO contains the text to be converted, or the converted text. It's a list.
	# Each element of TEXTO is a list with three elemenst, containing one paragraph and its format
	# First element is an integer, and contains the type:
	#	bit 2=1: There's a page jump before this paragraph
	#	bits 0,1=00: left alignment
	#	bits 0,1=01: center alignment
	#	bits 0,1=10: right alignment
	# Second element is a string with the ASCII text
	# Third element contains one byte for each ASCII character, representing its format
	#	0 normal
	#	bit 1=1 if underline 
	#	bit 2=1 if bold
	#	bit 4=1 if italic

	def latin2pseudo(this,text,translatetopipe):
		
		text_out=[]
		for elemento in text:
			texto1=""
			texto2=""
			for posicion in range(len(elemento[1])):
				caracter=elemento[1][posicion]
				estilo=elemento[2][posicion]
				if translatetopipe.has_key(caracter):
					texto1+="'"+translatetopipe[caracter]
					texto2+=2*estilo
				else:
					texto1+=caracter
					texto2+=estilo
			text_out.append([elemento[0],texto1,texto2])
		
		return text_out
	
	def pseudo2latin(this,text,translatefrompipe):
		
		text_out=[]
		for elemento in text:
			texto1=""
			texto2=""
			modo=0
			for posicion in range(len(elemento[1])):
				caracter=elemento[1][posicion]
				estilo=elemento[2][posicion]
				if modo==0:
					if caracter=="'":
						modo=1
					else:
						texto1+=caracter
						texto2+=estilo
				else:
					modo=0
					if translatefrompipe.has_key(caracter):
						texto1+=translatefrompipe[caracter]
					else:
						texto1+=caracter
					texto2+=estilo
			text_out.append([elemento[0],texto1,texto2])
		
		return text_out
				

	def __init__(this,translator=""):
		this.creturn="\015" # 0x0D
		this.creturnD="\015" # 0x0D
		this.creturnA="\012" # 0x0A	
		this.command=""
		this.ctext=[]
		this.current_style=0
		this.current_mode=0
		this.current_text=""
		this.current_tstyle=""
		this.current_talign=0
		this.last_char=""
		
	def add_char(this,caracter):
		this.current_text+=caracter
		this.current_tstyle+=chr(this.current_style)
	
	def newline(this):
		if this.current_text!="":
			while this.current_text[-1]==" ":
				this.current_text=this.current_text[:-1]
				this.current_tstyle=this.current_tstyle[:-1]
				if this.current_text=="":
					break
		if this.current_text!="":
			this.ctext.append([this.current_talign,this.current_text,this.current_tstyle])
			this.current_talign=0
		else:
			this.current_talign&=4;
		this.current_text=""
		this.current_tstyle=""
		this.current_style=0
	
	def close(this):
		this.newline()
	
	def write(this,caracter):
		if this.current_mode==2:
			if caracter==this.creturnD:
				this.newline()
				this.current_mode=4 # wait for printable character
			elif caracter!=this.creturnA: # ignore the 0x0A characters
				if this.last_char!=" ":
					this.add_char(" ")
					this.last_char=" "
				this.current_mode=0
		elif this.current_mode==3:
			if caracter==this.creturnA:
				this.newline()
				this.current_mode=4 # wait for printable character
			elif caracter!=this.creturnD: # ignore the 0x0D characters
				if this.last_char!=" ":
					this.add_char(" ")
					this.last_char=" "
				this.current_mode=0
		elif this.current_mode==4:
			if (caracter!=this.creturnA) & (caracter!=this.creturnD):
				this.current_mode=0
		
		if this.current_mode==0:
			if caracter=='%':
				this.command=""
				this.current_mode=1 # command mode
			elif caracter==this.creturnD:
				this.current_style=0
				this.current_mode=2 # returnD_mode
			elif caracter==this.creturnA:
				this.current_style=0
				this.current_mode=3 # returnA_mode
			else:
				this.add_char(caracter)
				this.last_char=caracter
		elif this.current_mode==1:
			if caracter=='%': # end of command
				this.current_mode=this.proccess_command()
			else:
				this.command+=caracter
		elif this.current_mode==5:
			this.current_style=0
			if (caracter==this.creturnA) | (caracter==this.creturnD):
				this.current_mode=4
		
	def proccess_command(this):
		if this.command=="OP":
			return 5 # wait for a CR
		
		if this.command=="":
			this.add_char("%")
			return 0
		if this.command=="H1": # underline
			this.current_style^=1
			return 0
		if this.command=="H2": # bold
			this.current_style^=2
			return 0
		if this.command=="H4": # italic
			this.current_style^=4
			return 0
			
		if this.command=="P0": # new page
			this.setnewformat(4)
		if this.command=="R" : # right align
			this.setnewformat(2)
		if this.command=="C" : # center align
			this.setnewformat(1)
		if this.command=="L" : # left align
			this.setnewformat(0)
		return 0 # normal mode

	def setnewformat(this,format):
		if this.current_text!="": # if we find a "NEW PAGE", or "ALIGN CHANGE" command in the middle
			this.newline() # of a paragraph, we have to end it and start a new paragraph
		if format==4:
			this.current_talign=4
		else:
			this.current_talign&=4
			this.current_talign+=format

	def convert2pdd(this,texto,wrap_len):
		
		this.text=""
		
		otro=False
		cambio_alineacion=False
		current_style=0
		this.text="%CO:A,12,"+str(wrap_len)+"%"
		for elemento in texto:
			if otro:
				if current_style!=0:
					this.set_style(current_style,0)
				this.text+=this.creturn
			if (elemento[0]&4)!=0:
				this.text+="%P0%"
			alineacion=(elemento[0])&3
			while True:
				if otro:
					this.text+=this.creturn
				otro=True
				current_style=0
				inicio=False
				linelen=0
				if (alineacion==0)&(cambio_alineacion):
					cambio_alineacion=False
					this.text+="%L%"
				elif alineacion==1:
					cambio_alineacion=True
					this.text+="%C%"
				elif alineacion==2:
					cambio_alineacion=True
					this.text+="%R%"
				while True:
					if inicio:
						a_sumar=1
					else:
						a_sumar=0
					inicio=True
					if (linelen+a_sumar+len(elemento[1]))<=wrap_len:
						current_style=this.add_text(elemento[1],elemento[2],a_sumar,current_style)
						linelen+=a_sumar+len(elemento[1])
						elemento[1]=""
						elemento[2]=""
						break;
					else:
						posicion=elemento[1].find(" ")
						if posicion==-1:
							if linelen==0:
								this.add_text(elemento[1][:wrap_len],elemento[2][:wrap_len],0,current_style)
								elemento[1]=elemento[1][wrap_len:]
								elemento[2]=elemento[2][wrap_len:]
								linelen+=wrap_len
							break;
						else:
							if (linelen+a_sumar+posicion)<=wrap_len:
								current_style=this.add_text(elemento[1][:posicion],elemento[2][:posicion],a_sumar,current_style)
								elemento[1]=elemento[1][posicion+1:]
								elemento[2]=elemento[2][posicion+1:]
								linelen+=(posicion+a_sumar)
							else:
								break
				if elemento[1]=="":
					break;
								
		while (this.text[-1]==this.creturn):
			this.text=this.text[:-1]
		this.text+=this.creturn+"%CO:B,12,60%%CO:C,12,48%%CO:D,12,36%%CO:E,12,24%%CO:F,12,12%"
	
	def add_text(this,texto,estilo,espacios,current_style):
	
		tamano=len(texto)
		if espacios!=0:
			this.text+=" "
		for posicion in range(tamano):
			style=ord(estilo[posicion])
			if current_style!=style:
				current_style=this.set_style(current_style,style)
			this.text+=texto[posicion]
		return current_style
		
	def set_style(this,current_style,new_style):
		
		style=new_style^current_style
		
		if (style&1!=0): # underline
			this.text+=("%H1%")
		if (style&2!=0): # bold
			this.text+=("%H2%")
		if (style&4!=0): # italic
			this.text+=("%H4%")
		return new_style
