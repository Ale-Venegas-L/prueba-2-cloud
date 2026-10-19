package com.example.minipedidos;

import org.springframework.amqp.core.AmqpAdmin;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.support.converter.JacksonJsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    public static final String PEDIDOS_QUEUE = "pedidos";

    @Bean
    public Queue pedidosQueue() {
        return new Queue(PEDIDOS_QUEUE, true);
    }

    @Bean
    public ApplicationRunner inicializarRabbitMQ(AmqpAdmin amqpAdmin) {
        return args -> amqpAdmin.initialize();
    }
    
    @Bean
    public MessageConverter jsonMessageConverter() {
        return new JacksonJsonMessageConverter();
    }
}