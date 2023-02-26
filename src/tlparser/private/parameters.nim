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

## Module implementing parameters of a TL constructor

import strutils
import utils
import types
import options
import flags

type FlagsInt* = distinct uint32

type TLParameterType* = ref object of RootObj

type TLParameterTypeFlag* = ref object of TLParameterType

type TLParameterTypeSpecified* = ref object of TLParameterType ## A normal type, may be also a flag
    `type`*: TLType ## The type
    flag*: Option[TLFlag] ## If this is a conditional type (may appear only sometimes), the original flag to check if it exists


proc parseParameterType*(parameterType: string): TLParameterType =
    if parameterType == "#":
        return TLParameterTypeFlag()

    let splittedFlags = parameterType.split('?', 1)
    if splittedFlags.len > 1:
        return TLParameterTypeSpecified(`type`: parseType(splittedFlags[1]),
                flag: parseFlag(splittedFlags[0]).some())
    else:
        return TLParameterTypeSpecified(`type`: parseType(splittedFlags[0]))


type TLParameter* = object
    name*: string                           ## Name of the parameter
    anytype*: bool                          ## Any type defintion
    parameterType*: Option[TLParameterType] ## Type of the parameter

proc parseParameter*(parameter: string): TLParameter =
    if parameter.startsWith("{"): # 'Any type' definition
        if parameter.endsWith(":Type}"):
            let val = parameter.split(":", 1)
            return TLParameter(name: val[0][1..val.high], anytype: true)
        else:
            raise newException(ParseDefect, "Invalid generic")

    let paramSplit = parameter.split(":", 1)
    if not paramSplit[0].isEmptyOrWhitespace():
        result.name = paramSplit[0]
        if paramSplit.len > 1:
            result.parameterType = parseParameterType(paramSplit[1]).some()
        else:
            raise newException(ParseDefect, "Expected type of the parameter, got nothing")
    else:
        raise newException(ParseDefect, "Expected name of the parameter, got nothing/whitespace")

