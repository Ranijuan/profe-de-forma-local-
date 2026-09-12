# Asistente de inglés — imagen Docker

FROM python:3.12-slim

LABEL maintainer="Ranijuan"
LABEL description="Asistente que aprende de tu pantalla para enseñarte inglés"

# ============================================================================
#  DEPENDENCIAS DEL SISTEMA
# ============================================================================
# gcc, g++: para compilar el núcleo en C
# tesseract-ocr: motor de OCR
# libsm6, libxrender1: requeridos por Qt para GUI

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    tesseract-ocr \
    libsm6 \
    libxrender1 \
    x11-utils \
    && rm -rf /var/lib/apt/lists/*

# ============================================================================
#  CONFIGURACIÓN
# ============================================================================

WORKDIR /app

# Variables de entorno para Qt y Tesseract
ENV DISPLAY=:0 \
    QT_QPA_PLATFORM=offscreen \
    TESSERACT_PATH=/usr/bin/tesseract

# ============================================================================
#  COPIAR CÓDIGO
# ============================================================================

COPY . .

# ============================================================================
#  DEPENDENCIAS PYTHON E INSTALACIÓN
# ============================================================================

RUN pip install --no-cache-dir \
    PySide6==6.11.2 \
    pytesseract==0.3.13 \
    pillow==12.3.0 \
    ctranslate2==4.8.2 \
    sentencepiece==0.2.2

# Compilar el núcleo en C
RUN cd /app && \
    mkdir -p nucleo/bin && \
    gcc -shared -o nucleo/bin/nucleo.dll \
        -Inucleo/incluir -Inucleo/src \
        -DNUCLEO_CONSTRUYENDO_DLL \
        -std=c11 -Wall -Wextra -Werror -O2 -s \
        nucleo/src/nucleo.c \
        nucleo/src/captura.c \
        nucleo/src/deteccion_cambios.c \
        nucleo/src/preproceso.c

# Descargar el modelo de traducción (una sola vez en la construcción)
RUN python aplicacion/traduccion/descargar_modelo.py

# ============================================================================
#  ENTRADA
# ============================================================================

# La app necesita acceso a la pantalla (X11 forwarding)
# Se ejecuta con: docker run -e DISPLAY=:0 -v /tmp/.X11-unix:/tmp/.X11-unix ...

ENTRYPOINT ["python", "aplicacion/principal.py"]
CMD ["--vueltas", "2", "--silencioso"]
