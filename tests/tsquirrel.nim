import unittest
import sqnim
import std/[math, tables]

proc execute(v: HSQUIRRELVM; code: string; name = "Script"; raiseError = true): HSQOBJECT =
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

test "test simple data":
  let v = sq_open(1024)

  # integer
  var result = execute(v, "return 42")
  doAssert sq_isinteger(result)
  doAssert result.objType == OT_INTEGER
  doAssert result.value.nInteger == 42

  # float
  result = execute(v, "return 3.14159")
  doAssert sq_isfloat(result)
  doAssert result.objType == OT_FLOAT
  doAssert almostEqual(result.value.fFloat, 3.14159)

  # string
  result = execute(v, """return "Foo"""")
  doAssert sq_isstring(result)
  doAssert result.objType == OT_STRING
  sq_pushobject(v, result)
  var s: cstring
  discard sq_getstring(v, -1, s)
  doAssert $s == "Foo"
  sq_pop(v, 1)

  result = execute(v, """return "Foo"""")
  doAssert sq_objtostring(result) == "Foo"

  # array
  result = execute(v, "return [3, 2, 1]")
  doAssert sq_isarray(result)
  doAssert result.objType == OT_ARRAY
  var arr: seq[int]

  sq_pushobject(v, result)
  sq_pushnull(v) # null iterator
  while SQ_SUCCEEDED(sq_next(v, -2)):
    # here -1 is the value and -2 is the key
    var i: int
    discard sq_getinteger(v, -1, i)
    arr.add(i)
    sq_pop(v, 2) # pops key and val before the next iteration
  sq_pop(v, 2) # pops the null iterator and array

  doAssert arr == [3, 2, 1]

  # table
  result = execute(v, "return {a=3, b=2, c=1}")
  doAssert sq_istable(result)
  doAssert result.objType == OT_TABLE
  var t: Table[string, int]

  sq_pushobject(v, result)
  sq_pushnull(v) # null iterator
  while SQ_SUCCEEDED(sq_next(v, -2)):
    # here -1 is the value and -2 is the key
    var k: cstring
    var i: int
    discard sq_getstring(v, -2, k)
    discard sq_getinteger(v, -1, i)
    t[$k] = i
    sq_pop(v, 2) # pops key and val before the next iteration
  sq_pop(v, 2) # pops the null iterator and array

  doAssert t == {"a":3, "b":2, "c":1}.toTable

  # closure
  result = execute(v, "return function() {return 42}")
  doAssert sq_isclosure(result)
  doAssert result.objType == OT_CLOSURE
  doAssert closure_srcname(result) == "Script"
  doAssert closure_line(result) == 1
  sq_pushobject(v, result)
  var nparams, nfreevars: SQInteger
  discard sq_getclosureinfo(v, -1, nparams, nfreevars)

  sq_pushroottable(v)
  discard sq_call(v, nparams, SQTrue, SQTrue)
  var funcResult: int
  discard sq_getinteger(v, -1, funcResult)
  sq_pop(v, 2)

  doAssert nparams == 1
  doAssert nfreevars == 0
  doAssert funcResult == 42
  doAssert sq_gettop(v) == 0

  sq_close(v)
