
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	This file contains activation functions
;
;	Author: Alexey Lyashko 
;	Site:	syprog.blogspot.com
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;Indices of neuron activation functions
ACTIVATION_EXPONENTIAL			= 0

;Neuron activation functions table

activation_funcs:
		dq	activation_exp

activation_signals:
		dq	activation_exp_signal



;===============================================================================
;double		activation_exp(double value/*, double alpha*/)
;This is the  =1.0 / (1.0 + exp(-value * 2 /* * alpha*/)) logistic function

activation_exp:
		push		rbp
		mov			rbp, rsp
		sub			rsp, 8
		pushregs
		;-------------------
		virtual at rbp-8
			.value	dq	?
			;.alpha	dq	?
		end virtual
		;-------------------
		movsd		[.value], xmm0	;value
		;movsd		[.alpha], xmm1	;alpha
		;-------------------
		finit
		fld1
		fadd 		st0, st0
		fld1
		fsub		st0, st1
		fmulp		st1, st0
		fld			qword [.value]
		;fld			qword [.alpha]
		;fmulp		st1, st0
		fmulp		st1, st0
		fstp		qword [.value]
		;-------------------
		movsd		xmm0, [.value]
		call		_exp
		movsd		[.value], xmm0
		;-------------------
		fld1
		fld			qword [.value]
		faddp		st1, st0
		fld1
		fdiv		st0, st1
		fstp		qword [.value]
		fstp		st0
		;-------------------
		movsd		xmm0, [.value]
		;mov			qword [.alpha], 0
		;movsd		xmm1, [.alpha]
		;-------------------
		popregs
		add			rsp, 8
		leave 
		ret

;===============================================================================
;double		activation_exp_signal(neuron_t* neuron, double target)
;xmm0									 	rdi		  	   xmm0
activation_exp_signal:
		push		rbp
		mov			rsp, rbp
		sub			rsp, 8
		pushregs
		;-------------------
		virtual at rbp-8
			.target	dq	?
		end virtual
		virtual at rdi
			.n		neuron
		end virtual
		virtual at rbx
			.s		synaps 
		end virtual
		;-------------------
		; Check params
		or			rdi, 0
		jz			.return
		; params ok
		test		word [.n.type], NEURON_TYPE_OUTPUT
		jnz			.output
		test		word [.n.type], NEURON_TYPE_NORMAL
		jnz			.hidden
		jmp			.return
		;-------------------
	.output:
		movsd		[.target], xmm0
		fld			qword [.n.value]
		fld1
		fsub		st0, st1
		fmul		st0, st1
		fld			qword [.target]
		fsub		st0, st2
		fmulp		st1, st0
		fstp		qword [.n.signal]
		fstp		st0
		;-------------------
		jmp			.process_inputs
	.hidden:
		; check for output synapses
		or			qword [.n.output], 0
		jz			.return
		;-------------------
		fldz
		mov			rbx, [.n.output]
	.hidden_collect_signals:
		fld			[.s.signal]
		fld			[.s.weight]
		fmulp		st1, st0
		faddp		st1, st0
		;-------------------
		mov			rbx, [.s.outputs.next_ptr]
		or			rbx, 0
		jz			.hidden_signals_collected
		jmp			.hidden_collect_signals
	.hidden_signals_collected:
		;-------------------
		fld			qword [.n.value]
		fld1
		fsub		st0, st1
		fmulp		st1, st0
		fmulp		st1, st0
		fstp		qword [.n.signal]
		;-------------------
	.process_inputs:
		or			qword [.n.input], 0
		jz			.return
		mov			rbx, [.n.input]
		mov			rax, [.n.signal]
	.process_inputs_loop:
		mov			[.s.signal], rax
		mov			rbx, [.s.inputs.next_ptr]
		or			rbx, 0
		jnz			.process_inputs_loop
		;-------------------
	.return:
		popregs
		add			rsp, 8
		leave
		ret




;===============================================================================
;double		_exp(double d)
;this function calculates the exponent of a double
;special thanks to Consto (wasm.ru)
_exp:
		push		rbp
		mov			rbp, rsp
		sub			rsp, 8
		pushregs
		;Store the double to memory
		movsd		qword [rbp-8], xmm0
		;-------------------
		fld			qword [rbp-8]
		fldl2e
		fmulp		st1, st0
		fld			st0
		frndint
		fsub		st1, st0
		fxch		st1
		f2xm1
		fld1
		faddp		st1, st0
		fscale
		fstp		st1
		fstp		qword [rbp-8]
		fwait
		;-------------------
		movsd		xmm0, qword [rbp-8]
		popregs
		add			rsp, 8
		leave
		ret

;===============================================================================
;double		_pow(double a, double b)
;works with positive a only
_pow:
		push		rbp
		mov			rbp, rsp
		sub			rsp, 16
		pushregs
		;-------------------
		virtual at rbp-16
			.a	dq	?
			.b	dq	?
		end virtual
		;-------------------
		movsd		qword [.a], xmm0
		movsd		qword [.b], xmm1
		;-------------------
		fldln2
		fld			qword [.a]
		fyl2x
		fmul		qword [.b]
		fldl2e
		fmulp		st1, st0
		fld			st0
		frndint
		fsub		st1, st0
		fxch		st1
		f2xm1
		fld1
		faddp		st1, st0
		fscale
		fstp		st1
		fstp		qword [.a]
		;--------------------
		mov			qword [.b], 0
		movsd		xmm1, [.b]
		movsd		xmm0, [.a]
		popregs
		add			rsp, 16
		leave
		ret

