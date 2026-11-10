#!/bin/bash
set -e

KAFKA_BOOTSTRAP="localhost:9092"
TOPICO_PEDIDOS="pedidos-creados"
TOPICO_ALERTAS="pedidos-alertas"

show_menu() {
    clear
    echo "================================="
    echo "  Administración de Kafka"
    echo "================================="
    echo ""
    echo "1. Listar topicos"
    echo "2. Consultar particiones y replicas"
    echo "3. Crear topico"
    echo "4. Consultar configuraciones"
    echo "5. Modificar retencion"
    echo "6. Salir"
    echo ""
    read -p "Seleccione una opcion [1-6]: " opcion
}

list_topics() {
    echo ""
    echo "Topics disponibles:"
    docker exec kafka /opt/kafka/bin/kafka-topics.sh \
        --list \
        --bootstrap-server "$KAFKA_BOOTSTRAP"
    echo ""
    read -p "Presione Enter para continuar..."
}

check_topic_config() {
    local topic=$1
    echo ""
    echo "Configuracion de $topic:"
    docker exec kafka /opt/kafka/bin/kafka-topics.sh \
        --describe \
        --topic "$topic" \
        --bootstrap-server "$KAFKA_BOOTSTRAP"
    echo ""
    read -p "Presione Enter para continuar..."
}

create_topic() {
    read -p "Nombre del topic: " topic
    read -p "Particiones [3]: " partitions
    partitions=${partitions:-3}
    read -p "ReplicationFactor [1]: " replication
    replication=${replication:-1}

    echo "Creando topic $topic..."
    docker exec kafka /opt/kafka/bin/kafka-topics.sh \
        --create \
        --topic "$topic" \
        --bootstrap-server "$KAFKA_BOOTSTRAP" \
        --partitions "$partitions" \
        --replication-factor "$replication"

    echo "Topic creado exitosamente."
    echo ""
    read -p "Presione Enter para continuar..."
}

consult_configs() {
    echo ""
    echo "Configuraciones del topic $TOPICO_PEDIDOS:"
    docker exec kafka /opt/kafka/bin/kafka-configs.sh \
        --describe \
        --entity-type topics \
        --entity-name "$TOPICO_PEDIDOS" \
        --bootstrap-server "$KAFKA_BOOTSTRAP"

    echo ""
    echo "Configuraciones del topic $TOPICO_ALERTAS:"
    docker exec kafka /opt/kafka/bin/kafka-configs.sh \
        --describe \
        --entity-type topics \
        --entity-name "$TOPICO_ALERTAS" \
        --bootstrap-server "$KAFKA_BOOTSTRAP"

    echo ""
    read -p "Presione Enter para continuar..."
}

modify_retencion() {
    read -p "Topic [pedidos-creados]: " topic
    topic=${topic:-pedidos-creados}
    read -p "Retencion en ms [604800000]: " retention
    retention=${retention:-604800000}

    echo "Modificando retencion para $topic..."
    docker exec kafka /opt/kafka/bin/kafka-configs.sh \
        --alter \
        --entity-type topics \
        --entity-name "$topic" \
        --config retention.ms=$retention \
        --bootstrap-server "$KAFKA_BOOTSTRAP"

    echo "Retencion actualizada."
    echo ""
    read -p "Presione Enter para continuar..."
}

main() {
    while true; do
        show_menu

        case $opcion in
            1) list_topics ;;
            2) check_topic_config "$TOPICO_PEDIDOS" ;;
            3) create_topic ;;
            4) consult_configs ;;
            5) modify_retencion ;;
            6) echo "Saliendo..."; break ;;
            *) echo "Opcion invalida"; sleep 1 ;;
        esac
    done
}

main