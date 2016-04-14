SomeCtx = {
  a = { 42; }
  b = { 32; }
}

SomeCtx:find a in b = 3; { /* 'in' need to be fellowed by range */
  print("%0.0f\n", a);
}