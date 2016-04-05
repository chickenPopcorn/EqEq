SomeContext = {
  a = {
    if (3>4){
      3;
    }
    else{
      4;
    }
  }

}

SomeContext: find a {
  print("variable a should print out %.0f\n", a);
}
