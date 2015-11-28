
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	This file contains service functions for net_t object
;
;	Author: Alexey Lyashko 
;	Site:	syprog.blogspot.com
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;===============================================================================
;net_t*		net_alloc(void)
net_alloc:
		push		rbp
		mov			rbp, rsp
		pushregs
		;-------------------
		virtual at 0
			.n	net
		end virtual
		;-------------------
		mov			rdi, .n.size
		call		malloc
		popregs
		leave
		ret

;===============================================================================
;void		net_delete(net_t** net)
net_delete:
		push 		rbp
		mov			rbp, rsp
		pushregs
		;-------------------
		virtual at rbx
			.net	net
		end virtual
		;-------------------
		; Check params
		or			rdi, 0
		jz			.return
		; params ok
		mov			rbx, [rdi]
		or			qword[.net.neurons], 0
		jz			.neurons_free
		push 		rdi
		lea 		rdi, [.net.neurons]
		call		neuron_delete_list
		pop			rdi
	.neurons_free:
		mov			qword [rdi], 0
		mov			rdi, rbx
		call		free
	.return:
		popregs
		leave
		ret

;===============================================================================
;void		net_fill(net_t* net, int num_neurons, int num_ins, int num_outs)
;							rdi		 rsi		  rdx 			   rcx
net_fill:
		push		rbp
		mov 		rbp, rsp
		sub			rsp, 8*4
		pushregs
		;-------------------
		virtual at	rbp-8*4
			.net			dq	?
			.num_neurons	dq	?
			.num_ins		dq	?
			.num_outs		dq	?
		end virtual
		virtual	at	rbx
			.nt				net
		end virtual
		virtual at	rdx		
			.n				neuron
		end virtual
		;-------------------
		; Check params
		or					rdi, 0
		jz					.return
		;-------------------
		; params ok
		mov			[.net], rdi
		mov			[.num_neurons], rsi
		mov			[.num_ins], rdx
		mov			[.num_outs], rcx
		;-------------------
		; Allocate list
		mov			rdi, rsi
		call		neuron_list_alloc
		or			rax, 0
		jz			.return
		;-------------------
		mov			rbx, [.net]
		mov			[.nt.neurons], rax
		mov			rdx, [.nt.neurons]
		;Set input neurons' type
		mov			rcx, [.num_ins]
		;dec			ecx
	.set_inputs_type:
		mov			[.n.type], NEURON_TYPE_INPUT
		mov			rdx, [.n.list.next_ptr]
		loop		.set_inputs_type
		;Set all the rest to INPUT
	.set_normals_type:
		mov			[.n.type], NEURON_TYPE_NORMAL
		or			qword [.n.list.next_ptr], 0
		jz			.roll_back_outputs
		mov			rdx, [.n.list.next_ptr]
		jmp			.set_normals_type
		;Set output neurons
	.roll_back_outputs:
		mov			rcx, [.num_outs]
	.roll_back_outputs_loop:
		mov			[.n.type], NEURON_TYPE_OUTPUT
		mov			rdx, [.n.list.prev_ptr]
		loop		.roll_back_outputs_loop
		;Set outs pointer
		mov			rax, [.n.list.next_ptr]
		mov			[.nt.outs], rax
		;Set the rest of parameters
		mov			rax, [.num_ins]
		mov			[.nt.num_inputs], ax
		mov			rax, [.num_outs]
		mov			[.nt.num_outputs], ax
		mov			rax, [.num_neurons]
		mov			[.nt.num_neurons], eax
	.return:
		popregs
		add			rsp, 8*4
		leave
		ret



;===============================================================================
;int		net_set_links(net_t* net, int* links)
;								 rdi	   rsi
net_set_links:
		push 		rbp
		mov			rbp, rsp
		sub			rsp, 8*5
		pushregs
		;-------------------
		virtual at 	rbp-8*5
			.neurons	dq	?		;pointer to net->neurons
			.ninput		dq	?		;pointer to left neuron
			.noutput	dq	?		;pointer to right neuron
			.link		dq	?		;pointer to synaps
			.links		dq	?		;pointer to array of indices
		end virtual
		virtual at	rdi
			.net		net
		end virtual
		virtual at 	rax
			.s			synaps
		end virtual
		virtual at	rdx
			.n			neuron
		end virtual
		;-------------------
		; Check params
		or			rdi, 0
		jz			.return
		; params ok
		;-------------------
		mov			rax, [.net.neurons]
		mov			[.neurons], rax
		mov			[.links], rsi
		;-------------------
		mov			rbx, [.links]		;RBX points to the current link
	.set_links:
		or			qword [rbx], 0
		jz			.return				; no more links
		; Find left neuron
		mov			rdi, [.neurons]
		xor 		rsi, rsi
		mov			esi, [rbx]
		call		neuron_find_by_index
		or			rax, 0
		jz			.error				; no such neuron
		mov			[.ninput], rax
		; Find right neuron
		mov			rdi, [.neurons]
		mov			esi, [rbx+4]
		call		neuron_find_by_index
		or			rax, 0
		jz			.error				; no such neuron 
		mov			[.noutput], rax
		; Allocate synaps
		call		synaps_alloc
		or			rax, 0
		jz			.error				; allocation error
		mov			[.link], rax
		; Set input/output indices
		mov			si, [rbx]
		mov			[.s.input_index], si
		mov			si, [rbx+4]
		mov			[.s.output_index], si
		; Add synaps to the list of outputs
		mov			rdx, [.ninput]
		or			[.n.output], 0
		jz			.add_first_output
		mov			rsi, [.n.output]
		mov			rdi, [.link]
		push		rdx
		mov			rdx, SYNAPS_LINK_OUTPUTS
		call		synaps_link
		pop			rdx
		mov			[.n.output], rdi
		jmp			.output_added
	.add_first_output:
		mov			rax, [.link]
		mov			[.n.output], rax
	.output_added:
		; Add synaps to the list of inputs
		mov			rdx, [.noutput]
		or			[.n.input], 0
		jz			.add_first_input
		mov			rsi, [.n.input]
		mov			rdi, [.link]
		push 		rdx
		mov			rdx, SYNAPS_LINK_INPUTS
		call		synaps_link
		pop			rdx
		mov			[.n.input], rdi
		jmp			.input_added
	.add_first_input:
		mov			rax, [.link]
		mov			[.n.input], rax
	.input_added:
		add			rbx, 8
		jmp			.set_links
		
	.return:
		popregs
		add			rsp, 8*5
		leave
		ret
	.error:
		xor 		eax, eax
		dec 		eax
		jmp 		.return


;===============================================================================
;void			net_feed(net_t* net, double* values)
;								rdi			 rsi
net_feed:
		push 		rbp
		mov			rbp, rsp
		pushregs
		; Check params
		or			rdi, 0
		jz			.return
		or			rsi, 0
		jz			.return
		; params ok
		;-------------------
		virtual at 	rdi
			.net	net
		end virtual
		virtual at 	rbx
			.n		neuron
		end virtual
		;-------------------
		mov			rbx, [.net.neurons]
		;Process input neurons
	.feed:
		cmp			[.n.type], NEURON_TYPE_INPUT
		jnz			.return
		mov			rax, [rsi]
		mov			[.n.sum], rax
		mov			rbx, [.n.list.next_ptr]
		add			rsi, 8
		jmp			.feed
		
	.return:
		popregs
		leave
		ret

;===============================================================================
;void			net_process(net_t* net)
;								   rdi
net_process:
		push 		rbp
		mov			rbp, rsp
		pushregs
		; Check params
		or			rdi, 0
		jz			.return
		; params ok
		;-------------------
		virtual at rdx
			.net	net
		end virtual
		;-------------------
		mov			rdx, rdi
		;-------------------
		virtual at	rdi
			.n		neuron
		end virtual
		;-------------------
		mov			rdi, [.net.neurons]
		xor			rsi, rsi
		mov			esi, [.net.activation]
	.process_neurons:
		or			rdi, 0
		jz			.return
		movsd		xmm0, [.net.rate]
		call		neuron_process
		mov			rdi, [.n.list.next_ptr]
		jmp			.process_neurons
		
		
	.return:
		popregs
		leave 
		ret


;===============================================================================
;double	net_calculate_error(net_t* net, double* targets)
;								   rdi			rsi
net_calculate_error:
		push 		rbp
		mov			rbp, rsp
		sub			rsp, 16
		pushregs
		mov			qword [rbp-8], 0
		; Check params
		or			rdi, 0
		jz			.error
		or			rsi, 0
		jz			.error
		; params ok
		mov			[rbp-16], rdi
		;-------------------
		virtual at	rcx
			.net		net
		end virtual
		virtual at 	rdi
			.n			neuron
		end virtual
		;-------------------
		mov			rbx, rsi
		mov			rcx, rdi
		mov			rdi, [.net.outs]
		xor			rsi, rsi
		finit
		fwait
		fldz
	.process_output_neurons:
		or			rdi, 0
		jz			.processed
		cmp			[.n.type], NEURON_TYPE_OUTPUT
		jnz			.processed
		mov			esi, [.net.activation]
		movsd		xmm0, [rbx]
		call		neuron_calculate_signal
		fld			[.n.signal]
		fmul		st0, st0
		faddp		st1, st0
		inc			dword [rbp-8]
		add			rbx, 8
		mov			rdi, [.n.list.next_ptr]
		jmp			.process_output_neurons
	.processed:
		fild		dword[rbp-8]
		fdivp		st1, st0
		fstp		qword[rbp-8]
		movsd		xmm0, [rbp-8]
		;-------------------
		mov			rcx, [rbp-16]
		movsd		[.net.qerror], xmm0
		
	.return:
		popregs
		add			rsp, 16
		leave
		ret
	.error:
		movsd		xmm0, [rbp-8]
		jmp			.return


;===============================================================================
;void			net_propagate_error(net_t* net)
;										   rdi
net_propagate_error:
		push 		rbp
		mov			rbp, rsp
		pushregs
		; Check params
		or			rdi, 0
		jz			.return
		; params ok
		;-------------------
		virtual at 	rbx
			.net	net
		end virtual
		;-------------------
		mov			rbx, rdi
		mov			rdi, [.net.outs]			; Output neurons already have their
												; signals calculated, so we start
												; with the neuron before the first 
												; output and continue backwards
		;-------------------
		virtual at rdi
			.n		neuron
		end virtual
		;-------------------
		xor 		rsi, rsi
		mov			esi, [.net.activation]
		push		0
		movsd		xmm0, [rsp]
		add			rsp, 8
	.propagate:
		; Step back one neuron
		mov			rdi, [.n.list.prev_ptr]
		; Check validity
		or			rdi, 0
		jz			.return
		; Calculate signal
		call		neuron_calculate_signal
		jmp			.propagate

	.return:
		popregs
		leave
		ret


;===============================================================================
;void			net_adjust_weights(net_t* net)
;										  rdi
net_adjust_weights:
		push 		rbp
		mov			rbp, rsp
		pushregs
		; Check params
		or			rdi, 0
		jz			.return
		; params ok
		;-------------------
		virtual at	rdi
			.net		net
		end virtual
		;-------------------
		movsd		xmm0, [.net.rate]
		movsd		xmm1, [.net.momentum]
		mov			rdi, [.net.neurons]
		;-------------------
		virtual at	rdi
			.n			neuron
		end virtual
		;-------------------
	.adjust:
		or			rdi, 0
		jz			.return
		call		neuron_adjust_weights
		mov			rdi, [.n.list.next_ptr]
		jmp			.adjust
		;-------------------
	.return:
		popregs
		leave
		ret
		

;===============================================================================
;void			net_run(net_t* net, double* values)
;							   rdi			rsi
net_run:
		push 		rbp
		mov			rbp, rsp
		pushregs
		; Check params
		or			rdi, 0
		jz			.return
		or			rsi, 0
		jz 			.return
		; params ok
		; Feed the network
		call		net_feed
		; Process the network
		call		net_process
	.return:
		popregs
		leave
		ret

;===============================================================================
;double 		net_train(net_t* net, double* values, double* targets)
;								 rdi		  rsi			  rdx
net_train:
		push 		rbp
		mov			rbp, rsp
		sub			rsp, 8
		pushregs
		; Check params
		or			rdi, 0
		jz 			.return
		or			rsi, 0
		jz			.return
		or			rdx, 0
		jz			.return
		; params ok
		;-------------------
		virtual at 	rdi
			.net	net
		end virtual
		;-------------------
		; Run the network
		call		net_run
		; Calculate error
		mov			rsi, rdx
		call 		net_calculate_error
		; Now xmm0 has the quadratic error
		; Load threshold to FPU
		
	.train:
		; Error is still too high and we need to adjust weights
		call		net_propagate_error
		call		net_adjust_weights
		movsd		xmm0, [.net.qerror]
		;-------------------
	.return:
		popregs
		add			rsp, 16
		leave
		ret
		
		
		
		
		
		
		
		











