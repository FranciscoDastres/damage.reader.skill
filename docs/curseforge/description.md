# Damage Reader Skill

See estimated damage, healing and absorption directly on Blizzard action buttons. Damage Reader Skill reads supported spell descriptions and current character statistics, with spell families for all nine WoW Forever classes.

- Direct spells show their average amount per target.
- Periodic effects show a total and duration, or an amount per tick.
- Initial damage and damage over time appear separately.
- Weapon attacks use current weapon damage; combo finishers use the readable combo-point table.
- Paladin Judgment follows the confirmed active seal and its rank.
- Estimates refresh when readable stats, equipment, resources and auras change, including during combat.

Examples: `19+2/4s` means 19 initial damage plus 2 over four seconds. `16e` is a weapon-based approximation. `*` marks a previous readable estimate waiting to refresh; `+` marks a base amount without an unmodeled extra effect. Hover outside combat for details.

Use `/drs on` or `/drs off` to toggle labels, `/drs refresh` to refresh them, `/drs status` to check the version, and `/drs report` outside combat to collect diagnostics.

Designed for **WoW Forever, Interface 16001**. English and Spanish spell-family names are supported. Current real-client reports are from esMX, build 70862. Estimates are before mitigation, critical hits and overhealing. They are not DPS or guaranteed combat results. Support for nine classes does not mean every spell, rank, talent or proc has been verified. Unknown or protected values are not reconstructed. Utility spells and passive statistics do not display invented damage.

The addon is standalone. It does not cast spells, automate gameplay, read combat logs or bundle DrDamage code or data.

## Español

Muestra estimaciones de daño, sanación y absorción en los botones de las barras de Blizzard. Lee las descripciones de habilidades reconocidas y las estadísticas disponibles del personaje, con familias para las nueve clases de WoW Forever.

Distingue daño inicial y periódico, remates por puntos de combo y Sentencia según el sello activo. Las aproximaciones de arma llevan `e`; `*` indica una lectura anterior pendiente de actualizar. No es DPS ni daño garantizado y no cubre todavía todas las habilidades, talentos o rangos.

Usa `/drs on`, `/drs off`, `/drs refresh`, `/drs status` y `/drs report`. El informe se genera fuera de combate. Destino: Forever, Interface 16001.
