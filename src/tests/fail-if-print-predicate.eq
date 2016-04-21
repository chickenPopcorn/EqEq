SomeContext = {
  a = { 42.333; }
}

SomeContext:find a {
  if (print("")){
    print("inside: if!\n");
    }
  else{
    print("inside: else!\n");
  }
}
