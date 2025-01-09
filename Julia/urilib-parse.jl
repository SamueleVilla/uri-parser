### -*- Mode: Julia -*-
### begin: urilib-parse.jl
###
### 914194 Villa Samuele
### 909506 Sorrentino Raoul

### ------------------------------------------------------------------------ ###
# Constants
const IPV4_LENGTH_RANGE = 7:15
const IPV4_DECIMAL_LENGTH_RANGE = 1:3
const IPV4_DOTS = 3

const DEFAULT_PORTS = Dict(
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
  port :: String 
  path :: Union{String, Nothing}
  query :: Union{String, Nothing}
  fragment :: Union{String, Nothing}
end

URI(scheme, userinfo, host, port, path, query, fragment) =
    URI(scheme,
        userinfo,
        host,
        isnothing(port) ? get(DEFAULT_PORTS, scheme, "80") : port,
        path,
        query,
        fragment)

URI(scheme, userinfo, host) =
    URI(scheme,
        userinfo,
        host,
        nothing,
        nothing,
        nothing,
        nothing)


urilib_scheme(uri :: URI) = uri.scheme
urilib_userInfo(uri :: URI) = uri.userInfo
urilib_host(uri :: URI) = uri.host
urilib_port(uri :: URI) = uri.port
urilib_path(uri :: URI) = uri.path
urilib_query(uri :: URI) = uri.query
urilib_fragment(uri :: URI) = uri.fragment

### ------------------------------------------------------------------------ ###
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

### ------------------------------------------------------------------------ ###
### Parser functions

"""
Type alias for defining the Parser data type
"""
const Parser = Tuple{Union{Nothing, Vector{Char}}, String}

"""
Throws the error and stop the parser execution
"""
parser_error() = error("ParserError: Invalid URI")
function parser_error(message :: String)
    error("ParserError: Invalid URI - $message")
end

"""
Parses <Exp>
"""
function grammar_match_char(str :: String, pred) :: Parser
    if isempty(str) || !pred(first(str))
        ([], str)
    else
        ([first(str)], tail(str))
    end
end

"""
Parses <Exp>*
"""
function grammar_exp_star(str :: String, parse_func) :: Parser
    (res, rest) = parse_func(str)
    if isempty(res)
        (res, rest)
    else
        (res_ric, rest_ric) = grammar_exp_star(rest, parse_func)
        ([res..., res_ric...], rest_ric)
    end
end

"""
Parses <Exp>+
"""
function grammar_exp_plus(str :: String, parse_func) :: Parser
    (res, rest) = grammar_exp_star(str, parse_func)
    if isempty(res)
        parser_error()
    end

    (res, rest)
end

"""
Parses <Exp> <AnotherExp>
"""
function grammar_startswith_exp(str :: String, p1, p2) :: Parser
    (res1, rest1) = p1(str)
    (res2, rest2) = p2(rest1)

    ([res1..., res2...], rest2)
end

"""
Parses the expression
[ <Exp> 'Char' ]
Backtracks if the given parser func doesn't end with the given char
"""
function grammar_endswith_char(str :: String,
                               char :: Char,
                               parser_func) :: Parser
    (res, rest) = parser_func(str)

    if first(rest) == char
        return (res, tail(rest))
    else
        return ([], vec_to_string(res) * rest)
    end
end

"""
Parses the expression
['Char' <Exp> ]*
"""
function grammar_startswith_char_ric(str :: String,
                                     char :: Char,
                                     parser_func) :: Parser
    if isempty(str) || first(str) != char
        ([], str)
    else
        (res, rest) = parser_func(tail(str))
        (res_ric, rest_ric) = grammar_startswith_char_ric(rest,
                                                          char,
                                                          parser_func)

        ([char, res..., res_ric...], rest_ric)
    end
end

"""
Parses the expression
['Char' <Exp>]
"""
function grammar_startswith_char(str :: String, char, parser_func) :: Parser
    if !isempty(str) && first(str) == char
        if isempty(tail(str))
            parser_error("Unexpected end of the string after `$char`")
        end

        parser_func(tail(str))
    else
        ([], str)
    end
end

### ------------------------------------------------------------------------ ###
isalpha(c) = isdigit(c) || isletter(c)

parse_letter(str :: String) =
    grammar_match_char(str, isletter)

parse_digit(str :: String) =
    grammar_match_char(str, isdigit)

parse_alnum(str :: String) =
    grammar_match_char(str, isalpha)

parse_character(str :: String) =
    grammar_match_char(str,
                       c ->
                           isalpha(c)
                       || c in ['_', '=', '+', '-', '&'])

parse_id44_char(str :: String) =
    grammar_match_char(str,
                       c -> isalpha(c)
                       || c in ['.'])

"""
Function to verify that a vector of char is a valid Ipv4 decimal octet
"""
is_ipv4_octet(vec :: Vector{Char}) = 
    parse(Int, vec_to_string(map(n -> n - '0', vec))) in 0:255

"""
Parses the expression
IP-Adress ::= <NNN.NNN.NNN.NNN> with N digit
"""
function parse_ipv4_ric(str :: String) :: Parser
    (res, rest) = grammar_exp_star(str, parse_digit)

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
        parser_error("Invalid Ipv4 address octet range")
    end
end

"""
Parses the expression
IP-Address ::= <NNN.NNN.NNN>
"""
function parse_ipv4(str :: String) :: Parser
    (res, rest) = parse_ipv4_ric(str)

    if isempty(res)
        return ([], rest)
    end

    if !(length(res) in IPV4_LENGTH_RANGE) ||
        count(c -> c == '.', res) != IPV4_DOTS
        parser_error("Invalid Ipv4 address octet")
    end

    (res, rest)
end


"""
Parses the expession
[ '/' ]
"""
function parse_slash(str :: String) :: Parser
    if !isempty(str) && first(str) == '/'
        ([first(str)], tail(str))
    else
        ([], str)
    end
end

"""
Parses the expression
identifier ::= <character>+
"""
function parse_identifier(str :: String) :: Parser
    grammar_exp_plus(str, parse_character)
end

"""
Parses the expression
host-dentifier ::= <letter> <alfanum>*
"""
function parse_host_id(str :: String) :: Parser
    let
        (res, rest) = parse_letter(str)
        if isempty(res)
            parser_error("host identifier must start with a letter")
        else
            let
                (res_ric, rest_ric) = grammar_exp_star(rest, parse_alnum)
                ([res..., res_ric...], rest_ric)
            end
        end
    end
end
"""
Parses the expression
scheme ::= <identifier>
"""
function parse_scheme(str :: String) :: Parser
    parse_identifier(str)
end

"""
Parses the expression
userinfo ::= <identifier>
"""
function parse_userinfo(str :: String) :: Parser
    parse_identifier(str)
end

"""
Parses the expression
host ::= <host-identifier> [ '.' <host-identifier> ]*
     | <IP-Address>
"""
function parse_host(str :: String) :: Parser

    # try to parse the ipv4 address
    (ipv4_res, ipv4_rest) = parse_ipv4(str)

    # if is not an ipv4 address parse the hostname
    if !isempty(ipv4_res)
        (ipv4_res, ipv4_rest)
    else
        grammar_startswith_exp(str,
                               parse_host_id,
                               str ->
                                   grammar_startswith_char_ric(str,                                                               
                                                               '.',
                                                               parse_host_id))
    end
end

"""
Parses the expression
port ::= <digit>+
"""
function parse_port(str :: String) :: Parser
    grammar_exp_plus(str, parse_digit)
end

"""
Parses the expression path ::= [ <Identifier> | ['/' <Identifier> ]* ]
"""
function parse_path(str :: String) :: Parser
    grammar_startswith_exp(str,
                           parse_identifier,
                           str -> grammar_startswith_char_ric(str,
                                                              '/',
                                                              parse_identifier))
end

"""
Parses the expression ::= <character> without '#'
"""
function parse_query(str :: String) :: Parser
    grammar_exp_plus(str, parse_character)
end

"""
Parses the expression ::= <character>+
"""
function parse_fragment(str :: String) :: Parser
    grammar_exp_plus(str, parse_character)
end

function parse_id8(str :: String)
    let
        (res, rest) = grammar_match_char(str, isletter)
        if isempty(res)
            parser_error("id8 must start with a letter")
        else
            let
                (res_ric, rest_ric) = grammar_exp_star(str, parse_alnum)
                ([res..., res_ric...], rest_ric)
            end
        end
    end
end

function parse_id44(str :: String)
    let
        (res, rest) = parse_letter(str)
        if isempty(res)
            parser_error("i44 must start with a letter")
        else
            let
                (res_ric, rest_ric) =
                    grammar_exp_star(rest, parse_id44_char)
                
                id44 = [res..., res_ric...]
                
                if length(id44) > 44 || id44[end] == '.'
                    parser_error("id44 cannot exceed 44 characters or end with `.`")
                else
                    (id44, rest_ric)
                end
            end
        end
    end
end

function parse_zos_path(str :: String) :: Parser
    
end

"""
Parses the expression
authority ::= '//' [userinfo '@'] host [':' port]
"""
function parse_authority(str :: String)
    if length(str) >= 2 && str[1] == '/' && str[2] == '/'

        (userinfo, userinfo_rest) = grammar_endswith_char(str[3:end],
                                                          '@',
                                                          parse_userinfo)
        
        (host, host_rest) = parse_host(userinfo_rest)

        (port, port_rest) = grammar_startswith_char(host_rest, ':', parse_port)
        
        (userinfo,
         host,
         port,
         port_rest)
    else
        ([], [], [], str)
    end
end

"""
Parses the expression
generic-scheme ::= authority ['/' [path] ['?' query] ['#fragment']]
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

    (query, rest_query) = grammar_startswith_char(rest_path, '?', parse_query)

    (fragment, rest_fragment) = grammar_startswith_char(rest_query,
                                                        '#',
                                                        parse_fragment)

    (isempty(userinfo) ? nothing : userinfo,
     isempty(host) ? nothing : host,
     isempty(port) ? nothing : port,
     isempty(path) ? nothing : path,
     isempty(query) ? nothing : query,
     isempty(fragment) ? nothing : fragment)
end

"""
Parses the expression
mailto ::= userinfo [ '@' host ]
"""
function parse_mailto_scheme_syntax(str :: String)
    (userinfo, userinfo_rest) = parse_userinfo(str)
    (host, host_rest) = grammar_startswith_char(userinfo_rest, '@', parse_host) 

    (userinfo, isempty(host) ? nothing : host)
end

"""
Parses the expression
news ::= host
"""
function parse_news_scheme_syntax(str :: String)
    (host, _) = parse_host(str)

    (host)
end

"""
Parses the expression
tel|fax ::= userinfo
"""
function parse_telfax_scheme_syntax(str :: String)
    (userinfo, _) = parse_userinfo(str)

    (userinfo)
end

### ------------------------------------------------------------------------ ###
### Main function

function urilib_parse(uri :: String) :: URI
    (scheme, scheme_rest) =
        grammar_endswith_char(uri, ':', parse_scheme)

    if isempty(scheme)
        parse_error("Unexpected char `$(peek(rest)) after scheme")
    end

    scheme = vec_to_string(scheme)

    if scheme == "mailto"
       (userinfo, host) = parse_mailto_scheme_syntax(scheme_rest) 

        userinfo = vec_to_string(userinfo)
        host = vec_to_string(host)

        URI(scheme, userinfo, host)

    elseif scheme == "news"
        (host) = parse_news_scheme_syntax(scheme_rest)

        host = vec_to_string(host)

        URI(scheme, nothing, host)

    elseif scheme in ["tel", "fax"]
        (userinfo) = parse_telfax_scheme_syntax(scheme_rest)

        userinfo = vec_to_string(userinfo)

        URI(scheme, userinfo, nothing)
    else
        (userinfo, host, port, path, query, fragment) =
            parse_generic_scheme_syntax(scheme_rest)
        
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
            port,
            path,
            query,
            fragment)
    end
end

### end: urilib_parse.jl

