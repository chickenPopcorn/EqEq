SomeCtx = {
  a = { 42; }
  b = { 32; }

}

SomeCtx:find a with c in range(10, "abc", 0); { /* range can only take numbers as its arguments */
  print("%.0f\n", a);
}