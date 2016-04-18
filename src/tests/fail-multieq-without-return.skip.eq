SomeContext = {
  a = { print("42\n"); }
}

SomeContext:find a {
  print("%.0f\n", a);
}