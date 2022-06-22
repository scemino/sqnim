import std/strutils

proc currentSourceDir(): string {.compileTime.} =
  result = currentSourcePath().replace("\\", "/")
  result = result[0 ..< result.rfind("/")]

{.passc: "-I" & currentSourceDir() & "/private/squirrel/include".}
{.compile: "private/squirrel/src/squirrel/sqapi.cpp",
  compile: "private/squirrel/src/squirrel/sqbaselib.cpp",
  compile: "private/squirrel/src/squirrel/sqclass.cpp",
  compile: "private/squirrel/src/squirrel/sqcompiler.cpp",
  compile: "private/squirrel/src/squirrel/sqdebug.cpp",
  compile: "private/squirrel/src/squirrel/sqfuncstate.cpp",
  compile: "private/squirrel/src/squirrel/sqlexer.cpp",
  compile: "private/squirrel/src/squirrel/sqmem.cpp",
  compile: "private/squirrel/src/squirrel/sqobject.cpp",
  compile: "private/squirrel/src/squirrel/sqstate.cpp",
  compile: "private/squirrel/src/squirrel/sqtable.cpp",
  compile: "private/squirrel/src/squirrel/sqvm.cpp",
  compile: "private/squirrel/src/sqstdlib/sqstdaux.cpp",
  compile: "private/squirrel/src/sqstdlib/sqstdblob.cpp",
  compile: "private/squirrel/src/sqstdlib/sqstdio.cpp",
  compile: "private/squirrel/src/sqstdlib/sqstdmath.cpp",
  compile: "private/squirrel/src/sqstdlib/sqstdrex.cpp",
  compile: "private/squirrel/src/sqstdlib/sqstdstream.cpp",
  compile: "private/squirrel/src/sqstdlib/sqstdstring.cpp",
  compile: "private/squirrel/src/sqstdlib/sqstdsystem.cpp",
  compile: "private/util.cpp",
.}
{.pragma: squirrel_header, header: "include/squirrel.h", header: "util.h".}

type
  SQObjectType* = cuint

const 
  RT_NULL*            =0x00000001
  RT_INTEGER*         =0x00000002
  RT_FLOAT*           =0x00000004
  RT_BOOL*            =0x00000008
  RT_STRING*          =0x00000010
  RT_TABLE*           =0x00000020
  RT_ARRAY*           =0x00000040
  RT_USERDATA*        =0x00000080
  RT_CLOSURE*         =0x00000100
  RT_NATIVECLOSURE*   =0x00000200
  RT_GENERATOR*       =0x00000400
  RT_USERPOINTER*     =0x00000800
  RT_THREAD*          =0x00001000
  RT_FUNCPROTO*       =0x00002000
  RT_CLASS*           =0x00004000
  RT_INSTANCE*        =0x00008000
  RT_WEAKREF*         =0x00010000
  RT_OUTER*           =0x00020000
  SQOBJECT_REF_COUNTED    =0x08000000
  SQOBJECT_NUMERIC        =0x04000000
  SQOBJECT_DELEGABLE      =0x02000000
  SQOBJECT_CANBEFALSE     =0x01000000
  SQTrue* = 1.cuint
  SQFalse* = 0.cuint
  SQ_OK* = 0
  SQ_ERROR* = -1
  OT_NULL* =           (RT_NULL or SQOBJECT_NUMERIC or SQOBJECT_CANBEFALSE).SQObjectType
  OT_INTEGER* =        (RT_INTEGER or SQOBJECT_NUMERIC or SQOBJECT_CANBEFALSE).SQObjectType
  OT_FLOAT* =          (RT_FLOAT or SQOBJECT_NUMERIC or SQOBJECT_CANBEFALSE).SQObjectType
  OT_BOOL* =           (RT_BOOL or SQOBJECT_CANBEFALSE).SQObjectType
  OT_STRING* =         (RT_STRING or SQOBJECT_REF_COUNTED).SQObjectType
  OT_TABLE* =          (RT_TABLE or SQOBJECT_REF_COUNTED or SQOBJECT_DELEGABLE).SQObjectType
  OT_ARRAY* =          (RT_ARRAY or SQOBJECT_REF_COUNTED).SQObjectType
  OT_USERDATA* =       (RT_USERDATA or SQOBJECT_REF_COUNTED or SQOBJECT_DELEGABLE).SQObjectType
  OT_CLOSURE* =        (RT_CLOSURE or SQOBJECT_REF_COUNTED).SQObjectType
  OT_NATIVECLOSURE* =  (RT_NATIVECLOSURE or SQOBJECT_REF_COUNTED).SQObjectType
  OT_GENERATOR* =      (RT_GENERATOR or SQOBJECT_REF_COUNTED).SQObjectType
  OT_USERPOINTER* =    RT_USERPOINTER.SQObjectType
  OT_THREAD* =         (RT_THREAD or SQOBJECT_REF_COUNTED).SQObjectType 
  OT_FUNCPROTO* =      (RT_FUNCPROTO or SQOBJECT_REF_COUNTED).SQObjectType #internal usage only
  OT_CLASS* =          (RT_CLASS or SQOBJECT_REF_COUNTED).SQObjectType
  OT_INSTANCE* =       (RT_INSTANCE or SQOBJECT_REF_COUNTED or SQOBJECT_DELEGABLE).SQObjectType
  OT_WEAKREF* =        (RT_WEAKREF or SQOBJECT_REF_COUNTED).SQObjectType
  OT_OUTER* =          (RT_OUTER or SQOBJECT_REF_COUNTED).SQObjectType #internal usage only

type
  PrintCallback = proc (v: HSQUIRRELVM, s: cstring) {.cdecl, varargs.}
  SQFUNCTION* = proc (v: HSQUIRRELVM): SQInteger {.cdecl.}
  SQCOMPILERERROR* = proc (v: HSQUIRRELVM, desc: SQString, source: SQString, line: SQInteger, column: SQInteger) {.cdecl.}
  SQLEXREADFUNC* = proc (p: SQUserPointer): SQInteger {.cdecl.}
  HSQUIRRELVM* = pointer
  SQUserPointer* = pointer
  SQInteger* = int
  SQFloat* = cfloat
  SQString* = cstring
  SQUnsignedInteger* = cuint
  SQRESULT* = cint
  SQBool* = cuint
  SQObjectValue* {.final, union, pure.} = object
    pTable*: pointer
    pArray*: pointer
    pClosure*: pointer
    pOuter*: pointer
    pGenerator*: pointer
    pNativeClosure*: pointer
    pString*: pointer
    pUserData*: pointer
    nInteger*: SQInteger
    fFloat*: SQFloat
    pUserPointer*: pointer
    pFunctionProto*: pointer
    pRefCounted*: pointer
    pDelegable*: pointer
    pThread*: pointer
    pClass*: pointer
    pInstance*: pointer
    pWeakRef*: pointer
    raw*: SQInteger
  HSQOBJECT* = object
    objType*: SQObjectType
    value*: SQObjectValue

# UTILITY
proc sq_isnumeric*(o: HSQOBJECT): bool {.inline.} = (o.objType and SQOBJECT_NUMERIC) == SQOBJECT_NUMERIC
proc sq_istable*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_TABLE
proc sq_isarray*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_ARRAY
proc sq_isfunction*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_FUNCPROTO
proc sq_isclosure*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_CLOSURE
proc sq_isgenerator*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_GENERATOR
proc sq_isnativeclosure*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_NATIVECLOSURE
proc sq_isstring*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_STRING
proc sq_isinteger*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_INTEGER
proc sq_isfloat*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_FLOAT
proc sq_isuserpointer*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_USERPOINTER
proc sq_isuserdata*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_USERDATA
proc sq_isthread*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_THREAD
proc sq_isnull*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_NULL
proc sq_isclass*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_CLASS
proc sq_isinstance*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_INSTANCE
proc sq_isbool*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_BOOL
proc sq_isweakref*(o: HSQOBJECT): bool {.inline.} = o.objType == OT_WEAKREF

# vm
proc sq_open*(initialstacksize: SQInteger): HSQUIRRELVM {.importc: "sq_open".}
proc sq_newthread*(friendvm: HSQUIRRELVM, initialstacksize: SQInteger): HSQUIRRELVM {.importc: "sq_newthread".}
proc sq_seterrorhandler*(v: HSQUIRRELVM) {.importc: "sq_seterrorhandler".}
proc sq_close*(v: HSQUIRRELVM) {.importc: "sq_close".}
proc sq_setforeignptr*(v: HSQUIRRELVM, p: SQUserPointer) {.importc: "sq_setforeignptr".}
proc sq_getforeignptr*(v: HSQUIRRELVM): SQUserPointer {.importc: "sq_getforeignptr".}
proc sq_setprintfunc*(v: HSQUIRRELVM, printfunc, errfunc: PrintCallback) {.importc: "sq_setprintfunc".}
proc sq_suspendvm*(v: HSQUIRRELVM): SQRESULT {.importc: "sq_suspendvm".}
proc sq_wakeupvm*(v: HSQUIRRELVM, resumedret, retval, raiseerror, throwerror: SQBool): SQRESULT {.importc: "sq_wakeupvm".}
proc sq_getvmstate*(v: HSQUIRRELVM): SQInteger {.importc: "sq_getvmstate".}
proc sq_getversion*(): SQInteger {.importc: "sq_getversion".}

# compiler
proc sq_compile*(v: HSQUIRRELVM, read: SQLEXREADFUNC, p: SQUserPointer, sourcename: cstring, raiseerror: SQBool): SQRESULT {.importc: "sq_compile".}
proc sq_compilebuffer*(v: HSQUIRRELVM, s: cstring, size: SQInteger, sourcename: cstring, raiseerror: SQBool): SQRESULT {.importc: "sq_compilebuffer".}
proc sq_enabledebuginfo*(v: HSQUIRRELVM, enable: SQBool) {.importc: "sq_enabledebuginfo".}
proc sq_notifyallexceptions*(v: HSQUIRRELVM, enable: SQBool) {.importc: "sq_notifyallexceptions".}
proc sq_setcompilererrorhandler*(v: HSQUIRRELVM, f: SQCOMPILERERROR) {.importc: "sq_setcompilererrorhandler".}

# stack operations
proc sq_push*(v: HSQUIRRELVM, idx: SQInteger) {.importc: "sq_push".}
proc sq_pop*(v: HSQUIRRELVM, nelemstopop: SQInteger) {.importc: "sq_pop".}
proc sq_poptop*(v: HSQUIRRELVM) {.importc: "sq_poptop".}
proc sq_remove*(v: HSQUIRRELVM, idx: SQInteger) {.importc: "sq_remove".}
proc sq_gettop*(v: HSQUIRRELVM): SQInteger {.importc: "sq_gettop".}
proc sq_settop*(v: HSQUIRRELVM, newtop: SQInteger) {.importc: "sq_settop".}
proc sq_reservestack*(v: HSQUIRRELVM, nsize: SQInteger): SQRESULT {.importc: "sq_reservestack".}
proc sq_cmp*(v: HSQUIRRELVM): SQInteger {.importc: "sq_cmp".}
proc sq_move*(dest,src: HSQUIRRELVM, idx: SQInteger) {.importc: "sq_move".}

# object creation handling
proc sq_newtable*(v: HSQUIRRELVM) {.importc: "sq_newtable".}
proc sq_newarray*(v: HSQUIRRELVM, size: SQInteger) {.importc: "sq_newarray".}
proc sq_newclosure*(v: HSQUIRRELVM, function: SQFUNCTION, nfreevars: SQUnsignedInteger) {.importc: "sq_newclosure".}
proc sq_setparamscheck*(v: HSQUIRRELVM, nparamscheck: SQInteger, typemask: cstring): SQRESULT {.importc: "sq_setparamscheck".}
proc sq_bindenv*(v: HSQUIRRELVM, idx: SQInteger): SQRESULT {.importc: "sq_bindenv".}
proc sq_setclosureroot*(v: HSQUIRRELVM, idx: SQInteger): SQRESULT {.importc: "sq_setclosureroot".}
proc sq_getclosureroot*(v: HSQUIRRELVM, idx: SQInteger): SQRESULT {.importc: "sq_getclosureroot".}
proc sq_pushstring*(v: HSQUIRRELVM, s: cstring, len: SQInteger) {.importc: "sq_pushstring".}
proc sq_pushfloat*(v: HSQUIRRELVM, f: SQFloat) {.importc: "sq_pushfloat".}
proc sq_pushinteger*(v: HSQUIRRELVM, n: SQInteger) {.importc: "sq_pushinteger".}
proc sq_pushbool*(v: HSQUIRRELVM, b: SQBool) {.importc: "sq_pushbool".}
proc sq_pushnull*(v: HSQUIRRELVM) {.importc: "sq_pushnull".}
proc sq_pushthread*(v: HSQUIRRELVM, thread: HSQUIRRELVM) {.importc: "sq_pushthread".}
proc sq_gettype*(v: HSQUIRRELVM, idx: SQInteger): SQObjectType {.importc: "sq_gettype".}
proc sq_getsize*(v: HSQUIRRELVM, idx: SQInteger): SQInteger {.importc: "sq_getsize".}
proc sq_getstring*(v: HSQUIRRELVM, idx: SQInteger, c: var cstring): SQRESULT {.importc: "sq_getstring".}
proc sq_getinteger*(v: HSQUIRRELVM, idx: SQInteger, i: var SQInteger): SQRESULT {.importc: "sq_getinteger".}
proc sq_getfloat*(v: HSQUIRRELVM, idx: SQInteger, i: var SQFloat): SQRESULT {.importc: "sq_getfloat".}
proc sq_getclosureinfo*(v: HSQUIRRELVM, idx: SQInteger,nparams, nfreevars: var SQInteger): SQRESULT {.importc: "sq_getclosureinfo".}
proc sq_getclosurename*(v: HSQUIRRELVM, idx: SQInteger): SQRESULT {.importc: "sq_getclosurename".}

# object manipulation
proc sq_pushroottable*(v: HSQUIRRELVM) {.importc: "sq_pushroottable".}
proc sq_pushregistrytable*(v: HSQUIRRELVM) {.importc: "sq_pushregistrytable".}
proc sq_pushconsttable*(v: HSQUIRRELVM) {.importc: "sq_pushconsttable".}
proc sq_setroottable*(v: HSQUIRRELVM): SQRESULT {.importc: "sq_setroottable".}
proc sq_setconsttable*(v: HSQUIRRELVM): SQRESULT {.importc: "sq_setconsttable".}
proc sq_newslot*(v: HSQUIRRELVM, idx: SQInteger, bstatic: SQBool): SQRESULT {.importc: "sq_newslot".}
proc sq_deleteslot*(v: HSQUIRRELVM, idx: SQInteger, pushval: SQBool): SQRESULT {.importc: "sq_deleteslot".}
proc sq_get*(v: HSQUIRRELVM, idx: SQInteger): SQRESULT {.importc: "sq_get".}
proc sq_rawget*(v: HSQUIRRELVM, idx: SQInteger): SQRESULT {.importc: "sq_rawget".}
proc sq_rawset*(v: HSQUIRRELVM, idx: SQInteger): SQRESULT {.importc: "sq_rawset".}
proc sq_arrayappend*(v: HSQUIRRELVM, idx: SQInteger): SQRESULT {.importc: "sq_arrayappend".}
proc sq_setdelegate*(v: HSQUIRRELVM, idx: SQInteger): SQRESULT {.importc: "sq_setdelegate".}
proc sq_getdelegate*(v: HSQUIRRELVM, idx: SQInteger): SQRESULT {.importc: "sq_getdelegate".}
proc sq_clone*(v: HSQUIRRELVM, idx: SQInteger): SQRESULT {.importc: "sq_clone".}
proc sq_next*(v: HSQUIRRELVM, idx: SQInteger): SQRESULT {.importc: "sq_next".}

# calls
proc sq_call*(v: HSQUIRRELVM, params: SQInteger, retval, raiseerror: SQBool): SQRESULT {.importc: "sq_call".}
proc sq_throwerror*(v: HSQUIRRELVM, err: cstring): SQRESULT {.importc: "sq_throwerror".}

# raw object handling
proc sq_getstackobj*(v: HSQUIRRELVM, idx: SQInteger, po: var HSQOBJECT): SQRESULT {.importc: "sq_getstackobj".}
proc sq_pushobject*(v: HSQUIRRELVM, obj: HSQOBJECT) {.importc: "sq_pushobject".}
proc sq_addref*(v: HSQUIRRELVM, po: var HSQOBJECT) {.importc: "sq_addref".}
proc sq_release*(v: HSQUIRRELVM, po: var HSQOBJECT): SQBool {.importc: "sq_release".}
proc sq_getrefcount*(v: HSQUIRRELVM, po: var HSQOBJECT): SQUnsignedInteger {.importc: "sq_getrefcount".}
proc sq_resetobject*(po: var HSQOBJECT) {.importc: "sq_resetobject".}
proc sq_objtostring*(o: var HSQOBJECT): SQString {.importc: "sq_objtostring".}
proc sq_objtointeger*(o: var HSQOBJECT): SQInteger {.importc: "sq_objtointeger".}
proc sq_objtofloat*(o: var HSQOBJECT): SQFloat {.importc: "sq_objtofloat".}
proc sq_getvmrefcount*(v: HSQUIRRELVM, o: var HSQOBJECT): SQUnsignedInteger {.importc: "sq_getvmrefcount".}

# register methods
proc sqstd_register_bloblib*(v: HSQUIRRELVM) {.importc: "sqstd_register_bloblib".}
proc sqstd_register_iolib*(v: HSQUIRRELVM) {.importc: "sqstd_register_iolib".}
proc sqstd_register_mathlib*(v: HSQUIRRELVM) {.importc: "sqstd_register_mathlib".}
proc sqstd_register_stringlib*(v: HSQUIRRELVM) {.importc: "sqstd_register_stringlib".}
proc sqstd_register_systemlib*(v: HSQUIRRELVM) {.importc: "sqstd_register_systemlib".}

# compiler helpers
proc sqstd_loadfile*(v: HSQUIRRELVM, filename: cstring, printerror: SQBool): SQRESULT {.importc: "sqstd_loadfile".}
proc sqstd_dofile*(v: HSQUIRRELVM, filename: cstring, retval, printerror: SQBool): SQRESULT {.importc: "sqstd_dofile".}
proc sqstd_writeclosuretofile*(v: HSQUIRRELVM, filename: cstring): SQRESULT {.importc: "sqstd_writeclosuretofile".}

# aux
proc sqstd_seterrorhandlers*(v: HSQUIRRELVM) {.importc: "sqstd_seterrorhandlers".}
proc sqstd_printcallstack*(v: HSQUIRRELVM) {.importc: "sqstd_printcallstack".}

# util
proc printfunc*(v: HSQUIRRELVM, s: cstring) {.importc: "printfunc", cdecl, varargs.}

proc SQ_FAILED*(res: SQInteger): bool {.inline.} = res < 0
proc SQ_SUCCEEDED*(res: SQInteger): bool {.inline.} = res >= 0

converter toSQBool*(b: bool): SQBool =
  if b: SQTrue else: SQFalse

converter toSQInteger*(i: int): SQInteger =
  i.SQInteger

converter toSQFloat*(i: float): SQFloat =
  i.SQFloat

converter toSQString*(s: string): SQString =
  s.SQString
