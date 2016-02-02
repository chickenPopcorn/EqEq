
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>

typedef struct BALL{
	double mass;
	double acc;
	double vel;
	double pos;
} BALL;

void printBlanks(int num){
	int i=0;
	for (i;i<num+39;i++) printf(" ");
}

int main(int argc, char** argv) {
	double springForce=0;
	double springConstant=1;    //F =-kx Hooke's Law
	double tstep = 0.1;
	BALL ball;
	ball.mass = 0.1;
	ball.vel = 0;
	ball.acc = 0;
	ball.pos = -39;
	
	while(1){
		springForce = -springConstant*ball.pos - ball.vel*0.1;
		ball.acc = springForce/ ball.mass;
		ball.vel += ball.acc*tstep;
		ball.pos += ball.vel*tstep;
		printf("\n\n\n\n");
		printBlanks(ball.pos);
		printf("O\n\n\n");
		usleep(50000);
		printf("\033[2J");
	}
	return (EXIT_SUCCESS);
}
