# Audio provisional reproducible

Rama `feat/audio-narrative`, dependiente de `feat/ui-flow` en `f112eb3`.
Sin cambios de main_scene ni autoloads adicionales.

## Integración

- `MusicDirector.set_region(region_id: StringName)`: A público, B restringido,
  C cámara; también acepta MusicRegionA/B/C. Crossfade exportado de 0.8 s.
- Instanciar `music_region.tscn`, nombrar MusicRegionA/B/C o configurar region_id.
  Detecta cuerpo en capa 2 y grupo player. No depende de índices de hijos.
- El host registra cada enemigo con `watch_enemy(enemy: Node)`; escucha
  enemy_alerted/enemy_died y tree_exiting. Una alerta activa combate; sólo la
  última muerte/salida permite volver a la región más reciente. Duplicados no
  incrementan el contador; un enemigo muerto no puede reactivarse hasta reset.
- `play_sfx(id: StringName)`: menu, door, pickup, alarm, hit, parry, rift.
  Botones, puertas, pickups y alertas conectados; hit/parry quedan para los
  consumidores de combate de Jhon/Gian (sus archivos están fuera de alcance).
- `Level1Progress.progress_reset` llama reset_session: detiene canales y limpia
  enemigos/conexiones. El host debe volver a registrar enemigos al reiniciar.
- Música continúa durante pausa. Cuatro canales musicales y ocho voces SFX
  acotan recursos incluso si se interrumpe repetidamente un crossfade.

## Síntesis y pruebas

`python3 audio/generate_placeholders.py` genera once WAV mono PCM16/22050 Hz.
`python3 audio/generate_placeholders.py --check` compara todos los bytes.
No necesita dependencias, red ni material sonoro externo. Licencias pendientes
de decisión del equipo y créditos individuales: docs/credits/ASSETS.md.

Abrir tests/interactables/audio_lab.tscn y pulsar Pruebas. Con MCP ejecutar
`get_tree().current_scene.run_checks.call_deferred()` y consultar results y
testing después: la prueba de bucle supera el timeout de un eval síncrono.
El laboratorio mide señal real en el bus y verifica las once fuentes; no
sustituye una escucha subjetiva ni la mezcla final en hardware de destino.
