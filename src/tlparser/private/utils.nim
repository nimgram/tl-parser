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

import strutils
import crc32

type ParseDefect* = object of Defect
    ## Raised if the parsing operation fails

proc stripTLComments*(data: string): string =
    ## Deletes single-line/multi-line comments
    var comment = false
    var multilineComment = false
    var prevChar = ' '
    var prev2Char = ' '

    for i, c in data:
        if not comment and $prevChar & $data[i] == "/*":
            result.add(c)
            when NimMajor == 1 and NimMinor < 6:
                result.delete(len(result)-1, len(result)-1)
            else:
                result.delete(len(result)-1..len(result)-1)
            multilineComment = true
        if not multilineComment and not comment and $data[i] & $prevChar == "//":
            when NimMajor == 1 and NimMinor < 6:
                result.delete(len(result)-1, len(result)-1)
            else:
                result.delete(len(result)-1..len(result)-1)
            comment = true
        if c == '\n':
            comment = false
        if not comment:
            if not multilineComment:
                result.add(c)
        prev2Char = if i-2 < 0: ' ' else: data[i-2]

        if not comment and $prevChar & $data[i] == "*/":
            if not multilineComment: raise newException(ParseDefect, "Unexpected end of comment")
            when NimMajor == 1 and NimMinor < 6:
                result.delete(len(result)-1, len(result)-1)
            else:
                result.delete(len(result)-1..len(result)-1)
            multilineComment = false
            comment = false
        prevChar = data[i]

proc generateID*(data: string): uint32 =
    ## Generate constructor id by calculating the crc32 checksum of the constructor

    var processedData = data.multiReplace((":bytes", ":string"), ("?bytes ",
            "?string "), ("<", " "), (">", ""), ("{", ""), ("}", ""))
    var flagIndex = processedData.find("?true")
    while flagIndex >= 0:
        var lspace = processedData[0..flagIndex].rfind(' ')
        if lspace < 0:
            lspace = 0
        processedData[lspace..flagIndex+4] = ""
        flagIndex = processedData.find("?true")
    processedData.crc32()
    return fromHex[uint32](processedData)
