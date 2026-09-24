# Verificación bloque 4

Godot 4.7.2-stable, MCP conectado, 24 septiembre 2026.
Base apilada: feat/ui-flow en f112eb3. No se cambia run/main_scene.

- Audio lab: 26/26, regiones por colisión A/B/C, crossfade 0.8 s, interrupción,
  bucle más allá de cuatro segundos, dos enemigos, muerte duplicada/salida,
  región durante combate, siete SFX, ocho voces máximas y reset. Bus Master
  con señal no silenciosa. Resultado final consultado por MCP; el eval
  síncrono superó su timeout, por eso se usa ejecución diferida y sondeo.
- Regresión con MusicDirector completo: puzzle_lab 29/29 y ui_lab 20/20.
- Playground ejecutado como smoke test sin modificar su escena.
- Las 19 escenas actuales de ui/, interactables/, tests/interactables/ y
  audio/ abiertas una por una en el editor vía MCP (incluye las dos nuevas).
- Logs finales de editor/juego sin errores ni warnings.
- Once WAV reproducibles: --check confirma igualdad byte por byte.
- Créditos enumeran los 76 archivos UI y 22 archivos audio, incluidos imports
  y textos de licencia. Caché .godot excluido.

No verificado: escucha subjetiva/mezcla final, integración con Player/enemigos
reales, cinco salas y export. Hit/parry se ofrecen como API, sin editar combate.
El laboratorio usa enemigos simulados y Player propio; el host final deberá
registrar enemigos y colocar áreas musicales.

Decisiones: audio sintético sin referencias culturales; TODO_LICENSE para
licencia de publicación del audio y cláusula Book Styles; fuentes culturales
siguen TODO_CULTURAL. La instrucción actual New Game/Retry resetea progreso,
sustituyendo la antigua decisión de conservarlo. README pide ramas desde main,
pero Kevin pidió ramas apiladas; su restricción de rutas prevalece.

Lista exacta para git diff --name-only f112eb3...feat/audio-narrative:
FILES_AUDIO_NARRATIVE.txt.
