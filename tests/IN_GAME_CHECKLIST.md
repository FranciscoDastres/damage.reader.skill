# Validación dentro de Forever — 0.6.2

Pendiente: esta lista requiere el cliente real. Los valores siguientes corresponden a los informes recibidos; cambiar arma, nivel o equipo puede cambiar las cifras.

- [ ] Instalar el ZIP, `/reload` fuera de combate y comprobar `/drs status`: 0.6.2. Sin errores Lua.
- [ ] Mago: Escarcha 19, Explosión 28, Bola de Fuego rango 1 `19+2/4s`, rango 2 `32+3/6s`.
- [ ] Pícaro: Golpe siniestro `8e` con el arma del informe; Eviscerar vacío con 0 puntos y 8/13/18/23/28 con 1–5. Cambiar objetivo no conserva el remate anterior.
- [ ] Guerrero: Golpe heroico `16e` con el arma del informe.
- [ ] Cazador: Raptor `10e` y Disparo automático 11 con el arma del informe.
- [ ] Druida: Cólera 15 y Toque de sanación 44; verificar cambio de forma y página de acciones.
- [ ] Chamán: Relámpagos 16 y Ola de sanación 39.
- [ ] Sacerdote: Punición 15 y Sanación inferior 51.
- [ ] Brujo: Descarga de las Sombras 13; Piel de demonio no inventa daño/sanación por uso.
- [ ] Paladín: Golpe Sagrado 20, Luz Sagrada rango 3 156; Imposición de manos coincide con salud máxima actual. No se recibió la salud máxima en el informe original.
- [ ] Sentencia vacía sin sello; Rectitud rango 2 `3–11` y Sentencia 34 al activarlo; Furia 6 y Sentencia 30. Cambiar sellos y rangos también en combate.
- [ ] Atacar muestra promedio de mano principal. Lanzar del pícaro 7 con su arma del informe. Disparar no inventa daño sin varita; equipar una y revisar la cifra publicada por el cliente.
- [ ] Cambiar equipo/estadísticas actualiza las cifras; en combate no aparecen signos que parezcan daño negativo ni cantidades del contexto anterior.
- [ ] Pasivas, profesiones y raciales del informe quedan identificadas sin etiquetas numéricas engañosas.
- [ ] Generar `/drs report` si falla algo; conservar el texto exacto junto al resultado esperado y observado.

No marcar casillas con pruebas Lua: registrar aquí únicamente comprobaciones hechas en el juego.
