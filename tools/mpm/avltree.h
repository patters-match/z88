
/* -------------------------------------------------------------------------------------------------

   MMMMM       MMMMM   PPPPPPPPPPPPP     MMMMM       MMMMM
    MMMMMM   MMMMMM     PPPPPPPPPPPPPPP   MMMMMM   MMMMMM
    MMMMMMMMMMMMMMM     PPPP       PPPP   MMMMMMMMMMMMMMM
    MMMM MMMMM MMMM     PPPPPPPPPPPP      MMMM MMMMM MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
   MMMMMM     MMMMMM   PPPPPP            MMMMMM     MMMMMM

  Copyright (C) 1991-2003, Gunther Strube, gbs@users.sourceforge.net

  This file is part of Mpm.
  Mpm is free software; you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by the Free Software Foundation;
  either version 2, or (at your option) any later version.
  Mpm is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the GNU General Public License for more details.
  You should have received a copy of the GNU General Public License along with Mpm;
  see the file COPYING.  If not, write to the
  Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

  $Id$

 -------------------------------------------------------------------------------------------------*/



typedef struct avlnode {
                        short           height;        /* height of avltree (max search levels from node) */
                        void           *data;          /* pointer to data of node */
                        struct avlnode *left, *right;  /* pointers to left and right avl subtrees */
                       } avltree_t;

void    *Find(avltree_t *p, void *key, int  (*comp)(void *,void *));
void    *ReOrder(avltree_t *p, int  (*symcmp)(void *,void *));
void    Copy(avltree_t *p, avltree_t **newroot, int  (*symcmp)(void *,void *), void  *(*create)(void *));
void    DeleteAll(avltree_t **p, void (*deldata)(void *));
void    DeleteNode(avltree_t **root, void *key, int  (*comp)(void *,void *), void (*delkey)(void *));
void    InOrder(avltree_t *p, void  (*action)(void *));
void    Insert(avltree_t **root, void *key, int  (*comp)(void *,void *));
void    Move(avltree_t **p, avltree_t **newroot, int  (*symcmp)(void *,void *));
void    PreOrder(avltree_t *p, void  (*action)(void *));
