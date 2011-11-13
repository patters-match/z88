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
 *
 **************************************************************************************
 *      uutools.c
 *      A utility to UUdecode or UUencode the marked file
 *
 *      20/3/00 GWL
 *      21/3/00 slight improvements
 *      25/3/00 base64 support, now uses new fopen_z88 fn for niceness
 *      26/3/00 more fiddles, uses new window/filename lib functions
 *      27/3/00 first attempt at a package with this stuff
 *      21/2/01 restructured to make the package work
 *
 */

/* Compiler directives, no bad space, not expanded */

#pragma -reqpag=0
#pragma -no-expandz88

#define FDSTDIO 1
#include <stdlib.h>
#include <stdio.h>
#include <strings.h>
#include <ctype.h>
#include <z88.h>


/* Prototypes */

int decode_i(FILE *,FILE *,unsigned char *,int);
int encode_i(FILE *,FILE *,unsigned char *,int);
FILE *createoutput(FILE *,FILE *,unsigned char *);
unsigned char uud(unsigned char, int *);
unsigned char b6d(unsigned char, int *);
unsigned char uue(unsigned char,int);
unsigned char b6e(unsigned char,int);

/* Defines & types etc */

#define BUFSIZE 80
#define NAMESIZE 80
#define ZZZ 3

enum emodes {MODE_UUE,MODE_B64E};
enum dmodes {MODE_UUD,MODE_B64D};

/* Static data */

unsigned char (*enc_fn[])()={uue,b6e};
unsigned char (*dec_fn[])()={uud,b6d};

/* Here we go... */

int main()
{
        unsigned char   fname[NAMESIZE+1];
        unsigned char   buffer[BUFSIZE+1];
        unsigned char   c,mode;
        unsigned char   *nptr,*fnptr,*fileext;
        enum emodes     encmode=MODE_UUE;       /* default is UU, not base64 */
        enum dmodes     decmode=MODE_UUD;
        FILE    *fpi,*fpo;

        opentitled(1,8,1,70,6,"UUtools v1.06");

        if ( readmail(FILEMAIL,(far char *)fname,NAMESIZE) == NULL ) {
                printf("File to encode/decode: ");
                fgets(fname,BUFSIZE,stdin);
                printf("\nPress D to decode, E to encode, or B to encode in Base64\n");
                while ( ((mode=toupper(getk()))!='D') && (mode!='E') && (mode!='B') );
                if (mode=='B') {
                        encmode=MODE_B64E;
                        mode='E';
                }
        }
        else {
                printf("Analysing file %s...\n",fname);
                mode='A';
        }

        if  ( (fpi=fopen(fname,"r") ) == NULL ) {
                printf("Cannot open file %s.\007",fname);
                sleep(ZZZ);
                exit(0);
        }

        if ( (mode=='A') || (mode=='D') ) {
        while (fgets(buffer,BUFSIZE,fpi) != NULL) {
                if (strncmp(buffer,"begin",5) == 0) {
                        if ( (nptr=strchr(strchr(buffer,' ')+1,' ')) == NULL) {
                                printf("No filename given on 'begin' line.\007");
                                fclose(fpi);
                                sleep(ZZZ);
                                exit(0);
                        }                                
                        nptr++;
                        fpo=createoutput(fpi,fpo,nptr);
                        printf("Decoding file to %s...\n",nptr);
                        if (strncmp(buffer,"begin-base64",12) == 0) decmode=MODE_B64D;
                        switch (decode_i(fpi,fpo,buffer,decmode)) {
                                case 0: printf("Successfully decoded file!\007");
                                        break;
                                case 1: printf("Incomplete file.\007");
                                        break;
                                case 2: printf("Error: short line.\007");
                                        break;
                                case 3: printf("Error writing output file.\007");
                        }
                        fclose(fpi);
                        fclose(fpo);
                        sleep(ZZZ);
                        exit(0);
                }
        }
        }

        fclose(fpi);

        if (mode=='D') {
                printf("Not an encoded file.\007");
                sleep(ZZZ);
                exit(0);
        }

        if  ( (fpi=fopen(fname,"r") ) == NULL ) {
                printf("Couldn't reopen file %s.\007",fname);
                sleep(ZZZ);
                exit(0);
        }

        fnptr=strippath(fname);
        strcpy(buffer,fnptr);   /* save original filename for later */
        if (encmode==MODE_UUE)
                fileext=".uue";
        else
                fileext=".b64";
        if ( (nptr=strchr(fnptr,'.'))==NULL )
                strcpy((fnptr+strlen(fnptr)),fileext);
        else
                strcpy(nptr,fileext);
        fpo=createoutput(fpi,fpo,fnptr);
        printf("Encoding file to %s...\n",fnptr);
        if (encode_i(fpi,fpo,buffer,encmode))
                printf("Error writing output file.\007");
        else
                printf("Successfully encoded file!\007");
        fclose(fpi);
        fclose(fpo);
        sleep(ZZZ);
        exit(0);

}


/* Now our functions */

FILE *createoutput(FILE *fpi,FILE *fpo,unsigned char *nptr)
{
        if ( (fpo=fopen(nptr,"r") ) != NULL ) {
                printf("Output file %s already exists.\007",nptr);
                fclose(fpi);
                fclose(fpo);
                sleep(ZZZ);
                exit(0);
        }
        if ( (fpo=fopen(nptr,"w") ) == NULL ) {
                printf("Unable to create file %s.\007",nptr);
                fclose(fpi);
                sleep(ZZZ);
                exit(0);
        }

        return(fpo);    /* return the new handle */
}


int decode_i(FILE *fpi,FILE *fpo,unsigned char *buffer,int decmode)
{
        unsigned char   *dptr;
        unsigned char   c;
        int     n,l,ferr;

        while (fgets(buffer,BUFSIZE,fpi) != NULL) {
                dptr=buffer;
                if (decmode==MODE_UUD) {
                        if (strncmp(buffer,"end",3) == 0) return(0);
                        n=uud(*dptr++,&n);
                        l=n*4/3;
                        if (n%3) l++;
                        if (strlen(dptr)<l) return(2);
                }
                else {
                        if (strncmp(buffer,"====",4) == 0) return(0);
                        n=strlen(buffer)*3/4;
                }
                while (n>0) {
                        c=(*dec_fn[decmode])((*dptr),&n)<<2 |
                                (*dec_fn[decmode])((*++dptr),&n)>>4;
                        if (n>=1) ferr=fputc(c,fpo);
                        c=(*dec_fn[decmode])((*dptr),&n)<<4 |
                                (*dec_fn[decmode])((*++dptr),&n)>>2;
                        if (n>=2) ferr=fputc(c,fpo);
                        c=(*dec_fn[decmode])((*dptr),&n)<<6 |
                                (*dec_fn[decmode])((*++dptr),&n);
                        if (n>=3) ferr=fputc(c,fpo);
                        n-=3;
                        dptr++;
                        if (ferr==EOF) return(3);
                }
        }

        return(1);   /* Valid termination sequence not detected */

}


int encode_i(FILE *fpi,FILE *fpo,unsigned char *buffer,int encmode)
{
        unsigned char   l,*dptr;
        int     n;
        
        if (encmode==MODE_UUE)
                fputs("begin 664 ",fpo);
        else
                fputs("begin-base64 664 ",fpo);

        fputs(buffer,fpo);
        fputc('\n',fpo);

        do {
        for (n=0,dptr=buffer;n<45;n++)
                if ((*dptr++=fgetc(fpi)) == EOF) break;

        if (n<45) for (l=n-1,dptr--;l<45;l++) *dptr++=NULL;

        l=n;
        dptr=buffer;
        if (encmode==MODE_UUE) fputc( (*enc_fn[encmode])(l),fpo );
        while (n>0) {
                fputc( (*enc_fn[encmode])((*dptr)>>2,n),fpo );
                fputc( (*enc_fn[encmode])(((*dptr)<<4) | ((*++dptr)>>4),n),fpo );
                n--;
                fputc( (*enc_fn[encmode])(((*dptr)<<2) | ((*++dptr)>>6),n),fpo );
                n--;
                if ( (fputc( (*enc_fn[encmode])(*dptr++,n),fpo )) == EOF )
                        return(3);
                n--;
        }

        if ((l>0) || (encmode==MODE_UUE)) fputc( '\n',fpo );
        } while (l);

        if (encmode==MODE_UUE)
                fputs("end\n",fpo);
        else
                fputs("====\n",fpo);


        return(0);
}


unsigned char uue(unsigned char c,int n)
{
        c=c & 0x3f;
        if (c) return(c + 0x20);
        else return('`');
}


unsigned char uud(unsigned char c,int *n)
{
        return( (c-0x20) & 0x3f );
}


unsigned char b6e(unsigned char c,int n)
/* we cheat here - only suitable for ASCII-based computers! */
{
        c=c & 0x3f;
        if (n>0) {
                if (c<26) return('A'+c);
                if (c<52) return('a'+c-26);
                if (c<62) return('0'+c-52);
                if (c==62) return('+');
                return('/'); }
        return('=');
}


unsigned char b6d(unsigned char c,int *n)
/* we cheat here - only suitable for ASCII-based computers! */
{
        if (isupper(c)) return(c-'A');
        if (islower(c)) return(26+c-'a');
        if (isdigit(c)) return(52+c-'0');
        if (c=='+') return(62);
        if (c=='/') return(63);
        return(*n=0);                   /* padding encountered */
}
        
