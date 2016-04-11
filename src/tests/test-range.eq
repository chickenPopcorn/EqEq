SomeCtx = {
  a = { 42; }
  b = { 32; }

}

SomeCtx:find a {
   print("print for simple find\n");
   print("a = %0.0f\n", a);
   print("b = %0.0f\n", b);
}

SomeCtx:find a with c in range(0,3); {
  print("print for find with range (0,3)\n");
  print("a = %0.0f\n", a);
  print("b = %0.0f\n", b);
  print("c = %0.0f\n", c);
}

/*
SomeCtx:find a with c in range(2,-1); {
  print("print for find with range (2,-1)\n");
  print("a = %0.0f\n", a);
  print("b = %0.0f\n", b);
  print("c = %0.0f\n", c);
}


SomeCtx:find a with c in range(-1,-1); {
  print("print for find with range (-1,-1)\n");
  print("a = %0.0f\n", a);
  print("b = %0.0f\n", b);
  print("c = %0.0f\n", c);
}

SomeCtx:find a with b = 10; c in range(0,2); {
  print("print for find with range (0,2)\n");
  print("a = %0.0f\n", a);
  print("b = %0.0f\n", b);
  print("c = %0.0f\n", c);
}
*/