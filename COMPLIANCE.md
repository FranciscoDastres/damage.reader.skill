# Compliance y límites del proyecto

## Decisiones de implementación

- El addon es código nuevo bajo el nombre `damage.reader.skill`.
- No se copian archivos, tablas de daño, nombres internos ni fragmentos de DrDamage.
- No se redistribuyen archivos de Blizzard, texturas del juego ni código ofuscado.
- No se usan macros, automatización de clics, lectura de memoria, ejecutables externos ni comunicación con servidores.
- No se usa el combat log para tomar decisiones en combate.
- El overlay es informativo y se oculta cuando el cliente no permite leer de forma segura la acción o el hechizo.
- No se solicita dinero, donaciones, publicidad ni datos personales dentro del juego.

## Alcance de compatibilidad

La versión actual apunta únicamente a WoW: Forever y a su API moderna. El manifiesto usa `Interface: 16001` y el código evita las funciones antiguas de Classic que no corresponden al cliente moderno.

La compatibilidad real debe confirmarse en la build exacta que ejecuta el usuario. Un launcher puede cambiar el nombre de la carpeta del producto o actualizar el número de interfaz; si eso ocurre, el valor del `.toc` tendrá que actualizarse junto con una prueba dentro del cliente.

## Referencias de política

El desarrollo sigue la política pública de Blizzard para addons de interfaz: código visible y gratuito, sin publicidad ni solicitudes de donación en el juego, sin impacto deliberado en el rendimiento y respetando los Términos de Uso y el EULA aplicables.

El hecho de que un addon sea técnicamente compatible no constituye una autorización legal de Blizzard ni una garantía de que una futura actualización mantendrá todas las APIs. Blizzard puede cambiar o limitar funcionalidades de addons.
