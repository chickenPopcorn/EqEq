SomeContext = {
  a = { 42.333; }

}

SomeContext:find a {
  a =log(cos(30));
  print("%0.2f\n", a);
}
