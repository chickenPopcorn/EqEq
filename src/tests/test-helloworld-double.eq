SomeContext = {
  a = { 42; }
}

SomeContext:find a {
  print("%.0f\n", a);
}
