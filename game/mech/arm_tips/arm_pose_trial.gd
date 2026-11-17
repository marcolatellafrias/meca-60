class_name ArmPoseTrial
extends Resource

## LO ELEGIDO EN EL PANEL DE POSES PARA PROBAR (ArmPosesPanel; ver ArmPoseIdeas): los números de las hojas. No se
## guarda: es temporal. Los nombres, los de ArmPoseIdeas (sin comas ni dos puntos: en `@export_enum` separan).

static var current := ArmPoseTrial.new()

@export_enum("1 hoy al costado abajo", "2 guardia de boxeo", "3 guardia baja", "4 adelante y afuera",
	"5 abajo y adelante", "6 alto y afuera", "7 cruzado adelante del vidrio", "8 estirado al frente") var fist_rest := 0
@export_enum("1 hoy al frente estirado", "2 estirado apuntando abajo", "3 estirado abajo y adentro",
	"4 doblado a la cadera", "5 doblado al frente", "6 estirado hacia afuera", "7 doblado al hombro",
	"8 medio doblado afuera y abajo", "L1 codo pegado cañón al frente", "L2 codo de siempre",
	"L3 cruzando hacia adentro", "L4 alta a la altura del pecho", "L5 baja inclinado abajo",
	"L6 codo atrás pegado a la panza", "L7 adentro y alta", "L8 cañón un poco afuera") var cannon_rest := 0
@export_enum("1 hoy el directo", "2 mazazo de arriba", "3 barrido de costado") var strike := 0
