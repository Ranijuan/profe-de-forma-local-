# ============================================================================
#  construir.ps1  -  Compila el nucleo en C y genera la DLL
# ============================================================================
#
#  USO:   .\construir.ps1
#         .\construir.ps1 -Depurar     (version con simbolos, sin optimizar)
#
#  QUE PRODUCE:  nucleo\bin\nucleo.dll
#
#  Python carga esa DLL con ctypes. No hay que "instalar" nada mas.
# ============================================================================

param(
    [switch]$Depurar
)

$ErrorActionPreference = 'Stop'
$raiz = $PSScriptRoot

# ---------------------------------------------------------------------------
#  1. Localizar el compilador
# ---------------------------------------------------------------------------
#  winget instala WinLibs en una carpeta del usuario que no siempre esta en el
#  PATH de la sesion actual. Si 'gcc' no responde, lo buscamos a mano.
# ---------------------------------------------------------------------------
$gcc = (Get-Command gcc -ErrorAction SilentlyContinue).Source

if (-not $gcc) {
    $candidatos = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages" `
                    -Filter 'gcc.exe' -Recurse -ErrorAction SilentlyContinue
    if ($candidatos) { $gcc = $candidatos[0].FullName }
}

if (-not $gcc) {
    Write-Host "ERROR: no se encontro gcc." -ForegroundColor Red
    Write-Host "Instalalo con:  winget install -e --id BrechtSanders.WinLibs.POSIX.UCRT"
    exit 1
}

Write-Host "Compilador: $gcc" -ForegroundColor Cyan
& $gcc --version | Select-Object -First 1

# ---------------------------------------------------------------------------
#  2. Opciones de compilacion
# ---------------------------------------------------------------------------
$fuentes = @(
    "$raiz\nucleo\src\nucleo.c"
    "$raiz\nucleo\src\captura.c"
    "$raiz\nucleo\src\deteccion_cambios.c"
    "$raiz\nucleo\src\preproceso.c"
)

$salida = "$raiz\nucleo\bin\nucleo.dll"
New-Item -ItemType Directory -Force -Path "$raiz\nucleo\bin" | Out-Null

$opciones = @(
    '-shared'                      # generar una DLL, no un ejecutable
    '-o', $salida
    "-I$raiz\nucleo\incluir"       # donde buscar nucleo.h
    "-I$raiz\nucleo\src"           # donde buscar interno.h
    '-DNUCLEO_CONSTRUYENDO_DLL'    # activa __declspec(dllexport)
    '-std=c11'                     # version del lenguaje C
    '-Wall'                        # avisar de todo lo sospechoso
    '-Wextra'                      # y de mas cosas todavia
    '-Werror'                      # tratar cada aviso como un error
)

if ($Depurar) {
    Write-Host "Modo: DEPURACION" -ForegroundColor Yellow
    $opciones += @('-g', '-O0')
} else {
    Write-Host "Modo: RELEASE" -ForegroundColor Green
    # -O2   : optimizacion fuerte, la habitual para codigo de produccion.
    # -ffast-math NO se usa a proposito: cambia el resultado de las cuentas
    #             con decimales y aqui Otsu depende de comparaciones exactas.
    $opciones += @('-O2', '-s')
}

# Bibliotecas de Windows que necesitamos:
#   gdi32  : BitBlt, CreateDIBSection, todo el dibujo
#   user32 : GetDC, GetSystemMetrics
$bibliotecas = @('-lgdi32', '-luser32')

# ---------------------------------------------------------------------------
#  3. Compilar
# ---------------------------------------------------------------------------
#  Se usa -Werror a proposito. Un aviso del compilador en C casi siempre
#  senala un fallo real (una variable sin inicializar, una comparacion entre
#  con signo y sin signo, un valor de retorno ignorado). Dejar que la
#  compilacion falle obliga a arreglarlos en el momento, en vez de acumular
#  cientos de avisos que nadie lee.
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Compilando $($fuentes.Count) archivos..." -ForegroundColor Cyan

$argumentos = $opciones + $fuentes + $bibliotecas
& $gcc @argumentos

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "FALLO LA COMPILACION" -ForegroundColor Red
    exit 1
}

$info = Get-Item $salida
Write-Host ""
Write-Host "OK -> $salida" -ForegroundColor Green
Write-Host ("Tamano: {0:N1} KB" -f ($info.Length / 1KB))
