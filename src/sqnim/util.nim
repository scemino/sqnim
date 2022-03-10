import "std/macros"

proc regGblFun*(v: HSQUIRRELVM, f: SQFUNCTION, fname: cstring) =
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

proc pushValue*(v: HSQUIRRELVM, value: SQInteger) =
  sq_pushinteger(v, value)

proc pushValue*(v: HSQUIRRELVM, value: cstring) =
  sq_pushstring(v, value, value.len)

proc pushValue*(v: HSQUIRRELVM, value: SQFloat) =
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

macro sqBindFun*(vm, funName, procDef): untyped =
  echo procDef.treeRepr
  result = newStmtList()
  # declare a procedure
  let name = procDef
  var stmts = newStmtList()
  procDef.expectMinLen(4)
  var params: seq[NimNode]
  for iParam in 1..procDef[3].len-1:
    # tranform each param in squirrel param
    let paramNode = procDef[3][iParam]
    let identNode = paramNode[0]
    let typeNode = paramNode[1]
    params.add(identNode)

    var stmt: NimNode
    case typeNode.repr:
    of "SQInteger":
      stmt = newCall(ident("sq_getinteger"), ident("v"), newLit(iParam+1), identNode)
    of "SQFloat":
      stmt = newCall(ident("sq_getfloat"), ident("v"), newLit(iParam+1), identNode)
    of "SQString":
      stmt = newCall(ident("sq_getstring"), ident("v"), newLit(iParam+1), identNode)
    of "HSQOBJECT":
      stmt = newCall(ident("sq_getstackobj"), ident("v"), newLit(iParam+1), identNode)
    else:
      assert false, "unexpected param type: " & typeNode.repr
    stmts.add(newNimNode(nnkVarSection).add(newIdentDefs(identNode, typeNode)))
    stmts.add(newNimNode(nnkDiscardStmt).add(stmt))
  # result
  let resultType = procDef[3][0]
  var stmt: NimNode
  case resultType.repr:
    of "SQInteger":
      stmt = newCall(ident("sq_pushinteger"), ident("v"), newCall(name, params))
    of "SQFloat":
      stmt = newCall(ident("sq_pushfloat"), ident("v"), newCall(name, params))
    of "SQString":
      stmt = newCall(ident("sq_pushstring"), ident("v"), newCall(name, params), newLit(-1))
    of "HSQOBJECT":
      stmt = newCall(ident("sq_pushobject"), ident("v"), newCall(name, params))
    of "":
      stmt = newEmptyNode()
    else:
      assert false, "unexpected result type: " & resultType.repr
  stmts.add(stmt)
  # returns 1 to indicate that this function returns a value
  stmts.add(newLit(1))
  
  # create procedures
  let sqbdName = ident("sqbd_" & name.repr)
  # register function
  let regStmt = newCall(ident("regGblFun"), vm, sqbdName, funName)
  # add procedure definition
  result.add(procDef)
  # add squirrel procedure definition
  result.add(newProc(sqbdName, 
    [ident("SQInteger"), newIdentDefs(ident("v"), ident("HSQUIRRELVM"))],
    stmts, pragmas = newNimNode(nnkPragma).add(ident("cdecl"))))
  result.add(regStmt)

macro sqBind*(vm, body): untyped =
  result = newStmtList()
  for bodyStmt in body:
    if bodyStmt.kind == nnkConstSection:
      # declare a constant section
      let constSection = bodyStmt
      for constDef in constSection:
        # declare a constant
        let constName = constDef[0]
        let constValue = constDef[2]
        result.add(newCall(ident("sq_pushconsttable"), vm))
        result.add(newCall(ident("sq_pushstring"), vm, newStrLitNode(constName.repr), newLit(-1)))
        result.add(newCall(ident("pushValue"), vm, constValue))
        result.add(newNimNode(nnkDiscardStmt).add(newCall(ident("sq_newslot"), vm, newLit(-3), newLit(SQTrue))))
        result.add(newCall(ident("sq_pop"), vm, newLit(1)))
    else:
      # declare a procedure
      let procDef = bodyStmt
      let name = procDef[0]
      var stmts = newStmtList()
      procDef.expectMinLen(4)
      var params: seq[NimNode]
      for iParam in 1..procDef[3].len-1:
        # tranform each param in squirrel param
        let paramNode = procDef[3][iParam]
        let identNode = paramNode[0]
        let typeNode = paramNode[1]
        params.add(identNode)

        var stmt: NimNode
        case typeNode.repr:
        of "SQInteger":
          stmt = newCall(ident("sq_getinteger"), ident("v"), newLit(iParam+1), identNode)
        of "SQFloat":
          stmt = newCall(ident("sq_getfloat"), ident("v"), newLit(iParam+1), identNode)
        of "SQString":
          stmt = newCall(ident("sq_getstring"), ident("v"), newLit(iParam+1), identNode)
        of "HSQOBJECT":
          stmt = newCall(ident("sq_getstackobj"), ident("v"), newLit(iParam+1), identNode)
        else:
          assert false, "unexpected param type: " & typeNode.repr
        stmts.add(newNimNode(nnkVarSection).add(newIdentDefs(identNode, typeNode)))
        stmts.add(newNimNode(nnkDiscardStmt).add(stmt))
      # result
      let resultType = procDef[3][0]
      var stmt: NimNode
      case resultType.repr:
        of "SQInteger":
          stmt = newCall(ident("sq_pushinteger"), ident("v"), newCall(name, params))
        of "SQFloat":
          stmt = newCall(ident("sq_pushfloat"), ident("v"), newCall(name, params))
        of "SQString":
          stmt = newCall(ident("sq_pushstring"), ident("v"), newCall(name, params), newLit(-1))
        of "HSQOBJECT":
          stmt = newCall(ident("sq_pushobject"), ident("v"), newCall(name, params))
        of "":
          stmt = newEmptyNode()
        else:
          assert false, "unexpected result type: " & resultType.repr
      stmts.add(stmt)
      # returns 1 to indicate that this function returns a value
      stmts.add(newLit(1))
      
      # create procedures
      let sqbdName = ident("sqbd_" & name.repr)
      # register function
      let regStmt = newCall(ident("regGblFun"), vm, sqbdName, newLit(name.repr))
      # add procedure definition
      result.add(procDef)
      # add squirrel procedure definition
      result.add(newProc(sqbdName, 
        [ident("SQInteger"), newIdentDefs(ident("v"), ident("HSQUIRRELVM"))],
        stmts, pragmas = newNimNode(nnkPragma).add(ident("cdecl"))))
      result.add(regStmt)
