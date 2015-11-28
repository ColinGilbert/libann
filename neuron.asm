
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	This file contains service functions for neuron_t object
;
;	Author: Alexey Lyashko 
;	Site:	syprog.blogspot.com
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

		include 'activation.asm'

;===============================================================================
;neuron_t	neuron_alloc(void)
neuron_alloc:
		push 		rbp
		mov			rbp, rsp
		push 		rdi rsi rdx rcx
		;----------------------
		virtual at 0
			.n	neuron
		end virtual
		;----------------------
		mov			rdi, .n.size
		call		malloc
		or			rax, 0
		jz			.return
		push 		rax
		mov			rdi, rax
		xor			rsi, rsi
		mov			rdx, .n.size
		call		memset
		pop			rax
		;----------------------
		virtual at rax
			.n1	neuron
		end virtual
		;----------------------
		finit
		fld1
		fld1
		fadd		st1, st0
		fdiv		st0, st1
		fstp		[.n1.bias]
		ffree		st0
		fwait
	.return:
		set_errno
		pop			rcx rdx rsi rdi
		leave
		ret

;===============================================================================
;void		neuron_list_add(neuron_t* list, neuron_t* n)
neuron_list_add:
		push 		rbp
		mov			rbp, rsp
		push 		rdi rsi rdx rcx
		;Check arguments
		or			rdi, 0
		jz			.return
		or			rsi, 0
		jz 			.return
		mov			rdx, rdi
		;----------------------
		virtual at rdx
			.n	neuron
		end virtual
		virtual	at rsi
			.n1 neuron
		end virtual
		;----------------------
	.scan_list:
		or			qword[.n.list.next_ptr],0
		jz			.found_last
		push		qword[.n.list.next_ptr]
		pop			rdx
		jmp			.scan_list
	.found_last:
		mov			[.n.list.next_ptr], rsi
		mov			[.n1.list.prev_ptr], rdx
	.return:
		set_errno
		pop			rcx rdx rsi rdi
		leave
		ret

;===============================================================================
;neuron_t*	neuron_list_alloc(int	count)
neuron_list_alloc:
		push 		rbp
		mov 		rbp, rsp
		push 		rdi rsi rdx rcx
		xor			rax, rax
		xor			rcx, rcx
		mov			ecx, edi
		xor 		rdi, rdi
		xor			rsi, rsi
		inc			rsi
		call 		neuron_alloc
		;--------------------------
		virtual at rax
			.n	neuron
		end virtual
		;--------------------------
		or 			rax, 0
		jz			.error
		mov			[.n.index], si
		inc			rsi
		mov			rdi, rax
		dec 		ecx
	.add_new:
		call		neuron_alloc
		or			rax, 0
		jz			.error
		mov			[.n.index], si
		inc			rsi
		push		rsi
		mov			rsi, rax
		call		neuron_list_add
		pop			rsi
		loop		.add_new
		mov			rax, rdi
		jmp			.return
	.error:
		;do something about errors here
		set_errno 	EINCOMPLETE
	.return:
		pop			rcx rdx rsi rdi
		leave
		ret
	

;===============================================================================
;void		neuron_delete(neuron_t** neuron)
neuron_delete:
		push 		rbp
		mov 		rbp, rsp
		pushregs
		;Check params
		or			rdi, 0
		jz			.return
		or			qword [rdi], 0
		jz			.return
		;params ok
		;------------------
		virtual at rbx
			.n	neuron
		end virtual
		;------------------
		mov			rbx, [rdi]
		mov			qword [rdi], 0
		or			qword [.n.output], 0
		jz			.no_out_synaps
		;Delete output neurons
		lea			rdi, [.n.output]
		call		synaps_delete_list
	.no_out_synaps:
		mov			rdi, rbx
		call		free
	.return:
		popregs
		leave
		ret
		
;===============================================================================
;void		neuron_delete_list(neuron_t** n_list)
neuron_delete_list:
		push		rbp
		mov			rbp, rsp
		pushregs
		;Check params
		or			rdi, 0
		jz			.return
		or			qword [rdi], 0
		jz			.return
		;params ok
		;------------------
		virtual at rbx
			.n neuron
		end virtual
		;------------------
		mov			rbx, [rdi]
		mov			qword [rdi], 0
	.deletion_loop:
		push		rbx
		mov			rdi, rsp
		mov			rbx, [.n.list.next_ptr]
		call 		neuron_delete
		pop			rdi
		or			rbx, 0
		jz			.return
		jmp			.deletion_loop
	.return:
		popregs
		leave
		ret

;===============================================================================
;neuron_t*	neuron_find_by_index(neuron_t* list, int index)
neuron_find_by_index:
		push 		rbp
		mov			rbp, rsp
		pushregs
		;Check params
		or			rdi, 0
		jz			.return
		;params ok
		;------------------
		virtual at rdi
			.n	neuron
		end virtual
		;------------------
	.search_loop:
		cmp			[.n.index], si
		jz			.found
		mov			rdi, [.n.list.next_ptr]
		or			rdi, 0
		jz			.not_found
		jmp			.search_loop
	.not_found:
		xor			rax, rax
		jmp			.return
	.found:
		mov			rax, rdi
	.return:
		popregs
		leave
		ret
		
;===============================================================================
;void		neuron_process(neuron_t* n, /* double alpha, */ int	activation_type)
neuron_process:
		push 		rbp
		mov			rbp, rsp
		sub			rsp, 16
		pushregs
		;-------------------
		; Check params
		or			rdi, 0
		jz			.return
		;-------------------
		; params ok
		lea			rbx, [activation_funcs]		;Select activation function
		add			rbx, rsi
		mov			rbx, [rbx]
		mov			[rbp-8], rbx
		;-------------------
		virtual at rdi
			.n		neuron
		end virtual
		virtual at rbx
			.s		synaps
		end virtual
		;-------------------
		; Check neuron type
		cmp			word [.n.type], NEURON_TYPE_INPUT
		jz			.is_input
		; Process hidden neuron
		; check for inputs
		fldz
		or			qword [.n.input], 0
		jz			.inputs_done
		mov			rbx, [.n.input]
		or			rbx, 0
		jz			.inputs_done
	.process_inputs:
		fld			qword [.s.value]
		fld			qword [.s.weight]
		fmulp		st1, st0
		faddp		st1, st0
		mov			rbx, [.s.inputs.next_ptr]
		or			rbx, 0
		jnz			.process_inputs
		;-------------------
	.inputs_done:
		fld			qword [.n.bias]
		faddp		st1, st0
		fstp		qword [.n.sum]
		;-------------------
		mov			rdx, [rbp-8]
		;movsd		xmm1, xmm0
		movsd		xmm0, [.n.sum]
		call		rdx
		movsd		[.n.value], xmm0
		mov			rax, [.n.value]
		;-------------------
		jmp			.set_outputs
		;-------------------
	.is_input:
		mov			rax, [.n.sum]
		mov			[.n.value], rax
		;-------------------
	.set_outputs:
		or			qword [.n.output], 0
		jz			.return
		mov			rbx, [.n.output]
	.set_outputs_loop:
		mov			[.s.value], rax
		mov			rbx, [.s.outputs.next_ptr]
		or			rbx, 0
		jnz			.set_outputs_loop
		;-------------------
	.return:
		popregs
		add			rsp, 16
		leave
		ret

;===============================================================================
;void		neuron_calculate_signal(neuron_t* n, double target, int mode)
;											rdi			xmm0		rsi
neuron_calculate_signal:
		push 		rbp
		mov			rbp, rsp
		pushregs
		;-------------------
		lea			rdx, [activation_signals]
		add			rdx, rsi
		mov			rdx, [rdx]
		;-------------------
		; All arguments are already in proper registers
		call		rdx
		;-------------------
		popregs
		leave
		ret

;===============================================================================
;void		neuron_adjust_weights(neuron_t* n, double alpha, double eta)
;										  rdi		  xmm0			xmm1
neuron_adjust_weights:
		push		rbp
		mov			rbp, rsp
		sub			rsp, 16
		pushregs
		; Check params
		or			rdi, 0
		jz			.inputs_processed
		; params ok
		;-------------------
		virtual at rdi
			.n		neuron
		end virtual
		virtual at rbx
			.s		synaps
		end virtual
		virtual at rbp-16
			.alpha	dq	?
			.eta	dq	?
		end virtual
		;-------------------
		;If this is an input neuron, then we have nothing to do with it
		test		word [.n.type], NEURON_TYPE_INPUT
		jnz			.inputs_processed
		movsd		[.alpha], xmm0
		movsd		[.eta], xmm1
		;-------------------
		; Adjust the bias first
		fld			[.n.signal]
		fld			[.eta]
		fmulp		st1, st0
		fld			[.alpha]
		fld			[.n.bias_delta]
		fmulp		st1, st0
		faddp		st1, st0
		fst			[.n.bias_delta]
		fld			[.n.bias]
		faddp		st1, st0
		fstp		[.n.bias]
		;-------------------
		; Adjust weights for every input synaps
		or			qword [.n.input], 0
		jz			.inputs_processed
		mov			rbx, [.n.input]
		or			rbx, 0
		jz			.inputs_processed
	.process_inputs:
		fld			[.s.signal]
		fld			[.s.value]
		fmulp		st1, st0
		fld			[.eta]
		fmulp		st1, st0
		fld			[.alpha]
		fld			[.s.delta]
		fmulp		st1, st0
		faddp		st1, st0
		fst			[.s.delta]
		fld			[.s.weight]
		faddp		st1, st0
		fstp		[.s.weight]
		mov			rbx, [.s.inputs.next_ptr]
		or			rbx, 0
		jnz 		.process_inputs
	.inputs_processed:
		popregs
		add			rsp, 16
		leave
		ret



















