SomeCtx = { a = { 42; } }

SomeCtx:find a {
  print("%0.0f\n", a);
  print("%0.5f\n", 4.2e-4 );
  print("%0.2f\n", 0.42   );
  print("%0.2f\n", .42    );
  print("%0.1f\n", 0e1    );
  print("%0.0f\n", 4.2e4  );
  print("%0.0f\n", -42    );
  print("%0.5f\n", -4.2e-4);
  print("%0.2f\n", -0.42  );
  print("%0.2f\n", -.42   );
  print("%0.1f\n", -0e1   );
  print("%0.0f\n", -4.2e4 );
  print("%f\n", 5 * -4.2e-4);
}
