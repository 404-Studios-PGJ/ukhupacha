# Reporte consolidado de cambios — bloques 1–4

Proyecto: UKHUPACHA · Godot 4.7.2 · responsable: Kevin

## Ramas y dependencia

Las ramas se construyeron apiladas, cada una sobre la anterior:

1. `chore/integration-contracts`: `a305dd5`, `ee37400`.
2. `feat/level-interactions`: `6635f5d`, depende de la rama anterior.
3. `feat/ui-flow`: `5a128a1`, `25ed579`, `f112eb3`, depende de `6635f5d`.
4. `feat/audio-narrative`: `26d7b6b`, depende de `f112eb3`.

Las ramas 3 y 4 fueron publicadas en `origin`; nunca se hizo push a `main`.

## Bloque 1 — contratos de integración

- Capas físicas, inputs y aliases documentados.
- Autoloads mínimos `Level1Progress` y `MusicDirector`.
- Firmas tipadas de Player/Enemy, hit/parry, estado de nivel, muerte única y marcadores.
- Contrato en [INTEGRATION_CONTRACT.md](../INTEGRATION_CONTRACT.md).

## Bloque 2 — interacciones y progreso

- Base `Interactable`, sistema independiente de Player y selección del objeto más cercano.
- Raycast contra pared, un disparo por pulsación y bloqueo cuando Player está deshabilitado.
- Records, terminal de acceso, pickup de equipo, punto de memoria y puertas con collider realmente deshabilitado.
- `Level1Progress` con flags, señales, reset y reglas de puertas/rift.
- `tests/interactables/puzzle_lab.tscn` con casos de pared, proximidad, reintento y reset.

## Bloque 3 — UI Hybrid Discovery v2

- 37 PNG runtime y metadatos `.import`, preservando licencias suministradas.
- Un Theme central (`ui/theme/ukhupacha_theme.tres`) y registro de assets (`ui/ui_assets.gd`).
- HUD, menú principal, pausa, equipo, controles, muerte, ending, terminal de puzzle y flujo común construidos con Controls reales.
- Estado inicial y señales del HUD; equipo descubierto únicamente por flags/señales; pausa y equipo restauran input.
- Placeholders geométricos donde faltan assets; pendientes registrados en [MISSING_ASSETS.md](../ui/MISSING_ASSETS.md).
- Pruebas y limitaciones en [VERIFICATION_UI.md](../ui/VERIFICATION_UI.md).
- Manifiesto exacto: [FILES_UI_FLOW.txt](../ui/FILES_UI_FLOW.txt).

## Bloque 4 — audio y narrativa

- `MusicDirector` con ambientes A/B/C, combate, crossfade configurable de 0.8 s y ocho voces SFX.
- Regiones `MusicRegionA/B/C`, seguimiento de enemigos y liberación de combate al morir el último enemigo.
- SFX para menú, puerta, pickup, alarma, hit, parry y rift; hooks disponibles para combate futuro.
- Once WAV sintéticos reproducibles mediante `audio/generate_placeholders.py`; sin samples externos ni contenido cultural inventado.
- Laboratorio de audio y créditos por archivo, incluidos `.import`, en [ASSETS.md](ASSETS.md).
- Pruebas detalladas en [VERIFICATION_AUDIO.md](VERIFICATION_AUDIO.md).
- Manifiesto exacto: [FILES_AUDIO_NARRATIVE.txt](FILES_AUDIO_NARRATIVE.txt).

## Verificación MCP

- Godot MCP 4.7.2: escenas de UI, interactables, audio y laboratorios abiertas correctamente.
- `ui_lab`: 20/20.
- `puzzle_lab`: 29/29.
- `audio_lab`: 26/26.
- Playground ejecutado como smoke test sin modificarlo.
- Logs finales de editor y juego: cero errores y cero warnings.
- WAV: `generate_placeholders.py --check` confirmó igualdad byte por byte.

## Decisiones y pendientes

- New Game/Retry reinician flags, equipo y HUD, conforme a la instrucción más reciente de Kevin.
- `TODO_CULTURAL` conserva textos culturales pendientes de Nayeli.
- `TODO_LICENSE` conserva la decisión de publicación del audio y la cláusula pendiente del pack Book Styles.
- No se modificaron `run/main_scene`, niveles, Player/Enemy reales ni exportación.
- La integración en las cinco salas y los enlaces hit/parry en actores ajenos quedan para las ramas de sus responsables.

## Auditoría de repositorio

- Sólo se cambiaron rutas permitidas por los prompts.
- `addons/` y `leer.md` no aparecen en commits.
- `project.godot` conserva localmente las entradas MCP; no se versionaron.
- `git log --all -p -- project.godot | grep -c godot_ai` devuelve `0`.
