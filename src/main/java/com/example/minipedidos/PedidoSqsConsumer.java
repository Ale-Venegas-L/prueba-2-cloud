package com.example.minipedidos;

import java.util.List;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.DeleteMessageRequest;
import software.amazon.awssdk.services.sqs.model.Message;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageRequest;
import tools.jackson.databind.ObjectMapper;

@Service
public class PedidoSqsConsumer {

    private static final String QUEUE_URL =
            "http://localhost:9324/000000000000/pedidos-mini";

    private final SqsClient sqsClient;
    private final ObjectMapper objectMapper;

    public PedidoSqsConsumer(
            SqsClient sqsClient,
            ObjectMapper objectMapper) {

        this.sqsClient = sqsClient;
        this.objectMapper = objectMapper;
    }

    @Scheduled(fixedDelay = 3000)
    public void recibirPedidos() {

        ReceiveMessageRequest request =
                ReceiveMessageRequest.builder()
                        .queueUrl(QUEUE_URL)
                        .maxNumberOfMessages(10)
                        .waitTimeSeconds(1)
                        .build();

        List<Message> mensajes =
                sqsClient.receiveMessage(request).messages();

        for (Message mensaje : mensajes) {

            try {

                Pedido pedido =
                        objectMapper.readValue(
                                mensaje.body(),
                                Pedido.class
                        );

                System.out.println("==============================");
                System.out.println("CONSUMIDOR SQS - Pedido recibido");
                System.out.println("ID: " + pedido.getId());
                System.out.println("Producto: " + pedido.getProducto());
                System.out.println("Cantidad: " + pedido.getCantidad());
                System.out.println("Cliente: " + pedido.getCliente());
                System.out.println("Pedido SQS procesado correctamente");
                System.out.println("==============================");

                DeleteMessageRequest deleteRequest =
                        DeleteMessageRequest.builder()
                                .queueUrl(QUEUE_URL)
                                .receiptHandle(mensaje.receiptHandle())
                                .build();

                sqsClient.deleteMessage(deleteRequest);

                System.out.println(
                        "Mensaje eliminado de SQS: "
                        + mensaje.messageId()
                );

            } catch (Exception e) {

                System.err.println(
                        "Error procesando mensaje SQS: "
                        + e.getMessage()
                );
            }
        }
    }
}