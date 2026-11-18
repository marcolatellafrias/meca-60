class_name BossMode
extends Resource

## UN MODO DE UN JEFE (17/11/2026): un tramo de la pelea con otras reglas. LA IRA ES UN MODO MÁS; otro puede ser «vuela
## y tira bombas». El usuario: «el concepto de ira es un concepto muy estructurado… podría haber varios tipos de
## ciclos… un boss que se queda volando y tirando bombas del cielo… es un tipo de ciclo que no es ira y puede tener
## otras reglas». Un jefe tiene una lista de modos (sus perillas, una pestaña por modo en su panel); fuera de todos,
## está TRANQUILO. Cada poder dice en cuáles se usa (BossPower).
##   · CUÁNDO ENTRA: cada tanto tiempo tranquilo (`every`: un ciclo) o cuando su vida baja de una parte
##     (`below_health`: una fase, una sola vez). CUÁNTO DURA (`lasts`; 0, hasta el final).
##   · QUÉ CAMBIA: cuánto más rápido anda (`hurry`), si encadena ataques (`chain`), si los poderes usan sus variantes
##     fuertes (`strong`), a qué altura vuela (`fly_height`; 0, en el piso), a qué distancia se queda rodeando
##     (`keep_from`/`keep_to`; 0, lo de siempre) y cómo se ve (`look`: uno de los aspectos del cuerpo).
## La cabeza del jefe (BrawlerBrain) entra y sale de los modos mientras rodea, nunca en medio de un ataque.

## Si existe para este jefe.
@export var on := true
## Entra cada tanto tiempo tranquilo (s; 0, no por tiempo) o cuando su vida baja de esta parte (0 a 1; 0, no).
@export_range(0.0, 300.0, 1.0) var every := 40.0
@export_range(0.0, 1.0, 0.05) var below_health := 0.0
## Cuánto dura (s; 0, hasta el final de la pelea).
@export_range(0.0, 300.0, 1.0) var lasts := 18.0
## Cuánto más rápido anda y gira (veces).
@export_range(0.5, 3.0, 0.05) var hurry := 1.35
## Qué chance tiene de encadenar otro ataque al terminar uno (0 a 1).
@export_range(0.0, 1.0, 0.05) var chain := 0.6
## Los poderes usan sus variantes fuertes (más ondas, más piedras, rebota…).
@export var strong := true
## Vuela a esta altura (m; 0, en el piso).
@export_range(0.0, 80.0, 1.0) var fly_height := 0.0
## Rodeando, se queda entre estas distancias (m; 0, las de siempre).
@export_range(0.0, 200.0, 1.0) var keep_from := 0.0
@export_range(0.0, 200.0, 1.0) var keep_to := 0.0
## Cómo se ve mientras dura: uno de los aspectos que ofrece el cuerpo (BossPower.choices: «normal», «con ira»…).
@export var look := 1

## Su nombre (lo pone el jefe: «ira», «vuelo»).
var title := "modo"

const LABELS := {"on": "EXISTE", "every": "entra cada (s tranquilo; 0, no)", "below_health": "o con la vida bajo (parte; 0, no)",
	"lasts": "dura (s; 0, hasta el final)", "hurry": "más rápido (veces)", "chain": "encadena ataques (chance)",
	"strong": "variantes fuertes de los poderes", "fly_height": "vuela a (m; 0, en el piso)",
	"keep_from": "rodea desde (m; 0, lo de siempre)", "keep_to": "rodea hasta (m)", "look": "cómo se ve"}
