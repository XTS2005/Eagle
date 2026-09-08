# Hide Dock — investigación y correcciones, build 77

8 de septiembre de 2026. El usuario reportó un cierre/reinicio al intentar Hide Dock en el build 76 y pidió conservar todas las funciones. **El reinicio no se considera resuelto.** La suspensión temporal propuesta se retiró antes de compilar; Hide Dock continúa habilitado en su rango existente de iOS 17–18.

## Evidencia

- El dispositivo conectado tiene Eagle 1.0.3 (76), iPhone 16 Pro (`iPhone17,1`), iOS 18.6.2 (`22G100`). Se copiaron los tres logs disponibles y el diario de Prepare, sin iniciar Eagle ni ejecutar operaciones nativas.
- Los registros de las 11:45:56 y 11:46:19 terminan durante Prepare. El primero llega a `waiting for zone trimming`; el diario del último intento, iniciado a las 11:46:21, permanece en `darkSwordRunning`. Ninguno de estos registros conservados contiene la entrada a Hide Dock. No permiten atribuir el cierre a su setter ni descartar que falte la sesión del incidente.
- El listado de informes accesible por CoreDevice no contiene un panic, ResetCounter, Eagle o SpringBoard nuevo que coincida con el incidente; `Retired` está vacío. La ausencia del informe no demuestra que no haya ocurrido un reinicio.
- La última release pública consultada es `v1.0.3`, build 62. Su implementación escribía dos archivos `materialrecipe` mediante VFS y requería respring. La implementación del build 76 cambia vistas de SpringBoard mediante RemoteCall. No se restauró automáticamente la ruta antigua, que el usuario también describió como inestable.

## Cambios concretos

1. Hide Dock reutiliza la sesión sana y verificada que ya existe. La versión 76 solicitaba destruir/recrear la sesión en cada activación o restauración, incluso tras aplicar un tema. Si no hay sesión válida, sigue disponible la preparación serializada existente con su límite de tiempo; no se elimina la función ni se aceptan sesiones sin verificar.
2. Al volver de la preparación asíncrona, se obtiene la propiedad exclusiva **antes** de leer PID o propiedades nativas. Una sesión reemplazada por otra operación se rechaza sin tocarla. El bloqueo ahora se libera mediante `defer`, después de verificar el resultado o poner en cuarentena un transporte fallido.
3. Se rechazan solicitudes mientras otra operación está ejecutándose o Eagle está en segundo plano. El interruptor muestra un indicador de progreso durante su operación. No anuncia activación antes de que la llamada se haya verificado.
4. Los puntos de entrada a preparación y a la operación nativa, y su resultado, se sincronizan con el log en disco para distinguir mejor las etapas en un próximo diagnóstico.

Estos cambios afectan al controlador/vista de Hide Dock y al número de build. No se modificaron el motor nativo compartido, los perfiles de Island, los temas de Dock/Gallery ni los archivos de fondo del sistema.

## Pruebas

- `verify_hide_dock_session.py`: ejecuta el controlador Swift de producción con transporte instrumentado. Ocho escenarios: reutilización, sesión reemplazada, preparación fallida, operación ocupada, segundo plano, primera preparación, timeout y fallo nativo. Reutilización y acceso a sesión reemplazada fallaron contra el código anterior y pasan con la corrección. Un timeout no anuncia éxito ni permite reintentos en una sesión inválida.
- `verify_hide_dock_native.py`: ejecuta la función nativa completa sobre UIViews y asociaciones Objective-C reales del simulador. Comprueba 20 ciclos de ocultar/repetir ocultar/restaurar, preservación de tema/iconos, fallo parcial con rollback, reintento, rechazo de iconos/overlay como fondo y preservación de materiales ocultos por el sistema. Discovery y transporte remoto se sustituyen; no es una validación del kernel ni de SpringBoard físico.
- Regresiones de propiedad de sesión, ciclo de segundo plano, capacidad del Dock y contrato de aislamiento/rollback: pasan. El antiguo verificador de Hide Dock solo inspeccionaba texto fuente; su mensaje ahora aclara que no prueba seguridad en dispositivo.

## Pendiente

Confirmar en el dispositivo el comportamiento de esta revisión y obtener el registro coincidente si vuelve a fallar. No se provocó el fallo, no se instaló una IPA, no se reinició el teléfono ni se importó a Vendor. Las correcciones verificadas reducen operaciones de sesión innecesarias y eliminan una ventana de acceso a sesión reemplazada; no demuestran la causa ni la resolución del reinicio reportado.

La evidencia y los resultados están en `build/hide-dock77/`.

## Compilación entregable

Release iOS/arm64e: **BUILD SUCCEEDED**, versión 1.0.3 (77). [IPA sin firma](../build/Eagle-1.0.3-77-HideDock.ipa). Integridad ZIP correcta; los tres Mach-O empaquetados carecen de `LC_CODE_SIGNATURE`, y el paquete no contiene `_CodeSignature` ni perfil de aprovisionamiento. Se retiraron firmas únicamente de la copia temporal de empaquetado.

SHA-256: `6d748c01aa82b2266ef27c143bf2c81be50a993b5f1b9a37729ac497b05f85fd`.

La compilación correcta y estas pruebas no certifican la ausencia de reinicios físicos. No se instaló el build 77 en el teléfono.
