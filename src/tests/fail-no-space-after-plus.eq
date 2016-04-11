SomeContext = {
 a={1;}
}

SomeContext: find a {
  print("%.0f\n",a+1); /* fail b/c space are needed after the + sign */
}