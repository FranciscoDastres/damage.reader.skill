# Damage Reader Skill — Forever

Addon independiente para mostrar estimaciones sobre las barras de Blizzard. Destino: WoW Forever, Interface 16001. No incluye código ni tablas de DrDamage.

## Versión 0.6.2: correcciones con informes de las nueve clases

Se corrigen las frases esMX de Golpe siniestro, Golpe heroico y Golpe de raptor para sumar el daño del arma y su bonificación. Bola de Fuego rango 1 separa el golpe inicial del daño periódico. Imposición de manos reconoce la fórmula de salud máxima del informe.

Atacar muestra el golpe medio de la mano principal; Disparo automático, Lanzar y Disparar con varita muestran el promedio por disparo cuando el cliente publica daño a distancia válido. No son DPS. Sin arma/datos legibles no se inventa un valor. Las raciales, pasivas y profesiones observadas se identifican sin confundir sus estadísticas con daño.

El informe conserva los textos originales y muestra el resultado del modelo; ya no añade debajo el fallo de un lector genérico que no corresponde a esa familia. Incluye salud máxima y solo informa del sello activo para paladines.

## Lectura de las cifras durante el combate

Se retiran los signos `~` y `≈` del comienzo de la cifra en la barra: con el tamaño pequeño podían parecer daño negativo. Una lectura pendiente de actualizar se ve como `18*`; una aproximación con arma como `55e`; y una cantidad base sin efecto adicional como `110+`. El tooltip explica los estados fuera de combate. Los informes conservan la notación de los modelos.

Los rangos como `3–10` siguen siendo un mínimo y un máximo, no daño negativo. El renderizado también rechaza resultados realmente negativos, no finitos o con rangos invertidos; no los convierte en positivos ni muestra un cero inventado.

## Familias de las nueve clases

Se mantienen los modelos del paladín y se añaden familias para pícaro, druida, sacerdote, guerrero, mago, brujo, cazador y chamán. Cada rango se descubre por el nombre publicado por el cliente; las cantidades se leen de su descripción actual. No se importa una tabla de daños de Classic, TBC o WotLK.

| Clase | Modelos añadidos |
| --- | --- |
| Pícaro | Ataques con arma, Mutilar, Garrote, venenos con cantidad explícita y remates con tabla por puntos de combo. |
| Druida | Daño y sanación de hechizos, efectos iniciales + periódicos, ataques ferales, remates y Espinas. |
| Sacerdote | Daño, curaciones, Renovar, escudo, Nova Sagrada/Penitencia, Peste devoradora y Rezo de alivio. |
| Guerrero | Ataques con arma, daño directo, Desgarrar, porcentaje explícito de AP para Sed de sangre y fórmula legible de Ejecutar. |
| Mago | Daño directo, inicial + periódico, canales, daño de área por objetivo y absorciones. |
| Brujo | Daño directo/periódico, drenajes, Transfusión de vida, Cauce de salud y Resguardo de las Sombras. |
| Cazador | Ataques a distancia/cuerpo a cuerpo, picaduras, trampas y Aliviar mascota. |
| Chamán | Hechizos directos, sanación, efectos periódicos/tótems, Golpe de tormenta y escudos reactivos. |

Puntos de combo, ira, daño a distancia, cambio de objetivo y cambio de forma también solicitan recálculo. Sin puntos de combo legibles, un remate no conserva el valor correspondiente a otro número de puntos. Cambiar de forma invalida las asociaciones anteriores de los botones.

Las cantidades se distinguen en la etiqueta:

- `120/12s`: total periódico por objetivo durante 12 segundos.
- `20/t`: cantidad por tick; el intervalo está en el tooltip. No se supone el número de ticks.
- `25+40/8s`: golpe inicial y efecto periódico separados.
- `25 | 35`: daño y sanación separados, explicados en el tooltip.
- `55e`: aproximación usando daño actual del arma; no incorpora la normalización interna de ataques especiales.
- `110+`: base del remate sin conversión no modelada de energía adicional.
- `*` al final: lectura anterior pendiente de actualizar; no se usa para un remate con puntos desconocidos ni para Ejecutar con ira/coste ilegibles.

[CLASS_COVERAGE.md](CLASS_COVERAGE.md) detalla las limitaciones y las fuentes oficiales. Estas familias no equivalen a todas las habilidades y condiciones del juego verificadas. Los informes recibidos cubren las nueve clases, principalmente sus habilidades iniciales. Hay pruebas con esos textos reales y otras sintéticas, identificadas por separado; aún falta verificar la actualización dentro del juego y ampliar rangos, talentos y habilidades avanzadas.

## Modelos del paladín conservados

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

`*` al final indica la última estimación legible, pendiente de actualizar. La caché de Sentencia es independiente por ID/rango de sello: si se confirma un rango sin cantidades conocidas, se oculta el número anterior. Cambiar de casilla, habilidad o página también invalida los datos correspondientes.

No se crean etiquetas protegidas ni se escanea GameTooltip en combate. Si recargas durante una pelea, los botones que todavía no tenían etiqueta esperan hasta salir. No se leen combat logs ni se reconstruyen valores secretos.

## Límites de los cálculos

Son estimaciones antes de mitigación, crítico y sobrecuración. No se añaden coeficientes de poder de hechizos o talentos que el cliente no describa y el modelo no contemple. Los procs se reflejan cuando modifican entradas legibles del cálculo.

No se modela la amplificación del perjuicio de Cruzado sobre el enemigo, la probabilidad de cada proc, la condición de aturdimiento de Sentencia de Orden ni el total de daño de todos los objetivos. Descripciones con varias cantidades del mismo tipo sin una regla clara se dejan sin estimación.

Los informes de las nueve clases corresponden a Forever 1.60.1 / build 70862 / esMX. `tests/forever-classes.lua` comprueba sus descripciones y estadísticas; recursos, cambios de aura y salud máxima se simulan explícitamente. Ejecutar estas pruebas no reemplaza probar la actualización dentro del juego. La lista de familias no equivale a una certificación de todas las habilidades, talentos, traducciones o builds.

## Instalación

Descomprime `dist/damage.reader.skill-0.6.2.zip` dentro de `Interface/AddOns`, reemplazando la carpeta `damage.reader.skill`. El archivo `damage.reader.skill.toc` debe quedar directamente dentro. Ejecuta `/reload` fuera de combate y confirma `/drs status`: versión 0.6.2.

Para verificar este cambio: prueba un ataque directo y uno periódico de tu clase, cambia de rango y repite en combate. Para pícaro/druida, comprueba remates con 0, 1 y 5 puntos de combo y al cambiar de objetivo. Para guerrero, comprueba Ejecutar con distintos niveles de ira. Los casos originales de Rectitud rango 2 y Furia siguen incluidos. Si falta un valor, `/drs report` incluye ahora el libro de hechizos completo disponible, además de las barras.

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
lua5.1 tests/forever-classes.lua
lua5.1 tests/combat.lua
lua5.1 tests/paladin-ranks.lua
lua5.1 tests/classes.lua
lua5.1 tests/display.lua
```

Las suites cubren las ocho clases nuevas y sus eventos de combate, el informe original, rangos desconocidos previamente, Furia, aislamiento de Sentencia por rango, cambio de botones, datos protegidos, libro moderno/clásico, cantidades de daño/sanación/maná/absorción y regresiones de combate. Las pruebas indican qué datos vienen de informes reales y cuáles son sintéticos; no certifican todos los rangos ni el comportamiento del cliente en vivo.

[Descripción oficial del paladín de Forever](https://news.blizzard.com/en-us/article/24302099/world-of-warcraft-forever-class-deep-dives-paladin): referencia de las familias y de los efectos separados de Furia. Sus valores pueden cambiar; el addon toma las cantidades del cliente.

[Documentación de las APIs de libro de hechizos del cliente Blizzard](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellBookDocumentation.lua): referencia de la interfaz moderna, con fallback a la clásica y comprobación de disponibilidad.

## Paquete y publicación

`python3 scripts/package.py` genera el ZIP instalable en `dist/`, incluyendo solo los archivos del addon y documentación de uso/licencia. [Preparación para CurseForge](docs/curseforge/submission-checklist.md): campos, descripción, notas y pendientes concretos. Todavía no se ha publicado esta versión en CurseForge.
