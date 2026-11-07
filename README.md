# Damage Reader Skill

Addon nuevo e independiente para **WoW: Forever**. El proyecto no modifica ni incluye DrDamage.

Su primera versión coloca un número pequeño sobre las habilidades de las barras de acción de Blizzard cuando la API del cliente expone una descripción numérica de daño o sanación para el hechizo.

## Instalación

1. Copia esta carpeta completa como `damage.reader.skill` dentro de la carpeta `Interface/AddOns` del cliente de WoW Forever.
2. Comprueba en la pantalla de selección de personaje que **Damage Reader Skill** aparezca habilitado.
3. Entra al juego y escribe `/drs`.

La ruta exacta del producto puede variar entre versiones del launcher de Forever. Usa la carpeta `Interface/AddOns` perteneciente al cliente que realmente ejecutas; no mezcles la ruta de Retail, Classic o PTR.

## Comandos

- `/drs` o `/drs status`: muestra ayuda y estado.
- `/drs on`: activa los números.
- `/drs off`: los desactiva.
- `/drs refresh`: fuerza la actualización de las barras.
- `/drs reset`: restablece la configuración.
- `/drs debug`: activa mensajes de diagnóstico.

## Alcance de esta versión

- Usa la API de acciones expuesta por Forever: primero intenta `C_ActionBar` y, cuando el cliente no ofrece ese namespace, utiliza el `GetActionInfo` global disponible en algunas builds. También usa `C_Spell` y `C_TooltipInfo` cuando están disponibles.
- No usa el combat log, lectura de eventos de daño, automatización de acciones, macros, código ejecutable externo ni decisiones protegidas durante combate.
- Oculta el overlay durante combate si la información de acción puede ser un valor secreto.
- No contiene tablas, código ni archivos tomados de DrDamage.

El número mostrado es una **estimación basada en la descripción del hechizo**. No debe presentarse todavía como una predicción completa de daño real: faltan pruebas en el cliente, datos por clase, talentos, equipo, buffs, resistencias y reglas específicas de Forever. Esa ampliación se hará con datos propios verificados, no copiando una base de datos de terceros.

## Estado de verificación

La estructura y el código están preparados para el cliente moderno, pero este entorno no tiene una instalación ejecutable de WoW Forever para validar la creación de cada botón y las respuestas exactas de su build. La validación final debe hacerse dentro del cliente con `/drs debug` y una captura de las barras.
