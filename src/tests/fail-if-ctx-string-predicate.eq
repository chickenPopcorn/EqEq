SomeContext = {
  a = { 42.333; }
  b = { if ("hello world"){
          print("inside: if!\n");
        }
        else if ("hello world") {
          print("inside: else if!\n");
        }
      }
}

SomeContext:find a {
}
