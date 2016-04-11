SomeContext = {
  a = { 42.333; }
}

SomeContext:find a {
  if (3>4){
    print("inside: if!\n");
  } else if (  ) {
    print("inside: else if!\n");
  }
}
