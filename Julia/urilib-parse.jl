### -*- Mode: Julia -*-
### begin: urilib-parse.jl
###
### 894446 Bertoli Michelangelo
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

### ------------------------------------------------------------------------ ###
### Type definitions
struct URI
    scheme :: String
    userinfo :: Union{String, Nothing}
    host :: Union{String, Nothing}
    port :: String
    path :: Union{String, Nothing}
    query :: Union{String, Nothing}
    fragment :: Union{String, Nothing}
end

URI(scheme, userInfo, host, port, path, query, fragment) =
    URI(scheme,
        userInfo,
        host,
        isnothing(port) ? get(DEFAULT_PORTS, scheme, "80") : port,
        path,
        query,
        fragment)

URI(scheme, userInfo, host) =
    URI(scheme,
        userInfo,
        host,
        nothing,
        nothing,
        nothing,
        nothing)

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
vec_to_string(vec) = isnothing(vec) || isempty(vec) ? nothing : join(vec)

### ------------------------------------------------------------------------ ###
### Parsers of grammar expressions

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
Parses the expression <Exp> with the given predicate function
"""
function grammar_match_char(str :: String, pred) :: Parser
    if isempty(str) || !pred(first(str))
        ([], str)
    else
        ([first(str)], tail(str))
    end
end

"""
Parses the expression <Exp>* 0 or more characters
"""
function grammar_exp_star(str :: String, parse_func) :: Parser
    (res, rest) = parse_func(str)
    if isempty(res)
        (res, rest)
    else
        let
            (res_ric, rest_ric) = grammar_exp_star(rest, parse_func)
            ([res..., res_ric...], rest_ric)
        end
    end
end

"""
Parses the expression <Exp>+ at least one character
"""
function grammar_exp_plus(str :: String, parse_func) :: Parser
    (res, rest) = grammar_exp_star(str, parse_func)
    if isempty(res)
        parser_error()
    end
    (res, rest)
end

"""
Parses the expression [ <Exp> 'Char' ]
Backtracks if the given parser func doesn't end with the given char
"""
function grammar_endswith_char(str :: String,
    char::Char,
    parser_func) :: Parser
    (res, rest) = parser_func(str)

    if !isempty(rest) && first(rest) == char
        return (res, tail(rest))
    else
        return ([], vec_to_string(res) * rest)
    end
end

"""
Parses the expression ['Char' <Exp> ]*
"""
function grammar_startswith_char_ric(str :: String,
    char::Char,
    parser_func) :: Parser
    if isempty(str) || first(str) != char
        ([], str)
    else
        let
            (res, rest) = parser_func(tail(str))
            (res_ric, rest_ric) = grammar_startswith_char_ric(rest,
                char,
                parser_func)

            ([char, res..., res_ric...], rest_ric)
        end
    end
end

"""
Parses the expression ['Char' <Exp>]
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
### Parsers of uri syntax

isalnum(c) = isdigit(c) || isletter(c)

parse_letter(str :: String) =
    grammar_match_char(str, isletter)

parse_digit(str :: String) =
    grammar_match_char(str, isdigit)

parse_alpha(str :: String) =
    grammar_match_char(str, isalnum)

parse_character(str :: String) =
    grammar_match_char(str,
        c ->
            isalnum(c)
            ||
                c in ['_', '=', '+', '-', '&'])

parse_id44_char(str :: String) =
    grammar_match_char(str,
        c -> isalnum(c)
        ||
            c in ['.'])

"""
Function to verify that a vector of char is a valid Ipv4 decimal octet
"""
is_ipv4_octet(vec :: Vector{Char}) =
    parse(Int, vec_to_string(map(n -> n - '0', vec))) in 0:255

"""
Parses the expression
IP-Address ::= <NNN.NNN.NNN.NNN> with N digit
"""
function parse_ipv4_ric(str :: String) :: Parser
    let
        (res, rest) = grammar_exp_star(str, parse_digit)
        if isempty(res)
            return ([], rest)
        elseif length(res) in IPV4_DECIMAL_LENGTH_RANGE &&
               is_ipv4_octet(res)
            if !isempty(rest) && first(rest) == '.'
                let
                    (res_ric, rest_ric) = parse_ipv4_ric(tail(rest))
                    ([res...; '.'; res_ric...], rest_ric)
                end
            else
                (res, rest)
            end
        else
            parser_error("Invalid Ipv4 address octet range")
        end
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
Parses the expression
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
host-identifier ::= <letter> <alfanum>*
"""
function parse_host_id(str :: String) :: Parser
    let
        (res, rest) = parse_letter(str)
        if isempty(res)
            parser_error("host identifier must start with a letter")
        else
            let
                (res_ric, rest_ric) = grammar_exp_star(rest, parse_alpha)
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
userInfo ::= <identifier>
"""
function parse_userInfo(str :: String) :: Parser
    parse_identifier(str)
end

"""
Parses the expression
host ::= <host-identifier> [ '.' <host-identifier> ]*
     | <IP-Address>
"""
function parse_host(str :: String) :: Parser
    let
        # try to parse the ipv4 address
        (ipv4_res, ipv4_rest) = parse_ipv4(str)

        # if is not an ipv4 address parse the hostname
        if !isempty(ipv4_res)
            (ipv4_res, ipv4_rest)
        else
            let
                (host, rest) = parse_host_id(str)
                (host_ric, rest_ric) = grammar_startswith_char_ric(rest,
                    '.',
                    parse_host_id)

                ([host..., host_ric...], rest_ric)
            end
        end
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
Parses the expression
path ::= [ <Identifier> ['/' <Identifier> ]* ]
"""
function parse_path(str :: String) :: Parser
    let
        (id, id_rest) = grammar_exp_star(str, parse_character)
        (id_ric, id_rest_ric) = grammar_startswith_char_ric(id_rest,
            '/',
            parse_identifier)
        ([id..., id_ric...], id_rest_ric)
    end
end

"""
Parses the expression
query ::= <character>+
"""
function parse_query(str :: String) :: Parser
    grammar_exp_plus(str, parse_character)
end

"""
Parses the expression
fragment ::= <character>+
"""
function parse_fragment(str :: String) :: Parser
    grammar_exp_plus(str, parse_character)
end

"""
Parses the expression
id8 ::= <letter> <alphanum>*
"""
function parse_id8(str :: String) :: Parser
    (id8, rest) = grammar_exp_plus(str, parse_alpha)
    if !isletter(first(id8)) || length(id8) > 8
        parser_error("Invalid id8")
    else
        (id8, rest)
    end
end

"""
Parses the expression
id44::= <letter> (<alphanum> | '.')*
"""
function parse_id44(str :: String) :: Parser
    (id44, rest) = grammar_exp_star(str, parse_id44_char)
    if isempty(id44)
        (id44, rest)
    else
        if !isletter(first(id44)) || length(id44) > 44 || id44[end] == '.'
            parser_error("Invalid id44")
        else
            (id44, rest)
        end
    end
end

"""
Parses the expression
path ::= <id44> ['(' <id8> ')']
"""
function parse_zos_path(str :: String) :: Parser
    (id44, id44_rest) = parse_id44(str)
    if !isempty(id44_rest) && first(id44_rest) == '('
        (id8, id8_rest) = parse_id8(tail(id44_rest))
        if isempty(id8_rest) || first(id8_rest) != ')'
            parser_error("Missing closing bracket `)`")
        else
            ([id44..., '(', id8..., ')'], tail(id8_rest))
        end
    else
        (id44, id44_rest)
    end
end

"""
Parses the expression
authority ::= '//' [userinfo '@'] host [':' port]
"""
function parse_authority(str :: String)
    if length(str) >= 2 && str[1] == '/' && str[2] == '/'
        let
            (userInfo, userInfo_rest) = grammar_endswith_char(str[3:end],
                '@',
                parse_userInfo)
            (host, host_rest) = parse_host(userInfo_rest)
            (port, port_rest) = grammar_startswith_char(host_rest,
                                                        ':',
                                                        parse_port)
            (userInfo,
                host,
                port,
                port_rest)
        end
    else
        ([], [], [], str)
    end
end

"""
Parses the expression
generic-scheme ::= authority ['/' [path] ['?' query] ['#fragment']]
               | ['/'] [path] ['?' query] ['#' fragment]
"""
function parse_genericzos(scheme :: String, str :: String) :: URI
    let
        (userinfo, host, port, auth_rest) = parse_authority(str)

        no_auth = str == auth_rest
        (slash, slash_rest) = parse_slash(auth_rest)

        if !no_auth && isempty(slash) && !isempty(slash_rest)
            parser_error("Expected char `/` after authority")
        end

        (path, rest_path) = path_choice(scheme, slash_rest)

        (query, rest_query) = grammar_startswith_char(rest_path,
                                                      '?',
                                                      parse_query)
        (fragment, _) = grammar_startswith_char(rest_query,
            '#',
            parse_fragment)

        URI(
            scheme,
            vec_to_string(userinfo),
            vec_to_string(host),
            vec_to_string(port),
            vec_to_string(path),
            vec_to_string(query),
            vec_to_string(fragment))
    end
end

function path_choice(scheme :: String, str :: String) :: Parser
    if scheme == "zos"
        parse_zos_path(str)
    else
        parse_path(str)
    end
end

"""
Parses the expression
mailto ::= userinfo [ '@' host ]
"""
function parse_mailto(scheme :: String, str :: String) :: URI
    let
        (userinfo, userinfo_rest) = parse_userInfo(str)
        (host, _) = grammar_startswith_char(userinfo_rest, '@', parse_host)

        URI(scheme,
            vec_to_string(userinfo),
            vec_to_string(host))
    end
end

"""
Parses the expression
news ::= host
"""
function parse_news(scheme :: String, str :: String) :: URI
    (host, _) = parse_host(str)
    URI(scheme, nothing, vec_to_string(host))
end

"""
Parses the expression
tel|fax ::= userinfo
"""
function parse_telfax(scheme :: String, str :: String) :: URI
    (userinfo, _) = parse_userInfo(str)
    URI(scheme, vec_to_string(userinfo), nothing)
end

function parse_afterscheme(scheme :: String, str :: String)
    if scheme == "mailto"
        parse_mailto(scheme, str)
    elseif scheme == "news"
        parse_news(scheme, str)
    elseif scheme in ["tel", "fax"]
        parse_telfax(scheme, str)
    else
        parse_genericzos(scheme, str)
    end
end

### ------------------------------------------------------------------------ ###
### API functions

urilib_scheme(uri :: URI) = uri.scheme
urilib_userInfo(uri :: URI) = uri.userinfo
urilib_host(uri :: URI) = uri.host
urilib_port(uri :: URI) = uri.port
urilib_path(uri :: URI) = uri.path
urilib_query(uri :: URI) = uri.query
urilib_fragment(uri :: URI) = uri.fragment

function urilib_display(uri :: URI, stream = stdout)
    println(stream, "Scheme:      $(urilib_scheme(uri))")
    println(stream, "Userinfo:    $(urilib_userInfo(uri))")
    println(stream, "Host:        $(urilib_host(uri))")
    println(stream, "Port:        $(urilib_port(uri))")
    println(stream, "Path:        $(urilib_path(uri))")
    println(stream, "Query:       $(urilib_query(uri))")
    println(stream, "Fragment:    $(urilib_fragment(uri))")
end

function urilib_parse(uri::String) :: URI
    (scheme, scheme_rest) =
        grammar_endswith_char(uri, ':', parse_scheme)
    if isempty(scheme)
        parser_error("Unexpected char after scheme")
    end

    parse_afterscheme(vec_to_string(scheme), scheme_rest)
end

### end: urilib_parse.jl

