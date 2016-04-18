SomeContext = {
  a = { 42.333; }

}

SomeContext:find a {
  print("%0.0f ", a)-print("%0.0f ", a);
}
