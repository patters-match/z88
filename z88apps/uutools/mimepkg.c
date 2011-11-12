/*
 **************************************************************************************
 *
 * UUtools utility, (c) Garry Lancaster, 2000-2001
 *
 * UUtools is free software; you can redistribute it and/or modify it under the terms of the
 * GNU General Public License as published by the Free Software Foundation;
 * either version 2, or (at your option) any later version.
 * UUtools is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
 * without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License along with UUtools;
 * see the file COPYING. If not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * $Id$
 *
 **************************************************************************************
 *      mimepkg.c
 *      Functions for the MIMEtypes package
 *
 *      27/3/00 first attempt at a package with this stuff
 *      21/2/01 restructured to make the package work
 *
 */

#define FDSTDIO 1
#include <stdio.h>

#pragma -shareoffset=6
#pragma -shared-file

/* Prototypes */

extern int decode_i(FILE *,FILE *,unsigned char *,int);
extern int decode_i(FILE *,FILE *,unsigned char *,int);
int encode(FILE *,FILE *,unsigned char *,int);
int encode(FILE *,FILE *,unsigned char *,int);
void pack_ayt(void);
void pack_bye(void);
void pack_dat(void);


/* First, the standard required calls */
/* We are very, very simple!! */

void pack_ayt(void)
{
#pragma asm
        and     a       ; Fc=0, success!
#pragma endasm
}


void pack_bye(void)
{
#pragma asm
        and     a       ; Fc=0, success!
#pragma endasm
}


void pack_dat(void)
{
#pragma asm
        ld      bc,0
        ld      de,0    ; no resources
        xor     a       ; A=0, Fc=0, success!
#pragma endasm
}


/* Now our functions */

int decode(FILE *fpi,FILE *fpo,unsigned char *buffer,int decmode)
{
        return_nc(decode_i(fpi,fpo,buffer,decmode));
}

int encode(FILE *fpi,FILE *fpo,unsigned char *buffer,int encmode)
{
        return_nc(encode_i(fpi,fpo,buffer,encmode));
}

