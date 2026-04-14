# Export e “instalador”

## Durante el desarrollo

No hace falta instalador: ejecutas desde **Godot** (F5) o exportas un **`.exe`** suelto y lo pruebas en carpeta.

## Cuando quieras un ejecutable

1. Instala **Export Templates** (Godot te lo pide la primera vez que exportas).
2. **Project → Export…** → añade preset **Windows Desktop** (y más tarde Linux si aplica).
3. Exporta a una carpeta `exports/` o `build/` (local, en `.gitignore`).

Eso genera el juego empaquetado; para usuarios finales suele bastar un **ZIP** con el `.exe` y la carpeta `.pck` / datos que Godot genere.

## Instalador tipo “Setup.exe”

Herramientas externas (**Inno Setup**, **NSIS**, WiX) envuelven tu carpeta exportada. Conviene usarlas cuando ya tengas **versión estable**, nombre final, icono y rutas de instalación definidas — no es el primer paso del prototipo.
