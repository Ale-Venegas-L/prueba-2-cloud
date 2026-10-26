#!/bin/bash
set -euo pipefail

# Configuración RabbitMQ (management API)
HOST="http://localhost:15672"
usuario="guest"
passwd="guest"

# Topología de cola normal
exchangePrincipal="pedidos.exchange"
colaPrincipal="pedidos.cola"
routingKeyPrincipal="pedidos.nuevo"

exchangeDLX="pedidos.dlx"
colaDLQ="pedidos.dlq"
routingKeyError="pedidos.error"
nombrePolitica="pedidos-dlx-policy"

log() { echo -e "\n==> $1"; }

# 1. Verificar conexión a RabbitMQ (overview)
log "Verificando conexión a RabbitMQ en $HOST"
if ! curl -sf -u "$usuario:$passwd" "$HOST/api/overview" > /dev/null; then
    echo "ERROR: No se pudo conectar a RabbitMQ. ¿Está corriendo el contenedor?" >&2
    exit 1
fi
echo "Conexión exitosa."

# 2. Verificar cola principal
log "Verificando cola principal: $colaPrincipal"
if curl -sf -u "$usuario:$passwd" "$HOST/api/queues/%2F/$colaPrincipal" > /dev/null; then
    echo "La cola $colaPrincipal ya existe."
else
    echo "ERROR: La cola principal $colaPrincipal no existe. Inicie la app Spring Boot primero." >&2
    exit 1
fi

# 3. Crear DLX (direct exchange)
log "Creando Dead Letter Exchange: $exchangeDLX"
curl -sf -u "$usuario:$passwd" \
    -X PUT "$HOST/api/exchanges/%2F/$exchangeDLX" \
    -H "Content-Type: application/json" \
    -d '{"type":"direct","durable":true}'
echo "DLX creado (o ya existía)."

# 4. Crear DLQ
log "Creando Dead Letter Queue: $colaDLQ"
curl -sf -u "$usuario:$passwd" \
    -X PUT "$HOST/api/queues/%2F/$colaDLQ" \
    -H "Content-Type: application/json" \
    -d '{"durable":true}'
echo "DLQ creada (o ya existía)."

# 5. Vincular DLQ al DLX
log "Vinculando DLQ al DLX con routing key: $routingKeyError"
curl -sf -u "$usuario:$passwd" \
    -X POST "$HOST/api/bindings/%2F/e/$exchangeDLX/%2F/$colaDLQ" \
    -H "Content-Type: application/json" \
    -d "{\"routing_key\":\"$routingKeyError\"}"
echo "Binding DLX -> DLQ creado."

# 6. Crear política para enrutar mensajes fallidos de la cola principal al DLX
log "Creando política: $nombrePolitica"
curl -sf -u "$usuario:$passwd" \
    -X PUT "$HOST/api/policies/%2F/$nombrePolitica" \
    -H "Content-Type: application/json" \
    -d "{\"pattern\":\"^$colaPrincipal$\",\"definition\":{\"dead-letter-exchange\":\"$exchangeDLX\",\"dead-letter-routing-key\":\"$routingKeyError\"},\"priority\":0,\"apply-to\":\"queues\"}"
echo "Política creada."

# 7. Verificación final
log "Verificación final"
echo "--- Exchanges ---"
curl -sf -u "$usuario:$passwd" "$HOST/api/exchanges/%2F" | python3 -c "import sys,json; [print(e['name'], e['type']) for e in json.load(sys.stdin)]"
echo "--- Colas ---"
curl -sf -u "$usuario:$passwd" "$HOST/api/queues/%2F" | python3 -c "import sys,json; [print(q['name']) for q in json.load(sys.stdin)]"
echo "--- Políticas ---"
curl -sf -u "$usuario:$passwd" "$HOST/api/policies/%2F" | python3 -c "import sys,json; [print(p['name'], p['pattern']) for p in json.load(sys.stdin)]"

log "Setup completado."
