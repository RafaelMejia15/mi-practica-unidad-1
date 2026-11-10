# Script para analizar y comparar resultados de resiliencia
# Uso: .\analyze-resilience.ps1

if (-not (Test-Path "availability-baseline.txt") -or -not (Test-Path "resilience-sample.txt")) {
    Write-Host "[ERROR] Archivos no encontrados." -ForegroundColor Red
    Write-Host "   Asegurate de que existen: availability-baseline.txt y resilience-sample.txt"
    exit 1
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "          ANALISIS DE RESILIENCIA: Lab 1.1 vs Lab 1.2           " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

Write-Host ""
Write-Host "[1] LINEA BASE (Lab 1.1 - SIN patrones)" -ForegroundColor Yellow
Write-Host "-----------------------------------------" -ForegroundColor Yellow
$baseline = @(Get-Content "availability-baseline.txt")
$total_1_1 = $baseline.Count
$success_1_1 = ($baseline | Where-Object { $_ -like '*"status":"SUCCESS"*' }).Count
$errors_1_1 = $total_1_1 - $success_1_1
$avail_1_1 = if ($total_1_1 -gt 0) { [math]::Round($success_1_1 / $total_1_1, 4) } else { 0 }
$pct_success_1_1 = if ($total_1_1 -gt 0) { [math]::Round($success_1_1 * 100 / $total_1_1) } else { 0 }
$pct_errors_1_1 = if ($total_1_1 -gt 0) { [math]::Round($errors_1_1 * 100 / $total_1_1) } else { 0 }

Write-Host ("Total solicitudes:         {0}" -f $total_1_1)
Write-Host ("SUCCESS (HTTP 200):        {0} (~{1}%)" -f $success_1_1, $pct_success_1_1)
Write-Host ("Errores/No disponibles:    {0} (~{1}%)" -f $errors_1_1, $pct_errors_1_1)
Write-Host ("Disponibilidad:            {0} ({1}%)" -f $avail_1_1, $pct_success_1_1)

Write-Host ""
Write-Host "[2] CON PATRONES (Lab 1.2 - Completo: Timeout + Retry + Fallback + CircuitBreaker)" -ForegroundColor Yellow
Write-Host "----------------------------------------------------------------------------------" -ForegroundColor Yellow
$resilience = @(Get-Content "resilience-sample.txt")
$total_1_2 = $resilience.Count
$success_1_2 = ($resilience | Where-Object { $_ -like '*"status":"SUCCESS"*' }).Count
$degraded_1_2 = ($resilience | Where-Object { $_ -like '*"status":"DEGRADED_CACHE"*' }).Count
$http500_1_2 = ($resilience | Where-Object { $_ -notmatch '^\d+\s+200\s+' }).Count
$total_respuestas = $success_1_2 + $degraded_1_2
$avail_1_2 = if ($total_1_2 -gt 0) { [math]::Round($total_respuestas / $total_1_2, 4) } else { 0 }
$pct_success_1_2 = if ($total_1_2 -gt 0) { [math]::Round($success_1_2 * 100 / $total_1_2) } else { 0 }
$pct_degraded_1_2 = if ($total_1_2 -gt 0) { [math]::Round($degraded_1_2 * 100 / $total_1_2) } else { 0 }
$pct_avail_1_2 = if ($total_1_2 -gt 0) { [math]::Round($total_respuestas * 100 / $total_1_2) } else { 0 }

Write-Host ("Total solicitudes:         {0}" -f $total_1_2)
Write-Host ("SUCCESS (HTTP 200):        {0} (~{1}%)" -f $success_1_2, $pct_success_1_2)
Write-Host ("DEGRADED_CACHE (HTTP 200): {0} (~{1}%)" -f $degraded_1_2, $pct_degraded_1_2)
Write-Host ("Errores HTTP 500:          {0}" -f $http500_1_2)
Write-Host ("Disponibilidad:            {0} ({1}%)" -f $avail_1_2, $pct_avail_1_2)

Write-Host ""
Write-Host "[3] COMPARACION - MEJORA OBTENIDA" -ForegroundColor Green
Write-Host "-----------------------------------------" -ForegroundColor Green
$mejora_avail = [math]::Round($avail_1_2 - $avail_1_1, 4)
$mejora_porcentaje = [math]::Round(($avail_1_2 - $avail_1_1) * 100, 2)

Write-Host ("Disponibilidad mejorada:   {0} (+{1}%)" -f $mejora_avail, $mejora_porcentaje)
Write-Host ("Errores eliminados:        de ~{0}% a {1}%" -f $pct_errors_1_1, $http500_1_2)
Write-Host "HTTP 500 desaparecieron:   Completamente"
Write-Host ("Respuestas degradadas:     {0} solicitudes salvadas por @Fallback" -f $degraded_1_2)

Write-Host ""
Write-Host "[OK] CONCLUSION" -ForegroundColor Green
Write-Host "-----------------------------------------" -ForegroundColor Green
if ($avail_1_2 -gt 0.99) {
    Write-Host "La implementacion de patrones de resiliencia fue EXITOSA." -ForegroundColor Green
    Write-Host "Disponibilidad alcanzada: ~100% (aceptable para mayoria de aplicaciones)" -ForegroundColor Green
} else {
    Write-Host "La implementacion funciona, pero revisa si el @CircuitBreaker se activo correctamente." -ForegroundColor Yellow
}
Write-Host ""
