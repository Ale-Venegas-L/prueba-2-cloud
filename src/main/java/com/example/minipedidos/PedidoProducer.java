package com.example.minipedidos;

import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

@Service
public class PedidoProducer {

    private final RabbitTemplate rabbitTemplate;

    public PedidoProducer(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void enviarPedido(Pedido pedido) {

        rabbitTemplate.convertAndSend(
            RabbitMQConfig.PEDIDOS_QUEUE,
            pedido
        );

        System.out.println("Pedido enviado a RabbitMQ: " + pedido);
    }
}