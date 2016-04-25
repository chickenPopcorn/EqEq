SomeContext = {
  a = { 42.333; }
  b = { if (print("")){
          print("inside: if!\n");
        }
        else{
          print("inside: else!\n");
        }
      }
}

SomeContext:find a {
}
