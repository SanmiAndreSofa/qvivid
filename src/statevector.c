#include <R.h>
#include <Rinternals.h>
#include <R_ext/Utils.h>

#define QV_INTERRUPT_INTERVAL ((R_xlen_t) 262144)

static Rcomplex qv_add(Rcomplex left, Rcomplex right) {
  Rcomplex result;
  result.r = left.r + right.r;
  result.i = left.i + right.i;
  return result;
}

static Rcomplex qv_multiply(Rcomplex left, Rcomplex right) {
  Rcomplex result;
  result.r = left.r * right.r - left.i * right.i;
  result.i = left.r * right.i + left.i * right.r;
  return result;
}

SEXP qv_apply_1q(SEXP state_sexp, SEXP gate_sexp, SEXP qubit_sexp) {
  if (TYPEOF(state_sexp) != CPLXSXP || TYPEOF(gate_sexp) != CPLXSXP) {
    error("Native state and gate inputs must use complex storage.");
  }
  if (XLENGTH(gate_sexp) != 4) {
    error("A one-qubit native gate must contain four complex entries.");
  }

  int qubit = asInteger(qubit_sexp);
  if (qubit < 1) {
    error("Native qubit indices are one-based and must be positive.");
  }

  R_xlen_t dimension = XLENGTH(state_sexp);
  R_xlen_t stride = 1;
  for (int index = 1; index < qubit; ++index) {
    stride *= 2;
  }
  if (stride <= 0 || 2 * stride > dimension || dimension % (2 * stride) != 0) {
    error("Native qubit index exceeds the statevector dimension.");
  }

  SEXP output_sexp = PROTECT(duplicate(state_sexp));
  Rcomplex *output = COMPLEX(output_sexp);
  const Rcomplex *gate = COMPLEX(gate_sexp);
  R_xlen_t processed = 0;

  for (R_xlen_t block = 0; block < dimension; block += 2 * stride) {
    for (R_xlen_t offset = 0; offset < stride; ++offset) {
      R_xlen_t index0 = block + offset;
      R_xlen_t index1 = index0 + stride;
      Rcomplex amplitude0 = output[index0];
      Rcomplex amplitude1 = output[index1];

      output[index0] = qv_add(
        qv_multiply(gate[0], amplitude0),
        qv_multiply(gate[2], amplitude1)
      );
      output[index1] = qv_add(
        qv_multiply(gate[1], amplitude0),
        qv_multiply(gate[3], amplitude1)
      );
      ++processed;
      if ((processed & (QV_INTERRUPT_INTERVAL - 1)) == 0) {
        R_CheckUserInterrupt();
      }
    }
  }

  UNPROTECT(1);
  return output_sexp;
}

SEXP qv_apply_2q(
    SEXP state_sexp,
    SEXP gate_sexp,
    SEXP qubit1_sexp,
    SEXP qubit2_sexp) {
  if (TYPEOF(state_sexp) != CPLXSXP || TYPEOF(gate_sexp) != CPLXSXP) {
    error("Native state and gate inputs must use complex storage.");
  }
  if (XLENGTH(gate_sexp) != 16) {
    error("A two-qubit native gate must contain sixteen complex entries.");
  }

  int qubit1 = asInteger(qubit1_sexp);
  int qubit2 = asInteger(qubit2_sexp);
  if (qubit1 < 1 || qubit2 < 1 || qubit1 == qubit2) {
    error("Native two-qubit gates require two distinct positive indices.");
  }

  R_xlen_t dimension = XLENGTH(state_sexp);
  R_xlen_t mask1 = 1;
  R_xlen_t mask2 = 1;
  for (int index = 1; index < qubit1; ++index) mask1 *= 2;
  for (int index = 1; index < qubit2; ++index) mask2 *= 2;
  if (mask1 <= 0 || mask2 <= 0 || mask1 >= dimension || mask2 >= dimension) {
    error("Native qubit index exceeds the statevector dimension.");
  }

  SEXP output_sexp = PROTECT(duplicate(state_sexp));
  Rcomplex *output = COMPLEX(output_sexp);
  const Rcomplex *gate = COMPLEX(gate_sexp);
  R_xlen_t processed = 0;

  for (R_xlen_t base = 0; base < dimension; ++base) {
    if ((base & mask1) != 0 || (base & mask2) != 0) continue;

    R_xlen_t indices[4];
    indices[0] = base;
    indices[1] = base + mask2;
    indices[2] = base + mask1;
    indices[3] = base + mask1 + mask2;

    Rcomplex amplitudes[4];
    Rcomplex updated[4];
    for (int column = 0; column < 4; ++column) {
      amplitudes[column] = output[indices[column]];
    }
    for (int row = 0; row < 4; ++row) {
      updated[row].r = 0;
      updated[row].i = 0;
      for (int column = 0; column < 4; ++column) {
        updated[row] = qv_add(
          updated[row],
          qv_multiply(gate[row + 4 * column], amplitudes[column])
        );
      }
    }
    for (int row = 0; row < 4; ++row) {
      output[indices[row]] = updated[row];
    }
    ++processed;
    if ((processed & (QV_INTERRUPT_INTERVAL - 1)) == 0) {
      R_CheckUserInterrupt();
    }
  }

  UNPROTECT(1);
  return output_sexp;
}
