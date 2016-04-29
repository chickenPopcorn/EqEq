myVal = 42; /* in the "global" context */

/* `find` doesn't prefix with a "context" */
find myVal {
  print("myVal is defined on the global context as %.0f\n", myVal);
}
