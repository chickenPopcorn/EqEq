SomeContext = {
  a = { 42.22; }
  a = { 25; }
}

SomeContext:find a {
  print("%.0f\n", a);
}
