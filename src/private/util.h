#include <squirrel.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*SQPRINTEXFUNCTION)(HSQUIRRELVM,const SQChar * );

void printfunc(HSQUIRRELVM v, const SQChar *s, ...);
void setprintfunc(HSQUIRRELVM v, SQPRINTEXFUNCTION printfunc, SQPRINTEXFUNCTION errfunc);

#ifdef __cplusplus
}
#endif
