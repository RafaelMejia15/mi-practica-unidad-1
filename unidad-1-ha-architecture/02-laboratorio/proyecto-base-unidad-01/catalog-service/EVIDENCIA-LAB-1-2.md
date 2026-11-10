# Resultados y Evidencia — Laboratorio 1.1 y 1.2

## 1. Tabla Comparativa de Resultados

| Métrica | Lab 1.1 (Línea base: `availability-baseline.txt`) | Lab 1.2 (Con resiliencia: `resilience-sample.txt`) |
| --- | --- | --- |
| Solicitudes totales | 200 | 200 |
| Respuestas `SUCCESS` (HTTP 200) | 133 (66.5%) | 13 (6.5%) |
| Respuestas `DEGRADED_CACHE` (HTTP 200) | 0 (0%) | 187 (93.5%) |
| Errores HTTP 500 | 67 (33.5%) | 0 (0%) |
| Disponibilidad observada | 0.6650 (66.5%) | 1.0000 (100%) |
| Latencia observada (máx. / típica) | ~3.00 s (en fallos de latencia) | ~1.23 s (con reintentos) / ~0.15 s - 0.35 s (circuito abierto) |

Muestras generadas incluidas en este directorio:
- [`availability-baseline.txt`](./availability-baseline.txt) (200 solicitudes sin patrones de resiliencia)
- [`resilience-sample.txt`](./resilience-sample.txt) (200 solicitudes con `@Timeout`, `@Retry`, `@CircuitBreaker` y `@Fallback`)

---

## 2. Preguntas del Laboratorio 1.2

**1. ¿Disminuyeron las respuestas HTTP 500 respecto a la línea base?**
Sí, pasaron de 67 errores en el laboratorio 1.1 a 0 errores en el 1.2, porque cuando fallan los intentos entra el método `getCatalogFallback()` y responde HTTP 200 con los datos en caché.

**2. ¿Qué porcentaje de respuestas fue SUCCESS vs DEGRADED_CACHE en la configuración completa?**
De las 200 peticiones, 13 fueron `SUCCESS` (6.5%) y 187 fueron `DEGRADED_CACHE` (93.5%).

**3. ¿La latencia de respuesta mejoró con respecto a Lab 1.1?**
Sí. En el lab 1.1 las peticiones lentas tardaban los 3 segundos completos (`3.006s`, `3.009s`). Con `@Timeout(800)` se corta el intento lento a los 800 ms (quedando en ~1.0s - 1.2s sumando los reintentos), y cuando se abre el Circuit Breaker baja a unos 0.15s - 0.35s.

**4. ¿Qué costo tiene el Retry en latencia y llamadas adicionales a la base de datos?**
Cuando una petición falla hace hasta 3 intentos seguidos en vez de 1, lo que genera el triple de consultas a la base de datos y suma el tiempo de espera (`delay = 150ms`) más lo que tarde cada intento (~1.2s en total antes de ir al fallback).

**5. ¿En qué momento observaste que el circuito se abrió y cuánto duró la fase OPEN?**
Se abrió después de las primeras peticiones fallidas (a partir de la petición 006 el tiempo baja de ~1.0s a ~0.20s y en los logs sale el fallback con 0 intentos). Duró abierto unos 5 segundos (`delay = 5000`), que fue lo que se configuró en `@CircuitBreaker`.

**6. ¿Después de que el circuito se recuperó (HALF_OPEN a CLOSED), volvieron a funcionar los reintentos completos?**
Sí, pasados los 5 segundos el circuito dejó pasar peticiones de prueba (por ejemplo en las peticiones 049-054, 109-113 y 129-133), donde volvieron a salir respuestas `SUCCESS` y también se volvieron a ejecutar los 3 intentos completos cuando tocaba fallo.

---

## 3. Salida del Análisis Automático (`analyze-resilience.ps1`)

```text
================================================================
         ANALISIS DE RESILIENCIA: Lab 1.1 vs Lab 1.2            
================================================================

LINEA BASE (Lab 1.1 - SIN patrones)
-----------------------------------------
Total solicitudes:        200
SUCCESS (HTTP 200):       133 (~66%)
Errores/No disponibles:   67 (~34%)
Disponibilidad:           0.665 (66%)

CON PATRONES (Lab 1.2 - Completo: Timeout + Retry + Fallback + CircuitBreaker)
---------------------------------------------------------------------------------
Total solicitudes:        200
SUCCESS (HTTP 200):       13 (~6%)
DEGRADED_CACHE (HTTP 200):187 (~94%)
Errores HTTP 500:         0
Disponibilidad:           1 (100%)

COMPARACION - MEJORA OBTENIDA
-----------------------------------------
Disponibilidad mejorada:  0.335 (33.50%)
Errores eliminados:       ~100% (de ~34% a 0%)
HTTP 500 desaparecieron:  Completamente
Respuestas degradadas:    187 solicitudes salvadas por @Fallback

CONCLUSION
-----------------------------------------
La implementacion de patrones de resiliencia fue EXITOSA.
Disponibilidad alcanzada: ~100% (aceptable para mayoria de aplicaciones)
```

---

## 4. Compilación Exitosa (`.\mvnw.cmd test`)

```text
[INFO] Scanning for projects...
[INFO] 
[INFO] ----------------------< com.ecom:catalog-service >----------------------
[INFO] Building catalog-service 1.0.0
[INFO]   from pom.xml
[INFO] --------------------------------[ jar ]---------------------------------
[INFO] 
[INFO] --- resources:3.4.0:resources (default-resources) @ catalog-service ---
[INFO] Copying 1 resource from src\main\resources to target\classes
[INFO] 
[INFO] --- quarkus:3.38.0:generate-code (default) @ catalog-service ---
[INFO] 
[INFO] --- compiler:3.13.0:compile (default-compile) @ catalog-service ---
[INFO] Recompiling the module because of added or removed source files.
[INFO] Compiling 2 source files with javac [debug release 25] to target\classes
[INFO] 
[INFO] --- quarkus:3.38.0:generate-code-tests (default) @ catalog-service ---
[INFO] 
[INFO] --- resources:3.4.0:testResources (default-testResources) @ catalog-service ---
[INFO] skip non existing resourceDirectory D:\ITQ\Noveno\Despliegues\mi-practica-unidad-1\unidad-1-ha-architecture\02-laboratorio\proyecto-base-unidad-01\catalog-service\src\test\resources
[INFO] 
[INFO] --- compiler:3.13.0:testCompile (default-testCompile) @ catalog-service ---
[INFO] No sources to compile
[INFO] 
[INFO] --- surefire:3.2.5:test (default-test) @ catalog-service ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
```

---

## 5. Diff de `CatalogResource.java`

```diff
diff --git a/unidad-1-ha-architecture/02-laboratorio/proyecto-base-unidad-01/catalog-service/src/main/java/com/ecom/catalog/CatalogResource.java b/unidad-1-ha-architecture/02-laboratorio/proyecto-base-unidad-01/catalog-service/src/main/java/com/ecom/catalog/CatalogResource.java
index 0744a1c..7fbb559 100644
--- a/unidad-1-ha-architecture/02-laboratorio/proyecto-base-unidad-01/catalog-service/src/main/java/com/ecom/catalog/CatalogResource.java
+++ b/unidad-1-ha-architecture/02-laboratorio/proyecto-base-unidad-01/catalog-service/src/main/java/com/ecom/catalog/CatalogResource.java
@@ -7,6 +7,10 @@ import jakarta.ws.rs.core.MediaType;
 import jakarta.ws.rs.core.Response;
 import java.util.Random;
 import java.util.logging.Logger;
+import org.eclipse.microprofile.faulttolerance.Timeout;
+import org.eclipse.microprofile.faulttolerance.Retry;
+import org.eclipse.microprofile.faulttolerance.Fallback;
+import org.eclipse.microprofile.faulttolerance.CircuitBreaker;
 
 /**
  * Catalog Resource - Endpoint principal del servicio de catálogo.
@@ -21,37 +25,86 @@ public class CatalogResource {
     private final Random random = new Random();
 
     /**
-     * Endpoint principal que retorna el catálogo de productos.
-     * 
-     * Simulación de escenarios:
-     * - 20% de probabilidad de latencia alta (>3000ms)
-     * - 30% de probabilidad de falla de conexión a base de datos
-     * - 50% de probabilidad de respuesta exitosa normal
-     * 
-     * @return Response con el catálogo de productos o datos degradados del fallback
-     * @throws InterruptedException si el thread es interrumpido durante la
-     *                              simulación de latencia
+     * ThreadLocal para rastrear el número de intento de cada solicitud HTTP.
+     * Se incrementa en cada invocación de getProducts() debido a @Retry,
+     * permitiendo observar claramente los reintentos en los logs.
      */
+    private static final ThreadLocal<Integer> ATTEMPT_COUNT = ThreadLocal.withInitial(() -> 0);
+
+    /**
+     * ThreadLocal para determinar si la solicitud HTTP actual debe fallar en los
+     * primeros 2 intentos. Se genera una sola vez por solicitud y se reutiliza
+     * en todos los reintentos, garantizando un patrón predecible de fallos.
+     */
+    private static final ThreadLocal<Boolean> SHOULD_FAIL_FIRST_ATTEMPTS = ThreadLocal.withInitial(() -> false);
+
     @GET
     @Produces(MediaType.APPLICATION_JSON)
+    @Timeout(800)
+    @Retry(maxRetries = 2, delay = 150)
+    @CircuitBreaker(requestVolumeThreshold = 10, failureRatio = 0.7, delay = 5000)
+    @Fallback(fallbackMethod = "getCatalogFallback")
     public Response getProducts() throws InterruptedException {
-        int chance = random.nextInt(10);
+        try {
+            // Incrementar contador de intentos para esta solicitud HTTP
+            ATTEMPT_COUNT.set(ATTEMPT_COUNT.get() + 1);
+            int currentAttempt = ATTEMPT_COUNT.get();
 
-        // Simular latencia degradada en la base de datos (20% de probabilidad)
-        if (chance < 2) {
-            LOG.warning("Simulando latencia alta en consulta de catálogo...");
-            Thread.sleep(3000);
-        }
+            // Separador visual: marca el inicio de una nueva solicitud HTTP
+            if (currentAttempt == 1) {
+                LOG.info("════════════════════════════════════════════════════════════");
+            }
 
-        // Simular falla de conexión a la base de datos (30% de probabilidad)
-        if (chance >= 2 && chance < 5) {
-            LOG.severe("Falla de conexión a la base de datos primaria.");
-            throw new RuntimeException("Database connection timeout");
+            LOG.info("[Intento " + currentAttempt + "/3] Consultando catálogo de productos...");
+
+            // En el primer intento, decidir si esta solicitud HTTP fallará en todos los intentos
+            if (currentAttempt == 1) {
+                // 60% de probabilidad de que los 3 intentos fallen
+                SHOULD_FAIL_FIRST_ATTEMPTS.set(random.nextInt(10) < 6);
+            }
+
+            boolean shouldFail = SHOULD_FAIL_FIRST_ATTEMPTS.get();
+
+            // Los 3 intentos pueden fallar (si fue marcado)
+            // Si todos fallan, el @Fallback se activará
+            if (shouldFail && currentAttempt <= 3) {
+                // Alternar entre tipo de fallo en cada intento para mayor claridad en logs
+                if (currentAttempt == 1) {
+                    LOG.severe("[Intento " + currentAttempt + "/3] Falla de conexión a la base de datos primaria.");
+                    throw new RuntimeException("Database connection timeout");
+                } else if (currentAttempt == 2) {
+                    LOG.warning("[Intento " + currentAttempt + "/3] Simulando latencia alta en consulta de catálogo...");
+                    Thread.sleep(3000);  // Esto será capturado por @Timeout(800)
+                } else if (currentAttempt == 3) {
+                    LOG.severe("[Intento " + currentAttempt + "/3] Falla de conexión después de reintentos.");
+                    throw new RuntimeException("Database connection timeout after retries");
+                }
+            }
+
+            // Respuesta exitosa (tercer intento o si no estaba marcado para fallar)
+            LOG.info("[Intento " + currentAttempt + "/3] Catálogo retornado exitosamente desde la base de datos primaria.");
+            ATTEMPT_COUNT.set(0);  // Resetear inmediatamente para siguiente solicitud HTTP
+            SHOULD_FAIL_FIRST_ATTEMPTS.set(false);
+            return Response.ok("{\"status\":\"SUCCESS\",\"data\":[\"Product A\",\"Product B\",\"Product C\"]}").build();
+            
+        } finally {
+            // No resetear aquí: si la solicitud falla, getCatalogFallback() leerá el contador
+            // antes de resetearlo. Si tuvo éxito, ya se reseteó antes del return.
         }
+    }
 
-        // Respuesta exitosa (50% de probabilidad)
-        LOG.info("Catálogo retornado exitosamente desde la base de datos primaria.");
-        return Response.ok("{\"status\":\"SUCCESS\",\"data\":[\"Product A\",\"Product B\",\"Product C\"]}").build();
+    /**
+     * Método de fallback invocado cuando:
+     * - El @Timeout se activa (la solicitud tardó más de 800ms)
+     * - El @CircuitBreaker se abre (demasiadas fallas detectadas)
+     * - Ambos reintentos del @Retry fracasan
+     */
+    public Response getCatalogFallback() {
+        int failedAttempts = ATTEMPT_COUNT.get();
+        LOG.info("Fallback activado: Se agotaron todos los " + failedAttempts + " intentos. Sirviendo datos desde caché.");
+        ATTEMPT_COUNT.set(0);  // Resetear contador para siguiente solicitud HTTP
+        SHOULD_FAIL_FIRST_ATTEMPTS.set(false);  // Resetear flag para siguiente solicitud HTTP
+        return Response.ok("{\"status\":\"DEGRADED_CACHE\",\"data\":[\"Cached Product A\",\"Cached Product B\"]}").build();
     }
 
     /**
```
