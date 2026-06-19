```markdown
# Dinamométrico

Proyecto creado en **Godot 4.3+**

## 🚀 Pasos necesarios tras descargar el proyecto

Si acabas de clonar o descargar este repositorio en limpio, necesitas regenerar las plantillas de Android para evitar errores con los iconos adaptativos y mantener la configuración del plugin de Bluetooth:

1. **Renombrar el directorio actual:** Ve a la carpeta `android/` en la raíz de tu proyecto y cambia el nombre de la subcarpeta `build` (por ejemplo, a `build_bak`).
2. **Instalar la plantilla nativa:** Abre el proyecto en el editor de Godot y ve al menú superior: **Proyecto** -> **Instalar plantilla de exportación de Android...** (confirma la instalación).
3. **Restaurar la configuración:** Esto creará una carpeta `android/build` nueva y limpia con los iconos correctos. Ahora, copia los archivos que guardaste en el paso 1 (especialmente el `build.gradle` con las dependencias de Bluetooth) y pégalos en este nuevo directorio reemplazando los existentes.

---

## 🛠️ Comandos útiles de Git para el día a día

Cuando hagas cambios en tus scripts o escenas de Godot y quieras subirlos a la nube, abre tu terminal y ejecuta estos comandos en orden:

```bash
# 1. Comprobar qué archivos has modificado
git status

# 2. Añadir todos los cambios al paquete
git add .

# 3. Firmar el paquete con tu nota personal
git commit -m "Aquí pones tu mensaje"

# 4. Subir los cambios a GitHub
git push
