const formulario = document.getElementById("formPedido");
const resultado = document.getElementById("resultado");
const boton = document.getElementById("btnEnviar");

formulario.addEventListener("submit", async function (event) {

    event.preventDefault();

    const cliente = document.getElementById("cliente").value.trim();
    const producto = document.getElementById("producto").value;
    const cantidad = Number(document.getElementById("cantidad").value);

    resultado.style.display = "none";
    if (!cliente || !producto || !Number.isInteger(cantidad) || cantidad < 1) {
        mostrarResultado("Complete correctamente todos los campos.", false);
        return;
    }

    const pedido = {
        cliente: cliente,
        producto: producto,
        cantidad: cantidad
    };

    boton.disabled = true;

    try {

        const respuesta = await fetch("/api/pedidos", {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify(pedido)
        });

        if (!respuesta.ok) {
            throw new Error("HTTP " + respuesta.status);
        }

        const datos = await respuesta.json();

        mostrarResultado(
            "Pedido aceptado para procesamiento\n" +
            "ID: " + datos.pedidoId + "\n" +
            "Estado: " + datos.estado,
            true
        );

        formulario.reset();
        document.getElementById("cantidad").value = 1;

    } catch (error) {

        mostrarResultado(
            "Error al enviar el pedido: " + error.message,
            false
        );

    } finally {
        boton.disabled = false;
    }

});

function mostrarResultado(mensaje, correcto) {

    resultado.textContent = mensaje;
    resultado.className = correcto ? "exito" : "error";
    resultado.style.display = "block";

}