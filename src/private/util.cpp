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
#include "util.h"

#ifdef __cplusplus
extern "C" {
#endif

SQPRINTEXFUNCTION gPrintfunc = NULL;
SQPRINTEXFUNCTION gErrfunc = NULL;

void printfunc(HSQUIRRELVM v, const SQChar *s, ...)
{
  va_list vl;
  va_start(vl, s);
  vfprintf(stdout, s, vl);
  va_end(vl);
}

void printexfunc(HSQUIRRELVM v, const SQChar *s, ...)
{
  if (gPrintfunc)
  {
    char buf[1024];
    va_list vl;
    va_start(vl, s);
    vsprintf(buf, s, vl);
    va_end(vl);
    gPrintfunc(v, buf);
  }
}

void errorexfunc(HSQUIRRELVM v, const SQChar *s, ...)
{
  if (gPrintfunc)
  {
    char buf[1024];
    va_list vl;
    va_start(vl, s);
    vsprintf(buf, s, vl);
    va_end(vl);
    gErrfunc(v, buf);
  }
}

const SQChar* closure_srcname(HSQOBJECT obj)
{
  return _stringval(_closure(obj)->_function->_sourcename);
}

SQInteger closure_line(HSQOBJECT obj)
{
  return _closure(obj)->_function->_lineinfos->_line;
}

void setprintfunc(HSQUIRRELVM v, SQPRINTEXFUNCTION printfunc, SQPRINTEXFUNCTION errfunc)
{
  sq_setprintfunc(v, printexfunc, errorexfunc);
  gPrintfunc = printfunc;
  gErrfunc = errfunc;
}

#ifdef __cplusplus
}
#endif
