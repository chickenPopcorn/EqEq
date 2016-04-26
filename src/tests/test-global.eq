c = 1;;

SomeContext = {
     a={1;}
     b=1;
}


SomeContext: find a{
    while(a<4){
    print("%.0f\n",a);
    a=a+1;
    continue;
    print("%.0f\n",a);
  }
}