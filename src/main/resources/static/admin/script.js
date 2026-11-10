const formAdmin = document.getElementById("form-admin");
const selectOp = document.getElementById("operacion");
const camposDiv = document.getElementById("campos-admin");
const resultadoDiv = document.createElement("div");
resultadoDiv.setAttribute("role", "status");
resultadoDiv.setAttribute("aria-live", "polite");
document.body.appendChild(resultadoDiv);

const operations = {
    list: { title: "Listar tópicos", endpoint: "/api/topics", needsName: false },
    consult: { title: "Consultar particiones y réplicas", endpoint: "/api/topics/config", needsName: false },
    crear: { title: "Crear tópico", endpoint: "/api/topics", needsName: true },
    config: { title: "Consultar configuraciones", endpoint: "/api/topics/config", needsName: false },
    ret: { title: "Modificar retención", endpoint: "/api/topics/config", needsName: true }
};

function crearCampoNombre(op) {
    if (operations[op].needsName) {
        const div = document.createElement("div");
        div.className = "field";
        div.innerHTML = `<label for="nombre-topico">Nombre del topic</label><input type="text" id="nombre-topico" class="field-input" required placeholder="ej: pedidos-nuevos">`;
        return div;
    }
    return null;
}

function crearCampoRetencion() {
    const div = document.createElement("div");
    div.className = "field";
    div.innerHTML = `<label for="field-ret-retention">Retencion en ms</label><input type="number" id="field-ret-retention" class="field-input" value="604800000" min="1">`;
    return div;
}

function showField(op) {
    camposDiv.innerHTML = "";
    const opData = operations[op];
    const titleLabel = document.getElementById("operacion-label");
    if (titleLabel) titleLabel.textContent = opData.title;

    if (opData.needsName) {
        const nombreCampo = crearCampoNombre(op);
        if (nombreCampo) camposDiv.appendChild(nombreCampo);
    }

    if (op === "ret") {
        const retCampo = crearCampoRetencion();
        if (retCampo) camposDiv.appendChild(retCampo);
    }
}

async function consultAPI(url, method = "GET", body = null) {
    const headers = { "Content-Type": "application/json" };
    const options = { method, headers };
    if (body) options.body = JSON.stringify(body);

    const resp = await fetch(url, options);
    if (!resp.ok) {
        throw new Error("HTTP " + resp.status);
    }
    return await resp.json();
}

function mostrarResultado(mensaje, correcto) {
    resultadoDiv.textContent = mensaje;
    resultadoDiv.className = correcto ? "exito" : "error";
    resultadoDiv.style.display = "block";
    setTimeout(() => resultadoDiv.style.display = "none", 5000);
}

selectOp.addEventListener("change", () => {
    const op = selectOp.value;
    showField(op);
    resultadoDiv.style.display = "none";
});

// Inicializar al cargar
document.dispatchEvent(new Event("change"));