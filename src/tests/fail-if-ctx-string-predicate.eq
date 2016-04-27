SomeContext = {
  a = { 42.333; }
  b = { if ("hello world"){
          print("inside: if!\n");
          1;
        }
        else if ("hello world") {
          print("inside: else if!\n");
          0;
        }
      }
}

SomeContext:find a {
}
