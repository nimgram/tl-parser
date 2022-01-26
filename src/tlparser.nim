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
import tlparser/private/[utils, sections, constructors]

type TLParser* = ref object
    tl: string
    section: TLSection
    index: int

const FUNCTIONS_SEPARATOR = "functions"
const TYPES_SEPARATOR = "types"
const SEPARATOR_DASHES_COUNT = 3

const SEPARATOR_DASHES = "-".repeat(SEPARATOR_DASHES_COUNT)

proc parseNew*(data: string): TLParser =
    result = TLParser(tl: stripTLComments(data),
            section: Types,
            index: 0
        )

proc forcePositive(data: SomeInteger): SomeInteger =
    if data < 0: result = 0 else: result = data

iterator all*(self: TLParser): TLConstructor =
    while not(self.index >= self.tl.len-1):
        var strippedTL = ""
        var exit = false
        while true:
            if self.index >= self.tl.len-1:
                exit = true
                break

            var objectIndexEnd = self.tl[self.index..forcePositive(self.tl.len()-1)].find(";")
            objectIndexEnd = if objectIndexEnd == -1: self.tl.len() else: self.index+objectIndexEnd
            strippedTL = self.tl[self.index..objectIndexEnd-1].strip()

            self.index = objectIndexEnd+1
            if not strippedTL.isEmptyOrWhitespace():
                break

        if exit:
            exit = false
            continue
        if strippedTL.startsWith(SEPARATOR_DASHES):
            let separatorName = strippedTL.split(SEPARATOR_DASHES)[1]

            strippedTL.removePrefix(SEPARATOR_DASHES & separatorName & SEPARATOR_DASHES)
            strippedTL = strippedTL.strip()

            case separatorName
            of FUNCTIONS_SEPARATOR:
                self.section = Functions
            of TYPES_SEPARATOR:
                self.section = Types
            else:
                raise newException(ParseDefect, "Unknown separator " & separatorName)
        yield strippedTL.parse(self.section)

