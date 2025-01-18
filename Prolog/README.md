# Libreria Parser URI (Prolog)

Questa libreria Prolog permette l'analisi e la manipolazione di URI (Uniform Resource Identifier), offrendo supporto per vari schemi URI, come URI generici, mailto, news, e altri. Consente il parsing completo degli URI, gestione robusta con unificazione Prolog, e validazione completa dei componenti.

## Caratteristiche

Supporto completo per:

- Schema, Informazioni Utente, Host, Porta, Percorso, Query, Fragment

- Schemi speciali come mailto, news, tel, fax

- Percorsi specifici z/OS

## Installazione

```prolog
consult("urilib-parse.pl")
```

## Utilizzo

### Parsing e Visualizzazione

Effettua parsing e visualizzazione degli URI o utilizza schemi URI speciali tramite semplici comandi Prolog. Ad esempio:

?- urilib_parse("http://esempio.com", URI).
?- urilib_display(URI).

### Struttura e Validazioni

L'URI è rappresentato come un termine composto Prolog con componenti quali Scheme, Host, Path, ecc. La libreria implementa validazioni per nomi di dominio, formati di percorso, e controllo dei valori numerici delle porte.


## Limitazioni

Non supporta IPv6 e parsing nidificato. Limitato a percorsi z/OS ID44(ID8).

## Autori

 - Bertoli Michelangelo
 - Villa Samuele
 - Sorrentino Raoul