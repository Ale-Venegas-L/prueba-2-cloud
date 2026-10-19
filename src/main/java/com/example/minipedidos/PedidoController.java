package com.example.minipedidos;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class PedidoController {

    private final PedidoProducer pedidoProducer;
    private final PedidoSqsProducer pedidoSqsProducer;

    public PedidoController(
            PedidoProducer pedidoProducer,
            PedidoSqsProducer pedidoSqsProducer) {

        this.pedidoProducer = pedidoProducer;
        this.pedidoSqsProducer = pedidoSqsProducer;
    }

    @PostMapping("/pedidos")
    public String crearPedido(@RequestBody Pedido pedido) {

        System.out.println("Pedido recibido por la API: " + pedido);

        // RabbitMQ
        pedidoProducer.enviarPedido(pedido);

        // SQS / ElasticMQ
        pedidoSqsProducer.enviarPedido(pedido);

        return "Pedido enviado correctamente a RabbitMQ y SQS";
    }
}