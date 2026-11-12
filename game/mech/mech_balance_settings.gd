class_name MechBalanceSettings
extends Resource

## LAS PERILLAS DEL EQUILIBRIO DE LA MECA DE EQUILIBRIO (ver MechDummy): una sola copia para todas (`current`), que el
## panel de su fila (BalancePanel, F1 en la fila Meca) arma leyendo estas propiedades —lo que se ve es lo que se toca—.
## Los números de arriba son los de los personajes de character-parametric (CharacterRigidBody3D), escalados a la meca;
## los de abajo, los dos agregados (el empuje y los pasos).

static var current := MechBalanceSettings.new()

@export_group("El empuje (agregado)")
## El golpe se suma a la VELOCIDAD de la inclinación (se ve el envión); apagado, a la inclinación de una, como allá.
@export var hit_pushes := true
## Cuánto empuja: la velocidad de la inclinación por cada unidad de golpe.
@export_range(0.5, 15.0, 0.1) var push_rate := 6.0

@export_group("Los pasos (agregado)")
## Pasada `step_at`, da un paso hacia donde se va y la inclinación baja.
@export var steps := true
@export_range(0.1, 0.84, 0.01) var step_at := 0.4
@export_range(0.5, 8.0, 0.1) var step_length := 3.5
@export_range(0.15, 1.5, 0.01) var step_time := 0.5
## La inclinación que saca un paso entero.
@export_range(0.0, 1.0, 0.01) var step_catch := 0.45

@export_group("El resorte (character-parametric)")
@export_range(1.0, 80.0, 0.5) var stiffness := 25.0
@export_range(0.1, 20.0, 0.05) var damping := 6.0
## La meca es grande: su resorte va más lento que el de una persona.
@export_range(0.05, 2.0, 0.01) var spring_scale := 0.35
@export_range(0.05, 2.0, 0.01) var damp_scale := 0.6
## Cuánto inclina cada m/s de golpe (con firmeza 1).
@export_range(0.02, 1.0, 0.01) var lean_per_ms := 0.3
## Dónde se cae.
@export_range(0.2, 1.0, 0.01) var fall_at := 0.85
## Lo que se ve inclinarse antes de caer, si se fue acumulando.
@export_range(0.0, 1.0, 0.01) var fall_warning := 0.15

@export_group("La firmeza, por lado")
## Más de 1, cuesta más voltearla por ahí.
@export_range(0.1, 3.0, 0.05) var stability_forward := 1.0
@export_range(0.1, 3.0, 0.05) var stability_backward := 0.8
@export_range(0.1, 3.0, 0.05) var stability_sideways := 0.7

@export_group("El cuerpo")
## Cuánto se inclina el torso con la inclinación en 1 (grados).
@export_range(2.0, 45.0, 1.0) var lean_angle := 20.0
## Cuánto frena sola, parada (m/s²): sus pies la sostienen.
@export_range(0.0, 20.0, 0.1) var brake := 4.0
## Al caer, cuánto más rápido salen las partes de arriba (como si girara sobre los pies).
@export_range(0.0, 3.0, 0.05) var topple := 1.0
@export_range(0.5, 10.0, 0.1) var down_time := 4.0
@export_range(0.3, 6.0, 0.1) var rise_time := 2.5
