# Asistente de inglés

Un ayudante que aprende de lo que haces en el ordenador para enseñarte inglés.

Mira la pantalla, ve el texto en inglés con el que estás trabajando y, en un recuadro
pequeño de chat en una esquina, te va sugiriendo palabras en inglés con su significado en
español. No interrumpe: se queda en una esquina y tú sigues a lo tuyo.

Todo el reconocimiento de texto y la traducción ocurren en el equipo. No se envía ninguna
captura de tu pantalla a ningún servidor.

## Estado

Está construida y probada toda la maquinaria que hay debajo. **Falta el producto en sí**:
el recuadro de chat y la IA que decide qué vale la pena enseñarte.

Lo que ya funciona:

| Pieza | Estado |
|---|---|
| Captura de pantalla y detección de qué cambió (C) | funciona |
| Lectura del texto (OCR) | funciona |
| Traducción inglés→español sin conexión | funciona |
| Ventana superpuesta sobre la pantalla | funciona |
| Recuadro de chat con las sugerencias | pendiente |
| La IA que elige qué palabras enseñarte | pendiente |
| Recordar lo que ya te ha enseñado | pendiente |

Hoy, `aplicacion/principal.py` dibuja la traducción encima de todo el texto en inglés que
encuentra. Es el andamio con el que se probó que la cadena entera funciona, no la forma
final.

## Cómo funciona por dentro

```
pantalla → captura → ¿qué cambió? → OCR → traducción → recuadro de sugerencias
            (C)         (C)        (Tesseract) (CTranslate2)     (Qt)
```

La pieza importante es la segunda. Leer texto de una imagen cuesta entre 300 y 1300 ms,
mientras que capturar la pantalla cuesta 30 ms y comparar con el fotograma anterior, menos
de 1 ms. Todo el diseño consiste en llamar al OCR lo menos posible: si un trozo de pantalla
no ha cambiado, no se vuelve a leer. Sin eso, el programa no se podría dejar abierto
mientras trabajas.

El núcleo en C hace lo que se repite muchas veces por segundo:

| Archivo | Qué hace |
|---|---|
| `nucleo/src/captura.c` | copia la pantalla reutilizando los recursos de Windows |
| `nucleo/src/deteccion_cambios.c` | divide en bloques, calcula una huella de cada uno y agrupa los que cambiaron |
| `nucleo/src/preproceso.c` | pasa a blanco y negro con umbral automático (Otsu) |

Python se encarga del resto: OCR, traducción, interfaz y las decisiones de qué vale la pena
procesar.

## Instalación

Hacen falta tres cosas que no están en el repositorio.

**1. Compilador de C y Tesseract**

```powershell
winget install -e --id BrechtSanders.WinLibs.POSIX.UCRT
winget install -e --id UB-Mannheim.TesseractOCR
```

**2. Entorno de Python y dependencias**

```powershell
python -m venv entorno
.\entorno\Scripts\pip.exe install PySide6 pytesseract pillow ctranslate2 sentencepiece
```

**3. El núcleo y el modelo de traducción**

```powershell
.\construir.ps1
.\entorno\Scripts\python.exe aplicacion\traduccion\descargar_modelo.py
```

El modelo son 82 MB (OPUS-MT inglés→español, convertido a CTranslate2 y cuantizado a int8).
Se descarga una vez y a partir de ahí funciona sin internet.

## Uso

```powershell
.\entorno\Scripts\python.exe aplicacion\principal.py
```

Se cierra con `Ctrl+C`. Opciones:

| Opción | Para qué |
|---|---|
| `--vueltas N` | veces por segundo que se mira la pantalla (2 por defecto) |
| `--zona x,y,ancho,alto` | vigilar solo un rectángulo en vez de toda la pantalla |
| `--escala N` | ampliado antes del OCR (1, 2 o 3) |
| `--confianza N` | descartar lecturas por debajo de esa confianza |
| `--segundos N` | cerrarse solo pasados N segundos |

## Pruebas

Cada parte tiene su comprobación, y todas se ejecutan igual:

```powershell
.\entorno\Scripts\python.exe nucleo\pruebas\probar_nucleo.py        # el nucleo en C
.\entorno\Scripts\python.exe aplicacion\pruebas\probar_ocr.py       # lectura de texto
.\entorno\Scripts\python.exe aplicacion\pruebas\probar_traductor.py # traduccion
.\entorno\Scripts\python.exe aplicacion\pruebas\probar_ciclo.py     # todo junto
```

Miden además el tiempo de cada fase, que es lo que permite ver si un cambio mejoró o
empeoró las cosas.

## Rendimiento medido

En un portátil corriente a 1920x1080:

| Operación | Tiempo |
|---|---|
| Capturar la pantalla completa | 33 ms |
| Detectar qué cambió | < 1 ms |
| OCR de una franja de 1920x100 | 260 ms |
| OCR de la pantalla completa | 995 ms |
| Traducir una frase | 34 ms (11 ms en lote) |
| Traducir algo ya traducido antes | 0,01 ms (caché) |

El coste del OCR **no** es proporcional a la superficie: pesan más el arranque del proceso
de Tesseract y la cantidad de texto que haya. Por eso el programa raciona el número de
zonas que lee en cada vuelta, no los píxeles.

## Nota sobre el nombre de la carpeta

El proyecto empezó llamándose `traductor-pantalla`, cuando solo pretendía traducir lo que
había en pantalla. La carpeta conserva ese nombre; la idea, no.
