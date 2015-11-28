/*******************************************************************************
 * 
 * 	This is a test program that uses libann
 * 
 * 	Author: Alexey Lyashko
 * 	Site:	syprog.blogspot.com
 * 
 ******************************************************************************/



#include <stdio.h>
#include "ann.h"
#include <math.h>

#define		ALPHA	0.99			// Learning rate
#define 	ETA		0.015			// Momentum


int main()
{
	/*	List of links	*/
	int			pairs[][2]={
							{1,3},
							{1,4},
							{2,4},
							{2,5},
							{3,6},
							{3,7},
							{4,6},
							{4,7},
							{5,6},
							{5,7},
							{0,0}};
	
	/*	The net	is allocated here	*/
	net_t*		net = net_alloc();
	
	/*	A couple of auxiliary variables	*/
	neuron_t*	n;
	synaps_t*	s;
	
	/*	Input values	*/
	double		v1[]={1.0, 0.0};
	double		v2[]={1.0, 1.0};
	double		v3[]={0.0, 1.0};
	double		v4[]={0.0, 0.0};
	
	/*	Expected outputs	*/
	double		t1[]={1.0, 0.0};
	double		t2[]={0.0, 1.0};
	double		t3[]={1.0, 0.0};
	double		t4[]={0.0, 1.0};
	
	/*	Status and quadratic error	*/
	double 		status, qe;
	
	/*	Counter	*/
	int			cnt=0;
	
	/*	Fill the net appropriately	*/
	net_fill(net, 7, 2, 2);
	
	/*	Setup synaptic links	*/
	net_set_links(net, &pairs[0][0]);
	
	/*	Set learning rate, momentum and activation function	*/
	net->rate = ALPHA;
	net->momentum = ETA;
	net->activation_mode = ACTIVATION_EXPONENTIAL;
	
	/*	Traing the network	*/
	do
	{
		cnt++;
		net_train(net, &v1[0], &t1[0]);
		printf("\r%10d\t\tResult: %0.5f %0.5f", cnt, net->outs->value, ((neuron_t*)(net->outs->neuron_list.next))->value);
		qe = net->qerror;
		
		net_train(net, &v2[0], &t2[0]);
		printf("\t\tResult: %0.5f %0.5f", net->outs->value, ((neuron_t*)(net->outs->neuron_list.next))->value);
		qe += net->qerror;
		
		net_train(net, &v3[0], &t3[0]);
		printf("\t\tResult: %0.5f %0.5f", net->outs->value, ((neuron_t*)(net->outs->neuron_list.next))->value);
		qe += net->qerror;
		
		net_train(net, &v4[0], &t4[0]);
		printf("\t\tResult: %0.5f %0.5f", net->outs->value, ((neuron_t*)(net->outs->neuron_list.next))->value);
		qe += net->qerror;
		
		qe /= 4.0;
		
		printf("\tQE: %0.15f", qe);
	}while(qe > 0.00000001);
	printf("\n\n");
	
	
	/*	Run the network	*/
	net_run(net, &v1[0]);
	printf("%0.1f xor %0.1f = %0.5f\n", v1[0], v1[1], net->outs->value, ((neuron_t*)(net->outs->neuron_list.next))->value);
	
	net_run(net, &v2[0]);
	printf("%0.1f xor %0.1f = %0.5f\n", v2[0], v2[1], net->outs->value, ((neuron_t*)(net->outs->neuron_list.next))->value);
	
	net_run(net, &v3[0]);
	printf("%0.1f xor %0.1f = %0.5f\n", v3[0], v3[1], net->outs->value, ((neuron_t*)(net->outs->neuron_list.next))->value);
	
	net_run(net, &v4[0]);
	printf("%0.1f xor %0.1f = %0.5f\n", v4[0], v4[1], net->outs->value, ((neuron_t*)(net->outs->neuron_list.next))->value);
	
	net_delete(net);
	return 0;
}
