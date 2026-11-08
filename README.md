# Damage Reader Skill — Forever

Addon independiente en desarrollo para mostrar daño (amarillo) y sanación (verde) sobre las barras de Blizzard. No incluye código ni tablas de DrDamage.

## Estado 0.2.0

La interfaz funciona según las capturas del usuario. El motor completo de predicción por hechizo, estadísticas, talentos y sellos **todavía no está terminado**.

Esta versión corrige la lectura de cantidades directas del tooltip. Conserva las líneas, reconoce rangos en español e inglés y muestra el promedio del rango indicado por el cliente. Un rango 88–106 muestra 97; eso no garantiza que cada lanzamiento sea de 97.

Elimina la conversión no verificada de porcentajes a vida máxima. Porcentajes, daño de arma, sellos, daño periódico y descripciones con varios efectos requieren modelos específicos; sin modelo no se muestra un número. No se suma poder de hechizos indiscriminadamente: el tooltip puede incluirlo ya.

Se prueban casos sintéticos con Lua 5.1; no son datos verificados de hechizos de Forever. Falta validar con las descripciones reales del cliente. El manifiesto conserva Interface 16001; el informe muestra la build real sin asumir sus APIs.

## Instalación

Copia la carpeta como `Interface/AddOns/damage.reader.skill` en la instalación de Forever que ejecutas. El archivo `damage.reader.skill.toc` debe quedar directamente dentro. Al actualizar, reemplaza los archivos y usa `/reload`.

## Comandos

- `/drs status`: versión, build y disponibilidad de API.
- `/drs on`, `/drs off`: mostrar u ocultar.
- `/drs refresh`: actualizar.
- `/drs scan`: acciones detectadas.
- `/drs inspect N`: texto exacto de la casilla N y resultado.
- `/drs report`: ventana copiable con build, idioma, estadísticas propias y descripciones de las habilidades colocadas.
- `/drs reset`: restablecer preferencias.
- `/drs debug`: mensajes de actualización.

El informe evita nombres de jugador, cuenta y servidor. Permite comprobar qué cifras son costes, cantidades, duraciones o fórmulas antes de implementar modelos por habilidad.

## Restricciones y validación

Se inspeccionan valores legibles fuera de combate. El overlay se oculta durante combate; aún no hay soporte validado de predicción en combate. No se registra el combat log ni se interpreta un total de combate como daño por golpe. No se implementó C_DamageMeter: sus totales no bastan por sí solos para esa predicción.

Pruebas: `lua5.1 tests/calculator.lua`. No sustituyen las pruebas en el juego.

Referencia funcional: [DrDamage](https://www.curseforge.com/wow/addons/dr-damage) calcula usando equipo, talentos y buffs. Leer un tooltip es solamente una de las entradas necesarias para conseguir ese alcance.
