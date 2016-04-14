SomeCtx = {
  a = { 42; }
  b = { 32; }

}

SomeCtx:find a with c in range("abc"); { /* range can only take numbers as its arguments */
  print("%.0f\n", a);
}