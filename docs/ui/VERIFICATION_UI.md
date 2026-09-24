# Verificación bloque 3

Godot MCP: 4.7.2-stable (official), viewport 640×360, 24/09/2026.

- Se abrieron las 19 escenas existentes: nueve UI, ui_lab, las nueve previas.
- Se ejecutaron ui_lab (20/20), puzzle_lab (29/29) y Playground (smoke).
- 37/37 texturas PNG cargadas por ResourceLoader, ninguna nula.
- Logs finales del editor y de las ejecuciones verificadas: cero errores y
  cero advertencias. Los fallos detectados durante desarrollo se corrigieron
  y se repitieron las pruebas correspondientes.
- Capturas runtime inspeccionadas: main, HUD, equipo, pausa, controles y puzzle.
  Se verificaron tamaños de paneles/botones usados, tipografía legible,
  esquinas de nueve parches, HP rojo y stamina verde.
- Teclas reales MCP: Tab abre/cierra equipo; Esc abre/cierra pausa;
  input y paused cambian/restauran juntos.
- Casos UI: lectura inicial sin señales, señales de salud/stamina/equipo,
  pausa real del Player simulado, navegación anidada, input previamente
  bloqueado, inventario descubierto, ausencia de confirmación optimista,
  muerte/Retry, Nueva partida, HUD único, Player sin API, puzzle/error/reintento,
  cierre del puzzle y ending.

Reproducir: F6 en tests/interactables/ui_lab.tscn, Nueva partida y botón Pruebas.
También se puede ejecutar por MCP game_eval:
`return await get_tree().current_scene.run_checks()`.
En laboratorio Quit emite la intención sin cerrar el proceso (allow_quit=false);
en UIFlow de producción allow_quit=true solicita salida del árbol.

No verificado: Player final, enemigos/salas reales, mando, export, integración
de las cinco salas. No se afirma fidelidad tipográfica exacta: fuente final
pendiente. El diseño es una reconstrucción funcional del layout, no un raster.
Listado exacto de archivos del bloque en FILES_UI_FLOW.txt.
