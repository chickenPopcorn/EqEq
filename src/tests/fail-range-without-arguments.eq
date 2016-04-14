SomeCtx = {
  a = { 42; }
  b = { 32; }

}

SomeCtx:find a with c in range(); { /* range has to take at least one argument */
  print("%.0f\n", a);
}