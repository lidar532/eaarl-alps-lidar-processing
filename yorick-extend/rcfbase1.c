/*
 *
 *   $Id$
 *
 *   This file contains the c functions to implement the rcf.
 *   This is the intial part of the rcf.c file that is generated by the mkrcf.sh script.
 *   The contents of this file are simply copied into the rcf.c file
 *   
 *   c_fillarray is used in mode 2, to fill the winners into a yorick type array.
 *   XGetInfo is a function from std0.c, to get information on the array size
 *   
 *   Original rcf.i by W. Wright, 
 *   Converted to "C" by Conan Noronha
 */



#include "bcast.h"
#include "yio.h"
#include "defmem.h"
#include "pstdlib.h"
#include "play.h"
#include <string.h>
#include <stdio.h>
#include <errno.h>

static Member type;

/* This function is taken directly from Y_LAUNCH/std0.c 
 * to get the number of elements in the source array
 */

static DataBlock *XGetInfo(Symbol *s)
{
  DataBlock *db= 0;
  for (;;) {
    if (s->ops==&doubleScalar) {
      type.base= &doubleStruct;
      type.dims= 0;
      type.number= 1;
      break;
    } else if (s->ops==&longScalar) {
      type.base= &longStruct;
      type.dims= 0;
      type.number= 1;
      break;
    } else if (s->ops==&intScalar) {
      type.base= &intStruct;
      type.dims= 0;
      type.number= 1;
      break;
    } else if (s->ops==&dataBlockSym) {
      db= s->value.db;
      if (db->ops==&lvalueOps) {
        LValue *lvalue= (LValue *)db;
        type.base= lvalue->type.base;
        type.dims= lvalue->type.dims;
        type.number= lvalue->type.number;
      } else if (db->ops->isArray) {
        Array *array= (Array *)db;
        type.base= array->type.base;
        type.dims= array->type.dims;
        type.number= array->type.number;
      } else {
        type.base= 0;
        type.dims= 0;
        type.number= 0;
      }
      break;
    } else if (s->ops==&referenceSym) {
      s= &globTab[s->index];
    } else {
      YError("unexpected keyword argument");
    }
  }
  return type.base? 0 : db;
}

#define TBUFSIZE        32767
static unsigned int *winners, *fwinners, fcounter;	//Store the winners temporarily & global number of winners count.

short flag;	//Decides on the array use

unsigned int  twinners[ TBUFSIZE ], tidx[ TBUFSIZE ], tfwinners[ TBUFSIZE ];	//These arrays are only used when number_elems <= TBUFSIZE


/* Used to fill a 'Yorick' array with the winners indices
 * This function is called only for mode==2
 */

void c_fillarray (unsigned int *c)
{
   memcpy ((void*)c, (void*)fwinners, ((sizeof(unsigned int))*fcounter));	//Copy fwinners into the yorick array
   if (flag)
      free (fwinners);		//fwinners not needed now
}

/** CODE BELOW INSERTED FROM rcfbase2.c **/
