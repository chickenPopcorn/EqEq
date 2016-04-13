SomeCtx = {
  a = { 42; }
  b = { 32; }

}

SomeCtx:find a with c in range(); {
  print("print for find with range (0,3,1)\n");
  print("a = %0.0f\n", a);
  print("b = %0.0f\n", b);
  print("c = %0.0f\n", c);
}