# Resultados Laboratorio 1.1 y 1.2

## Comparación de resultados

| Métrica | Lab 1.1 (Línea base) | Lab 1.2 (Con resiliencia) |
| --- | --- | --- |
| Solicitudes totales | 200 | 200 |
| Respuestas SUCCESS (HTTP 200) | 133 (66.5%) | 13 (6.5%) |
| Respuestas DEGRADED_CACHE (HTTP 200) | 0 (0%) | 187 (93.5%) |
| Errores HTTP 500 | 67 (33.5%) | 0 (0%) |
| Disponibilidad | 0.6650 (66.5%) | 1.0000 (100%) |
| Latencia máxima aprox. | ~3.00 s | ~1.23 s (con reintentos) / ~0.20 s (circuito abierto) |

## Preguntas del laboratorio 1.2

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
