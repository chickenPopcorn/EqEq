Gcd = {
    gcd = {
        if (b == 0) { a; }
        else if (a == 0) { b; }
        else if (a == b ){ a; }

        if (a > b) {
            a = b;
            b = a % b;
        }
        else {
            a = b % a;
            b = a;
        }
        gcd;
    }
}

Gcd:find gcd {
    a = 10;
    b = 20;
    print("gcd between %0.f and %0.f is %0.f\n", a, b, gcd);
}
