SomeContext = {
  a = { 42.333; }
}

SomeContext:find a {
  pr("%.0f\n", a);
}
