#include <squirrel.h>
#include <stdio.h>
#include <stdarg.h>

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

#ifdef __cplusplus
}
#endif
