proc register_global_func*(v: HSQUIRRELVM, f: SQFUNCTION, fname: cstring): SQInteger =
  sq_pushroottable(v)
  sq_pushstring(v,fname,-1)
  sq_newclosure(v,f,0) # create a new function
  discard sq_newslot(v,-3,SQFalse)
  sq_pop(v,1) # pops the root table
  
proc execute*(v: HSQUIRRELVM; code: string; name = "Script"; raiseError = true): HSQOBJECT =
  sq_resetobject(result)
  var top = sq_gettop(v)
  # compile
  sq_pushroottable(v)
  if SQ_FAILED(sq_compilebuffer(v, code.cstring, code.len, name, raiseError)):
    echo "Error executing code " & code
    sq_settop(v, top)
    return
  sq_push(v, -2)
  # call
  if SQ_FAILED(sq_call(v, 1, SQTrue, raiseError)):
    echo "Error calling code " & code
    sq_settop(v, top)
    return
  discard sq_getstackobj(v, -1, result)
  sq_addref(v, result)
  sq_settop(v, top)

proc pushValue(v: HSQUIRRELVM, value: SQInteger) =
  sq_pushinteger(v, value)

proc pushValue(v: HSQUIRRELVM, value: cstring) =
  sq_pushstring(v, value, value.len)

proc pushValue(v: HSQUIRRELVM, value: SQFloat) =
  sq_pushfloat(v, value)

proc getValue(v: HSQUIRRELVM, idx: SQInteger, i: SQInteger): SQInteger =
  discard sq_getinteger(v, idx, result)

proc getValue(v: HSQUIRRELVM, idx: SQInteger, i: cstring): cstring =
  discard sq_getstring(v, idx, result)

proc getValue(v: HSQUIRRELVM, idx: SQInteger, i: SQFloat): SQFloat =
  discard sq_getfloat(v, idx, result)

type Table = object
  v: HSQUIRRELVM
  tableobj: HSQOBJECT

type VM* = object
  v*: HSQUIRRELVM
  root*: HSQOBJECT
  rootTable*: Table

proc newTable*(v: HSQUIRRELVM, root: HSQOBJECT): Table =
  result.v = v
  result.tableobj = root

proc newVM*(stackSize = 1024): VM =
  result.v = sq_open(stackSize)

  sq_pushroottable(result.v)
  discard sq_getstackobj(result.v, -1, result.root)
  sq_pop(result.v, -1)

  result.rootTable = newTable(result.v, result.root)

proc destroy*(self: VM) =
  sq_close(self.v)

proc newTable*(v: HSQUIRRELVM): Table =
  result.v = v
  sq_newtable(v)
  discard sq_getstackobj(v, -1, result.tableobj)
  sq_addref(v, result.tableobj)
  sq_pop(v, 1)

proc set*[T](self: var Table, name: string, value: T) =
  sq_pushobject(self.v, self.tableobj)
  sq_pushstring(self.v, name, -1)
  pushValue(self.v, value)
  discard sq_newslot(self.v, -3, SQFalse)
  sq_pop(self.v, 1)

proc get*[T](self: var Table, name: string, i: T): auto =
  sq_pushobject(self.v, self.tableobj)
  sq_pushstring(self.v, name, -1)
  discard sq_get(self.v, -2)
  getValue(self.v, -1, i)

proc getint*(self: var Table, name: string): int =
  sq_pushobject(self.v, self.tableobj)
  sq_pushstring(self.v, name, -1)
  discard sq_get(self.v, -2)
  getValue(self.v, -1, 0)

proc getstring*(self: var Table, name: string): string =
  sq_pushobject(self.v, self.tableobj)
  sq_pushstring(self.v, name, -1)
  discard sq_get(self.v, -2)
  $getValue(self.v, -1, "")

proc newTable*(v: VM): Table =
  newTable(v.v)