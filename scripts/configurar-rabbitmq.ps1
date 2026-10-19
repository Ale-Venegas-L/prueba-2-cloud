
# ==============================================================
# MINI PEDIDOS - CONFIGURACION AUTOMATICA DE RABBITMQ
# PASO 11 - DEAD LETTER EXCHANGE (DLX) Y DEAD LETTER QUEUE (DLQ)
# ==============================================================
#
# Requisitos:
# - Docker Desktop iniciado
# - Contenedor RabbitMQ funcionando
# - RabbitMQ Management disponible en localhost:15672
#
# El script NO elimina colas ni mensajes existentes.
# ==============================================================

$ErrorActionPreference = "Stop"

# --------------------------------------------------------------
# 1. CONFIGURACION DEL ENTORNO LOCAL
# --------------------------------------------------------------

$rabbitUrl = "http://localhost:15672"
$usuario = "guest"
$contrasena = "guest"

$exchangeDLX = "pedidos.dlx"
$colaDLQ = "pedidos.dlq"
$routingKey = "pedidos.error"
$nombrePolitica = "pedidos-dlx-policy"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " MINI PEDIDOS - CONFIGURACION RABBITMQ" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# --------------------------------------------------------------
# 2. PREPARAR AUTENTICACION
# --------------------------------------------------------------

$textoCredenciales = "${usuario}:${contrasena}"

$credenciales = [Convert]::ToBase64String(
    [Text.Encoding]::ASCII.GetBytes($textoCredenciales)
)

$encabezados = @{
    Authorization = "Basic $credenciales"
}

# --------------------------------------------------------------
# 3. FUNCION PARA ENVIAR SOLICITUDES A RABBITMQ
# --------------------------------------------------------------

function Enviar-RabbitMQ {
    param(
        [string]$Metodo,
        [string]$Ruta,
        [object]$Datos
    )

    $url = "$rabbitUrl$Ruta"

    $parametros = @{
        Uri         = $url
        Method      = $Metodo
        Headers     = $encabezados
        ErrorAction = "Stop"
    }

    if ($null -ne $Datos) {
        $parametros.ContentType = "application/json"
        $parametros.Body = ConvertTo-Json `
            -InputObject $Datos `
            -Depth 10 `
            -Compress
    }

    Invoke-RestMethod @parametros
}

try {

    # ----------------------------------------------------------
    # 4. VERIFICAR CONEXION CON RABBITMQ
    # ----------------------------------------------------------

    Write-Host ""
    Write-Host "[1/6] Verificando RabbitMQ..." -ForegroundColor Yellow

    $null = Enviar-RabbitMQ `
        -Metodo "GET" `
        -Ruta "/api/overview"

    Write-Host "RabbitMQ disponible." -ForegroundColor Green

    # ----------------------------------------------------------
    # 5. VERIFICAR QUE EXISTA LA COLA PRINCIPAL
    # ----------------------------------------------------------

    Write-Host ""
    Write-Host "[2/6] Verificando cola principal..." -ForegroundColor Yellow

    $null = Enviar-RabbitMQ `
        -Metodo "GET" `
        -Ruta "/api/queues/%2F/pedidos"

    Write-Host "Cola pedidos encontrada." -ForegroundColor Green

    # ----------------------------------------------------------
    # 6. CREAR DEAD LETTER EXCHANGE
    # ----------------------------------------------------------

    Write-Host ""
    Write-Host "[3/6] Configurando DLX..." -ForegroundColor Yellow

    $datosExchange = @{
        type        = "direct"
        durable     = $true
        auto_delete = $false
        internal    = $false
        arguments   = @{}
    }

    $null = Enviar-RabbitMQ `
        -Metodo "PUT" `
        -Ruta "/api/exchanges/%2F/$exchangeDLX" `
        -Datos $datosExchange

    Write-Host "DLX configurada: $exchangeDLX" -ForegroundColor Green

    # ----------------------------------------------------------
    # 7. CREAR DEAD LETTER QUEUE
    # ----------------------------------------------------------

    Write-Host ""
    Write-Host "[4/6] Configurando DLQ..." -ForegroundColor Yellow

    $datosCola = @{
        durable     = $true
        auto_delete = $false
        arguments   = @{}
    }

    $null = Enviar-RabbitMQ `
        -Metodo "PUT" `
        -Ruta "/api/queues/%2F/$colaDLQ" `
        -Datos $datosCola

    Write-Host "DLQ configurada: $colaDLQ" -ForegroundColor Green

    # ----------------------------------------------------------
    # 8. VINCULAR DLX CON DLQ
    # ----------------------------------------------------------

    Write-Host ""
    Write-Host "[5/6] Vinculando DLX con DLQ..." -ForegroundColor Yellow

    $datosBinding = @{
        routing_key = $routingKey
        arguments   = @{}
    }

    $null = Enviar-RabbitMQ `
        -Metodo "POST" `
        -Ruta "/api/bindings/%2F/e/$exchangeDLX/q/$colaDLQ" `
        -Datos $datosBinding

    Write-Host "Vinculacion configurada." -ForegroundColor Green
    Write-Host "Routing key: $routingKey"

    # ----------------------------------------------------------
    # 9. CREAR POLITICA PARA LA COLA PRINCIPAL
    # ----------------------------------------------------------

    Write-Host ""
    Write-Host "[6/6] Configurando politica DLX..." -ForegroundColor Yellow

    $datosPolitica = @{
        pattern    = "^pedidos$"
        apply_to   = "queues"
        priority   = 10
        definition = @{
            "dead-letter-exchange"    = $exchangeDLX
            "dead-letter-routing-key" = $routingKey
        }
    }

    $null = Enviar-RabbitMQ `
        -Metodo "PUT" `
        -Ruta "/api/policies/%2F/$nombrePolitica" `
        -Datos $datosPolitica

    Write-Host "Politica configurada: $nombrePolitica" `
        -ForegroundColor Green

    # ----------------------------------------------------------
    # 10. VERIFICACION FINAL
    # ----------------------------------------------------------

    $exchangeVerificado = Enviar-RabbitMQ `
        -Metodo "GET" `
        -Ruta "/api/exchanges/%2F/$exchangeDLX"

    $colaVerificada = Enviar-RabbitMQ `
        -Metodo "GET" `
        -Ruta "/api/queues/%2F/$colaDLQ"

    $politicaVerificada = Enviar-RabbitMQ `
        -Metodo "GET" `
        -Ruta "/api/policies/%2F/$nombrePolitica"

    if (
        $exchangeVerificado.name -ne $exchangeDLX -or
        $colaVerificada.name -ne $colaDLQ -or
        $politicaVerificada.name -ne $nombrePolitica
    ) {
        throw "La verificacion final no coincide con los recursos esperados."
    }

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host " CONFIGURACION COMPLETADA" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green

    Write-Host "Cola principal: pedidos"
    Write-Host "DLX: $exchangeDLX"
    Write-Host "DLQ: $colaDLQ"
    Write-Host "Routing key: $routingKey"
    Write-Host "Politica: $nombrePolitica"

    Write-Host ""
    Write-Host "RabbitMQ esta preparado para recibir" `
        "mensajes rechazados en la DLQ." `
        -ForegroundColor Green

}
catch {

    Write-Host ""
    Write-Host "ERROR CONFIGURANDO RABBITMQ" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    Write-Host ""
    Write-Host "Comprueba Docker, RabbitMQ y el puerto 15672." `
        -ForegroundColor Yellow

    exit 1
}
