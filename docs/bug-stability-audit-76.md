# Auditoría de estabilidad de Eagle — build 76

**Actualización posterior a la entrega:** el usuario reportó un cierre/reinicio al intentar Hide Dock en la 76. Esa función no debe considerarse resuelta por las pruebas locales de esta auditoría. La investigación y las correcciones posteriores están en [Hide Dock, build 77](hide-dock-77.md).

8 de septiembre de 2026. Continuación del build 75. Se revisaron de nuevo los **13 issues y sus 29 comentarios**, incluidos abiertos y cerrados, mediante la API de GitHub con paginación y comprobación del número de comentarios. Se consultaron los 11 adjuntos: 10 se recuperaron y uno devuelve HTTP 404. También se consultaron las tres referencias de código de #6.

**Resultado:** Release 1.0.3 (76) compilado; 23 verificadores pasan. Hay correcciones confirmadas en la lógica de passcode y en el diagnóstico de Prepare. Los reinicios históricos y los resultados visuales en los dispositivos afectados siguen pendientes de evidencia física. El estado cerrado de GitHub no se considera prueba de funcionamiento.

- [IPA sin firma, build 76](/Users/leonardobaptiste/Documents/Codex/Eagle-Beta11/build/Eagle-1.0.3-76-unsigned.ipa)
- [Resultados de las pruebas](/Users/leonardobaptiste/Documents/Codex/Eagle-Beta11/build/stability-audit-20260908/test-results.json)
- [Log Release](/Users/leonardobaptiste/Documents/Codex/Eagle-Beta11/build/stability-audit-20260908/release-build.log)
- [Cambios de producción respecto al build 75](/Users/leonardobaptiste/Documents/Codex/Eagle-Beta11/build/stability-audit-20260908/changes-since-build75.patch)
- [Issues y comentarios completos consultados](/Users/leonardobaptiste/Documents/Codex/Eagle-Beta11/build/stability-audit-20260908/issues-full.json)
- [Adjuntos, procedencia y SHA-256](/Users/leonardobaptiste/Documents/Codex/Eagle-Beta11/build/stability-audit-20260908/evidence/manifest.json)

## Lista exhaustiva por issue

### #1 — Reinicios al preparar iPhone 16 / iOS 18.5

[Issue #1](https://github.com/leonardob8777-bit/Eagle/issues/1), cerrado, cinco comentarios. **Pendiente: causa del reinicio en hardware.**

El texto identifica iPhone17,3, iOS 18.5 y build 35; los comentarios añaden repetición en Beta 9 y el bloqueo temporal de esa combinación. El log pegado procede de la sesión posterior al reinicio: los mensajes de XPF y de YouTube no permiten atribuir el fallo a una etapa concreta.

Se abrió el ZIP adjunto y se analizó su archivo IPS completo. Es un Jetsam, tipo 298, para iPhone17,3 / 22F76. El proceso marcado con `per-process-limit` es `ShortcutsTopHitsExtension`; Eagle/Lara no figura como proceso eliminado. SpringBoard aparece sin razón de terminación. Las fechas internas están censuradas y el nombre del archivo apunta a febrero, por lo que no se puede correlacionar ese evento con los intentos descritos en agosto. No demuestra un kernel panic ni identifica la causa de los reinicios de Eagle.

Se verificó y preservó la serialización existente: ninguna entrada a DarkSword hasta terminar la limpieza anterior, rechazo de Prepare simultáneo y cuarentena si falla la limpieza. **Resuelto en el diagnóstico local:** el diario ya no anuncia entrada a DarkSword durante una limpieza todavía pendiente; ahora registra el fallo terminal cuando la limpieza aborta. La prueba con la función de producción falló antes del cambio y pasa después.

**Prueba física necesaria:** en una futura sesión expresamente autorizada, iPhone 16 / iOS 18.5 (22F76), instalación directa firmada y build identificado. Registrar hora, último checkpoint del intento y resultado de Prepare. Si ocurre un reinicio espontáneo, conservar el IPS coincidente —panic-full, ResetCounter o Jetsam— y el diario del mismo intento. No se ejecutó esa sesión, no se provocó ningún reinicio y no se cambió la política pública de compatibilidad.

### #2 — Prepare reinicia; Collections no cambia el passcode

[Issue #2](https://github.com/leonardob8777-bit/Eagle/issues/2), cerrado, dos comentarios. **Pendiente: reproducción integral en el iPhone reportado.**

El reporte identifica iPhone 16 / iOS 18.5 (22F76), Beta 9; el diagnóstico pegado corresponde al build 50. El enlace al diagnóstico externo devuelve **404**. Se revisó el texto que permanece en el cuerpo del issue. No contiene el paquete de passcode, la lista de archivos de TelephonyUI ni la sesión que falló.

**Ya resuelto y preservado en el código:** reconocimiento de los diez nombres de dígito, incluyendo `0.png`–`9.png` en la raíz y el formato `other-2-N--dark.png`, sin confundir su marcador `2` con el número. También se preservó la restauración verificada y el rollback del destino cuya escritura falla parcialmente.

**Resuelto con evidencia local en esta ronda:**

- El editor aceptaba un dígito vacío y podía anunciar éxito tras una escritura sin efecto. Ahora rechaza datos vacíos, compara los bytes escritos y recupera la imagen previa si falla. Si también falla la recuperación, informa de ello y conserva la copia original para Restaurar.
- Collections podía sustituir originales por bytes de un tema al aparecer otra variante de archivo. Ahora conserva el primer original de cada ruta y añade las variantes nuevas. También conserva variantes temporalmente ausentes, rechaza una copia previa ilegible y valida las entradas antes de tocar el archivo de respaldo.
- Collections aceptaba imágenes/copias vacías; una ruta duplicada provocaba un cierre por `Dictionary(uniqueKeysWithValues:)`. Imágenes, originales y restauraciones se validan antes de la primera escritura. Una copia faltante ya no provoca escrituras intermedias seguidas de rollback.

Las reproducciones antes/después usan las funciones de producción, archivos temporales reales, plists y fallos de escritura inyectados. Cubren diez dígitos, cambio de tema, bytes vacíos, escritura sin efecto, escritura parcial, fallo de recuperación, copia dañada, variantes añadidas/ausentes, duplicados y error de persistencia. No se afirma que todos estos fallos fueran la causa del reporte histórico.

**Prueba física necesaria:** después de confirmar Prepare por separado en la combinación reportada, usar un paquete conocido de diez imágenes. Registrar las rutas y bytes antes/después, comprobar los diez dígitos visibles, aplicar un segundo tema, usar Deshacer/Restaurar y confirmar los originales. Probar una sola operación a la vez. La visualización real de la pantalla de código y la escritura VFS nativa no se certifican con estas pruebas de escritorio.

### #3 — Compatibilidad con iOS 26.6

[Issue #3](https://github.com/leonardob8777-bit/Eagle/issues/3), cerrado, tres comentarios. **Pendiente, fuera del alcance autorizado: ampliación de compatibilidad.**

Los comentarios confirman que la petición es iOS 26.6, con mención de iPhone 16 Pro. La matriz actual rechaza versiones de iOS 26 posteriores a 26.0.1; su regresión pasa. No hay un fallo de una función existente dentro del rango admitido que justifique quitar ese límite.

**Prueba física:** no corresponde ejecutar Prepare como parte de esta auditoría. El soporte solicitado necesitaría otro trabajo de compatibilidad y validación del motor en esa combinación, previamente autorizado.

### #4 — Desbloquear iPhone 16 con iOS 18.5

[Issue #4](https://github.com/leonardob8777-bit/Eagle/issues/4), cerrado, tres comentarios. **Ya resuelto y preservado: el bloqueo de acceso descrito.**

La matriz pública permite iPhone17,3 / iOS 18.5 por la ruta `stableLegacy`. Se ejecutaron las matrices pública y privada: el laboratorio conserva su requisito de modelo/build exacto y no amplía otras combinaciones. No se reintrodujo el bloqueo ni se modificó el motor.

**Límite y prueba física:** esto confirma la admisión por el código, no la ausencia de reinicios. La ejecución física de Prepare sigue pendiente bajo #1 y #2. En el dispositivo reportado también debe comprobarse que la pantalla de acceso permite continuar.

### #5 — Borde superior de Island ausente; comentario sobre Dock

[Issue #5](https://github.com/leonardob8777-bit/Eagle/issues/5), cerrado, tres comentarios. **Pendiente: ajuste visual confirmado en hardware.**

Se inspeccionaron las dos fotografías. La de Island muestra el contorno cian abajo y a los lados, sin contorno superior. La de Dock muestra un contorno alrededor de cinco iconos; por sí sola no establece un tamaño correcto ni una causa de recorte. El reporte identifica iPhone 14 Pro Max / iOS 18.3 (22D60), build 59.

El log completo registra aplicaciones con `core=148,13,134,39`. El árbol actual ya incorpora un perfil posterior para iPhone15,3 con origen vertical 10. Se conservó. Las pruebas de geometría, sombra y capas locales pasan; esto acredita la lógica y la existencia del cambio, pero no su alineación con el recorte físico de la pantalla.

**Prueba física necesaria:** iPhone 14 Pro Max / iOS 18.3, zoom de pantalla indicado, aplicar Glow cian a Island y después a Dock por separado. Comparar fotografía frontal externa y captura de pantalla completa, conservar log con modelo/escala/frame, y comprobar borde superior, centrado, recorte y restauración. No se hicieron ajustes adicionales de posición o tamaño.

### #6 — Atribución de Cyanide / 0xjohnny

[Issue #6](https://github.com/leonardob8777-bit/Eagle/issues/6), cerrado, un comentario. **Ya resuelto y preservado: la atribución solicitada.**

Se comprobaron los commits enlazados de Cyanide (8 de mayo de 2026) y Lara (29 de mayo de 2026), así como el tercer enlace al código de Cyanide. El aviso ya está en la cabecera de OTA, en los agradecimientos del README y en el aviso de licencia. La IPA 76 contiene `NOTICE_Cyanide_OTA.md`, con el crédito a 0xjohnny/Cyanide.

No se modificaron atribuciones ni código OTA. **Prueba física necesaria: ninguna** para verificar la presencia de estos textos; se verificaron fuente y paquete generado. Esto no constituye una evaluación jurídica de licencias.

### #7 — Añadir un desactivador de Screen Time

[Issue #7](https://github.com/leonardob8777-bit/Eagle/issues/7), cerrado, sin comentarios. **Pendiente de validación funcional; la petición de implementación queda fuera de esta ronda.**

El issue solo pide la función, sin reproducción de un error. El árbol actual ya contiene `ScreenTimeView` y la operación nativa correspondiente; se preservaron, sin ampliar sus capacidades ni ejecutar cambios del sistema.

**Prueba física:** el issue no aporta modelo, iOS ni resultado esperado suficientemente detallado para definir una reproducción de fallo. Si se aporta un error de esa función existente, se necesitará esa combinación y la verificación de aplicar/restaurar su configuración. No se ha confirmado aquí su funcionamiento en hardware.

### #8 — Compatibilidad con LiveContainer

[Issue #8](https://github.com/leonardob8777-bit/Eagle/issues/8), cerrado, dos comentarios. **Pendiente, fuera del alcance: compatibilidad con otro entorno de ejecución.**

Se revisaron la pregunta, la respuesta del mantenedor —instalación mediante firma directa— y el agradecimiento posterior. No se aporta un fallo reproducible bajo el método admitido. Se conservó la instalación directa y no se añadió una ruta LiveContainer.

**Prueba física:** no aplica a una corrección de estabilidad de esta ronda. Para un futuro reporte se debe distinguir LiveContainer de una IPA firmada directamente y aportar modelo, iOS, método y log de la operación que falla.

### #9 — Dock forzado a azul; Purple/Pulse no cambia

[Issue #9](https://github.com/leonardob8777-bit/Eagle/issues/9), cerrado, un comentario. **Pendiente: confirmación visual y transporte real.**

Se revisaron los tres logs completos. Dos aplicaciones registran iPhone15,2 —iPhone 14 Pro— / iOS 17.5.1, `mode=2`, `rgb=158,64,255`, tanto en la solicitud Swift como al entrar al código nativo. El log no respalda afirmar que la selección de la interfaz se hubiera convertido en azul antes de llegar al motor. El tercer archivo contiene solo el arranque.

**Ya resuelto y preservado en la lógica local:** el umbral de violeta `red >= 150`, la clasificación correcta de amarillo introducida en build 75, los colores separados por superficie y la instalación/verificación de Pulse. Las funciones de producción pasan con UIKit/CALayer reales del simulador: los cuatro presets y cuatro familias adicionales conservan su color, Glow permanece estático, Pulse cambia entre fotogramas, reaplicar deja una sola capa y una animación descartada no anuncia éxito.

**Prueba física necesaria:** iPhone 14 Pro / iOS 17.5.1 con el canal que permite Pulse. Aplicar sucesivamente cian, violeta, Glow y Pulse al Dock; grabar varios segundos del efecto, comprobar el color fuera de Eagle y Restaurar. Adjuntar log de esa misma operación. El transporte local simulado no prueba la ejecución remota en SpringBoard.

### #10 — Posición/tamaño de Island, Glow/Pulse, Dock y Laboratorio

[Issue #10](https://github.com/leonardob8777-bit/Eagle/issues/10), abierto, cinco comentarios. **Pendiente: geometría y animación físicas.**

Se revisaron las tres capturas y todos los comentarios: iPhone 16 demasiado bajo, iPhone 15 Pro Max desalineado, petición de mayor altura, Glow/Pulse frente a Rainbow, Dock demasiado grande, acceso a Laboratorio y breadcrumb. Una captura con música muestra el halo compacto dentro de una Island expandida; una imagen estática no permite medir la progresión de Pulse. Otra muestra un mensaje de verificación, que por sí solo no confirma el resultado visual.

- Se preservó exactamente el desplazamiento autorizado de **−0,50 puntos** en iPhone16,2 e iPhone17,3, tanto Aura como Gallery. La prueba ejecuta la función de producción sobre 12 identificadores, dos superficies y 29 anchuras; mantiene ancho, alto y centrado horizontal y no altera otros modelos.
- Se preservaron los tamaños y las rutas de Glow, Pulse, Rainbow y Gallery. Las pruebas locales de Pulse, sombra y animación pasan; el halo compacto sigue teniendo su límite de adaptación a música/temporizadores documentado en el producto.
- **Ya resuelto y preservado en código:** las rutas y la búsqueda de Laboratorio, verificadas por los tres canales y por búsquedas en inglés/español. No se añadieron experimentos ocultos ni capacidades nuevas.
- El editor de texto breadcrumb solicitado no existe en esta forma; el árbol tiene una opción distinta de ocultar breadcrumbs. No se convirtió esa petición en una función nueva.

**Prueba física necesaria:** iPhone 16 e iPhone 15 Pro Max, indicando iOS/build y zoom. Fotografiar/capturar Glow y Pulse con Island compacta, comprobar varios ciclos de Pulse y registrar qué ocurre al expandir música. Comparar Dock en reposo y con sus iconos habituales. Para el tamaño del Dock hace falta la medida/imagen esperada y la escala real antes de justificar otro cambio. La navegación de Laboratorio puede comprobarse sin ejecutar sus operaciones nativas.

### #11 — Ocultar elementos; Dock flotante y más iconos

[Issue #11](https://github.com/leonardob8777-bit/Eagle/issues/11), abierto, un comentario. **Pendiente, fuera del alcance: las ampliaciones solicitadas.**

Se revisaron la lista de peticiones y la respuesta del mantenedor sobre Hide Dock. El issue no describe un fallo concreto de los controles actuales. Se preservaron las funciones existentes de fondo del Dock y capacidad; pasan las pruebas de exclusión de sesión, segundo plano, capacidad inválida e inicialización fallida. Esto no confirma variantes flotantes ni todas las configuraciones físicas.

**Prueba física:** no hay una reproducción de error aportada. Para auditar un control existente se necesita modelo/iOS, número de iconos, acción exacta y resultado visible, incluyendo restauración. Las nuevas variantes de ocultación o capacidad no se implementaron.

### #12 — Soporte de iOS 26.0

[Issue #12](https://github.com/leonardob8777-bit/Eagle/issues/12), abierto, sin comentarios. **Ya resuelto y preservado en la matriz: aceptación de iOS 26.0/26.0.1. Pendiente: validación nativa por dispositivo.**

La matriz admite esas versiones en dispositivos sin MIE; las pruebas verifican los límites y mantienen el bloqueo de versiones posteriores. El issue no aporta modelo, error ni operación fallida. Permitir Prepare no implica que todas las funciones remotas de iOS 17/18 estén verificadas en iOS 26.

**Prueba física necesaria:** modelo y build concretos de iOS 26.0, resultado de Prepare y de la función existente que se quiera validar, cada una por separado. No se amplió el motor ni se modificaron sus límites.

### #13 — Temas de Control Center, acceso a Laboratorio y breadcrumb

[Issue #13](https://github.com/leonardob8777-bit/Eagle/issues/13), abierto, tres comentarios. **Ya resuelto y preservado en código: acceso a las herramientas existentes de Laboratorio. Pendiente/fuera de alcance: las nuevas funciones.**

Se revisaron el texto y los comentarios sobre un editor breadcrumb y la respuesta del mantenedor. La sección de Laboratorio, su entrada a Ajustes avanzados y sus resultados de búsqueda están conectados al canal experimental. El verificador ejecuta la política y búsqueda de producción y comprueba las conexiones de navegación; los canales Stable/Beta conservan sus restricciones. No se habilitaron todos los experimentos por el solo hecho de activar el canal.

**Prueba física necesaria:** para confirmar un fallo de navegación todavía presente, abrir Inicio con el canal Laboratorio, entrar en la sección y buscar «Laboratorio»/«RemoteCall», sin aplicar cambios nativos. Si falta una herramienta concreta, identificarla y aportar versión de Eagle y pantalla. Los temas de Control Center y la edición del texto breadcrumb son peticiones nuevas, sin implementación en esta ronda.

## Validación y límites

Los 20 verificadores existentes se ejecutaron antes de modificar su área correspondiente. Pasaron. Se añadieron tres verificadores y se amplió el de transacciones de passcode, conservando sus casos anteriores. Los escenarios nuevos se reprodujeron primero contra el código del build 75 y volvieron a ejecutarse después de cada corrección.

- Passcode: recuperación, transacciones de Collections, escritura del editor y persistencia de originales. Los archivos/plists son reales y temporales; la escritura nativa se simula para inyectar fallos y comprobar bytes.
- Prepare/sesiones: matrices pública y laboratorio, punteros, exclusión de propietarios, ciclo de segundo plano, capacidad del Dock y orden de limpieza/diario de Prepare. No se llama al kernel ni a un SpringBoard físico.
- Interfaz/medios: rutas de Laboratorio, selección/filtros de Gallery, geometría de #10, sombras, entrada exclusiva de Island, ZIP truncados/ZIP64/tamaños, integridad de los fotogramas y animación con Reduce Motion.
- UIKit real en el simulador ya abierto, iOS 26.5: Pulse de Island, paleta/overlay de Dock, renderizado de halo de Dock Gallery y animación de Island Gallery. RemoteCall se sustituye por despacho local. El simulador no reproduce el recorte físico ni el transporte privado de los modelos reportados.
- Release genérico iOS/arm64e, Xcode 26.6 (17F113): **BUILD SUCCEEDED**. Se conservan advertencias de nullability y conversión de enumeraciones en código nativo que esta ronda no modificó; están registradas en [el listado de advertencias](/Users/leonardobaptiste/Documents/Codex/Eagle-Beta11/build/stability-audit-20260908/release-warnings.txt).

## Preservación y entrega

Antes de editar se guardaron el diff binario, el estado del índice y el contenido/hash de 328 rutas del árbol. El historial base sigue en `8031eb5`; no hubo reset, stash, checkout, commit, push ni publicación. Las modificaciones nuevas de producción afectan únicamente al administrador de Prepare, los dos archivos de passcode/Collections y el número de build. Los cambios previos de interfaz, recursos eliminados, recursos nuevos y motor nativo se conservaron. El [manifiesto final](/Users/leonardobaptiste/Documents/Codex/Eagle-Beta11/build/stability-audit-20260908/preservation-check.json) permite verificarlo.

La IPA contiene 1.0.3 (76), mide **18.125.197 bytes** y su SHA-256 es:

```text
c1cfbf0c2e89590908f736f30010d9fd51cbdeebde7deba5951ce34254844fbd
```

Se comprobaron la integridad ZIP, la versión, el aviso Cyanide y la ausencia de firma en **los tres Mach-O** —Eagle, libgrabkernel2 y libxpf—, sin `LC_CODE_SIGNATURE`, `_CodeSignature` ni perfil de aprovisionamiento. La retirada de firmas se hizo solo en la copia temporal de empaquetado. [Verificación del paquete](/Users/leonardobaptiste/Documents/Codex/Eagle-Beta11/build/stability-audit-20260908/ipa-verification.json).

No se instaló nada en el iPhone, no se reinició el dispositivo, no se importó a Vendor y no se publicaron, cerraron ni comentaron issues. Las pruebas físicas descritas son trabajo pendiente para una sesión futura autorizada.
