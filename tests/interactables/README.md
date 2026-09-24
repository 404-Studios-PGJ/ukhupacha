# Laboratorio de interacciones — bloques 1 y 2

Dependencia: `feat/level-interactions` parte de `chore/integration-contracts`
en `ee37400`; fusionar bloque 1 antes del bloque 2. El bloque 1 contiene
`a305dd5` (contrato y servicios mínimos) y `ee37400` (configuración).

## Reproducir

Abrir `res://tests/interactables/puzzle_lab.tscn` y ejecutar F6.
WASD mueve al doble local; E elige solo el objeto próximo visible.
Botón **Pruebas** ejecuta `await run_checks()`: 29 casos, resultados
en `results`, resumen en pantalla y JSON `PUZZLE_LAB` en Output.
Botón **Reset** equivale a Nueva partida del laboratorio; limpia equipo del
doble, flags, puertas y diálogos. El reset al iniciar esta escena es exclusivo
del laboratorio, no un comportamiento de los sistemas de producción.

Recoger A/B/C en cualquier orden; reabrirlos permite releer.
Terminal: releer evidencias, probar respuesta incorrecta (pista), reintentar
con contradicción. La puerta 1 se abre solo al acertar con tres registros.
Memoria muestra tres líneas TODO_CULTURAL y requiere Registrar y proteger.
Puertas usan `door_1`, `door_4`, `rift`; la fisura aquí verifica únicamente
el desbloqueo físico por élite, no el flujo de final de demo.
Espada/hacha/escudo comprueban la API antes de consumir el pickup.

Integración: añadir una sola instancia de `systems/interaction_system.gd`
al contenedor activo, Player en grupo `player` y puente de input del contrato.
Instanciar las escenas bajo `interactables/`; configurar record_id,
equipment_id, door_id y posiciones por nombres/propiedades.
Flags se consultan/modifican por get_flag/set_flag; no editar el diccionario interno.

## Verificación realizada mediante Godot MCP

Godot `4.7.2-stable (official)`, viewport runtime `640×360`, 24/09/2026.

- Se abrieron las nueve escenas existentes al terminar: Player, Playground,
  cinco escenas de interactables, test_player y puzzle_lab.
- Playground ejecutado antes y después: movimiento de (302,171) a (318,171)
  y pulsación de ataque legado; cero errores/advertencias.
- puzzle_lab: **29/29** comprobaciones aprobadas, incluyendo pulsación mantenida,
  E dos veces, único más cercano, fuera de 24 px, pared, input desactivado,
  lectura C/A/B, relectura, señales sin duplicación, respuesta incompleta,
  error/pista/reintento, collider desactivado y cruce real del cuerpo,
  tres pickups, memoria/élite, flag final, puerta creada con progreso previo,
  reset completo y modal, Player sin API.
- Clics reales mediante input_mouse MCP: relectura B muestra su clasificación,
  respuesta errónea mantiene puerta cerrada y muestra pista, respuesta correcta
  abre puerta 1, Registrar y proteger abre puerta 4.
- Capturas MCP inspeccionadas a 640×360: laboratorio, terminal y memoria;
  texto y botones caben en pantalla.
- Logs finales de editor y juego: **cero errores y cero advertencias**.
  Fue necesario reiniciar el editor para reconocer los autoloads añadidos
  desde disco; los errores transitorios de caché no persisten tras reinicio.
- project.godot conserva localmente helper/plugin MCP; su único commit pasó
  por el script autorizado y `git show HEAD:project.godot | grep -c godot_ai`
  devolvió 0 después del commit.

No verificado: integración con Player final de Jhon, enemigos de Gian y salas
de Nayeli; aún no implementan/contienen aquí los consumidores finales. No se
implementan combate, muerte/Retry/Menu, audio narrativo ni export en estos bloques.
La validación del ataque legado es un smoke test, no una prueba de combate.

## Decisiones y pendientes

Se conserva la regla de muerte de Kevin en el contrato. Interacción falla
cerrada si Player no expone input_enabled o is_input_enabled(); pickups
conservan el objeto si falta equip_weapon/equip_shield. Empates de distancia
usan orden estable del árbol. No se agrega un tercer autoload de juego.
UI funcional con geometría propia y texto runtime; acabado Hybrid v2 posterior.
No se requieren assets externos para el laboratorio.
TODO_CULTURAL: fuentes y textos definitivos de Nayeli.
TODO_LICENSE: licencias de los 37 PNG preexistentes, fuera de estos commits.

Conflictos README: prevalece la instrucción actual de ramas apiladas sobre
la sugerencia de partir ambas de main. Permisos futuros del README sobre
niveles/Playground no aplican a estos bloques. No se tocaron esos archivos.
README, assets/ui y docs/ui preexistentes se conservan sin incorporarlos.

## Archivos por rama

Listado equivalente a `git diff --name-only 497fa22...chore/integration-contracts`:

```text
audio/music_director.gd
audio/music_director.gd.uid
docs/INTEGRATION_CONTRACT.md
project.godot
systems/level1_progress.gd
systems/level1_progress.gd.uid
```

Listado equivalente a `git diff --name-only chore/integration-contracts...feat/level-interactions`:

```text
interactables/access_terminal.gd
interactables/access_terminal.gd.uid
interactables/access_terminal.tscn
interactables/door_gate.gd
interactables/door_gate.gd.uid
interactables/door_gate.tscn
interactables/equipment_pickup.gd
interactables/equipment_pickup.gd.uid
interactables/equipment_pickup.tscn
interactables/interactable.gd
interactables/interactable.gd.uid
interactables/memory_point.gd
interactables/memory_point.gd.uid
interactables/memory_point.tscn
interactables/record_terminal.gd
interactables/record_terminal.gd.uid
interactables/record_terminal.tscn
systems/interaction_system.gd
systems/interaction_system.gd.uid
systems/level1_progress.gd
tests/interactables/README.md
tests/interactables/puzzle_lab.gd
tests/interactables/puzzle_lab.gd.uid
tests/interactables/puzzle_lab.tscn
tests/interactables/test_player.gd
tests/interactables/test_player.gd.uid
tests/interactables/test_player.tscn
ui/interaction_dialog.gd
ui/interaction_dialog.gd.uid
```
