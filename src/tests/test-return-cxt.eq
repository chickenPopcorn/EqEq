SomeContext = {
  a={ if(1){
        40;}
      else{
	      1;}
    }
}
SomeContext: find a {
  print("%.0f\n",a + 2);
}
