package com.example.minipedidos;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class MiniPedidosApplication {

    public static void main(String[] args) {
        SpringApplication.run(MiniPedidosApplication.class, args);
    }
}