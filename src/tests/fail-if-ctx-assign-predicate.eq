SomeContext = {
  a = { 42.333; }
  b = { if (a=b){
          print("inside: if!\n");
          1;
        }
        else{
          print("inside: else!\n");
          0;
        }
      }
}

SomeContext:find a {
}
