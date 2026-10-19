package com.example.minipedidos;

import org.springframework.stereotype.Service;

import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;
import software.amazon.awssdk.services.sqs.model.SendMessageResponse;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;

@Service
public class PedidoSqsProducer {

    private static final String QUEUE_URL =
            "http://localhost:9324/000000000000/pedidos-mini";

    private final SqsClient sqsClient;
    private final ObjectMapper objectMapper;

    public PedidoSqsProducer(SqsClient sqsClient, ObjectMapper objectMapper) {
        this.sqsClient = sqsClient;
        this.objectMapper = objectMapper;
    }

    public void enviarPedido(Pedido pedido) {

        try {

            String pedidoJson =
                    objectMapper.writeValueAsString(pedido);

            SendMessageRequest request =
                    SendMessageRequest.builder()
                            .queueUrl(QUEUE_URL)
                            .messageBody(pedidoJson)
                            .build();

            SendMessageResponse response =
                    sqsClient.sendMessage(request);

            System.out.println(
                    "Pedido enviado a SQS. MessageId: "
                    + response.messageId()
            );

        } catch (JacksonException e) {

            throw new RuntimeException(
                    "Error convirtiendo Pedido a JSON",
                    e
            );
        }
    }
}