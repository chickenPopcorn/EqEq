SomeContext = {
  a = { 42.333; }
  b = {pr("%.0f\n", a);}
}

SomeContext:find a {
  print("%.0f\n", a);
}
