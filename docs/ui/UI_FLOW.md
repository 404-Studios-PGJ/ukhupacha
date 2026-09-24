# UI runtime — bloque 3

Rama `feat/ui-flow`, dependiente de `feat/level-interactions@6635f5d`.
Commits separados para assets/ui, docs/ui y código UI con consumidores/tests.
No cambia run/main_scene, no añade autoloads ni modifica Player/enemigos/niveles.

## Montaje

Instanciar `ui/ui_flow.tscn` una sola vez en el contenedor de sesión.
Encuentra Player mediante grupo `player`; bind_player permite reenlazarlo.
HUD lee get_hud_state al inicio y conecta señales disponibles. Los métodos
y señales ausentes se guardan; no se presupone emisión al conectar.

El host conecta `restart_requested(reason: StringName)` antes de usar Nueva
partida/Reintentar. La UI cierra su modal, llama Level1Progress.reset y emite
la petición; el host restablece o reemplaza Player/sala síncronamente.
UIFlow vuelve a enlazar el Player del grupo y relee el estado para HUD.
Sin host, restart_session devuelve false y evita reset parcial. No hay una
ruta de nivel inventada: el laboratorio prueba este contrato; la integración
de las salas se realizará después.

Esc y Tab se procesan antes de navegación GUI para evitar que Tab solo mueva
el foco. Pausa/equipo guardan y restauran input, pausa previa y foco anterior.
Cambiar de pausa a controles mantiene el mismo bloqueo; no se reanuda el mundo.
El menú de equipo solo muestra puños y objetos descubiertos. Equipar llama al
Player y espera equipment_changed; no finge que una petición ya fue aplicada.
HUD y UIFlow rechazan instancias duplicadas.

## Arte y estructura

Un Theme: `ui/theme/ukhupacha_theme.tres`. Incluye StyleBoxTexture nueve parches,
StyleBoxFlat, variantes de tipografía y paleta. La fuente es el fallback
incorporado en Godot; fuente final pendiente. No hay overrides inline en UI.
`ui/ui_assets.gd` centraliza las rutas y enlaza las texturas al Theme único.
El shader ink convierte color de los packs a los tokens del Theme en runtime;
no modifica ningún PNG. Nearest y repeat disabled en las raíces.

Los .tscn son entradas de pantalla reutilizables; sus scripts construyen
Controls reales con nombres, foco y eventos. No son imágenes de mockup.
Menús comparten MenuScreen; HUD es CanvasLayer; EquipmentMenu y
PuzzleTerminalView mantienen sus propios modelos. Se usan Containers para
listas, anclas para raíces/HUD/pie y coordenadas lógicas 640×360 del diseño.
Las placas HUD, siluetas, diagrama Helix y relaciones son geometría runtime.
NinePatchRect se usa en el banner; StyleBoxTexture en paneles/botones.
TextureButton se usa en slots, TextureProgressBar en HP/stamina.

AccessTerminal monta PuzzleTerminalView: releer una tarjeta, relacionar A/B,
y vincular C con A o B después. Un orden incorrecto muestra pista; reintentar
no elimina evidencias. La lógica del terminal sigue validando los tres flags.
Los textos de cultura continúan TODO_CULTURAL; no se copió ficción cultural
del mockup. Controles explica el 5 % de riesgo residual del parry.

## Diferencias respecto a documentos anteriores

- La instrucción actual exige ramas apiladas, prevalece sobre README.
- Nueva partida y Retry resetean progreso/equipo, reemplazando la decisión
  anterior de conservarlos al morir. Contrato actualizado explícitamente.
- Los nombres/Tier II del mockup son solo demostrativos: la UI muestra
  espada/hacha/escudo y tier emitido por Player.
- Se implementó una biblioteca compartida de construcción de Controls en vez
  de diez escenas auxiliares; se mantienen las pantallas y jerarquía visual.
- Contenido cultural, host de las cinco salas, export y BUILD_AND_QA pendientes
  de integración; no se modifican en este bloque.
