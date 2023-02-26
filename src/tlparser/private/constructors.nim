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

## Module implemeting constructors of the TL Language

import parameters, sections, types, utils
import strutils, options, sequtils

type TLConstructor* = object
    namespaces*: seq[string] ## Namespace(s) for this constructor
    name*: string            ## Name of this constructor
    id*: uint32 ## The id of this constructor. If it is not present, it is calculated
    parameters*: seq[TLParameter]
    section*: TLSection
    `type`*: TLType

proc splitType(constructor: string): (string, string) =
    let eqSplit = constructor.split("=", 1)
    if eqSplit.len > 1:
        let constructorType = eqSplit[1].strip()
        if not constructorType.isEmptyOrWhitespace():
            return (eqSplit[0].strip(), constructorType)

    raise newException(ParseDefect, "The type is missing")

proc splitName(constructor: string): (string, string) =
    let wsSplit = constructor.split(" ", 1)
    if wsSplit.len > 1:
        return (wsSplit[0], wsSplit[1].strip())
    return (wsSplit[0], "")

proc splitID(constructor: string): (string, string) =
    let tagSplit = constructor.split("#", 1)
    if tagSplit.len > 1:
        if tagSplit[1].isEmptyOrWhitespace():
            raise newException(ParseDefect, "Expecting a valid constructor id, instead got an empty one")
        return (tagSplit[0], tagSplit[1].strip())
    return (tagSplit[0], "")


proc parse*(constructor: string, section: TLSection = Types): TLConstructor =

    if constructor.strip().isEmptyOrWhitespace():
        raise newException(ParseDefect, "The constructor is empty")

    let splittedType = splitType(constructor)

    result.section = section
    result.`type` = parseType(splittedType[1])

    let splittedName = splitName(splittedType[0])

    # 'name#5' or 'name' should become 'name'
    let splittedID = splitID(splittedName[0])

    # If the constructor id is specified, use it, otherwise generate it
    try:
        result.id = if splittedID[1] != "": uint32(parseHexInt(splittedID[
            1])) else: generateID(constructor)
    except:
        raise newException(ParseDefect, "Invalid constructor id")
    result.namespaces = splittedID[0].split(".")

    # Empty namespaces are not allowed
    if result.namespaces.len == 0 or result.namespaces.anyIt(
            it.isEmptyOrWhitespace()):
        raise newException(ParseDefect, "Expecting a valid namespace, got an empty one")

    result.name = result.namespaces.pop()

    let splittedParameters = splittedName[1].splitWhitespace()

    var genericDefinitions = newSeq[string]()
    var flagsDefinitions = newSeq[string]()

    for parameter in splittedParameters:

        # Parse a single parameter
        let parsedParameter = parseParameter(parameter)

        # Example: {X:Type}
        if parsedParameter.anytype:
            genericDefinitions.add(parsedParameter.name)
            result.parameters.add(parsedParameter)
            continue

        if parsedParameter.parameterType.isNone():
            raise newException(ParseDefect, "Expecting a valid parameterType, got empty option")

        if parsedParameter.parameterType.get() of TLParameterTypeFlag:
            result.parameters.add(parsedParameter)
            flagsDefinitions.add(parsedParameter.name)
            continue

        if not (parsedParameter.parameterType.get() of TLParameterTypeSpecified):
            raise newException(ParseDefect, "Expecting parsedParameter to be TLParameterTypeSpecified, got a different type")

        if parsedParameter.parameterType.get(
        ).TLParameterTypeSpecified.`type`.genericReference and not(
                genericDefinitions.contains(parsedParameter.parameterType.get(
        ).TLParameterTypeSpecified.`type`.name)):
            raise newException(ParseDefect,
                    "The generic reference was not properly defined")


        if parsedParameter.parameterType.get(
        ).TLParameterTypeSpecified.flag.isSome() and not(
                flagsDefinitions.contains(parsedParameter.parameterType.get(
        ).TLParameterTypeSpecified.flag.get().parameterName)):
            raise newException(ParseDefect,
                    "The flag was not properly defined")

        result.parameters.add(parsedParameter)




