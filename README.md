# Damage Reader Skill — Forever

Addon independiente en desarrollo para mostrar daño (amarillo) y sanación (verde) sobre las barras de Blizzard. No incluye código ni tablas de DrDamage.

## Estado 0.3.0

La interfaz funciona según las capturas del usuario. Incluye modelos para las habilidades del informe del paladín en Forever 1.60.1, build 70862, Interface 16001, idioma esMX. Se validan con pruebas Lua; falta confirmar su ejecución en esa build dentro del juego. No hay cobertura completa de clases, rangos ni talentos.

| Habilidad | Cálculo y presentación |
| --- | --- |
| Golpe Sagrado (679) | Porcentaje del tooltip × daño actual de mano principal + rango Sagrado del tooltip. Con el informe: 7.44–10.19, promedio redondeado 9. |
| Luz Sagrada (639) | Reconoce “Sana un objetivo amistoso en 78 a 93 p.”: promedio 85.5, muestra 86 en verde. |
| Sello de rectitud (21084) | Muestra el rango adicional por ataque 2–9, que depende de la velocidad del arma. No muestra aquí el daño de Sentencia. |
| Sentencia (20271) | Lee el sello activo fuera de combate. Rectitud: 24–27, muestra 26. Cruzado: 0 daño directo, aplica perjuicio. Sin sello legible/compatible: oculta el número. |
| Sello del cruzado (21082), bendiciones y utilidades | No muestra AP, duración, maná ni perjuicios como si fueran daño. |

Los rangos se leen del cliente en cada actualización; no se fijan a las estadísticas del informe. Golpe Sagrado usa UnitDamage, que ya refleja el arma y poder de ataque: no se vuelve a sumar el AP. El tooltip del botón explica la operación. Los eventos de equipo, estadísticas y auras actualizan las estimaciones fuera de combate.

Estas son estimaciones de un golpe normal antes de mitigación y crítico. Luz Sagrada usa la cantidad publicada por el tooltip; no se añadió un coeficiente de sanación ni una corrección de talentos no verificados. Un heal observado de 97 no prueba que cada lanzamiento deba ser 97; con este informe, el rango publicado es 78–93. La diferencia observada requiere contrastar buffs, rango y registro de combate del mismo lanzamiento.

Esta versión corrige la lectura de cantidades directas del tooltip. Conserva las líneas, reconoce rangos en español e inglés y muestra el promedio del rango indicado por el cliente. Un rango 88–106 muestra 97; eso no garantiza que cada lanzamiento sea de 97.

Elimina la conversión no verificada de porcentajes a vida máxima. Fuera de los modelos indicados, porcentajes, daño de arma, sellos, daño periódico y descripciones con varios efectos requieren modelos específicos; sin modelo no se muestra un número. No se suma poder de hechizos indiscriminadamente: el tooltip puede incluirlo ya.

Se prueban casos sintéticos y las descripciones reales aportadas por el usuario con Lua 5.1. El manifiesto conserva Interface 16001. El acceso al sello usa C_UnitAuras.GetAuraDataByIndex y rechaza información protegida, inaccesible o ambigua.

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

Pruebas: `lua5.1 tests/calculator.lua` y `lua5.1 tests/forever-paladin.lua`. No sustituyen las pruebas en el juego.

Referencia funcional: [DrDamage](https://www.curseforge.com/wow/addons/dr-damage) calcula usando equipo, talentos y buffs. Leer un tooltip es solamente una de las entradas necesarias para conseguir ese alcance.
