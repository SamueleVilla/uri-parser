### urilib_test.jl

using Test

include("urilib_parse.jl")

@testset "Test suite for urilib parser" begin

    @testset "Generic scheme syntax" begin
        uri = urilib_parse("http://example.com")
        @test urilib_scheme(uri) === "http"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == "example.com"
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === nothing
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        uri = urilib_parse(
            "https://user@example.com/path/to/resource?query#fragment")
        @test urilib_scheme(uri) === "https"
        @test urilib_userinfo(uri) === "user"
        @test urilib_host(uri) == "example.com"
        @test urilib_port(uri) == "443"
        @test urilib_path(uri) === "path/to/resource"
        @test urilib_query(uri) === "query"
        @test urilib_fragment(uri) === "fragment"

        uri = urilib_parse("ftp://ftp.example.com/dir/file")
        @test urilib_scheme(uri) === "ftp"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == "ftp.example.com"
        @test urilib_port(uri) == "21"
        @test urilib_path(uri) === "dir/file"
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing
        
        uri = urilib_parse(
            "http://user@example.com:8080/path/to/resource?query#fragment")
        @test urilib_scheme(uri) === "http"
        @test urilib_userinfo(uri) === "user"
        @test urilib_host(uri) == "example.com"
        @test urilib_port(uri) == "8080"
        @test urilib_path(uri) === "path/to/resource"
        @test urilib_query(uri) === "query"
        @test urilib_fragment(uri) === "fragment"

        uri = urilib_parse(
            "http://user@example.com:8080/pa+_th?qu-ery#fragme=nt")
        @test urilib_scheme(uri) === "http"
        @test urilib_userinfo(uri) === "user"
        @test urilib_host(uri) == "example.com"
        @test urilib_port(uri) == "8080"
        @test urilib_path(uri) === "pa+_th"
        @test urilib_query(uri) === "qu-ery"
        @test urilib_fragment(uri) === "fragme=nt"

        uri = urilib_parse(
            "http://example.com/path/to/resource")
        @test urilib_scheme(uri) === "http"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == "example.com"
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === "path/to/resource"
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        uri = urilib_parse(
            "http://example.com/path/to/resource?query=title")
        @test urilib_scheme(uri) === "http"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == "example.com"
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === "path/to/resource"
        @test urilib_query(uri) === "query=title"
        @test urilib_fragment(uri) === nothing

        uri = urilib_parse("http://192.168.1.1")
        @test urilib_scheme(uri) === "http"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == "192.168.1.1"
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === nothing
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        uri = urilib_parse("http://e")
        @test urilib_scheme(uri) === "http"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == "e"
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === nothing
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        uri = urilib_parse("http://abc")
        @test urilib_scheme(uri) === "http"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == "abc"
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === nothing
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        uri = urilib_parse("http://abc/?q")
        @test urilib_scheme(uri) === "http"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == "abc"
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === nothing
        @test urilib_query(uri) === "q"
        @test urilib_fragment(uri) === nothing

        uri = urilib_parse("http:path")
        @test urilib_scheme(uri) === "http"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == nothing
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === "path"
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        uri = urilib_parse("scheme:")
        @test urilib_scheme(uri) === "scheme"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == nothing
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === nothing
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        @test_throws ErrorException urilib_parse("scheme")
        @test_throws ErrorException urilib_parse("http?://example.com")
        @test_throws ErrorException urilib_parse(
            "https://user:pass@example.com:443/path/to/resource?query#fragment")

        @test_throws ErrorException urilib_parse("http://1")
        @test_throws ErrorException urilib_parse("http://e.1.5.e")
        @test_throws ErrorException urilib_parse("http://192.168.1")
        @test_throws ErrorException urilib_parse("http://256.256.256.256")
        @test_throws ErrorException urilib_parse("http://192.168.1.256")

        @test_throws ErrorException urilib_parse("http//example.com")
        @test_throws ErrorException urilib_parse("http//example.com.")
        @test_throws ErrorException urilib_parse("http://example.com:abc")
        @test_throws ErrorException urilib_parse("http://example.com:-1")

        @test_throws ErrorException urilib_parse("http://example.com/path//to")
        @test_throws ErrorException urilib_parse("http://example.com/path?#")
        @test_throws ErrorException urilib_parse("http://example.com/path?#")

        @test_throws ErrorException urilib_parse("http:/example.com")
    end

    @testset "Zos scheme syntax" begin
        uri = urilib_parse("zos://host.id/path.name(member)")
        @test urilib_scheme(uri) === "zos"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == "host.id"
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === "path.name(member)"
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        uri = urilib_parse("zos://host.id/path.name")
        @test urilib_scheme(uri) === "zos"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == "host.id"
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === "path.name"
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        @test_throws ErrorException urilib_parse(
            "zos://host.id/path.name(member.extra)")
        @test_throws ErrorException urilib_parse(
            "zos://host.id/path.name(")
    end

    @testset "Mailto scheme syntax" begin
        uri = urilib_parse("mailto:user")
        @test urilib_scheme(uri) === "mailto"
        @test urilib_userinfo(uri) === "user"
        @test urilib_host(uri) == nothing
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === nothing
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        uri = urilib_parse("mailto:user@example.com")
        @test urilib_scheme(uri) === "mailto"
        @test urilib_userinfo(uri) === "user"
        @test urilib_host(uri) == "example.com"
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === nothing
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        @test_throws ErrorException urilib_parse("mailto:")
        @test_throws ErrorException urilib_parse("mailto:user@")
        @test_throws ErrorException urilib_parse("mailto:user@example.com/api")
    end

    @testset "News scheme syntax" begin
        uri = urilib_parse("news:example.com")
        @test urilib_scheme(uri) === "news"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == "example.com"
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === nothing
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        uri = urilib_parse("news:127.0.0.1")
        @test urilib_scheme(uri) === "news"
        @test urilib_userinfo(uri) === nothing
        @test urilib_host(uri) == "127.0.0.1"
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === nothing
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing
        
        @test_throws ErrorException urilib_parse("news:")
        @test_throws ErrorException urilib_parse("news:example.com/api")
        @test_throws ErrorException urilib_parse("news://example.com")
    end

    @testset "Tel & Fax scheme syntax" begin
        uri = urilib_parse("tel:+123456789")
        @test urilib_scheme(uri) === "tel"
        @test urilib_userinfo(uri) === "+123456789"
        @test urilib_host(uri) == nothing
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === nothing
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing

        uri = urilib_parse("fax:12345")
        @test urilib_scheme(uri) === "fax"
        @test urilib_userinfo(uri) === "12345"
        @test urilib_host(uri) == nothing
        @test urilib_port(uri) == "80"
        @test urilib_path(uri) === nothing
        @test urilib_query(uri) === nothing
        @test urilib_fragment(uri) === nothing


        @test_throws ErrorException urilib_parse("tel:")
        @test_throws ErrorException urilib_parse("fax:")
        @test_throws ErrorException urilib_parse("tel:/")
        @test_throws ErrorException urilib_parse("fax:/")
        @test_throws ErrorException urilib_parse("fax:+123245656?")
    end
end

### urilib-test.jl ends here
