# Nimgram
# Copyright (C) 2020-2023 Daniele Cortesi <https://github.com/dadadani>
# This file is part of Nimgram, under the MIT License
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import src/tlparser/private/[utils, constructors, parameters]
import options

template doAssertRaisesMsg*(exception: typedesc, message: string,
    code: untyped) =
  var wrong = false
  const begin = "expected raising '" & astToStr(exception) & "', instead"
  const msgEnd = " by: " & astToStr(code)
  template raisedForeign = raiseAssert(begin & " raised foreign exception" & msgEnd)
  when Exception is exception:
    try:
      if true:
        code
      wrong = true
    except Exception as e:
      if e.msg != message:
        wrong = true
    except: raisedForeign()
  else:
    try:
      if true:
        code
      wrong = true
    except exception as e:
      if e.msg != message:
        wrong = true
    except Exception as e:
      mixin `$`
      raiseAssert(begin & " raised '" & $e.name & "'" & msgEnd)
    except: raisedForeign()
  if wrong:
    raiseAssert(begin & " nothing was raised or the message is invalid" & msgEnd)

proc utilsTest =
  # Check if comments are stripped correctly
  doAssert stripTLComments("hello\nworld") == "hello\nworld"
  doAssert stripTLComments(" \nhello\nworld\n ") == " \nhello\nworld\n "
  doAssert stripTLComments(" // hello\n world ") == " \n world "
  doAssert stripTLComments(" \nhello \n // world \n \n ") == " \nhello \n \n \n "
  doAssert stripTLComments("no\n//yes\nno\n//yes\nno\n") == "no\n\nno\n\nno\n"
  doAssert stripTLComments(" \nhello \n // world \n \n ") == " \nhello \n \n \n "
  doAssert stripTLComments(" \nmultiline \n /* test */\n \n ") == " \nmultiline \n \n \n "
  doAssert stripTLComments(" \nmultiline \n /* test \naaaaaa//*/\n \n ") == " \nmultiline \n \n \n "

  # Check if crc32 is generated correctly
  doAssert generateID("inputPhoto id:long access_hash:long file_reference:bytes = InputPhoto") ==
          uint32(0x3bb3b94a),
          "Constructor id generation of inputPhoto FAILED" # 'byte' to string test
  doAssert generateID("invokeWithTakeout {X:Type} takeout_id:long query:!X = X") ==
          uint32(0xaca9fd2e),
          "Constructor id generation of invokeWithTakeout FAILED" # curly bracket test
  doAssert generateID("messageActionChatAddUser users:Vector<long> = MessageAction") ==
          uint32(0x15cefd00),
          "Constructor id generation of messageActionChatAddUser FAILED" # angle bracket test
  doAssert generateID("inputMessagesFilterPhoneCalls flags:# missed:flags.0?true = MessagesFilter") ==
          uint32(0x80c99768),
          "Constructor id generation of inputMessagesFilterPhoneCalls FAILED" # conditional flag test
  doAssert generateID("inputMediaDocumentExternal flags:# url:string ttl_seconds:flags.0?int = InputMedia") ==
          uint32(0xfb52dc99),
          "Constructor id generation of inputMediaDocumentExternal FAILED" # another conditional flag test
  doAssert generateID("userProfilePhoto flags:# has_video:flags.0?true photo_id:long stripped_thumb:flags.1?bytes dc_id:int = UserProfilePhoto") ==
          uint32(0x82d1f706),
          "Constructor id generation of userProfilePhoto FAILED" # another conditional flag test with 'bytes' to string

proc constructorsTest =
  # Check invalid constructor IDs
  doAssertRaisesMsg(ParseDefect, "Invalid constructor id"): discard parse("invalid#id = bad")
  doAssertRaisesMsg(ParseDefect, "Expecting a valid constructor id, instead got an empty one"): discard parse("empty# = id")

  # Check invalid names
  doAssertRaisesMsg(ParseDefect, "Expecting a valid namespace, got an empty one"): discard parse(" = bad")
  doAssertRaisesMsg(ParseDefect, "Expecting a valid namespace, got an empty one"): discard parse("o..o = bad")


  # Check invalid types
  doAssertRaisesMsg(ParseDefect, "The type is missing"): discard parse("bad = ")

  # Check if the constructor id is obtained correctly
  doAssert parse("account.tmpPassword#db64fd34 tmp_password:bytes valid_until:int = account.TmpPassword").id ==
      uint32(0xdb64fd34)
  doAssert parse("account.tmpPassword tmp_password:bytes valid_until:int = account.TmpPassword").id ==
      uint32(0xdb64fd34)

  # Check if the type is obtained correctly
  doAssert (parse("testtype= a").`type`.name) == "a"

  var test = parse("testtype= e<b>")
  doAssert test.`type`.name == "b"
  doAssert test.`type`.genericArgument.isSome()
  doAssert test.`type`.genericArgument.get().name == "e"
  doAssert test.`type`.genericArgument.get().genericArgument.isNone()
  doAssert not test.`type`.genericArgument.get().genericReference

  test = parse("testtype=e<c<b>>")
  doAssert test.`type`.name == "b"
  doAssert test.`type`.genericArgument.isSome()
  doAssert test.`type`.genericArgument.get().name == "c"
  doAssert test.`type`.genericArgument.get().genericArgument.isSome()
  doAssert test.`type`.genericArgument.get().genericArgument.get().name == "e"
  doAssert not test.`type`.genericArgument.get().genericReference

  # Check if parameters are obtained correctly
  doAssertRaisesMsg(ParseDefect, "The generic reference was not properly defined"): discard parse("bad {T:Type} invalid:!wrong = ref")
  doAssertRaisesMsg(ParseDefect, "The flag was not properly defined"): discard parse("bad test:# invalid:badflags.0?a = flag")

  test = parse("test.test2.flagstest flags2:# test:flags2.0?asd = aaaa")
  doAssert test.name == "flagstest"
  doAssert test.namespaces == @["test", "test2"]
  doAssert test.parameters[0].name == "flags2"
  doAssert test.parameters[0].parameterType.isSome()
  doAssert test.parameters[0].parameterType.get() of TLParameterTypeFlag
  doAssert test.parameters[1].name == "test"
  doAssert test.parameters[1].parameterType.isSome()
  doAssert test.parameters[1].parameterType.get() of TLParameterTypeSpecified
  doAssert test.parameters[1].parameterType.get().TLParameterTypeSpecified.flag.isSome()
  doAssert test.parameters[1].parameterType.get().TLParameterTypeSpecified.flag.get().parameterName == "flags2"
  doAssert test.parameters[1].parameterType.get().TLParameterTypeSpecified.flag.get().index == 0

  test = parse("genericreftest#1111 {X:Type} acd:!X = aaaa")
  doAssert test.parameters[0].name == "acd"
  doAssert test.parameters[0].parameterType.isSome()
  doAssert test.parameters[0].parameterType.get() of TLParameterTypeSpecified
  doAssert test.parameters[0].parameterType.get().TLParameterTypeSpecified.`type`.genericReference

when isMainModule:
  echo "Starting utils module tests..."
  utilsTest()
  echo "Starting constructors module tests..."
  constructorsTest()
