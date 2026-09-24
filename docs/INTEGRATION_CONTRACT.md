# Contrato de integración — UKHUPACHA

Godot 4.7.2, GDScript tipado, viewport lógico 640×360. Responsable: Kevin.
Este contrato fija las firmas finales para Jhon, Gian y Nayeli; no afirma que
el Player/enemigos actuales ya las implementen.

## Entrada

| Acción | Tecla |
| --- | --- |
| arriba / abajo / izquierda / derecha | W / S / A / D |
| correr | Shift |
| atacar | LMB |
| defender | RMB |
| esquivar | Space |
| interactuar | E |
| equipo | Tab |
| pausa | Esc |

Deuda temporal: Space duplica `saltar/esquivar`, LMB duplica
`"cuerpo a cuerpo"/atacar`, RMB duplica `disparar/defender`. Jhon migra los
consumidores antes de retirar los tres alias. Nunca ejecutar ambos efectos por
pulsación. Nivel 1 no incorpora proyectiles por conservar `disparar`.

## Física

L y M designan números de capa, no valores decimales del bitmask.

| Objeto | Capa L | Máscara M | Bits L / M |
| --- | --- | --- | --- |
| Mundo/puerta cerrada | 1 mundo | 2,3 | 1 / 6 |
| Player body | 2 cuerpo_player | 1,3 | 2 / 5 |
| Enemy body | 3 cuerpo_enemigo | 1,2,3 | 4 / 7 |
| Player Hurtbox | 4 hurtbox_player | ninguna (pasiva) | 8 / 0 |
| Enemy Hurtbox | 5 hurtbox_enemigo | ninguna (pasiva) | 16 / 0 |
| Player AttackArea | 6 ataque_player | 5 | 32 / 16 |
| Enemy AttackArea | 7 ataque_enemigo | 4 | 64 / 8 |
| Interacción | 8 interaccion | ninguna (consulta de distancia) | 128 / 0 |

Interacción: un sistema por sala/contenedor activo; encuentra al Player por
grupo `player`. Selecciona solo el Interactable disponible más cercano a ≤24 px
y dentro de su radio exportado. Raycast contra mundo (bit 1) impide atravesar
paredes y puertas. Un disparo por pulsación de E. Las distancias parten de los
orígenes de los nodos, nunca de índices de hijos.

## Player (Jhon)

```gdscript
signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal equipment_changed(weapon_id: StringName, shield: bool, tier: int)
signal player_died()

func receive_hit(hit: Dictionary) -> StringName
func equip_weapon(weapon_id: StringName) -> void
func equip_shield() -> void
func set_input_enabled(enabled: bool) -> void
func get_hud_state() -> Dictionary
```

`receive_hit` devuelve `&"PARRIED"`, `&"BLOCKED"`, `&"DODGED"` o `&"DAMAGED"`.
`get_hud_state()` devuelve `{health: float, max_health: float, stamina: float,
max_stamina: float, weapon_id: StringName, shield: bool, tier: int}`. Conectar
señales no emite valores iniciales: leer esta consulta al montar HUD.
IDs de equipo: `&"sword"`, `&"axe"`, `&"none"`; escudo independiente.
Requisito: Player pertenece al grupo `player`.

Puente de bloqueo para consumidores externos: exponer `input_enabled: bool`,
actualizado por `set_input_enabled`, o `is_input_enabled() -> bool`.
El sistema acepta ambos (prioriza la consulta); si falta este puente bloquea
interacción hasta migración. No puede inferir el estado interno de un método
setter. Pausa del árbol también bloquea interacción. Pickups comprueban que
exista el método de equipo antes de consumir el objeto o modificar flags.

## Combate (Jhon/Gian)

```gdscript
# Esquema del paquete, no un literal GDScript de valores:
# hit: Dictionary = {attack_id:int, source:Node, damage:float,
#     parryable:bool, unblockable:bool, direction:Vector2}
signal enemy_died(enemy: Node)
signal enemy_alerted(enemy: Node)

func take_hit(amount: float, source: Node, was_critical: bool = false) -> void
func stagger(seconds: float) -> void
```

Un `attack_id` nuevo por swing, único entre atacantes durante la sesión;
un daño por objetivo y `attack_id`, aunque se solapen varios frames.
`enemy_died` se emite una sola vez. Muerte/interrupción cancela ataques pendientes.

Parry erróneo por timing y golpe durante recuperación de 0,30 s: daño ×1,25.
Timing correcto: una tirada por `attack_id`, 95 % éxito (0 daño, enemigo
aturdido 1 s), 5 % fallo fortuito (daño normal, sin stagger). La probabilidad
se exporta y ambos resultados se pueden forzar en debug. Player decide la
tirada; el atacante aplica `stagger(1.0)` una sola vez si recibe `PARRIED`.
El siguiente golpe sobre ese enemigo aturdido antes de 1 s consume crítico
×2, sin RNG. Rojo (`unblockable`) ignora guardia/parry: exige esquiva.

## Progreso y muerte (Kevin)

Solo dos autoloads de juego: `Level1Progress` y `MusicDirector`. El helper MCP
es exclusivamente local y nunca se versiona. MusicDirector queda mínimo en
estos bloques; audio sintético/propio se implementa después.

Flags booleanos: `record_a`, `record_b`, `record_c`, `puzzle_solved`,
`has_sword`, `has_axe`, `has_shield`, `memory_restored`, `elite_defeated`,
`demo_complete`. API final de Level1Progress:

```gdscript
signal flag_changed(flag: StringName, value: bool)
signal progress_reset()
signal door_state_changed(door_id: StringName, opened: bool)
func get_flag(flag: StringName) -> bool
func set_flag(flag: StringName, value: bool = true) -> bool
func reset() -> void
func all_records_read() -> bool
func is_door_open(door_id: StringName) -> bool
```

Leer registros en cualquier orden no resuelve automáticamente el puzzle:
tres registros → respuesta correcta del terminal → `puzzle_solved` → `door_1`.
`memory_restored` abre `door_4`; `elite_defeated` habilita `rift`.
Los cambios emiten señales solo si cambia el valor; Nueva partida llama
explícitamente `reset()`, que también restaura puertas/pickups y limpia selección
del puzzle. No resetear por entrar o salir de una sala.

Decisión única de Kevin, modificable: morir reinicia sala actual con HP/stamina
completos, conserva equipo y flags; ofrecer Reintentar/Menú. No llama `reset()`.
El flujo de muerte/menús queda para UI/integración, fuera de estos dos bloques.

## Marcadores (Nayeli)

Por nombre o propiedad exportada, jamás índice de hijo:
`PlayerSpawn`, `Exit`, `RoomCameraBounds`, `RecordA`, `RecordB`, `RecordC`,
`PuzzleTerminal`, `SwordPickup`, `AxePickup`, `ShieldPickup`, `MemoryPoint`,
`EnemySpawnBasic`, `EnemySpawnHeavy`, `EnemySpawnShield`, `EnemySpawnElite`,
`MusicRegionA`, `MusicRegionB`, `MusicRegionC`.

## Deuda, límites y orden de merge

1. `chore/integration-contracts`: contrato, capas, inputs existentes y dos
   scripts mínimos. Base inicial `497fa22`; sin dependencia de otra rama nueva.
2. `feat/level-interactions` parte del commit final de la anterior y depende
   explícitamente de ella. Laboratorio usa Player mínimo propio.
3. Jhon migra visual/combate, grupo e input gate; Gian base/variantes/élite;
   Nayeli blockout/props y contenido cultural. Sus pruebas deben preceder consumo.
4. UI/audio e integración completa después, fuera del alcance actual.

Los README sugieren ramas desde main; esta entrega aplica la instrucción de
Kevin de ramas apiladas. El permiso futuro del README para editar niveles o
Playground no aplica aquí: esos archivos están prohibidos en estos bloques.
La API antigua de Player todavía no garantiza equipo, salud ni bloqueo.

Contenido cultural pendiente: `TODO_CULTURAL` hasta fuentes/textos de Nayeli.
Licencias de los PNG seleccionados pendientes: `TODO_LICENSE`; no se inventan
autores/permisos. Los 37 PNG y la documentación Hybrid v2 preexistentes quedan
sin incorporar en estos bloques; las vistas funcionales usan geometría propia
y texto runtime. El acabado completo Hybrid v2 pertenece a UI posterior.
