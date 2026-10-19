
package com.example.minipedidos;

import com.rabbitmq.client.Channel;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;

import java.io.IOException;

@Service
public class PedidoConsumer {

    @RabbitListener(queues = RabbitMQConfig.PEDIDOS_QUEUE)
    public void procesarPedido(
            Pedido pedido,
            Channel channel,
            Message message) throws IOException {

        long deliveryTag = message.getMessageProperties().getDeliveryTag();

        try {
            System.out.println("==============================");
            System.out.println("CONSUMIDOR RABBITMQ - Pedido recibido");
            System.out.println("ID: " + pedido.getId());
            System.out.println("Producto: " + pedido.getProducto());
            System.out.println("Cantidad: " + pedido.getCantidad());
            System.out.println("Cliente: " + pedido.getCliente());

            // Validacion del pedido antes de confirmar
            if (pedido.getCantidad() == null
                    || pedido.getCantidad() <= 0) {

                throw new IllegalArgumentException(
                        "Cantidad invalida: debe ser mayor que cero"
                );
            }

            // Confirmar un pedido valido
            channel.basicAck(deliveryTag, false);

            System.out.println("Pedido procesado correctamente");
            System.out.println("ACK enviado correctamente");
            System.out.println("==============================");

        } catch (IllegalArgumentException e) {

            System.err.println(
                    "Pedido rechazado: " + e.getMessage()
            );

            // Rechazar sin reencolar
            channel.basicNack(deliveryTag, false, false);

            System.err.println("NACK enviado. Requeue = false");
            System.err.println(
                    "Mensaje enviado a DLX para su enrutamiento a DLQ"
            );

        } catch (Exception e) {

            System.err.println(
                    "Error inesperado procesando pedido: "
                            + e.getMessage()
            );

            // Rechazo provisional sin reencolar.
            // Posteriormente incorporaremos reintentos limitados.
            channel.basicNack(deliveryTag, false, false);

            System.err.println("NACK enviado. Requeue = false");
        }
    }
}
