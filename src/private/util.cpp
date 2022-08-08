#include <squirrel.h>
#include <stdio.h>
#include <stdarg.h>
#include "squirrel/src/squirrel/sqpcheader.h"
#include "squirrel/src/squirrel/sqvm.h"
#include "squirrel/src/squirrel/sqstring.h"
#include "squirrel/src/squirrel/sqtable.h"
#include "squirrel/src/squirrel/sqarray.h"
#include "squirrel/src/squirrel/sqfuncproto.h"
#include "squirrel/src/squirrel/sqclosure.h"

#ifdef __cplusplus
extern "C" {
#endif

void printfunc(HSQUIRRELVM v, const SQChar *s, ...)
{
  va_list vl;
  va_start(vl, s);
  vfprintf(stdout, s, vl);
  va_end(vl);
}

const SQChar* closure_srcname(HSQOBJECT obj)
{
  return _stringval(_closure(obj)->_function->_sourcename);
}

SQInteger closure_line(HSQOBJECT obj)
{
  return _closure(obj)->_function->_lineinfos->_line;
}

#ifdef __cplusplus
}
#endif
