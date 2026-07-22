#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <R_ext/Visibility.h>

extern SEXP qv_apply_1q(SEXP, SEXP, SEXP);
extern SEXP qv_apply_2q(SEXP, SEXP, SEXP, SEXP);

static const R_CallMethodDef call_methods[] = {
  {"qv_apply_1q", (DL_FUNC) &qv_apply_1q, 3},
  {"qv_apply_2q", (DL_FUNC) &qv_apply_2q, 4},
  {NULL, NULL, 0}
};

void attribute_visible R_init_qvivid(DllInfo *dll) {
  R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
  R_forceSymbols(dll, FALSE);
}
