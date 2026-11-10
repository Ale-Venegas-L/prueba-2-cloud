#!/bin/bash
set -e

TOPICO1="pedidos-creados"
TOPICO2="pedidos-alertas"
PARTICIONES_ESPERADAS=3
FACTOR_REPLICACION_ESPERADO=1

echo "================================="
echo "  Kafka Verification Script"
echo "================================="
echo ""

ERRORS=0

check_topic() {
    local topic=$1
    echo "Verificando tópico: $topic..."

    # Verificar si el topic existe
    if ! docker exec kafka /opt/kafka/bin/kafka-topics.sh \
        --describe \
        --topic "$topic" \
        --bootstrap-server localhost:9092 >/dev/null 2>&1; then
        echo "ERROR: Tópico $topic no existe."
        ERRORS=$((ERRORS + 1))
        return 1
    fi

    # Obtener configuración del topic
    local desc=$(docker exec kafka /opt/kafka/bin/kafka-topics.sh \
        --describe \
        --topic "$topic" \
        --bootstrap-server localhost:9092 2>&1)

    local partition_count=$(echo "$desc" | grep -oP 'PartitionCount:\s*\K\d+' || echo "0")
    local replication_factor=$(echo "$desc" | grep -oP 'ReplicationFactor:\s*\K\d+' || echo "0")

    echo "  Partitions: $partition_count (esperado: $PARTICIONES_ESPERADAS)"
    echo "  ReplicationFactor: $replication_factor (esperado: $FACTOR_REPLICACION_ESPERADO)"

    if [ "$partition_count" -ne "$PARTICIONES_ESPERADAS" ]; then
        echo "ERROR: $topic tiene $partition_count particiones, esperado $PARTICIONES_ESPERADAS"
        ERRORS=$((ERRORS + 1))
    fi

    if [ "$replication_factor" -ne "$FACTOR_REPLICACION_ESPERADO" ]; then
        echo "ERROR: $topic tiene factor de replicación $replication_factor, esperado $FACTOR_REPLICACION_ESPERADO"
        ERRORS=$((ERRORS + 1))
    fi

    echo ""
}

check_topic "$TOPICO1"
check_topic "$TOPICO2"

echo "================================="
echo "  Resumen de verificación"
echo "================================="
echo "Total de errores: $ERRORS"

if [ "$ERRORS" -eq 0 ]; then
    echo "Todas las verificaciones pasaron correctamente."
    exit 0
else
    echo "Se detectaron errores de configuración."
    exit 1
fi