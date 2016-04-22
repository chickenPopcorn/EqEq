SomeContext = {
  a = { 42.333; }
  b = { if (a=b){
          print("inside: if!\n");
        }
        else{
          print("inside: else!\n");
        }
      }
}

SomeContext:find a {
}
