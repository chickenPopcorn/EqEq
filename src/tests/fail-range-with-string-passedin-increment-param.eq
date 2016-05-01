SomeCtx = {
  a = { 42; }
}

/* range can only take numbers as its arguments */
SomeCtx:find a with c in range(3, 5, "abc"); {
  print("%.0f\n", a);
}
