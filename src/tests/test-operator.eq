
SomeContext = {
   a = {1;}
   a = {a+5;}
   a = {a-5;}
   a = {a*5;}
 /*  a = {a/5;} */
   a = {a<5; }
}


SomeContext: find a {
   print("%.0f\n", a);
}
