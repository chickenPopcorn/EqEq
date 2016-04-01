SomeCtx = {
  a = { -52; }
}
SomeCtx:find a {
  print("the value of a is %.0f\n", a );
  print("the value of a %% 3 is %.0f\n", a % 3 );
  print("the value of | a %% 3 | is %.0f\n", | a % 3 | );
  print("the value of | a %% 3 | + 2 is %.0f\n", | a % 3 | + 2 );
  print("the value of - ( | a %% 3 | + 2 ) is %.0f\n", - ( | a % 3 | + 2 ) );
}