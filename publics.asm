
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	This file contains smbols exported by the library
;
;	Author: Alexey Lyashko 
;	Site:	syprog.blogspot.com
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



public	errno as 'ann_errno'


public	neuron_alloc 
public  neuron_list_add
public  neuron_list_alloc
public	neuron_delete
public	neuron_delete_list
public	neuron_find_by_index
public	neuron_process
public	neuron_adjust_weights
public	neuron_calculate_signal

public 	synaps_alloc
public 	synaps_link
public	synaps_delete
public	synaps_delete_list

public	net_alloc
public	net_delete
public 	net_fill
public	net_set_links
public 	net_feed
public	net_process
public 	net_calculate_error
public 	net_propagate_error
public	net_adjust_weights
public	net_run
public	net_train

public 	_exp
public	_pow
public	activation_exp
public	activation_exp_signal
