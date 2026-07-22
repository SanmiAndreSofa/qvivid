#!/usr/bin/env Rscript

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
for (path in c("R/utils.R", "R/circuit.R", "R/gates.R", "R/simulate.R")) {
  source(file.path(root, path), chdir = FALSE)
}

sizes <- c(8L, 12L, 16L, 20L)
results <- lapply(sizes, function(n_qubits) {
  circuit <- quantum_circuit(n_qubits, name = sprintf("%d-qubit benchmark", n_qubits))
  for (layer in seq_len(5L)) {
    for (qubit in seq_len(n_qubits)) {
      circuit <- gate_ry(circuit, qubit, theta = 0.013 * (layer + qubit))
    }
    for (qubit in seq.int(1L, n_qubits - 1L, by = 2L)) {
      circuit <- gate_cx(circuit, qubit, qubit + 1L)
    }
  }

  elapsed <- system.time(
    result <- simulate_quantum(circuit, backend = "reference")
  )[["elapsed"]]
  stopifnot(abs(sum(Mod(result$state)^2) - 1) < 1e-9)
  data.frame(
    qubits = n_qubits,
    amplitudes = 2^n_qubits,
    gates = length(circuit$operations),
    state_mib = 16 * 2^n_qubits / 1024^2,
    elapsed_seconds = elapsed
  )
})

output <- do.call(rbind, results)
rownames(output) <- NULL
print(output, row.names = FALSE)

