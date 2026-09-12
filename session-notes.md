# Session Notes — 2026-09-11

## Qué se hizo (continuación de la misma sesión)
- Recompilada la DLL del núcleo (estaba desfasada) y pasadas sus pruebas: 6/6, sin fugas.
- Creados y probados los módulos de OCR (`ocr.py`), traducción local (`traductor.py`, `descargar_modelo.py`), orquestador (`ciclo.py`) e interfaz superpuesta; las 4 baterías de pruebas pasan.
- Descargado el modelo OPUS-MT en→es a `datos/modelos/en-es` (82,5 MB, int8).
- Verificada la superposición en pantalla real con captura: dibuja las cajas en su sitio.
- Construidos `aplicacion/ia/selector.py` (elige qué palabras enseñar) y `aplicacion/interfaz/panel_sugerencias.py` (recuadro flotante); ya integrados en `principal.py` y `hilo_ciclo.py`. Commit `d579667`.
- Añadido Docker (`Dockerfile`, `docker-compose.yml`, `DOCKER.md`). Mismo commit.
- **Nuevo hoy:** `aplicacion/aprendizaje/almacen.py` — persiste el estado del `SelectorPalabras` (frecuencias + palabras ya enseñadas) en `datos/aprendizaje.json`. `selector.py` ganó `exportar_estado`/`importar_estado`; `principal.py` carga al arrancar y guarda al cerrar (`hilo.ciclo` expuesto en `HiloCiclo` para leerlo tras `detener()`, sin carrera). Prueba nueva `probar_aprendizaje.py`, 5/5 OK. **Todavía sin commitear.**
- Repo git con remoto `origin` ya apuntando a `https://github.com/Ranijuan/teacher-de-idiomas-beta.git`, pero el repo remoto **no existe todavía** (push da "Repository not found"); **pendiente de subir**: `gh` sigue sin sesión.

## Decisiones tomadas
- Modelo desde `frisket-models/opus-mt-en-es-ct2` — Argos ya no resuelve y convertir exigiría transformers+torch (~2 GB).
- Añadir `</s>` al trocear — sin él el modelo no para: 1465 ms/frase frente a 34 ms.
- Racionar el **número** de llamadas al OCR (3 por vuelta), no los píxeles — el coste lo domina el arranque de `tesseract.exe` y la densidad de texto, no la superficie.
- Repo **público**, nombre `teacher-de-idiomas-beta` (remoto ya configurado con ese nombre exacto).
- README reescrito: el proyecto no es un traductor, es un asistente que sugiere palabras en inglés en un recuadro de chat.
- `datos/aprendizaje.json` va al `.gitignore`: es progreso personal del usuario, no código.
- La persistencia vive en `aprendizaje/almacen.py`, separada de `ia/selector.py`, para que el selector no necesite saber de archivos ni rutas (se puede probar entero en memoria).

## Siguientes pasos
- Ejecutar `gh auth login` (GitHub.com → HTTPS → navegador) y avisar; luego se crea el repo remoto (`gh repo create Ranijuan/teacher-de-idiomas-beta --public --source=. --remote=origin` o similar) y se hace push.
- Commitear el módulo de aprendizaje (`aplicacion/aprendizaje/almacen.py`, cambios en `selector.py`, `hilo_ciclo.py`, `principal.py`, `.gitignore`, prueba nueva).
- `SelectorPalabras.marcar_enseñada()` existe pero nada la llama todavía desde la interfaz — hoy nunca se marca nada como enseñado en uso real, así que la persistencia no tiene efecto notable hasta que el panel de sugerencias (o el usuario) dispare esa marca (p. ej. al hacer clic/descartar una sugerencia).

## Archivos modificados
- `aplicacion/traduccion/ocr.py`, `traductor.py`, `descargar_modelo.py` — nuevos.
- `aplicacion/ciclo.py`, `principal.py`, `interfaz/superposicion.py`, `interfaz/hilo_ciclo.py` — nuevos/editados.
- `aplicacion/ia/selector.py`, `aplicacion/interfaz/panel_sugerencias.py` — nuevos (commit `d579667`).
- `aplicacion/aprendizaje/almacen.py`, `aplicacion/aprendizaje/__init__.py` (editado) — nuevos, sin commitear.
- `aplicacion/pruebas/probar_ocr.py`, `probar_traductor.py`, `probar_ciclo.py`, `probar_aprendizaje.py` (nueva, sin commitear).
- `README.md`, `.gitignore` (editado hoy), `Dockerfile`, `docker-compose.yml`, `DOCKER.md`.
- `nucleo/bin/nucleo.dll` — recompilada (no se versiona).

## Contexto para restaurar
Lee session-notes.md. Continúa con: autenticar `gh`, crear el repo remoto y subir (incluyendo el módulo de aprendizaje sin commitear); después, decidir cómo se dispara `marcar_enseñada` desde la interfaz real.

## Avisos
- La red del sandbox no llega a los procesos hijo: las descargas con python fallan con DNS; hay que ejecutarlas fuera del sandbox.
- `nucleo/incluir/nucleo.h:152` afirma 4 ms por captura; medido: 33 ms.
