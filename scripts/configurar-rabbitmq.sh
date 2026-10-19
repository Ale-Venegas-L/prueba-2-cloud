#!/usr/bin/env bash
# ==============================================================
# MINI PEDIDOS - CONFIGURACION AUTOMATICA DE RABBITMQ
# PASO 11 - DEAD LETTER EXCHANGE (DLX) Y DEAD LETTER QUEUE (DLQ)
# ==============================================================
#
# Requisitos:
# - Docker iniciado
# - Contenedor RabbitMQ funcionando
# - RabbitMQ Management disponible en localhost:15672
#
# El script NO elimina colas ni mensajes existentes.
# ==============================================================

set -euo pipefail

# --------------------------------------------------------------
# 1. CONFIGURACION DEL ENTORNO LOCAL
# --------------------------------------------------------------

RABBIT_URL="http://localhost:15672"
USUARIO="guest"
CONTRASENA="guest"

EXCHANGE_DLX="pedidos.dlx"
COLA_DLQ="pedidos.dlq"
ROUTING_KEY="pedidos.error"
NOMBRE_POLITICA="pedidos-dlx-policy"

echo ""
echo "============================================"
echo " MINI PEDIDOS - CONFIGURACION RABBITMQ"
echo "============================================"

# --------------------------------------------------------------
# 2. PREPARAR AUTENTICACION
# --------------------------------------------------------------

CREDENCIALES="$(printf '%s' "${USUARIO}:${CONTRASENA}" | base64 -w0)"

# --------------------------------------------------------------
# 3. FUNCION PARA ENVIAR SOLICITUDES A RABBITMQ
# --------------------------------------------------------------

enviar_rabbitmq() {
    local metodo="$1"
    local ruta="$2"
    local datos="${3:-}"

    local url="${RABBIT_URL}${ruta}"

    if [[ -n "$datos" ]]; then
        curl -sS -f -X "$metodo" "$url" \
            -H "Authorization: Basic ${CREDENCIALES}" \
            -H "Content-Type: application/json" \
            -d "$datos"
    else
        curl -sS -f -X "$metodo" "$url" \
            -H "Authorization: Basic ${CREDENCIALES}"
    fi
}

trap 'echo ""; echo "ERROR CONFIGURANDO RABBITMQ"; echo "Comprueba Docker, RabbitMQ y el puerto 15672."; exit 1' ERR

# ----------------------------------------------------------
# 4. VERIFICAR CONEXION CON RABBITMQ
# ----------------------------------------------------------

echo ""
echo "[1/6] Verificando RabbitMQ..."

enviar_rabbitmq GET "/api/overview" > /dev/null

echo "RabbitMQ disponible."

# ----------------------------------------------------------
# 5. VERIFICAR QUE EXISTA LA COLA PRINCIPAL
# ----------------------------------------------------------

echo ""
echo "[2/6] Verificando cola principal..."

enviar_rabbitmq GET "/api/queues/%2F/pedidos" > /dev/null

echo "Cola pedidos encontrada."

# ----------------------------------------------------------
# 6. CREAR DEAD LETTER EXCHANGE
# ----------------------------------------------------------

echo ""
echo "[3/6] Configurando DLX..."

DATOS_EXCHANGE='{"type":"direct","durable":true,"auto_delete":false,"internal":false,"arguments":{}}'

enviar_rabbitmq PUT "/api/exchanges/%2F/${EXCHANGE_DLX}" "$DATOS_EXCHANGE" > /dev/null

echo "DLX configurada: ${EXCHANGE_DLX}"

# ----------------------------------------------------------
# 7. CREAR DEAD LETTER QUEUE
# ----------------------------------------------------------

echo ""
echo "[4/6] Configurando DLQ..."

DATOS_COLA='{"durable":true,"auto_delete":false,"arguments":{}}'

enviar_rabbitmq PUT "/api/queues/%2F/${COLA_DLQ}" "$DATOS_COLA" > /dev/null

echo "DLQ configurada: ${COLA_DLQ}"

# ----------------------------------------------------------
# 8. VINCULAR DLX CON DLQ
# ----------------------------------------------------------

echo ""
echo "[5/6] Vinculando DLX con DLQ..."

DATOS_BINDING="{\"routing_key\":\"${ROUTING_KEY}\",\"arguments\":{}}"

enviar_rabbitmq POST "/api/bindings/%2F/e/${EXCHANGE_DLX}/q/${COLA_DLQ}" "$DATOS_BINDING" > /dev/null

echo "Vinculacion configurada."
echo "Routing key: ${ROUTING_KEY}"

# ----------------------------------------------------------
# 9. CREAR POLITICA PARA LA COLA PRINCIPAL
# ----------------------------------------------------------

echo ""
echo "[6/6] Configurando politica DLX..."

DATOS_POLITICA="{\"pattern\":\"^pedidos\$\",\"apply_to\":\"queues\",\"priority\":10,\"definition\":{\"dead-letter-exchange\":\"${EXCHANGE_DLX}\",\"dead-letter-routing-key\":\"${ROUTING_KEY}\"}}"

enviar_rabbitmq PUT "/api/policies/%2F/${NOMBRE_POLITICA}" "$DATOS_POLITICA" > /dev/null

echo "Politica configurada: ${NOMBRE_POLITICA}"

# ----------------------------------------------------------
# 10. VERIFICACION FINAL
# ----------------------------------------------------------

EXCHANGE_VERIFICADO="$(enviar_rabbitmq GET "/api/exchanges/%2F/${EXCHANGE_DLX}")"
COLA_VERIFICADA="$(enviar_rabbitmq GET "/api/queues/%2F/${COLA_DLQ}")"
POLITICA_VERIFICADA="$(enviar_rabbitmq GET "/api/policies/%2F/${NOMBRE_POLITICA}")"

if ! grep -q "\"name\":\"${EXCHANGE_DLX}\"" <<< "$EXCHANGE_VERIFICADO" ||
   ! grep -q "\"name\":\"${COLA_DLQ}\"" <<< "$COLA_VERIFICADA" ||
   ! grep -q "\"name\":\"${NOMBRE_POLITICA}\"" <<< "$POLITICA_VERIFICADA"; then
    echo "La verificacion final no coincide con los recursos esperados."
    exit 1
fi

trap - ERR

echo ""
echo "============================================"
echo " CONFIGURACION COMPLETADA"
echo "============================================"
echo "Cola principal: pedidos"
echo "DLX: ${EXCHANGE_DLX}"
echo "DLQ: ${COLA_DLQ}"
echo "Routing key: ${ROUTING_KEY}"
echo "Politica: ${NOMBRE_POLITICA}"
echo ""
echo "RabbitMQ esta preparado para recibir mensajes rechazados en la DLQ."
