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

## Module implementing conditional flags of the TL Language

import strutils
import utils

type TLFlag* = object
    parameterName*: string ## The name of the parameter containings bits for this flag
    index*: int32 ## The index of this flag


proc parseFlag*(flag: string): TLFlag =
    let splittedParameterName = flag.split('.')
    result.parameterName = splittedParameterName[0]
    if splittedParameterName.len > 1:
        result.index = parseInt(splittedParameterName[1]).int32
    else:
        raise newException(ParseDefect, "Expecting index for this flag, got nothing")
