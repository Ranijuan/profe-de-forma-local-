# Ejecución con Docker

El asistente está empaquetado como una imagen Docker. La imagen incluye todo lo necesario: compilador C, Tesseract, Python, dependencias y el modelo de traducción.

## Requisitos

- **Linux con X11:** Docker corriendo en el equipo.
- **Windows/macOS:** Docker Desktop. La GUI no funcionará directamente (requiere X11 forwarding avanzado).

## Construcción

```bash
docker build -t teacher-de-idiomas .
```

Esto tarda unos 5-10 minutos la primera vez (descarga el modelo de 82 MB).

## Ejecución

### En Linux

```bash
docker run --rm \
  -e DISPLAY=:0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  teacher-de-idiomas
```

O con docker-compose:

```bash
docker-compose up
```

### En Windows/macOS

En teoría es posible con VcXsrv (Windows) o XQuartz (macOS) y X11 forwarding, pero es bastante complicado. 

La forma más simple es ejecutar directamente en el equipo (ver `README.md`).

## Opciones de ejecución

Pasar argumentos a la app:

```bash
docker run --rm \
  -e DISPLAY=:0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  teacher-de-idiomas \
  --vueltas 2 --zona 0,0,1920,1080
```

Disponibles:
- `--vueltas N`: veces por segundo que se mira la pantalla
- `--zona x,y,ancho,alto`: vigilar solo un rectángulo
- `--escala N`: ampliado antes del OCR (1, 2 o 3)
- `--confianza N`: descartar lecturas bajo este umbral
- `--segundos N`: cerrarse después de N segundos

## Volúmenes

Para conservar la caché de traducciones entre ejecuciones:

```bash
docker run --rm \
  -e DISPLAY=:0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v $(pwd)/datos:/app/datos \
  teacher-de-idiomas
```

## Notas

- La interfaz gráfica aparece como una ventana flotante que no intercepta clics.
- Se cierra con `Ctrl+C`.
- Los logs de depuración aparecen en la consola.
