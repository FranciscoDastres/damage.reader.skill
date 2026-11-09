# Damage Reader Skill — Forever

Addon independiente para mostrar estimaciones sobre las barras de Blizzard. Destino: WoW Forever, Interface 16001. No incluye código ni tablas de DrDamage.

## Versión 0.5.0: familias y rangos del paladín

Las habilidades se reconocen por su nombre de familia en español o inglés, en lugar de depender del ID de un solo rango. Al aprender un rango se actualiza el registro desde el libro de hechizos y las barras. Esto incluye Rectitud de rango 2 y posteriores, Furia y los rangos de las demás familias de la tabla. Las cantidades se leen del rango exacto que expone el cliente: no hay una tabla de daño fija ni se reutilizan los números de rango 1.

El libro se consulta fuera de combate con APIs modernas o clásicas, según disponibilidad. Si una habilidad nueva o su traducción no se reconoce, `/drs report` incluye su ID y descripción aunque no esté en las barras. No se promete cobertura numérica de cualquier descripción futura: una fórmula ambigua queda sin número y con el motivo en el informe.

| Familia, en todos los rangos reconocidos | Qué muestra |
| --- | --- |
| Golpe Sagrado | Porcentaje del tooltip × daño actual del arma + daño Sagrado indicado. UnitDamage ya incluye AP. |
| Sello de rectitud | Rango adicional por golpe, sin inventar un promedio para su dependencia de velocidad. |
| Sello de furia | Daño adicional por golpe; el escudo no se suma al daño. |
| Sello de orden | Daño por activación calculado con el porcentaje de arma descrito; no es DPS ni daño garantizado por golpe. |
| Sellos de Luz y sabiduría | Sanación o maná por activación. |
| Sentencia | Efecto del sello y rango activos: daño, sanación o maná. Furia incluye daño y provocación; Cruzado y Justicia muestran 0 daño directo. |
| Luz Sagrada y Destello de Luz | Sanación media del tooltip. |
| Exorcismo, Martillo de cólera y Cólera Sagrada | Daño medio por objetivo. |
| Choque Sagrado y Vigilia de la Luz | `daño/sanación`; el tooltip explica ambos valores. En Vigilia son efectos activados posteriormente con Choque Sagrado. |
| Consagración | `total/duración` o `cantidad/t` si el cliente describe daño por tick. No se multiplica por enemigos. |
| Escudo Sagrado, Aura de reprensión y Salvaguardia | Daño por activación cuando la descripción permite distinguirlo de sus otros efectos. |
| Imposición de manos | Salud máxima propia únicamente si el texto indica explícitamente esa fórmula de sanación. |
| Baluarte del templario | Absorción según el porcentaje explícito de salud máxima propia. |
| Cruzado, Justicia, bendiciones de estadísticas, resistencias, inmunidades, limpiezas, resurrección, monturas y otras utilidades registradas | Sin etiqueta de daño: duración, amenaza, AP y costes no son daño del lanzamiento. |

Amarillo: daño; verde: sanación; azul: maná; violeta: absorción. Las habilidades con dos efectos presentan daño a la izquierda y sanación a la derecha. El tooltip del botón explica la unidad fuera de combate.

## Combate y datos protegidos

Los números permanecen visibles y se recalculan ante cambios legibles de auras, arma, AP, poder de hechizos y salud máxima. Los eventos se agrupan a 0.1 s. Tras lanzar una habilidad se reintenta a 0.3 y 0.8 s para recoger auras retrasadas.

El sello activo se confirma por su aura, nunca por una tecla o por el ID del lanzamiento. Se consulta directamente cada rango descubierto; la enumeración de auras permite reconocer nuevos IDs por su nombre. Un aura ajena protegida no invalida un sello legible.

`~` indica la última estimación legible, pendiente de actualizar. La caché de Sentencia es independiente por ID/rango de sello: si se confirma un rango sin cantidades conocidas, se oculta el número anterior. Cambiar de casilla, habilidad o página también invalida los datos correspondientes.

No se crean etiquetas protegidas ni se escanea GameTooltip en combate. Si recargas durante una pelea, los botones que todavía no tenían etiqueta esperan hasta salir. No se leen combat logs ni se reconstruyen valores secretos.

## Límites de los cálculos

Son estimaciones antes de mitigación, crítico y sobrecuración. No se añaden coeficientes de poder de hechizos o talentos que el cliente no describa y el modelo no contemple. Los procs se reflejan cuando modifican entradas legibles del cálculo.

No se modela la amplificación del perjuicio de Cruzado sobre el enemigo, la probabilidad de cada proc, la condición de aturdimiento de Sentencia de Orden ni el total de daño de todos los objetivos. Descripciones con varias cantidades del mismo tipo sin una regla clara se dejan sin estimación.

El informe real disponible corresponde al paladín de Forever 1.60.1 / build 70862 / esMX y verifica las fórmulas iniciales. Los nuevos rangos y familias tienen pruebas sintéticas; falta validar sus descripciones y ejecución en el cliente real. La lista de familias no equivale a una certificación de todas las habilidades, talentos, traducciones o builds.

## Instalación

Descomprime `dist/damage.reader.skill-0.5.0.zip` dentro de `Interface/AddOns`, reemplazando la carpeta `damage.reader.skill`. El archivo `damage.reader.skill.toc` debe quedar directamente dentro. Ejecuta `/reload` fuera de combate y confirma `/drs status`: versión 0.5.0.

Para verificar este cambio: coloca Rectitud rango 2 y Furia en las barras, comprueba sus cantidades y cambia entre ambos mientras observas Sentencia. Repite en combate. Si falta un valor, `/drs report` incluye ahora el libro de hechizos completo disponible, además de las barras.

## Comandos

- `/drs status`: versión, build y APIs.
- `/drs on`, `/drs off`: mostrar u ocultar.
- `/drs refresh`: releer el libro y actualizar barras; si estás en combate, la lectura del libro espera hasta salir.
- `/drs scan`: acciones detectadas.
- `/drs inspect N`: descripción y resultado de la casilla N.
- `/drs report`: informe copiable con build, idioma, estadísticas, barras y libro de hechizos.
- `/drs reset`: restablecer preferencias.
- `/drs debug`: mensajes de actualización.

El informe evita nombres de jugador, cuenta y servidor.

## Pruebas y fuentes

Ejecuta con Lua 5.1:

```sh
lua5.1 tests/calculator.lua
lua5.1 tests/forever-paladin.lua
lua5.1 tests/combat.lua
lua5.1 tests/paladin-ranks.lua
```

Las suites cubren el informe original, rangos desconocidos previamente, Furia, aislamiento de Sentencia por rango, cambio de botones, datos protegidos, libro moderno/clásico, cantidades de daño/sanación/maná/absorción y regresiones de combate. Los fixtures nuevos están identificados como sintéticos; no certifican los valores del juego.

[Descripción oficial del paladín de Forever](https://news.blizzard.com/en-us/article/24302099/world-of-warcraft-forever-class-deep-dives-paladin): referencia de las familias y de los efectos separados de Furia. Sus valores pueden cambiar; el addon toma las cantidades del cliente.

[Documentación de las APIs de libro de hechizos del cliente Blizzard](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua): referencia de la interfaz moderna, con fallback a la clásica y comprobación de disponibilidad.
