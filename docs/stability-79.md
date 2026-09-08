# Eagle 1.0.3 (79) — revisión previa a publicación

## Persistencia de Hide Island y Hide Dock

La diferencia observada por el usuario es coherente con el código:

- Hide Island escribe `SBSuppressDynamicIslandCompletely` en `/var/Managed Preferences/mobile/com.apple.springboard.plist`. Es una preferencia reconocida por SpringBoard en un archivo de datos; el usuario confirma que sobrevive a un reinicio completo.
- Hide Dock 78 modifica `dockDark.materialrecipe` y `dockLight.materialrecipe` en `/System/Library/PrivateFrameworks/CoreMaterial.framework`. El escritor VFS abre el destino de solo lectura, lo mapea con `MAP_SHARED`, cambia las protecciones del mapa y copia los bytes. No equivale a guardar una preferencia persistente. El usuario confirma que funciona, pero vuelve al estado original tras reiniciar.
- La lectura posterior de bytes comprueba el estado visible en ese momento, **no demuestra persistencia después de apagar el dispositivo**. Guardar el interruptor en UserDefaults o el respaldo original no hace persistente el efecto.
- No se ha verificado una preferencia equivalente que oculte por completo este fondo en iOS 17–18. [Nugget usa `SBDisableGlassDock` para su opción NoLiquidDock](https://github.com/leminlimez/Nugget/blob/main/src/tweaks/tweak_loader.py), dentro de sus ajustes Liquid Glass: ese código no demuestra que sirva para ocultar el material del Dock en los dispositivos/versiones de Eagle.

Esta revisión no cambia el mecanismo de Hide Dock ni intenta hacerlo persistente mediante sesiones remotas, reaplicación automática o escrituras adicionales al sistema. La persistencia tras reinicio sigue pendiente de una alternativa comprobada. No se presenta como resuelta.

## Errores corregidos

1. **Sesión caducada antes de aplicar un tema.** Island Gallery, Dock Gallery y el ejecutor de Aura para Scenes leían propiedades de la sesión después de una suspensión `await`, pero antes de obtener su propiedad exclusiva. Otro trabajo podía haber reemplazado esa sesión. Ahora se adquiere primero la propiedad con comprobación de identidad y solo después se leen PID/helper. Se libera con `defer` en éxito y en todas las salidas anticipadas. Las cancelaciones tampoco entran al trabajo nativo. No cambia la creación de sesiones ni el motor de temas.
2. **Cierre por ajustes guardados fuera de rango.** La conversión directa de un entero mayor que `UInt32.max` producía una trampa en Aura, Island, Dock o Scenes. Las flags guardadas se convierten exactamente o se consideran no válidas (cero); se mantienen las máscaras existentes y todos los valores válidos.
3. **Cierre al convertir una intensidad no finita.** Un `NaN` podía alcanzar la conversión `Double → Int32` del brillo de Dock Gallery. Se normaliza antes del trabajo nativo y se guarda el mismo valor aplicado. Se conservan las intensidades finitas con los límites anteriores; los valores no finitos usan 0.72, igual que la protección existente en Island.
4. **Vista previa de capacidad con rango inválido.** Un valor negativo guardado podía construir `0..<cantidad` y cerrar la vista; uno enorme podía generar un número desmedido de elementos. Solo la vista previa usa ahora 4, 5 o 6 (5 como respaldo). El botón de aplicar conserva su validación existente y no escribe una capacidad sustituta en el sistema.

Son errores reproducidos con entradas/sesiones instrumentadas, no una atribución demostrada de los reinicios físicos anteriores.

## Verificación local

- `verify_gallery_session_lifetime.py --baseline build/stability79/before`: reproduce acceso prematuro a sesión destruida en los tres ejecutores anteriores.
- `verify_gallery_session_lifetime.py`: los tres ejecutores de producción, junto a las guardas reales del manager, rechazan sesión caducada, ausencia, PID distinto/cero, helper ausente, otra operación, segundo plano, escritura VFS y cancelación; completan 100 ciclos cada uno sin perder el bloqueo.
- `verify_stored_theme_values.py --baseline build/stability79/before`: reproduce trampas por flags fuera de rango, intensidad NaN y capacidad negativa con expresiones extraídas de los archivos anteriores.
- `verify_stored_theme_values.py`: valida límites, no finitos, 256 combinaciones de flags y conexiones de los consumidores de producción al validador.
- Regresiones: recetas Dock (incluida recuperación), controlador Hide Dock, ausencia de ruta remota Hide Dock, propiedad de sesiones, ciclo de segundo plano, capacidad Dock, limpieza Prepare, exclusión Island, geometría #10 y renderer del brillo Dock.

Las pruebas de transporte/escritura usan sustitutos locales para inyectar fallos: no ejecutan el exploit en un teléfono. El ajuste de -0.50 pt de #10 y las recetas/método de Hide Dock 78 permanecen sin cambios. No se desactiva ninguna función, no se importa a Vendor y no se publica ni se instala automáticamente.

Evidencia y copias previas de los cinco consumidores modificados: `build/stability79/`. Pendiente antes de presentar estabilidad física: repetir ocultar/restaurar, aplicar temas Dock/Island y comprobar el comportamiento después de reiniciar en dispositivos reales compatibles. Una activación exitosa de Hide Dock no demuestra estabilidad global.

## Candidato local

Release iOS/arm64e 1.0.3 (79): **BUILD SUCCEEDED**, sin errores de compilación ni advertencias nuevas de aislamiento del actor principal en el registro. Las doce suites indicadas pasan; también las dos ejecuciones que reproducen fallos del código previo. `git diff --check` pasa.

IPA sin firma: `build/Eagle-1.0.3-79-Stability.ipa` (17 MB). Integridad ZIP comprobada; no contiene `_CodeSignature` ni perfil de aprovisionamiento. Las firmas se retiraron únicamente de los tres Mach-O de la copia temporal de empaquetado, no de los archivos fuente ni de los binarios originales. SHA-256: `7017af3626f8aa671d312f75b0c31a3da0d2210ce6465bffb77577780f0ddc69`.

No se instaló en el iPhone ni se publicó en GitHub. Este candidato no es evidencia de haber eliminado todos los fallos físicos ni de compatibilidad global comprobada.
