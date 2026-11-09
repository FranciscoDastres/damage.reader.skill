# Cobertura de clases — v0.6.1

El addon reconoce familias por nombre (español/inglés), no por una lista incompleta de IDs de rango. `ClassData.lua` contiene el registro de las ocho clases nuevas; `Data.lua` conserva el registro del paladín. El libro de hechizos y las barras aportan los IDs de los rangos del personaje.

## Qué se calcula

| Tipo | Entrada necesaria | Unidad que se presenta |
| --- | --- | --- |
| Daño/sanación directa | Una cantidad o rango explícitos vinculados al efecto | Por objetivo; no se multiplican enemigos ni saltos. |
| Daño/sanación periódica o canalizada | Cantidad con duración o intervalo explícito | Total/duración o cantidad/tick. No se infieren ticks iniciales/finales. |
| Efecto inicial + periódico | Dos cantidades del mismo tipo, una directa y otra periódica | Componentes separados, como Bola de Fuego, Fuego lunar, Inmolar o Recrecimiento. |
| Daño y sanación | Dos cantidades explícitas de distinto tipo | Separadas. Nova/Penitencia según uso; Espiral de la muerte según sus dos efectos. |
| Absorción | Una cantidad explícita asociada a absorber | Capacidad del escudo; no daño ni sanación. |
| Ataque con arma | Fórmula de arma publicada + UnitDamage o UnitRangedDamage legible | Aproximación marcada con `e` al final, antes de mitigación. Sin AP duplicado ni normalización interna inventada. |
| Ambas armas | Texto explícito de ambas armas y dos rangos legibles | Aproximación; si no puede distinguir una bonificación por mano, no calcula. |
| Remate | Puntos legibles y fila correspondiente en la tabla del tooltip | Cantidad para los puntos actuales; cero/desconocidos/filas ausentes ocultan el valor. |
| Sed de sangre | Porcentaje de AP explícito + AP base y modificadores legibles | Daño del ataque; no suma curaciones posteriores. |
| Ejecutar | Daño base, tasa por ira extra, ira actual y costes públicos `minCost`/`cost` | Base + tasa × consumo opcional disponible. No presupone el umbral de salud del enemigo. |
| Drenaje/recursos | Cantidad explícita de vida, maná o energía ligada al efecto | Por activación o tick. Costes de vida/maná no se suman a la ganancia. |

Las habilidades de utilidad registradas no muestran daño. Las profesiones, invocaciones, resurrecciones, armadura, amenaza, cargas, alcances y costes no se convierten en daño del lanzamiento.

## Límites concretos

- La identidad de la clase no prueba una fórmula: si el texto cambia o contiene cantidades ambiguas, el addon explica el motivo en `/drs report` y no genera una cifra.
- No se incorporan coeficientes de otra expansión, tablas de talentos, DPS esperados, probabilidad de procs, resistencias/armadura enemigas ni críticos esperados.
- El daño de arma está marcado como aproximación porque las reglas de normalización de ataques especiales no se verificaron en este cliente. Las variantes de porcentaje según arma no se eligen sin evidencia.
- Un remate con conversión adicional de energía muestra únicamente la base con `+` al final. No se adivina la conversión ni se extrapola una fila de puntos ausente.
- No se comprueban condiciones del objetivo, por ejemplo congelación para Lanza de hielo, veneno para Mutilar o Inmolar para Incinerar. Se muestra la cantidad base descrita, sin inventar ese multiplicador.
- Llamas infernales, Quemadura de maná, Plan de contingencia, Embate con escudo e imbuciones condicionales de armas quedan registrados como pendientes de una fórmula específica. Sus autocostes, absorciones variables y condiciones requieren un informe real.
- Los saltos de cadenas, objetivos adicionales de áreas, cargas de escudos, acumulaciones de sangrado/veneno y ataques de mascotas no se totalizan. No se añaden etiquetas a la barra de mascotas en esta versión.
- Solo se dibuja sobre acciones de hechizos en las barras de Blizzard ya soportadas. Los venenos utilizados desde un objeto o una macro no se convierten automáticamente en acciones de hechizo.
- Las lecturas protegidas se respetan. Las estimaciones de remates o Ejecutar se ocultan cuando no se puede confirmar su recurso; el resto conserva `*` al final únicamente mientras su contexto siga siendo válido.

## Evidencia y pruebas

El único informe real disponible sigue siendo el del paladín de Forever 1.60.1 / 70862 / esMX. `tests/classes.lua` usa cantidades sintéticas y IDs arbitrarios para comprobar las reglas de cada clase, distintos rangos y el rechazo de datos ambiguos/protegidos. `tests/combat.lua` prueba los eventos y la etiqueta real del addon con un cliente simulado.

Falta comprobar cada clase dentro del juego. `/drs report`, fuera de combate, incluye clase, estadísticas, IDs, descripciones del libro y resultado/motivo por habilidad para contrastar lo que expone esa build.

## Fuentes de diseño

Se consultaron las descripciones oficiales de Forever para distinguir las familias nuevas y sus efectos. Los artículos no son una base de cantidades por rango; los valores se leen del cliente.

- [Pícaro y brujo — Blizzard](https://news.blizzard.com/en-us/article/24310968/world-of-warcraft-forever-class-deep-dives-rogue-and-warlock).
- [Cazador y druida — Blizzard](https://news.blizzard.com/en-us/article/24301515/world-of-warcraft-forever-class-deep-dives-hunter-and-druid).
- [Sacerdote y guerrero — Blizzard](https://news.blizzard.com/en-us/article/24301514/world-of-warcraft-forever-class-deep-dives-priest-and-warrior).
- [Mago y chamán — Blizzard](https://news.blizzard.com/en-us/article/24302097/world-of-warcraft-forever-class-deep-dives-mage-and-shaman).
- [APIs de unidades del cliente Blizzard](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua): puntos de combo, estadísticas, recursos y eventos.
- [Costes de hechizos del cliente Blizzard](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellSharedDocumentation.lua): `cost` incluye consumo opcional y `minCost` lo excluye. Si faltan estos campos, no se calcula Ejecutar.
