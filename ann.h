/*******************************************************************************
 * 
 * 	C header file for the libann library
 * 
 * 	Author:	Alexey Lyashko
 * 	Site:	syprog.blogspot.com
 * 
 ******************************************************************************/
 
 
  
#ifndef _ANN_H_
#define _ANN_H_

#define ANN_VERSION					0.9

//Error definitions
#define	RESULT_OK					0
#define	RESULT_ERROR				-1

#define	ENOERR						0
#define	EUNKNOWN					1
#define	EINCOMPLETE					2
#define	EINVALIDPARAM				3

#define	NEURON_TYPE_NORMAL 	 		1		//Normal neuron
#define	NEURON_TYPE_INPUT	 		2		//Input neuron
#define	NEURON_TYPE_OUTPUT	 		4		//Output neuron

//Synaps linkage constants
#define SYNAPS_LINK_INPUTS	 		0
#define SYNAPS_LINK_OUTPUTS	 		1

//Indices of neuron activation functions
#define ACTIVATION_EXPONENTIAL		0

//Should contain the error code for last operation
extern int ann_errno;

//Used in linked list of neurons
typedef struct _list
{
	struct _list*	prev;
	struct _list* 	next;
}list_t;

/*	This structure represents a synaptic link
 * 	between a couple of neurons	*/
typedef struct
{
	list_t			input_list;
	list_t			output_list;
	double 			value;
	double			weight;
	double 			delta;
	double 			signal;
	unsigned short	input_index;
	unsigned short	output_index;
	unsigned int	__padding;
}synaps_t;

/*	This structure represents a neuron	*/
typedef struct
{
	list_t			neuron_list;
	synaps_t*		input;
	synaps_t*		output;
	double 			value;
	double 			signal;
	double 			sum;
	double 			bias;
	double 			bias_delta;
	unsigned short	index;
	unsigned short	num_inputs;
	unsigned short	num_outputs;
	unsigned short	type;
}neuron_t;

/*	This one represents the whole network	*/
typedef struct
{
	neuron_t*		neurons;
	neuron_t*		outs;
	int				num_neurons;
	int				activation_mode;
	double			qerror;
	unsigned short	num_inputs;
	unsigned short	num_outputs;
	double			rate;				// Alpha
	double 			momentum;			// Eta
}net_t;


/*	Allocates a single neuron	*/
extern neuron_t*	neuron_alloc(void);

/*	Adds a neuron to the linked list of neurons	*/
extern void			neuron_list_add(neuron_t* list, neuron_t* n);

/*	Allocates a list of count neurons	*/
extern neuron_t*	neuron_list_alloc(int count);

/*	Releases all resources allocated for specific neuron	*/
extern void			neuron_delete(neuron_t** neuron);

/*	Releases all resources allocated for the whole list of neurons	*/
extern void			neuron_delete_list(neuron_t** n_list);

/*	Returns a pointer to the neuron specified by index	*/
extern neuron_t*	neuron_find_by_index(neuron_t* list, int index);

/*	This function actually processes the neuron by summing the inputs and 
 * 	invoking the activation function	*/
extern void			neuron_process(neuron_t* n, double alpha, int	activation_type);

/*	Calculates new weights for the given neron's input synaptic links	*/
extern void			neuron_adjust_weights(neuron_t* n, double alpha, double eta);

/*	Calculates an error signal value for a given neuron	*/
extern void			neuron_calculate_signal(neuron_t* n, double target, int mode);

/*	Allocates a synaptic link	*/
extern synaps_t*	synaps_alloc(void);

/*	Links a couple of synaptic links	*/
extern void			synaps_link(synaps_t* s1, synaps_t* s2, int	type);

/*	Releases all resources allocated for a single synaptic link	*/
extern void			synaps_delete(synaps_t** s);

/*	Releases all resources allocated for the whole list of synaptic links	*/
extern void			synaps_delete_list(synaps_t** s);

/*	Calculates an exponent of d	*/
extern double		_exp(double d);

/*	Calculates the b power of a	*/
extern double		_pow(double a, double b);

/*	Exponential (logistic) activation function	*/
extern double		activation_exp(double value, double alpha);

/*	This function calculates error signal for the logistic activation function	*/
extern double		activation_exp_signal(neuron_t* neuron, double target);

/*	Allocates the net_t structure	*/
extern net_t*		net_alloc(void);

/*	Releases all resources allocated for net. Including neurons 
 * 	and synaptic links	*/
extern void			net_delete(net_t* net);

/*	Fills the allocated net object with neurons. Sets correct 
 * 	amount of inputs and outputs	*/
extern void			net_fill(net_t* net, int num_neurons, int num_ins, int num_outs);

/*	Sets links between neurons as specified in links array	*/
extern void			net_set_links(net_t* net, int* links);

/*	Feeds the network with input values	*/
extern void			net_feed(net_t* net, double* values);

/*	Calculates the error value for the output neurons	*/
extern double		net_calculate_error(net_t* net, double* targets);

/*	Processes the whole network. Calls neuron_process for
 * 	each neuron	*/
extern void			net_process(net_t* net);

/*	Back propagates the error signal value	*/
extern void			net_propagate_error(net_t* net);

/*	Adjusts weights for each and every neuron (except inputs)	*/
extern void			net_adjust_weights(net_t* net);

/*	Performs the full run of the network including the feed operation	*/
extern void			net_run(net_t* net, double* values);

/* 	Performs the full train cycle for the network	*/
extern double 		net_train(net_t* net, double* values, double* targets);
#endif
