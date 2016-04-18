SomeContext = {
  a={1;}
}
SomeContext: find a {
 if(a==1){
   print("%.0f\n",a);
   continue;
   print("%.0f\n",a + 1);
}else{
   print("%.0f\n",a + 2);
  }
}
