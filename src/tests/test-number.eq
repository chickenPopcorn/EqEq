SomeCtx = {
  a = { 42;      }
  b = { 4.2e-4;  }
  c = { 0.42;    }
  d = { .42;     }
/*
  e = { 0e1;     }
  f = { 4.2e4;   }

  g = { -42;     }
  h = { -4.2e-4; }
  i = { -0.42;   }
  j = { -.42;    }
  k = { -0e1;    }
  l = { -4.2e4;  }
*/
}

SomeCtx:find a {
/*
  print("%0.0f\n", a);
  print("%0.5f\n", b);
  print("%0.2f\n", c);
  print("%0.2f\n", d);
  print("%0.1f\n", e);
  print("%0.0f\n", f);

  print("%0.0f\n", g);
  print("%0.5f\n", h);
  print("%0.2f\n", i);
  print("%0.2f\n", j);
  print("%0.1f\n", k);
  print("%0.0f\n", l);
*/

  /*printf("5 * -4.2e-4 = %f\n", 5 * -4.2e-4);*/
}
