SomeContext = {
  a = { 42; }

}

SomeContext:find a {
  print("%0.2f\n", log(a));
}
