# Libreria Parser URI

Libreria Julia per l'analisi di URI con supporto per schemi come mailto, news, tel, fax, e percorsi z/OS. Offre parsing completo, gestione errori robusta e mappatura di porte.

## Caratteristiche

- Parsing URI completo per schemi generici e specifici.
- Gestione errori con messaggi descrittivi.
- Validazione dei componenti URI.

## Installazione

Aggiungi il file nel progetto Julia e importa con:

```julia
include("urilib_parse.jl")
```

## Utilizzo

### Parsing e Visualizzazione

```julia
uri = urilib_parse("http://esempio.com:8080/percorso?query#frammento")
urilib_display(uri)
```

### Accesso ai Componenti

Estrai e visualizza i componenti individuali dell'URI:

```julia
schema = urilib_scheme(uri)
host = urilib_host(uri)
```

### Porte e Errori

La libreria include mappature porte predefinite e gestisce errori con precisione.

## Limitazioni

Non supporta IPv6 e parsing nidificato. Limitato a percorsi z/OS ID44(ID8).

## Autori

- Bertoli Michelangelo
- Villa Samuele
- Sorrentino Raoul
