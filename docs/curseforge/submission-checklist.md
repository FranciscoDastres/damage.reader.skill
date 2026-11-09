# Preparación de CurseForge — 0.6.2

Estado: código y paquete preparados para pruebas; no enviado a CurseForge. Se usa la estructura de documentación del proyecto SafeEnchanter, sin copiar sus recursos gráficos ni afirmar compatibilidad TBC.

## Preparado

- Nombre propuesto: `Damage Reader Skill` (sin versión en el nombre).
- Resumen: [summary.txt](summary.txt).
- Descripción en inglés y español: [description.md](description.md).
- Notas del archivo: [release-notes-0.6.2.md](release-notes-0.6.2.md).
- Licencia existente: MIT, incluida en el paquete.
- Generador: `python3 scripts/package.py`.
- ZIP instalable: `dist/damage.reader.skill-0.6.2.zip`; una carpeta `damage.reader.skill/`, con el TOC directamente dentro. Sin `.git`, entornos, pruebas ni archivos de preparación de publicación.
- Juego: World of Warcraft; clase de proyecto: AddOns. Categoría sugerida: Combat; Action Bars como adicional si figura en el formulario.
- Fuente: https://github.com/FranciscoDastres/damage.reader.skill
- Incidencias: https://github.com/FranciscoDastres/damage.reader.skill/issues

## Falta antes de enviar

1. Probar 0.6.2 en el cliente real y completar [la lista de pruebas](../../tests/IN_GAME_CHECKLIST.md). Las pruebas Lua simuladas pasan por separado; no demuestran funcionamiento en el juego.
2. Crear un icono original PNG cuadrado de al menos 400×400. No hay uno preparado en este repositorio. Añadir capturas de las etiquetas corregidas es recomendable, no un requisito general de los addons.
3. Revisar la cuenta/proyecto en el portal de autores: disponibilidad del nombre, proyecto existente o nuevo y selección exacta de la versión Forever compatible con Interface 16001. El selector autenticado no se ha inspeccionado; no marcar Retail/TBC ni otra versión por semejanza.
4. Elegir Beta mientras se valida, o Release después de validar, cargar ZIP y notas, y atender la moderación. Preparar archivos no equivale a una publicación aprobada.

La evidencia de las nueve clases es suficiente para corregir los casos reportados, pero faltan rangos altos, talentos/procs y habilidades avanzadas. Esos límites deben seguir visibles en la descripción; no ofrecer “todas las habilidades verificadas”.

## Fuentes oficiales revisadas

- [Crear y enviar un proyecto](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project): campos, descripción en inglés, ZIP, tipo de archivo, versiones y revisión.
- [Guía de envío](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips): nombre, icono original PNG de al menos 400×400 y capturas.
