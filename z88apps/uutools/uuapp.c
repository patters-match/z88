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
 *      uuapp.c
 *      Application DOR & package structures for UUtools & MIMEtypes
 *
 *      27/3/00 first attempt at a package with this stuff
 *      19/2/01 made to work with z88dk v1.32
 *      21/2/01 restructured to make the package work
 *
 */


#define FDSTDIO 1
#include <stdio.h>


/* Prototypes */

extern void pack_ayt(void);
extern void pack_bye(void);
extern void pack_dat(void);
extern int decode(FILE *,FILE *,unsigned char *,int);
extern int encode(FILE *,FILE *,unsigned char *,int);

/* The DOR Stuff */

#include <dor.h>

/* We're providing a package with this application */

#define MAKE_PACKAGE 1
#define PACK_VERSION $0001
#define PACK_NAME "MIMEtypes"
#define PACKAGE_ID $1b
#define MAX_CALL_NUM $0c

#include <package.h>

package_str mimetypespkg[] = {
        {decode},
        {encode}
};


/*
 * We're a popup so APP_INFO is not needed
 */

#define APP_INFO ""

#define HELP1   "A utility to UUencode & UUdecode files (also base64)"
#define HELP2   "Mark a file in the Filer and start this popdown"
#define HELP3   ""
#define HELP4   "v1.06 (c) 21/02/01 Garry Lancaster"
#define HELP5   "Made with z88dk"
#define HELP6   ""

#define APP_KEY  'U'
#define APP_NAME "UUtools"
#define APP_TYPE AT_Popd
#define APP_TYPE2 AT2_Cl

#include <application.h>

/* THE END! */
