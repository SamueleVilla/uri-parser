:- begin_tests(urilib).

% Include the file with your implementation.
:- consult("urilib-parse.pl").

test(http_ip_simple) :-
    urilib_parse("http://22.2.2.240",
                 uri(http, [], '22.2.2.240', 80, [], [], [])).

test(http_ip_invalid) :-
    (urilib_parse("http://256.256.256.240",
                 _) -> false ; true).

test(http_zero_ip) :-
    urilib_parse("http://00.0.0.0",
                 uri(http, [], '00.0.0.0', 80, [], [], [])).

test(http_example_com) :-
    urilib_parse("http://example.com",
                 uri(http, [], 'example.com', 80, [], [], [])).

test(http_full_uri) :-
    (urilib_parse("https://user:pass@example.com:443/path/to/resource?query#fragment",
                 uri(https, user:pass, 'example.com', 443, 'path/to/resource', query, fragment)) -> false ; true).

test(http_no_password) :-
    urilib_parse("https://user@example.com:443/path/to/resource?query#fragment",
                 uri(https, user, 'example.com', 443, 'path/to/resource', query, fragment)).

test(ftp_example_com) :-
    urilib_parse("ftp://ftp.example.com:21/dir/file",
                 uri(ftp, [], 'ftp.example.com', 21, 'dir/file', [], [])).

test(http_invalid_url) :-
    (urilib_parse("http:/example.com",
                 uri(http, [], 'example.com', 80, [], [], [])) -> false ; true).

test(http_no_scheme) :-
    (urilib_parse("http//example.com",
                 uri(http, [], 'example.com', 80, [], [], [])) -> false ; true).

test(mailto_user_example_com) :-
    urilib_parse("mailto:user@example.com",
                 uri(mailto, user, 'example.com', 80, [], [], [])).

test(mailto_user) :-
    (urilib_parse("mailto:user@",
                    _) -> false ; true).

test(mailto_user) :-
    urilib_parse("mailto:user",
                 uri(mailto, user, [], 80, [], [], [])).

test(news_example_com) :-
    urilib_parse("news:example.com",
                 uri(news, [], 'example.com', 80, [], [], [])).

test(news_with_double_slash) :-
    (urilib_parse("news://example.com",
                 uri(news, [], 'example.com', 80, [], [], [])) -> false ; true).

test(tel_number) :-
    urilib_parse("tel:+123456789",
                 uri(tel, '+123456789', [], 80, [], [], [])).

test(fax_number) :-
    urilib_parse("fax:12345",
                 uri(fax, '12345', [], 80, [], [], [])).

test(tel_scheme_empty) :-
    (urilib_parse("tel:",
                    _) -> false ; true).

test(tel_scheme_with_slash) :-
    (urilib_parse("tel:/",
                 uri(tel, [], [], 80, [], [], [])) -> false ; true).

test(zos_scheme) :-
    urilib_parse("zos://host.id/path.name(member)",
                 uri(zos, [], 'host.id', 80, 'path.name(member)', [], [])).

test(zos_scheme_no_member) :-
    urilib_parse("zos://host.id/path.name",
                 uri(zos, [], 'host.id', 80, 'path.name', [], [])).

test(zos_scheme_extra_member) :-
    (urilib_parse("zos://host.id/path.name(member.extra)",
                 uri(zos, [], 'host.id', 80, 'path.name(member.extra)', [], [])) -> false ; true).

test(zos_scheme_incomplete) :-
    (urilib_parse("zos://host.id/path.name(",
                 uri(zos, [], 'host.id', 80, 'path.name(', [], [])) -> false ; true).

test(http_ip_partial) :-
    (urilib_parse("http://192.168.1",
                 uri(http, [], '192.168.1', 80, [], [], [])) -> false ; true).

test(http_with_port) :-
    urilib_parse("http://example.com:8080",
                 uri(http, [], 'example.com', 8080, [], [], [])).

test(http_invalid_port) :-
    (urilib_parse("http://example.com:abc",
                 uri(http, [], 'example.com', 80, [], [], [])) -> false ; true).

test(http_invalid_port_negative) :-
    (urilib_parse("http://example.com:-1",
                 uri(http, [], 'example.com', 80, [], [], [])) -> false ; true).

test(http_path_resource) :-
    urilib_parse("http://example.com/path/to/resource",
                 uri(http, [], 'example.com', 80, 'path/to/resource', [], [])).

test(http_path_with_query) :-
    urilib_parse("http://example.com/path?query=value#frag",
                 uri(http, [], 'example.com', 80, path, 'query=value', frag)).

test(http_path_with_double_slash) :-
    (urilib_parse("http://example.com/path//to",
                 uri(http, [], 'example.com', 80, 'path//to', [], [])) -> false ; true).

test(http_path_with_empty_query) :-
    (urilib_parse("http://example.com/path?#",
                 uri(http, [], 'example.com', 80, 'path', [], [])) -> false ; true).

test(http_invalid_small_uri) :-
    urilib_parse("http://e",
                 uri(http, [], 'e', 80, [], [], [])).

test(http_invalid_ip) :-
    (urilib_parse("http://1",
                 uri(http, [], '1', 80, [], [], [])) -> false ; true).

test(http_invalid_host) :-
    (urilib_parse("http://e.1.5.e",
                 uri(http, [], 'e.1.5.e', 80, [], [], [])) -> false ; true).

test(http_trailing_slash) :-
    urilib_parse("http://abc/",
                 uri(http, [], 'abc', 80, [], [], [])).

test(http_with_query) :-
    urilib_parse("http://abc/?q",
                 uri(http, [], abc, 80, [], q, [])).

test(http_with_query_empty) :-
    (urilib_parse("http://abc/?",
                 uri(http, [], 'abc', 80, '', [], [])) -> false ; true).

test(path_scheme) :-
    urilib_parse("http:path",
                 uri(http, [], [], 80, path, [], [])).

test(scheme_only) :-
    urilib_parse("ftp:",
                 uri(ftp, [], [], 80, [], [], [])).

test(scheme_no_colon) :-
    (urilib_parse("ftp",
                 uri(ftp, [], '', 80, [], [], [])) -> false ; true).

test(https_with_dot) :-
    (urilib_parse("https://pippo.",
                 uri(https, [], 'pippo.', 80, [], [], [])) -> false ; true).

test(http_special_characters) :-
    urilib_parse("http://example.com/pa+_th?qu-ery#fragme=nt",
                 uri(http, [], 'example.com', 80, 'pa+_th', 'qu-ery', 'fragme=nt')).

:- end_tests(urilib).
