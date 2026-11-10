package com.minipedidos;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;

@Configuration
@EnableWebMvc
@SpringBootApplication
@ComponentScan({"com.minipedidos", "com.minipedidos.admin", "com.minipedidos.controller", "com.minipedidos.producer", "com.minipedidos.model"})
public class MinipedidosApplication {

	public static void main(String[] args) {
		SpringApplication.run(MinipedidosApplication.class, args);
	}

}
