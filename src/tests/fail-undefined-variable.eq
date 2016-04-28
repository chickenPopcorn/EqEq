TownCtx= {
  people = {17;}
}


TownCtx:find acres {
  print("to support the people we need %0.0f acres\n", acres);
  /*error: acres not defined*/
}
