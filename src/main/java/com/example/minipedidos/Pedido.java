package com.example.minipedidos;

public class Pedido {

    private Long id;
    private String producto;
    private Integer cantidad;
    private String cliente;

    public Pedido() {
    }

    public Pedido(Long id, String producto, Integer cantidad, String cliente) {
        this.id = id;
        this.producto = producto;
        this.cantidad = cantidad;
        this.cliente = cliente;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getProducto() {
        return producto;
    }

    public void setProducto(String producto) {
        this.producto = producto;
    }

    public Integer getCantidad() {
        return cantidad;
    }

    public void setCantidad(Integer cantidad) {
        this.cantidad = cantidad;
    }

    public String getCliente() {
        return cliente;
    }

    public void setCliente(String cliente) {
        this.cliente = cliente;
    }

    @Override
    public String toString() {
        return "Pedido{" +
                "id=" + id +
                ", producto='" + producto + '\'' +
                ", cantidad=" + cantidad +
                ", cliente='" + cliente + '\'' +
                '}';
    }
}