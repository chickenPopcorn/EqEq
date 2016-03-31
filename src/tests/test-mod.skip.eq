SomeContext = {
   a = { 42; }
   a = {a % 2;}

}

SomeContext: find a {
   print ("%.0f\n", a);
}
