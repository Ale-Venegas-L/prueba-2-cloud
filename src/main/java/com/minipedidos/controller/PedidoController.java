package com.minipedidos.controller;

import com.minipedidos.model.Pedido;
import com.minipedidos.producer.PedidoProducer;

import jakarta.validation.Valid;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicLong;

@RestController
@RequestMapping("/api/pedidos")
public class PedidoController {
    private final List<Pedido> pedidos = new ArrayList<>();
    private final AtomicLong secuencia = new AtomicLong(1000);
    private final PedidoProducer pedidoProducer;

    public PedidoController(PedidoProducer pedidoProducer) {
        this.pedidoProducer = pedidoProducer;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public synchronized Pedido crearPedido(@RequestBody Pedido pedido) {
        pedido.setPedidoId(secuencia.incrementAndGet());
        pedido.setEstado("PENDIENTE");
        pedidos.add(pedido);
        pedidoProducer.enviarPedido("Pedido creado - ID: " + pedido.getPedidoId());
        return pedido;
    }

    @GetMapping
    public synchronized List<Pedido> listarPedidos() {
        return new ArrayList<>(pedidos);
    }
}
