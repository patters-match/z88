
/* -------------------------------------------------------------------------------------------------

   MMMMM       MMMMM   PPPPPPPPPPPPP     MMMMM       MMMMM
    MMMMMM   MMMMMM     PPPPPPPPPPPPPPP   MMMMMM   MMMMMM
    MMMMMMMMMMMMMMM     PPPP       PPPP   MMMMMMMMMMMMMMM
    MMMM MMMMM MMMM     PPPPPPPPPPPP      MMMM MMMMM MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
    MMMM       MMMM     PPPP              MMMM       MMMM
   MMMMMM     MMMMMM   PPPPPP            MMMMMM     MMMMMM

  Copyright (C) 1991-2003, Gunther Strube

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


#include <stdlib.h>
#include "avltree.h"


/* Internal maintainance functions */
static void RotateLeft (avltree_t ** p);
static void RotateRight (avltree_t ** p);
static void FixHeight (avltree_t * p);
static void BalanceLeft (avltree_t ** p, short adj);
static void BalanceRight (avltree_t ** p, short adj);
static void DeleteMin (avltree_t ** p, void **data);
static short Difference (avltree_t * p);


/*
 * Find identifier in the avltree rooted at p
 */
void *
Find (avltree_t * p, void *key, int (*comp) (void *, void *))
{
  int cmp;

  if (p == NULL)
    return NULL;
  else
    {
      if ((cmp = comp (key, p->data)) == 0)
        return p->data;
      else
        {
          if (cmp < 0)
            return Find (p->left, key, comp);   /* search left subtree of p */
          else
            return Find (p->right, key, comp);  /* search right subtree of p */
        }
    }
}


/*
 * Insert identifier in the subtree rooted at p
 */
void
Insert (avltree_t ** p, void *newdata, int (*comp) (void *, void *))
{
  int cmp, dif;

  if (*p == NULL)
    {
      *p = (avltree_t *) malloc (sizeof (avltree_t));
      if (*p != NULL)
        {
           (*p)->height = 0;
           (*p)->data = newdata; /* new data linked to avltree node */
           (*p)->left = NULL;    /* initialized to no subtrees */
           (*p)->right = NULL;
        }
    }
  else
    {
      cmp = comp (newdata, (*p)->data);
      if (cmp <= 0)
        Insert (&(*p)->left, newdata, comp);    /* put it in left subtree of p */
      else
        if (cmp > 0)
          Insert (&(*p)->right, newdata, comp);   /* put it in right subtree of p */

      FixHeight (*p);       /* may have to adjust height if subtree grew */
      dif = Difference (*p);
      if (dif > 1)      /* insertion caused left subtree to be too high */
        BalanceLeft (p, 1);
      else
        if (dif < -1)    /* right subtree is too high */
          BalanceRight (p, 1);
    }
}


void
DeleteNode (avltree_t ** n, void *key, int (*comp) (void *, void *), void (*deletekey) (void *))
{
  avltree_t *temp;
  void *dataptr;        /* pointer to data record of avltree node */
  short dif, cmp;

  if (*n != NULL)
    {
      cmp = comp (key, (*n)->data);
      if (cmp < 0)
        DeleteNode (&(*n)->left, key, comp, deletekey);
      else
        {
          if (cmp > 0)
            DeleteNode (&(*n)->right, key, comp, deletekey);
          /* node to be deleted is found */
          else
            {
              if ((*n)->left != NULL && (*n)->right != NULL)
                {               /* node has both left & right subtrees */
                  DeleteMin (&(*n)->right, &dataptr);
                  deletekey ((*n)->data);   /* release old data */
                  (*n)->data = dataptr;     /* assign new data */
                }
              else
                {
                  temp = *n;
                  if ((*n)->right == NULL) {
                    if ((*n)->left == NULL)
                       *n = NULL;    /* node has no children */
                    else
                       *n = (*n)->left;  /* node has left child only */
                    }
                  else
                    *n = (*n)->right;   /* node has right child only */

                  deletekey (temp->data);   /* delete node data */
                  free (temp);  /* delete avltree node */
                }
            }
        }

      if (*n != NULL)
        {
          FixHeight (*n);
          dif = Difference (*n);
          if (dif > 1)      /* deletion caused left subtree to be too high */
            BalanceLeft (n, -1);
          else
            if (dif < -1)    /* deletion caused right subtree to be too high */
              BalanceRight (n, -1);
        }
    }
}


void
DeleteAll (avltree_t ** p, void (*deldata) (void *))
{
  if (*p != NULL)
    {
      DeleteAll (&(*p)->left, deldata);
      DeleteAll (&(*p)->right, deldata);

      deldata ((*p)->data);
      free (*p);
      *p = NULL;
    }
}


/*
 * interface function to Move source avltree into destination avl-tree
 * source avltree will be empty, when completed.
 */
void
Move (avltree_t ** p, avltree_t ** newroot, int (*symcmp) (void *, void *))
{
  if (*p != NULL)
    {
      Move (&(*p)->left, newroot, symcmp);
      Move (&(*p)->right, newroot, symcmp);

      Insert (newroot, (*p)->data, symcmp); /* Insert node data by symcmp order */
      free (*p);        /* release avl-node */
      *p = NULL;
    }
}


/*
 * interface function to Copy source avltree into destination avl-tree
 */
void
Copy (avltree_t * p, avltree_t ** newroot, int (*symcmp) (void *, void *), void *(*create) (void *))
{
  void *sym;

  if (p != NULL)
    {
      Copy (p->left, newroot, symcmp, create);
      Copy (p->right, newroot, symcmp, create);
      sym = create (p->data);   /* create a Copy of data */
      if (sym != NULL)
        Insert (newroot, sym, symcmp);  /* Insert node data by symcmp order */
    }
}



/*
 * interface function to re-order avltree
 */
void *
ReOrder (avltree_t * p, int (*symcmp) (void *, void *))
{
  avltree_t *newroot = NULL;

  Move (&p, &newroot, symcmp);  /* re-order avl-tree */
  return newroot;       /* return pointer to new root */
}


/*
 * interface function to traverse the avltree in InOrder (left, node, right)
 * and perform appropriate action for each data node.
 */
void
InOrder (avltree_t * p, void (*action) (void *))
{
  if (p != NULL)
    {
      InOrder (p->left, action);
      action (p->data);
      InOrder (p->right, action);
    }
}


/*
 * interface function to traverse the avltree in PreOrder (node, left, right)
 * and perform appropriate action for each data node.
 */
void
PreOrder (avltree_t * p, void (*action) (void *))
{
  if (p != NULL)
    {
      action (p->data);
      InOrder (p->left, action);
      InOrder (p->right, action);
    }
}


/* -------------------------- internal maintainance functions -------------------------- */


/*
 * rotate nodes pointed to by x and x->right
 */
static void
RotateLeft (avltree_t ** x)
{               /* return *x to caller */
  avltree_t *y;

  if ((*x) != NULL)
    if ((*x)->right != NULL)
      {
        y = (*x)->right;
        (*x)->right = y->left;  /* left subtree of y becomes right subtree */
        y->left = (*x);     /* x becomes left child of y */
        (*x) = y;       /* y becomes new root of whole subtree */
      }
}


/*
 * rotate nodes pointed to by x and x->left
 */
static void
RotateRight (avltree_t ** x)
{               /* return *x to caller */
  avltree_t *y;

  if ((*x) != NULL)
    if ((*x)->left != NULL)
      {
        y = (*x)->left;
        (*x)->left = y->right;  /* left subtree of y becomes right subtree */
        y->right = (*x);    /* x becomes left child of y */
        (*x) = y;       /* y becomes new root of whole subtree */
      }
}


/*
 * return the Difference between the heights of the left and right subtree of node n
 */
static short
Difference (avltree_t * n)
{
  short leftheight, rightheight;

  if (n == NULL)
    return 0;
  else
    {
      if (n->left == NULL)
        leftheight = -1;
      else
        leftheight = n->left->height;   /* get height of left subtree */
      if (n->right == NULL)
        rightheight = -1;
      else
        rightheight = n->right->height; /* get height of right subtree */

      return (leftheight - rightheight);
    }
}


/*
 * sets the correct height for node pointed to by n, used after insertion into subtree
 */
static void
FixHeight (avltree_t * n)
{
  short leftheight, rightheight;

  if (n->left == NULL)
    leftheight = -1;
  else
    leftheight = n->left->height;

  if (n->right == NULL)
    rightheight = -1;
  else
    rightheight = n->right->height;

  if (leftheight > rightheight)
    n->height = leftheight + 1;
  else
    n->height = rightheight + 1;
}


/*
 * restores balance at n after insertion, assuming that the right subtree of n is too high
 */
static void
BalanceRight (avltree_t ** n, short adjust)
{
  short dif;

  dif = Difference ((*n)->right);
  if (dif == 0)
    {
      RotateLeft (n);       /* both subtrees of right child of n have same height */
      ((*n)->height) -= adjust; /* 'decrease' height of current node */
      ((*n)->left->height) += adjust;   /* 'increase' height of left subtree */
    }
  else
    {
      if (dif < 0)
        {
          RotateLeft (n);   /* right subtree of right child of n is higher */
          (*n)->left->height -= 2;
        }
      else
        {                               /* left subtree of right child of n is higher */
          RotateRight (&(*n)->right);   /* pointer to n->right */
          RotateLeft (n);
          ++((*n)->height);             /* increase height of current node */
          (*n)->left->height -= 2;
          --((*n)->right->height);      /* decrease height of right subtree */
        }
    }
}


static void
BalanceLeft (avltree_t ** n, short adjust)
{
  short dif;

  dif = Difference ((*n)->left);
  if (dif == 0)
    {
      RotateRight (n);      /* both subtrees of left child of n have same height */
      ((*n)->height) -= adjust; /* 'decrease' height of current node */
      ((*n)->right->height) += adjust;  /* 'increase' height of right subtree */
    }
  else
    {
      if (dif > 0)
        {
           RotateRight (n);  /* left subtree of left child of n is higher */
           (*n)->right->height -= 2;
        }
      else
        {           /* right subtree of left child of n is higher */
          RotateLeft (&(*n)->left); /* pointer to n->left */
          RotateRight (n);
          ++((*n)->height); /* increase height of current node */
          (*n)->right->height -= 2;
          --((*n)->left->height);   /* decrease height of left subtree */
        }
    }
}


static void
DeleteMin (avltree_t ** n, void **dataptr)
{
  avltree_t *temp;
  short dif;

  if ((*n)->left != NULL)   /* keep going for leftmost node */
    DeleteMin (&(*n)->left, dataptr);
  else
    {               /* leftmost node found */
      *dataptr = (*n)->data;    /* get pointer to data */
      temp = *n;
      *n = (*n)->right;     /* return pointer to right subtree */
      free (temp);      /* of leftmost node                */
    }

  if (*n != NULL)
    {
      FixHeight (*n);
      dif = Difference (*n);
      if (dif > 1)      /* deletion caused left subtree to be too high */
        BalanceLeft (n, -1);
      else
        {
          if (dif < -1)    /* deletion caused right subtree to be too high */
            BalanceRight (n, -1);
        }
    }
}
