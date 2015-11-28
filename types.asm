
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	This file contains structures and types declarations to be used with
;	the library
;
;	Author: Alexey Lyashko 
;	Site:	syprog.blogspot.com
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;Error definitions
RESULT_OK					= 0
RESULT_ERROR				= -1

ENOERR						= 0
EUNKNOWN					= 1
EINCOMPLETE					= 2
EINVALIDPARAM				= 3


macro	set_errno [error_code]
{
	if error_code eq
		mov dword[errno],0
	else
		mov dword[errno],error_code
	end if
}

macro	pushregs
{
	push	rbx rcx rdx rdi rsi
}

macro	popregs
{
	pop		rsi rdi rdx rcx rbx
}

struc	list
{
	.prev_ptr	dq	?
	.next_ptr	dq	?
}

NEURON_TYPE_NORMAL 	= 1		;Normal neuron
NEURON_TYPE_INPUT	= 2		;Input neuron
NEURON_TYPE_OUTPUT	= 4		;Output neuron

struc	neuron
{
	.list			list			;Pointers to previous and next neurons
	.input			dq	?			;Pointer to the first input synaps
	.output			dq	?			;Pointer to the first output synaps
	.value			dq	?			;Resulting value of the neuron
	.signal			dq	?			;Error signal
	.sum			dq	?			;Sum of all weighted inputs
	.bias			dq	?			;Bias weight
	.bias_delta		dq	?			;Bias weight delta
	.index			dw	?			;Index of the given neuron
	.num_inputs		dw	?			;Number of input synapses
	.num_outputs	dw	?			;Number of output synapses
	.type			dw	?			;Type of the  neuron (bit field)
	.size 			= $ - .list
}

;Synaps linkage constants
SYNAPS_LINK_INPUTS	= 0
SYNAPS_LINK_OUTPUTS	= 1


struc	synaps
{
	.inputs			list			;Pointers to previous and next input synapses 
									;if such exist
	.outputs		list			;Pointers to previous and next output synapses
									;if such exist
	.value			dq	?			;Value to be transmitted
	.weight			dq	?			;Weight of the synaps
	.delta			dq	?			;Weight delta
	.signal			dq	?			;Error signal
	.input_index	dw	?			;Index of the input neuron
	.output_index	dw	?			;Index of the output neuron
					dd	?			;alignment...
	.size			= $ - .inputs
}

struc 	net
{
	.neurons		dq	?			;Pointer to the list of neurons
	.outs			dq	?			;Pointer to the first output neuron
	.num_neurons	dd	?			;Total amount of neurons
	.activation		dd	?			;Activation method
	.qerror			dq	?			;Mean quadratic error
	.num_inputs		dw	?			;Number of inputs
	.num_outputs	dw	?			;Number of outputs
	.rate			dq	?			;Alpha
	.momentum		dq	?			;Eta
	.size			= $ - .neurons
}

