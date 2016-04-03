SomeCtx = { a = { 42; } }

SomeCtx:find a {
  print("%0.0f\n", a);

  printf("%0.5f\n", 4.2e-4 );
  printf("%0.2f\n", 0.42   );
  printf("%0.2f\n", .42    );
  printf("%0.1f\n", 0e1    );
  printf("%0.0f\n", 4.2e4  );
  printf("%0.0f\n", -42    );
  printf("%0.5f\n", -4.2e-4);
  printf("%0.2f\n", -0.42  );
  printf("%0.2f\n", -.42   );
  printf("%0.1f\n", -0e1   );
  printf("%0.0f\n", -4.2e4 );

  printf("%f\n", 5 * -4.2e-4);
}
