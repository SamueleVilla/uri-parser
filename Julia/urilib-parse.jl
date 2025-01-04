### -*- Mode: Julia -*-
### begin: urilib-parse.jl
###
### 914194 Villa Samuele
### 909506 Sorrentino Raoul

### ----------------------------------------- ###
# Costants
const IPV4_LENGTH_RANGE = 7:15
const IPV4_DECIMAL_LENGTH_RANGE = 1:3
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

is_valid_identifier(char) =
    isletter(char) ||
        isdigit(char) ||
        char in ['_']

is_valid_host_identifier(char) =
    is_valid_identifier(char) &&
        char != '.'

is_valid_digit(char) = isdigit(char)

### ----------------------------------------- ###
### Helper functions

"""
Function to get the rest of the list
"""
function tail(list)
    return list[2:end]
end

"""
function to peek the first element of the strig
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
Throws an error and stop the parser
"""
parser_error() = error("ParserError: Invalid URI")
function parser_error(message :: String)
    error("ParserError: Invalid URI - $message")
end

"""
Backtracks if the given parser doesn't end with the given char
"""
function parser_endswith(parser :: Parser, char) :: Parser
    (res, rest) = parser

    if first(rest) == char
        return (res, tail(rest))
    else
        return ([], vec_to_string(res) * rest)
    end
end

"""
Parses an expression of the form <Identifier>*
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
Parses an expression of the form <Identifier>+
The identifier is composed of characters satisfying the given predicate
"""
function grammar_one_or_more(str, pred) :: Parser
    (res, rest) = grammar_zero_or_more(str, pred)
    if isempty(res)
        parser_error()
    else
        (res, rest)
    end
end

"""
Parses an expression of the form ['.' <Identifier>]*
"""
function grammar_char_identifier_star(str :: String, char, pred) :: Parser
    if isempty(str) || first(str) != char
        ([], str)
    else
        (res, rest) = grammar_one_or_more(tail(str), pred)
        (res_ric, rest_ric) = grammar_char_identifier_star(rest, char, pred)

        ([char, res..., res_ric...], rest_ric)
    end
end

"""
Parses an expressison of the form ['.' <Identifier>]
"""
function grammar_preceded_by_char(str :: String, char, parser_func) :: OptionalParser
    if !isempty(str) && first(str) == char
        if isempty(tail(str))
            parser_error("Unexpected end of the string after `$char`")
        end

        parser_func(tail(str))
    else
        (nothing, str)
    end
end

"""
Parses the expression: scheme ':'
"""
function parse_scheme(str :: String) :: Parser
    (res, rest) = parser_endswith(grammar_one_or_more(str, is_valid_identifier), ':') 
    if isempty(res)
        parser_error("Unexpected char `$(peek(rest))` in scheme")
    else
        (res, rest)
    end
end

function parse_generic(str :: String)
    (userinfo, host, port, rest) = parse_authority(str)
end

"""
Parses the expression: '//' [userinfo '@'] host [':' port]
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

        (userinfo, host, port, port_rest)
    else
        (nothing, nothing, nothing, str)
    end
end

"""
Parses the expression: [ userinfo '@']
"""
function parse_userinfo(str :: String) :: OptionalParser
    (res, rest) = parser_endswith(grammar_one_or_more(str, is_valid_identifier), '@')

    if isempty(res)
        (nothing, str)
    else
        (res, rest)
    end
end

""""
Parses the expression: <Host-identifier> [ '.' <Host-identifier ] | <Indirizzo-IP>
"""
function parse_host(str :: String) :: Parser
    (ipv4_res, ipv4_rest) = parse_ipv4(str)
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

is_valid_ipv4_decimal(vec) = 
    parse(Int, vec_to_string(map(n -> n - '0', vec))) in 0:255

function parse_ipv4_ric(str :: String) :: Parser
    (res, rest) = grammar_zero_or_more(str, is_valid_digit)

    if isempty(res)
        return ([], rest)
    end

    if length(res) in IPV4_DECIMAL_LENGTH_RANGE &&
        is_valid_ipv4_decimal(res)
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

function parse_ipv4(str :: String) :: OptionalParser
    (res, rest) = parse_ipv4_ric(str)

    if length(res) in IPV4_LENGTH_RANGE
        (res, rest)
    else
        (nothing, rest)
    end
end

function parse_port(str :: String) :: Parser
    grammar_one_or_more(str, is_valid_digit)
end

### ----------------------------------------- ###
### Main function

function urilib_parse(uri :: String) :: URI
    (scheme, rest) = parse_scheme(uri)

    
    (userinfo, host, port, rest) = parse_generic(rest)

    scheme = vec_to_string(scheme)
    userinfo = vec_to_string(userinfo)
    host = vec_to_string(host)
    port = vec_to_string(port)

    URI(
        scheme,
        userinfo,
        host,
        isnothing(port) ? get(PROTOCOL_PORTS, scheme, "80") : port,
        nothing,
        nothing,
        nothing)
end

### end: urilib_parse.jl

