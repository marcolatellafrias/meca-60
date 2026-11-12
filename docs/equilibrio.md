# El equilibrio

Lo usan la meca de equilibrio (fila **Equilibrio**, `MechDummy`) y el [[cubo]]. Viene del sistema de los personajes de
character-parametric (`CharacterRigidBody3D`): una **línea de equilibrio** aparte del cuerpo.

- Un golpe —medido como el cambio de velocidad que el cuerpo no pidió, por encima de un ruido— **suma a la velocidad de
  la inclinación** (no la hace saltar: se ve el envión).
- Un **resorte** la devuelve a cero (*resorte que lo endereza*, *freno de la inclinación*).
- Pasado *se cae en*, se cae (ragdoll o física suelta).
- **Firmeza**: en los personajes, peso/60 × estabilidad; más firme, menos se inclina.

## La meca de equilibrio
Una copia de la [[meca]] (el mismo `MechBody`) que sólo se tambalea, se cae y se levanta. Agregados al sistema de allá:
**el golpe empuja** y **los pasos** (pasada cierta inclinación da un paso hacia donde se va). Perillas en
`MechBalanceSettings` (F1, `BalancePanel`). Test: `tests/balance_check.tscn`.
