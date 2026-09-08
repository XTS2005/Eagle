# Revisión de errores — build 74

8 de septiembre de 2026. Alcance: errores de funciones existentes. No se añadieron funciones, no se cambiaron issues de GitHub ni se realizaron operaciones nativas en un iPhone.

## Lista de seguimiento

| Reportes | Error | Evidencia y resultado de esta revisión |
| --- | --- | --- |
| [#1](https://github.com/leonardob8777-bit/Eagle/issues/1), [#2](https://github.com/leonardob8777-bit/Eagle/issues/2), [#4](https://github.com/leonardob8777-bit/Eagle/issues/4) | Reinicios de Prepare en iPhone 16 con iOS 18.5 | El árbol actual ya serializa la limpieza de la sesión anterior antes de DarkSword y protege operaciones activas. Pasaron matrices de compatibilidad, validación de punteros, propiedad de sesiones y ciclo de segundo plano. No se confirmó la causa del reinicio antiguo; no se cambió el motor ni se bloqueó una combinación que el usuario considera funcional. Pendiente: evidencia física del build actual, con hora y etapa coincidentes con el reinicio. |
| [#2](https://github.com/leonardob8777-bit/Eagle/issues/2) | El passcode de un estilo no se aplica | Corregidos errores reproducibles al reconocer archivos: el marcador `2` de `other-2-5--dark.png` podía confundirse con el dígito, y `0.png`–`9.png` en la raíz de un paquete podían omitirse. Se comparte la misma interpretación entre el editor y Collections. No se afirma que estos errores expliquen cada instalación del reporte. |
| #2 y revisión de restauración | Restore anuncia éxito después de fallar | Ahora se propagan los errores de restauración, se rechazan copias vacías/ilegibles y se comprueban los bytes restaurados. Collections conserva sus originales cuando la restauración no se verifica. Si falla una escritura parcialmente, su destino también entra en rollback. |
| [#5](https://github.com/leonardob8777-bit/Eagle/issues/5) | Falta el borde superior en Island y Dock del iPhone 14 Pro Max | Ya existe un perfil específico para iPhone 14 Pro/Max. Se conservó sin retoques. Falta validación visual en iPhone 14 Pro Max/iOS 18.3 para distinguir posición, recorte y sombra. |
| [#9](https://github.com/leonardob8777-bit/Eagle/issues/9) | Dock azul y Purple/Pulse no cambia | El log adjunto muestra `rgb=158,64,255` tanto en Swift como al entrar al motor nativo, con `mode=2`: no respalda atribuir el fallo a una selección azul. El código actual ya separa colores por superficie e instala/verifica Pulse después de conectar la vista. Se conservó. Falta confirmación visual en iPhone 14 Pro/iOS 17.5.1, la combinación identificada en ese log. |
| [#10](https://github.com/leonardob8777-bit/Eagle/issues/10) | Aura baja/desnivelada en iPhone 15 Pro Max e iPhone 16 | Conservado el ajuste autorizado en build 73: −0,50 puntos, Aura Studio e Island Gallery, solo esos dos modelos. Pasó su regresión de geometría. Aún necesita validación física; no se aumentó el desplazamiento ni se alteró el tamaño. |
| #10 | Glow/Pulse y tamaño del Dock | Conservadas las correcciones existentes de Pulse y los tamaños actuales. No hay evidencia suficiente para justificar otro cambio visual general. Pendiente prueba en los modelos reportados. |
| #10 y #13 | Acceso a Laboratorio invisible | Ya corregido en build 71. Pasaron las pruebas actuales de búsqueda, rutas y restricciones por canal. |
| Revisión de estabilidad de Dock | Cambio de capacidad sin exclusión de sesión | Corregido: la operación mantiene la propiedad de su sesión hasta que termina, rechaza operaciones simultáneas/segundo plano/valores inválidos y no anuncia éxito si el transporte quedó inválido. Se eliminó la continuación tras una inicialización fallida. |

Las solicitudes de compatibilidad o funciones nuevas de #3, #6, #7, #8, #11, #12 y #13 quedan fuera de esta ronda. Las peticiones de breadcrumb, Control Center, más iconos o cambios de tamaño de #10 tampoco se implementaron. El estado cerrado/abierto de un issue no se usó como prueba de que el error esté resuelto.

## Validación

- Build Release iOS 74: correcto, sin firma de distribución; persisten advertencias del proyecto.
- `verify_passcode_recovery.py`: diez dígitos, variantes de nombres, copias originales, restauración parcial, fallos silenciosos y reintento; archivos temporales y escritura nativa simulada.
- `verify_passcode_transaction.py`: métodos de producción de Collections con fallos parciales en cada dígito, copia faltante y restauración sin efecto; comprueba rollback y rechazo de falso éxito.
- `verify_dock_capacity_operation.py`: acción de producción y bloqueo compartido con operación nativa suspendida; comprueba concurrencia, timeout, segundo plano, capacidad inválida e inicialización fallida.
- Regresiones existentes: matriz Prepare pública/laboratorio, punteros, propiedad de sesiones, segundo plano, exclusión de Island, sombra, Hide Dock Background, geometría #10 y rutas de Laboratorio.
- `git diff --check`: correcto.

Estas pruebas verifican lógica local y errores inyectados. No certifican el motor de acceso ni el resultado visual en dispositivos físicos. No se instaló el build ni se importó a Vendor.

## Seguimiento — build 75

- **#9, morado convertido a azul/cian:** el log adjunto `31579124/lara.log` confirma `rgb=158,64,255` al entrar al motor, con Pulse (`mode=2`). La función actual `eagle_dock_palette_color` ya contiene la corrección del umbral de Ultra Violet (`red >= 150`, antes `red > 160`). Su clasificación y la aplicación real al borde/sombra pasaron la prueba de UIKit. Se conservó esta corrección existente.
- **#9, Pulse sin efecto:** se ejecutó la función actual de instalación del overlay sobre vistas/capas reales del simulador. Se comprobó que cambia `presentationLayer.shadowOpacity` entre fotogramas, que Glow no tiene animación y que Pulse no se declara aplicado cuando se impide añadir su animación. Esto valida la lógica actual con transporte simulado; queda por confirmar el transporte real en el iPhone 14 Pro/iOS 17.5.1 del log.
- **Nuevo fallo de color confirmado durante esa prueba:** amarillo puro (`255,255,0`) seleccionaba naranja. La prueba falló antes del cambio y pasó después de evaluar amarillo antes de naranja. Es el único cambio al comportamiento nativo de esta ronda. Los cuatro presets incluidos y las familias roja, azul y naranja se conservaron.
- **#5, iPhone 14 Pro Max:** el log adjunto `31512088/lara.log` registra tres aplicaciones con `core=148,13,134,39`; el código actual ya usa `y=10` para `iPhone15,3`. Se conservó el perfil actual. Este hallazgo demuestra que hay una corrección posterior al reporte, no que su resultado físico esté confirmado. El comentario sobre Dock sigue pendiente de validación visual.
- **#10:** no se cambió el ajuste autorizado de medio punto ni los tamaños de Island/Gallery.

Prueba nueva: `python3 scripts/verify_dock_aura.py <simulator-id>`. Usa las funciones de producción de paleta, overlay y Pulse; UIKit/CALayer son reales y RemoteCall se sustituye por llamadas locales. Comprueba colores, progresión temporal, geometría, no interceptar toques, ausencia de recorte local de sombra, reaplicación, eliminación y fallo de animación.

Estado: las causas históricas de reinicio y la validación visual en los dispositivos afectados siguen pendientes. No se cerró ningún issue ni se añadieron funciones.
