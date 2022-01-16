# Nimgram
# Copyright (C) 2020-2022 Daniele Cortesi <https://github.com/dadadani>
# This file is part of Nimgram, under the MIT License
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import options
import strutils, sequtils
import utils

type TLType* = ref object
    namespaces*: seq[string] ## Namespace(s) for this type
    name*: string            ## Name of this type
    bare*: bool              ## Bare or boxed type
    genericReference*: bool  ## Generic definition
    genericArgument*: Option[TLType]

proc parseType*(data: string): TLType =
    result = new TLType
    var typ = data
    if typ.startsWith('!'):
        result.genericReference = true
        typ.removePrefix("!")
    let genericSeparatorIndex = typ.rfind('<')

    if genericSeparatorIndex != -1:
        if not typ.endsWith('>'):
            raise newException(ParseDefect, "Expecting end of generic")

        result.genericArgument = some(parseType(typ[
                0..genericSeparatorIndex-1] & typ[typ.find('>')+1..typ.len-1]))

        typ = typ[genericSeparatorIndex+1..typ.find('>')-1]

    result.namespaces = typ.split('.')

    # Empty namespaces are not allowed
    if result.namespaces.anyIt(it.isEmptyOrWhitespace()):
        raise newException(ParseDefect, "Expecting a valid namespace, got an empty one")

    result.name = result.namespaces.pop()

    if result.name.isEmptyOrWhitespace():
        raise newException(ParseDefect, "Name of the type is empty")

    result.bare = result.name[0].isLowerAscii()
