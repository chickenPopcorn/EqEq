TownCtx= {
  people = {17;}
}

FarmCtx = {
  acres = {42;}
}

TownCtx:find people {
  print("to support %0.0f people we need many acres\n", people);
  print("to support the people we need %0.0f acres\n", acres); /* error: undefined acres */
}
