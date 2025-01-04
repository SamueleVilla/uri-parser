### -*- Mode: Julia -*-
### 914194 Villa Samuele
### 909506 Sorrentino Raoul

struct URI
  scheme :: String
  userInfo :: Union{String, Nothing}
  host :: Union{String, Nothing}
  port :: Union{Int, Nothing} = "80"
  path :: Union{String, Nothing}
  query :: Union{String, Nothing}
  fragment :: Union{String, Nothing}
end


function urilib_parse(uri :: AbstractString) :: URI
  # TODO: implementare la funzione
end

# uri_parse.jl ends here.

