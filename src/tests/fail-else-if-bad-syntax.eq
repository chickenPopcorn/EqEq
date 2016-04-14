SomeContext = {
  a = { 42.333; }
}

SomeContext:find a {
  if (3 > 4){
    print("inside: if!\n");
  } elseif (3 < 4) {
    print("inside: else if!\n");
  }
}
