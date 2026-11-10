# Resultados Laboratorio 1.1 y 1.2

## Comparacion de resultados

| Metrica | Lab 1.1 (Linea base) | Lab 1.2 (Con resiliencia) |
| --- | --- | --- |
| Solicitudes totales | 200 | 200 |
| Respuestas SUCCESS (HTTP 200) | 133 (66.5%) | 13 (6.5%) |
| Respuestas DEGRADED_CACHE (HTTP 200) | 0 (0%) | 187 (93.5%) |
| Errores HTTP 500 | 67 (33.5%) | 0 (0%) |
| Disponibilidad | 0.6650 (66.5%) | 1.0000 (100%) |
| Latencia maxima aprox. | ~3.00 s | ~1.23 s (con reintentos) / ~0.20 s (circuito abierto) |

## Preguntas del laboratorio 1.2

1. ¿Disminuyeron las respuestas HTTP 500 respecto a la linea base?
Si, pasaron de 67 errores en el laboratorio 1.1 a 0 errores en el 1.2, porque cuando fallan los intentos entra el metodo getCatalogFallback() y responde HTTP 200 con los datos en cache.

2. ¿Que porcentaje de respuestas fue SUCCESS vs DEGRADED_CACHE en la configuracion completa?
De las 200 peticiones, 13 fueron SUCCESS (6.5%) y 187 fueron DEGRADED_CACHE (93.5%).

3. ¿La latencia de respuesta mejoro con respecto a Lab 1.1?
Si. En el lab 1.1 las peticiones lentas tardaban los 3 segundos completos (3.006s, 3.009s). Con @Timeout(800) se corta el intento lento a los 800 ms (quedando en ~1.0s - 1.2s sumando los reintentos), y cuando se abre el Circuit Breaker baja a unos 0.15s - 0.35s.

4. ¿Que costo tiene el Retry en latencia y llamadas adicionales a la base de datos?
Cuando una peticion falla hace hasta 3 intentos seguidos en vez de 1, lo que genera el triple de consultas a la base de datos y suma el tiempo de espera (delay = 150ms) mas lo que tarde cada intento (~1.2s en total antes de ir al fallback).

5. ¿En que momento observaste que el circuito se abrio y cuanto duro la fase OPEN?
Se abrio despues de las primeras peticiones fallidas (a partir de la peticion 006 el tiempo baja de ~1.0s a ~0.20s y en los logs sale el fallback con 0 intentos). Duro abierto unos 5 segundos (delay = 5000), que fue lo que se configuro en @CircuitBreaker.

6. ¿Despues de que el circuito se recupero (HALF_OPEN a CLOSED), volvieron a funcionar los reintentos completos?
Si, pasados los 5 segundos el circuito dejo pasar peticiones de prueba (por ejemplo en las peticiones 049-054, 109-113 y 129-133), donde volvieron a salir respuestas SUCCESS y tambien se volvieron a ejecutar los 3 intentos completos cuando tocaba fallo.

## Salida del script analyze-resilience.ps1

```
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

## Compilacion (mvnw test)

```
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
