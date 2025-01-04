### -*- Mode: Julia -*-
### begin: urilib-parse.jl
###
### 914194 Villa Samuele
### 909506 Sorrentino Raoul

struct URI
  scheme :: String
  userInfo :: Union{String, Nothing}
  host :: Union{String, Nothing}
  port :: Union{String, Nothing} 
  path :: Union{String, Nothing}
  query :: Union{String, Nothing}
  fragment :: Union{String, Nothing}
end

urilib_scheme(uri :: URI) = uri.scheme
urilib_userInfo(uri :: URI) = uri.userInfo
urilib_host(uri :: URI) = uri.host
urilib_port(uri :: URI) = uri.port
urilib_path(uri :: URI) = uri.path
urilib_query(uri :: URI) = uri.query
urilib_fragment(uri :: URI) = uri.fragment

### ----------------------------------------- ###
### Predicate functions

function is_valid_identifier(char)
    return isletter(char) ||
        isdigit(char) ||
        char in ['_']
end

### ----------------------------------------- ###
### Helper functions

"""
 function to get the rest of the list
"""
function tail(list)
    return list[2:end]
end

"""
function to peek the first element of the strig
"""
peek(str) = isempty(str) ? "" : first(str)

### ----------------------------------------- ###
### Parser functions

"""
Type alias for defining the Parser data type
"""
const Parser = Tuple{Union{Nothing, Vector{Char}}, String}

"""
Throws an error and stop the parser
"""
parser_error() = error("ParserError: Invalid URI")
function parser_error(message :: String)
    error("Parse Error: Invalid URI - $message")
end

"""
Backtracks if the given parser doesn't end with the given char
"""
function parser_endswith(parser :: Parser, char) :: Parser
    if char == nothing
        parser
    end

    (res, rest) = parser

    if first(rest) == char
        return (res, tail(rest))
    else
        return (nothing, rest)
    end
end

"""
Parses an expression of the form <Identifier>*
The identifier is composed of characters satisfying the given predicate
"""
function grammar_zero_or_more(lista, pred) :: Parser
    if isempty(lista) || !pred(first(lista))
        return ([], lista)
    else
        res_ric = grammar_zero_or_more(tail(lista), pred)
        return ([first(lista); first(res_ric)...], last(res_ric))
    end
end

"""
Parses an expression of the form <Identifier>+
The identifier is composed of characters satisfying the given predicate
"""
function grammar_one_or_more(str, pred) :: Parser
    (res, rest) = grammar_zero_or_more(str, pred)
    if isempty(res)
        parser_error()
    end

    return (res, rest)
end


function parse_scheme(str :: String)
    parser_endswith(grammar_one_or_more(str, is_valid_identifier), ':')
end

function parse_generic(str :: String)
    authority = parse_authority(str)
end

function parse_authority(str :: String)
    
end

### ----------------------------------------- ###

function urilib_parse(uri :: String) :: URI
    (res, rest) = parse_scheme(uri)
    if isnothing(res)
        parser_error("Unexpected char `$(peek(rest))` in scheme")
    end

    scheme = join(res)
    
    parse_generic(rest)

    URI(scheme, "", "", "", "", "", "")
end


### end: urilib_parse.jl

