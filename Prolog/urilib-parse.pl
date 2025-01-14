%%% -*- Mode: Prolog -*-
%%% begin: urilib-parse.pl
%%%
%%% 894446 Bertoli Michelangelo
%%% 914194 Villa Samuele
%%% 909506 Sorrentino Raoul

urilib_parse(URIString, URI) :- 
    string_codes(URIString, Codes),
    parse_scheme(Codes, Scheme, PostScheme),
    parse_afterScheme(Scheme, PostScheme, URI).

urilib_display(URI) :-
    URI = uri(Scheme, Userinfo, Host, Port, Path, Query, Fragment),
    format("Scheme: ~w~n", [Scheme]),
    format("Userinfo: ~w~n", [Userinfo]),
    format("Host: ~w~n", [Host]),
    format("Port: ~w~n", [Port]),
    format("Path: ~w~n", [Path]),
    format("Query: ~w~n", [Query]),
    format("Fragment: ~w~n", [Fragment]).

% Controlla se il parse e quello inserito sono uguali e poi fa il display
urilib_display(URIString, URIInput) :-
    urilib_parse(URIString, URIInput),
    urilib_display(URIInput).

parse_scheme(Codes, Scheme, PostScheme) :-
    append(SchemeCodes, [58 | PostScheme], Codes), % 58 :
    atom_codes(Scheme, SchemeCodes),
    identificatore(SchemeCodes).

% Solo schema
parse_afterScheme(Scheme, [], URI) :-
    Scheme \= mailto,
    Scheme \= news,
    Scheme \= tel,
    Scheme \= fax,
    URI = uri(Scheme, [], [], 80, [], [], []).

% Schemi speciali

% Valutare se mettere porta 80 oppure []

parse_afterScheme(Scheme, PostScheme, URI) :-
    Scheme = mailto,
    compulsory_userinfo(PostScheme, Userinfo, [64 | PostUserinfo]),
    host(PostUserinfo, Host, []),
    URI = uri(Scheme, Userinfo, Host, 80, [], [], []).

parse_afterScheme(Scheme, PostScheme, URI) :-
    Scheme = mailto,
    compulsory_userinfo(PostScheme, Userinfo, []),
    URI = uri(Scheme, Userinfo, [], 80, [], [], []).

parse_afterScheme(Scheme, PostScheme, URI) :-
    Scheme = news,
    host(PostScheme, Host, []),
    URI = uri(Scheme, [], Host, 80, [], [], []).

parse_afterScheme(Scheme, PostScheme, URI) :-
    Scheme = tel,
    tel_fax(Scheme, PostScheme, URI).

parse_afterScheme(Scheme, PostScheme, URI) :-
    Scheme = fax,
    tel_fax(Scheme, PostScheme, URI).

parse_afterScheme(Scheme, PostScheme, URI) :-
    Scheme = zos,
    PostScheme \= [],
    authority(PostScheme, Userinfo, Host, Port, PostAuthority),
    path_zos(PostAuthority, Path, PostPath),
    query(PostPath, Query, PostQuery),
    fragment(PostQuery, Fragment, PostFragment),
    PostFragment = [],
    URI = uri(Scheme, Userinfo, Host, Port, Path, Query, Fragment).

% Solo authority e schema

parse_afterScheme(Scheme, PostScheme, URI) :-
    Scheme \= mailto,
    Scheme \= news,
    Scheme \= tel,
    Scheme \= fax,
    Scheme \= zos,
    PostScheme \= [],
    authority(PostScheme, Userinfo, Host, Port, []),
    URI = uri(Scheme, Userinfo, Host, Port, [], [], []).

%   Parse per schema generico

parse_afterScheme(Scheme, PostScheme, URI) :-
    Scheme \= mailto,
    Scheme \= news,
    Scheme \= tel,
    Scheme \= fax,
    Scheme \= zos,
    authority(PostScheme, Userinfo, Host, Port, PostAuthority), 
    PostAuthority \= [],
    path(PostAuthority, Path, PostPath),
    query(PostPath, Query, PostQuery),
    fragment(PostQuery, Fragment, PostFragment),
    PostFragment = [],
    URI = uri(Scheme, Userinfo, Host, Port, Path, Query, Fragment).

tel_fax(Scheme, PostScheme, URI) :-
    compulsory_userinfo(PostScheme, Userinfo, []),
    URI = uri(Scheme, Userinfo, [], 80, [], [], []).

% authority ma niente dopo

authority([S1, S2 | AuthorityCodes], Userinfo, Host, Port, []) :-
    S1 = 47,
    S2 = 47,
    userinfo(AuthorityCodes, Userinfo, PostUserinfo),
    host(PostUserinfo, Host, PostHost),
    port(PostHost, Port, []).

% authority presente e cose dopo
authority([S1, S2 | AuthorityCodes], Userinfo, Host, Port, [47 | PostAuthority]) :-
    S1 = 47,
    S2 = 47,
    userinfo(AuthorityCodes, Userinfo, PostUserinfo),
    host(PostUserinfo, Host, PostHost),
    port(PostHost, Port, [47 | PostAuthority]).

% Senza Authority
authority(AuthorityCodes, Userinfo, Host, Port, AuthorityCodes) :-
    Userinfo = [],
    Host = [],
    Port = 80.

userinfo(AuthorityCodes, [], AuthorityCodes).

userinfo(AuthorityCodes, Userinfo, PostUserinfo) :-
    append(UserinfoCodes, [64 | PostUserinfo], AuthorityCodes), % 64 @
    atom_codes(Userinfo, UserinfoCodes),
    identificatore(UserinfoCodes).

compulsory_userinfo(AuthorityCodes, Userinfo, PostUserinfo) :-
    append(UserinfoCodes, PostUserinfo, AuthorityCodes),
    atom_codes(Userinfo, UserinfoCodes),
    identificatore(UserinfoCodes).

host(PostUserinfo, Host, PostHost) :-
    domain_name(PostUserinfo, Host, PostHost).

host(PostUserinfo, Host, PostHost) :-
    %Aggiungere controllo between
    % Come da specifica NNN.NNN.NNN.NNN
    append(HostCode, PostHost, PostUserinfo),
    ip(PostUserinfo, _, [46 | Rest1]),
    ip(Rest1, _, [46 | Rest2]),
    ip(Rest2, _, [46 | Rest3]),
    ip(Rest3, _, PostHost),
    atom_codes(Host, HostCode).
    /*
    HostCode = [A1, A2, A3, 46, B1, B2, B3, 46, C1, C2, C3, 46, D1, D2, D3],
    append(HostCode, PostHost, PostUserinfo),
    atom_codes(Host, HostCode).*/

ip([A | PostUserinfo], [A], PostUserinfo) :-
    digit([A]),
    number_codes(Number, [A]),
    between(0, 255, Number).

ip([A, B | PostUserinfo], [A, B], PostUserinfo) :-
    digit([A, B]),
    number_codes(Number, [A, B]),
    between(0, 255, Number).

ip([A, B, C | PostUserinfo], [A, B, C], PostUserinfo) :-
    digit([A, B, C]),
    number_codes(Number, [A, B, C]),
    between(0, 255, Number).
    


domain_name(PostUserinfo, Host, PostHost) :-
    append([A | HostCodes], PostHost, PostUserinfo),
    identificatore_host(A),
    HostCodes \= [],
    % \+ member(46, Post),
    split_segments([A | HostCodes], Segments),
    validate_segments(Segments),
    atom_codes(Host, [A | HostCodes]).

domain_name(PostUserinfo, Host, PostHost) :-
    append([A | HostCodes], PostHost, PostUserinfo),
    HostCodes = [], 
    identificatore_host(A),
    % \+ member(46, Post),
    atom_codes(Host, [A | HostCodes]).

% Divide una lista di codici in segmenti separati da '.'
split_segments([], [[]]).
split_segments([46 | Rest], [[] | Segments]) :- % 46 = '.'
    split_segments(Rest, Segments).
split_segments([Code | Rest], [[Code | Segment] | Segments]) :-
    split_segments(Rest, [Segment | Segments]).

validate_segments([]). 
validate_segments([[A |Segment] | Rest]) :-
    [A |Segment] \= [],
    identificatore_host(A),
    identificatore_v2([A |Segment]),
    validate_segments(Rest).       

port(PostHost, 80, PostHost).

port([C1 | PostHost], Port, PostAuthority) :-
    C1 = 58, % 58 :
    append(PortCodes, PostAuthority, PostHost),
    digit(PortCodes), 
    number_codes(Port, PortCodes).

path([47 | PostAuthority], [], PostAuthority).

path(PostAuthority, [], PostAuthority).

path([C1 | PostAuthority], Path, PostPath) :-
    C1 = 47,
    path_name(PostAuthority, Path, PostPath).

path([C1 | PostAuthority], Path, PostPath) :-
    C1 \= 47,
    path_name([C1 | PostAuthority], Path, PostPath).

%domain_name riscritto

path_name(PostAuthority, Path, PostPath) :-
    append(PathCodes, PostPath, PostAuthority),
    % \+ member(47, Post),
    split_path_segments(PathCodes, Segments),
    validate_path_segments(Segments),
    atom_codes(Path, PathCodes).

% Divide una lista di codici in segmenti separati da '/'

split_path_segments([], [[]]).
split_path_segments([47 | Rest], [[] | Segments]) :- % 47 = '/'
    split_path_segments(Rest, Segments).
split_path_segments([Code | Rest], [[Code | Segment] | Segments]) :-
    split_path_segments(Rest, [Segment | Segments]).

validate_path_segments([]).
validate_path_segments([Segment | Rest]) :-
    Segment \= [],
    identificatore(Segment),
    validate_path_segments(Rest).

query(PostPath, [], PostPath).

query([63 | PostPath], Query, PostQuery) :- % 63 ?
    append(QueryCodes, PostQuery, PostPath),
    identificatore(QueryCodes),
    atom_codes(Query, QueryCodes).

fragment(PostQuery, [], PostQuery).

fragment([35 | PostQuery], Fragment, PostFragment) :- % 35 #
    append(FragmentCodes, PostFragment, PostQuery),
    identificatore(FragmentCodes),
    atom_codes(Fragment, FragmentCodes).

path_zos([47 | PostAuthority], [], PostAuthority).

path_zos(PostAuthority, [], PostAuthority).

path_zos([C1 | PostAuthority], Path, PostPath) :-
    C1 = 47,
    append(PathCodes, PostPath, PostAuthority),
    length(PathCodes, Length44),
    Length44 =< 44,
    id44(PathCodes),
    atom_codes(Path, PathCodes).

path_zos([C1 | PostAuthority], Path, PostPath) :-
    C1 = 47,
    append(PartialPathCodes, [41 | PostPath], PostAuthority),
    append(Id44Codes, [40 | Id8Codes], PartialPathCodes),
    length(Id44Codes, Length44),
    length(Id8Codes, Length8),
    Length44 =< 44,
    Length8 =< 8,
    id44(Id44Codes),
    id8(Id8Codes),
    append(PartialPathCodes, [41], PathCodes),
    atom_codes(Path, PathCodes).

path_zos([C1 | PostAuthority], Path, PostPath) :-
    C1 \= 47,
    append(PathCodes, PostPath, [C1 | PostAuthority]),
    length(PathCodes, Length44),
    Length44 =< 44,
    id44(PathCodes),
    atom_codes(Path, PathCodes).

% iniziare con carattere alfabetico non alfanumerico
path_zos([C1 | PostAuthority], Path, PostPath) :-
    C1 \= 47,
    append(PartialPathCodes, [41 | PostPath], [C1 | PostAuthority]),
    append(Id44Codes, [40 | Id8Codes], PartialPathCodes),
    length(Id44Codes, Length44),
    length(Id8Codes, Length8),
    Length44 =< 44,
    Length8 =< 8,
    id44(Id44Codes),
    id8(Id8Codes),
    append(PartialPathCodes, [41], PathCodes),
    atom_codes(Path, PathCodes).

digit([Digit | []]) :-
    code_type(Digit, digit).

digit([Digit | Digits]) :-
    code_type(Digit, digit),
    digit(Digits).

identificatore_host(Char) :-
    code_type(Char, alpha).

identificatore_v2([Char | []]) :-
    code_type(Char, alnum).

identificatore_v2([Char | Chars]) :-
    code_type(Char, alnum),
    identificatore_v2(Chars).

identificatore([Char | []]) :-
    character(Char).

identificatore([Char | Chars]) :-
    character(Char),
    identificatore(Chars).

character(Char) :-
    code_type(Char, csym).

character(Char) :-
    Char = 61. % =

character(Char) :-
    Char = 43. % +

character(Char) :-
    Char = 45. % -

id44([Char | []]) :-
    Char \= 46,
    code_type(Char, alnum). 

id44([Char | Chars]) :-
    code_type(Char, alnum),
    id44(Chars).

id44([Char | Chars]) :-
    Char = 46,
    id44(Chars).

id8([Char | []]) :-
    code_type(Char, alnum). 

id8([Char | Chars]) :-
    code_type(Char, alnum),
    id8(Chars).