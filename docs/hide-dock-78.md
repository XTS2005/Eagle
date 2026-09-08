# Hide Dock — vuelta a material recipes, build 78

Se recuperó el mecanismo de la release pública 62, a petición del usuario después de un congelamiento en la 77. Hide Dock permanece disponible para iOS 17–18. La operación escribe exclusivamente `dockDark.materialrecipe` y `dockLight.materialrecipe` mediante VFS y ofrece un respring manual tras verificar ambos archivos.

La ruta Swift ya no prepara, reutiliza ni consulta sesiones de SpringBoard. Se eliminó la función nativa `eagle_set_dock_background_hidden` y su declaración; no hay fallback oculto al método descartado. Los motores remotos de Gallery/Aura permanecen disponibles para sus funciones habituales.

## Correcciones respecto a la implementación pública

- La transformación de color/blur es la misma. Se genera siempre desde los originales guardados, conservando el tamaño exacto; una segunda activación no transforma otra vez un archivo ya alterado.
- Se guardan conjuntamente los dos originales y sus versiones transparentes en un plist atómico, sincronizado y verificado antes de tocar el sistema. Se identifica el respaldo por modelo/build de iOS. Los respaldos antiguos se conservan y solo se importan si corresponden al contenido actual/original o transparente. No se inventan originales si ya están transparentes y no hay copia.
- Cada escritura se verifica por lectura de bytes. Se verifica también el conjunto final. Un éxito del escritor sin efecto no produce una activación falsa.
- Un destino escrito parcialmente entra en recuperación, junto con los anteriores. Si la recuperación falla se conserva la copia original y se ofrece Restaurar Dock. Nunca se elimina el respaldo al restaurar.
- Al abrir/regresar a la pantalla se comprueba el estado en disco; el booleano antiguo de preferencias ya no es la fuente de verdad. Se muestra recuperación si los archivos no están en un estado consistente. Los archivos verificados no equivalen a un efecto visible hasta refrescar SpringBoard mediante respring.
- VFS y las escrituras se ejecutan fuera del hilo de interfaz. Hay progreso, protección ante doble activación, cancelación antes de escribir si se cambia de app y recuperación si se interrumpe después de una escritura. El bloqueo se mantiene hasta que el trabajo nativo termina; no hay un temporizador que permita reintentar mientras sigue escribiendo.
- Prepare, creación/inicio de sesiones remotas y limpieza en segundo plano respetan la operación de archivos en curso. VFS comunica fallo mediante su callback incluso si rechaza la inicialización en sus guardas; antes esa ruta podía dejar esperando a la interfaz.
- Se usa directamente el escritor VFS de la release pública, evitando intentar antes una apertura `O_TRUNC` sobre los archivos del sistema.

`ColorSwapManager` y `addEmptyData` conservan su algoritmo; sus transformaciones puras se marcaron `nonisolated` para ejecutarlas correctamente fuera del actor de interfaz.

## Verificaciones

- `verify_dock_recipes.py`: once escenarios con archivos temporales reales y las recetas incluidas en el repo. Doce ciclos de ocultar/restaurar, ocultación repetida sin escrituras redundantes, reapertura, importación del respaldo público, escritura silenciosa, fallo parcial del segundo archivo, recuperación fallida y reintentada, respaldo dañado/identidad incorrecta, original ausente, tamaños distintos, cancelación y cambios externos.
- `verify_dock_recipe_controller.py`: siete escenarios ejecutando el controlador de producción con VFS instrumentado: preparación inicial, reutilización de VFS, preparación fallida, escritura fallida, segundo plano, cambio de app durante preparación y operación ocupada. Se comprueban liberación del bloqueo y de la reserva de tiempo, resultado y petición de respring.
- Contrato de ruta: ausencia de llamadas remotas en Hide Dock y eliminación de su función nativa.
- Regresiones de propiedad de sesiones (incluyendo rechazo durante escritura de recetas), segundo plano (incluyendo no destruir sesiones durante esa escritura), capacidad de Dock y limpieza de Prepare.
- Release iOS/arm64e 1.0.3 (78): **BUILD SUCCEEDED**. Las pruebas antiguas exclusivas del método descartado se retiraron; sus resultados históricos no se presentan como validación de esta implementación.

Evidencia: `build/hide-dock78/`, incluyendo copia previa de los archivos principales modificados. No se tocó ningún archivo del sistema del iPhone durante el desarrollo, no se reinició el teléfono ni se importó a Vendor. Los escritores VFS de las pruebas son sustitutos para inyectar fallos; se verificó lógica local, no ausencia global de reinicios físicos.

La causa exacta del síntoma histórico de «solo una vez» no está demostrada por estos tests. Los fallos de verificación/recuperación descritos sí se corrigieron, y Hide Dock ya no puede entrar en la preparación remota donde terminó el registro de la 77.

Entrega: [Eagle 1.0.3 (78), IPA sin firma](../build/Eagle-1.0.3-78-HideDock-VFS.ipa). Integridad ZIP comprobada y firmas retiradas de los tres Mach-O exclusivamente en la copia de empaquetado. SHA-256: `ce7bae7ae76177b92739f911abfc00521dfbf61ccc5b45403c0838eb60d1841e`.
