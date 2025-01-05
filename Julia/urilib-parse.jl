### -*- Mode: Julia -*-
### begin: urilib-parse.jl
###
### 914194 Villa Samuele
### 909506 Sorrentino Raoul

### ----------------------------------------- ###
# Constants
const IPV4_LENGTH_RANGE = 7:15
const IPV4_DECIMAL_LENGTH_RANGE = 1:3
const IPV4_DOTS = 3

const PROTOCOL_PORTS = Dict(
    "http" => "80",
    "https" => "443",
    "ftp" => "21",
    "smtp" => "25",
    "ssh" => "22",
    "telnet" => "23"
)

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

"""
Predicate ::= <character '_', A-Z, a-<, 0-9>
"""
is_valid_identifier(char) =
    isletter(char) ||
        isdigit(char) ||
        char in ['_']

"""
Predicate ::= <letter> <character>
"""
is_valid_host_identifier(char) =
    is_valid_identifier(char) &&
        char != '.'

"""
Predicate ::= <digit>+
"""
is_valid_digit(char) = isdigit(char)

"""
Predicate ::= <character> without '#'
"""
is_valid_query(char) =
    isletter(char) ||
    isdigit(char) ||
    char in ['_', '&', '=']

is_valid_fragment(char) =
    is_valid_identifier(char)

### ----------------------------------------- ###
### Helper functions

"""
Function to get the tail of the list (exclude the first element)
"""
function tail(list)
    return list[2:end]
end

"""
Function to peek the first element of the string
"""
peek(str) = isempty(str) ? "" : first(str)

"""
Function to convert Vector of char to a string handling nothing case
"""
vec_to_string(vec) = isnothing(vec) ? nothing : join(vec)

### ----------------------------------------- ###
### Parser functions

"""
Type alias for defining the Parser data type
"""
const Parser = Tuple{Union{Nothing, Vector{Char}}, String}
const OptionalParser = Tuple{Union{Nothing, Vector{Char}}, String}

"""
Throws an error and stop the parser execution
"""
parser_error() = error("ParserError: Invalid URI")
function parser_error(message :: String)
    error("ParserError: Invalid URI - $message")
end

"""
Backtracks if the given parser doesn't end with the given char
"""
function parser_endswith(parser :: Parser, char :: Char) :: Parser
    (res, rest) = parser

    if first(rest) == char
        return (res, tail(rest))
    else
        return ([], vec_to_string(res) * rest)
    end
end

"""
Parses an expression ::= <Identifier>*
The identifier is composed of characters satisfying the given predicate
"""
function grammar_zero_or_more(str :: String, pred) :: Parser
    if isempty(str) || !pred(first(str))
        return ([], str)
    else
        res_ric = grammar_zero_or_more(tail(str), pred)
        return ([first(str); first(res_ric)...], last(res_ric))
    end
end

"""
Parses an expression ::= <Identifier>+
The identifier is composed of characters satisfying the given predicate
"""
function grammar_one_or_more(str :: String, pred) :: Parser
    (res, rest) = grammar_zero_or_more(str, pred)
    if isempty(res)
        parser_error()
    else
        (res, rest)
    end
end

"""
Parses an expression ::= ['Char' <Identifier>]*
"""
function grammar_char_identifier_star(str :: String, char :: Char, pred) :: Parser
    if isempty(str) || first(str) != char
        ([], str)
    else
        (res, rest) = grammar_one_or_more(tail(str), pred)
        (res_ric, rest_ric) = grammar_char_identifier_star(rest, char, pred)

        ([char, res..., res_ric...], rest_ric)
    end
end

"""
Parses an expression ::=  ['Char' <Identifier>]
"""
function grammar_preceded_by_char(str :: String, char, parser_func) :: Parser
    if !isempty(str) && first(str) == char
        if isempty(tail(str))
            parser_error("Unexpected end of the string after `$char`")
        end

        parser_func(tail(str))
    else
        ([], str)
    end
end


"""
Parses the expression := scheme ':'
"""
function parse_scheme(str :: String) :: Parser
    (res, rest) = parser_endswith(grammar_one_or_more(str, is_valid_identifier), ':') 
    if isempty(res)
        parser_error("Unexpected char `$(peek(rest))` in scheme")
    else
        (res, rest)
    end
end

"""
Parses the expression ::= authority ['/' [path] ['?' query] ['#fragment']]
                      | ['/'] [path] ['?' query] ['#' fragment]
"""
function parse_generic_scheme_syntax(str :: String)
    (userinfo, host, port, auth_rest) = parse_authority(str)

    noauth = str == auth_rest

    (slash, slash_rest) = parse_slash(auth_rest)

    (path, rest_path) = parse_path(slash_rest)

    if !noauth && isempty(slash) && !isempty(path)
        parser_error("Expected char `/` between authority and path")
    end

    (query, rest_query) =
        grammar_preceded_by_char(rest_path, '?', parse_query)

    (fragment, rest_fragment) =
        grammar_preceded_by_char(rest_query, '#', parse_fragment)

    (isempty(userinfo) ? nothing : userinfo,
     isempty(host) ? nothing : host,
     isempty(port) ? nothing : port,
     isempty(path) ? nothing : path,
     isempty(query) ? nothing : query,
     isempty(fragment) ? nothing : fragment)
end

"""
Parses the expression ::= '//' [userinfo '@'] host [':' port]
"""
function parse_authority(str :: String)
    if length(str) >= 2 && str[1] == '/' && str[2] == '/'
        (userinfo, userinfo_rest) =
            parse_userinfo(str[3:end])
        (host, host_rest) =
            parse_host(userinfo_rest)
        (port, port_rest) =
            grammar_preceded_by_char(host_rest,
                                     ':',
                                     parse_port)
        
        (userinfo,
         host,
         port,
         port_rest)
    else
        ([], [], [], str)
    end
end

"""
Parses the expression ::= [ userinfo '@']
"""
function parse_userinfo(str :: String) :: Parser
    (res, rest) = parser_endswith(grammar_one_or_more(str, is_valid_identifier), '@')
end

"""
Parses the expression ::= <Host-identifier> [ '.' <Host-identifier> ] | <IP-Address>
"""
function parse_host(str :: String) :: Parser

    # try to parse an ipv4 address
    (ipv4_res, ipv4_rest) = parse_ipv4(str)

    # if not an ipv4 address parse the hostname
    if isnothing(ipv4_res)
        (host_res, host_rest) =
            grammar_one_or_more(str, is_valid_host_identifier)
        (host_res_ric, host_rest_ric) =
            grammar_char_identifier_star(host_rest,
                                         '.',
                                         is_valid_host_identifier)

        ([host_res...; host_res_ric...], host_rest_ric)
    else
        (ipv4_res, ipv4_rest)
    end
end

"""
Function to verify that a vector of char is a valid Ipv4 decimal octet
"""
is_ipv4_octet(vec :: Vector{Char}) = 
    parse(Int, vec_to_string(map(n -> n - '0', vec))) in 0:255

"""
Parses the expression ::= <NNN.NNN.NNN.NNN> with N digit
"""
function parse_ipv4_ric(str :: String) :: Parser
    (res, rest) = grammar_zero_or_more(str, is_valid_digit)

    if isempty(res)
        return ([], rest)
    end

    if length(res) in IPV4_DECIMAL_LENGTH_RANGE &&
        is_ipv4_octet(res)
        if !isempty(rest) && first(rest) == '.'
            (res_ric, rest_ric) = parse_ipv4_ric(tail(rest))
            ([res...; '.'; res_ric...], rest_ric)
        else
            (res, rest)
        end
    else
        parser_error("Invalid Ipv4 address")
    end
end

"""
Parses the expression ::= <IP-Address>
"""
function parse_ipv4(str :: String) :: OptionalParser
    (res, rest) = parse_ipv4_ric(str)

    if length(res) in IPV4_LENGTH_RANGE
        if count(c -> c == '.', res) != IPV4_DOTS
            parser_error("Invalid Ipv4 address")
        else
            (res, rest)
        end
    else
        (nothing, rest)
    end
end

"""
Parses the expression ::= <digit>+
"""
function parse_port(str :: String) :: Parser
    grammar_one_or_more(str, is_valid_digit)
end


function parse_slash(str :: String) :: Parser
    if !isempty(str) && first(str) == '/'
        ([first(str)], tail(str))
    else
        ([], str)
    end
end

"""
Parses the expression ::= <Identifier> [ '/' <Identifier>]*
"""
function parse_path(str :: String) :: OptionalParser
    (res, rest) = grammar_zero_or_more(str, is_valid_identifier)
    if isempty(res)
        ([], rest)
    else
        (res_ric, rest_ric) = grammar_char_identifier_star(rest, '/', is_valid_identifier)

        ([res..., res_ric...], rest_ric)
    end
end

"""
Parses the expression ::= <character> without '#'
"""
function parse_query(str :: String) :: Parser
    grammar_one_or_more(str, is_valid_query)
end

"""
Parses the expression ::= <character>+
"""
function parse_fragment(str :: String) :: Parser
    grammar_one_or_more(str, is_valid_fragment)
end

### ----------------------------------------- ###
### Main function

function urilib_parse(uri :: String) :: URI
    (scheme, rest) = parse_scheme(uri)

    
    (userinfo, host, port, path, query, fragment) = parse_generic_scheme_syntax(rest)

    scheme = vec_to_string(scheme)
    userinfo = vec_to_string(userinfo)
    host = vec_to_string(host)
    port = vec_to_string(port)
    path = vec_to_string(path)
    query = vec_to_string(query)
    fragment = vec_to_string(fragment)

    URI(
        scheme,
        userinfo,
        host,
        isnothing(port) ? get(PROTOCOL_PORTS, scheme, "80") : port,
        path,
        query,
        fragment)
end

### end: urilib_parse.jl

