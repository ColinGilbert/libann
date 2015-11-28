
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;	This file contains service functions for synaptic links
;
;	Author: Alexey Lyashko 
;	Site:	syprog.blogspot.com
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;===============================================================================
;	Allocation of synaptic link and setting its weight to 0.5
;synaps_t*	synaps_alloc(void)
synaps_alloc:
		push		rbp
		mov			rbp, rsp
		pushregs
		;-------------------------
		virtual at 0
			.s	synaps
		end virtual
		;-------------------------
		mov			rdi, .s.size
		call		malloc
		or			rax, 0
		jz			.return
		push 		rax
		mov			rdi, rax
		xor 		rsi, rsi
		mov			rdx, .s.size
		call 		memset
		pop			rax
		;------------------------
		virtual at rax
			.s1	synaps
		end virtual
		;------------------------
		finit
		fld1
		fld1
		fadd		st1, st0
		fdiv		st0, st1
		fstp		[.s1.weight]
		ffree		st0
		fwait
	.return:
		set_errno
		popregs
		leave
		ret
		
;===============================================================================
;	Linking a couple of synaptic links together
;void		synaps_link(synaps_t* s1, synaps_t* s2, int	type)
;type = 0 - link input synapses
;type = 1 - link output synapses
synaps_link:
		push		rbp
		mov			rbp, rsp
		pushregs
		;-----------------------
		virtual at rdi
			.s1	synaps
		end virtual
		virtual at rsi
			.s2 synaps 
		end virtual
		;-----------------------
		;Check params
		or			rdi, 0
		jz			.error
		or			rsi, 0
		jz			.error
		jmp			.params_ok
	.error:
		set_errno	EINVALIDPARAM
		jmp			.return
	.params_ok:
		or			edx, SYNAPS_LINK_INPUTS
		jnz			.outputs
		;Link input synapses
		mov			[.s1.inputs.next_ptr], rsi
		mov			[.s2.inputs.prev_ptr], rdi
		jmp			.done
	.outputs:
		cmp			edx, SYNAPS_LINK_OUTPUTS
		jnz			.error
		;link output synapses
		mov			[.s1.outputs.next_ptr], rsi
		mov			[.s2.outputs.prev_ptr], rdi
	.done:
		set_errno
	.return:
		popregs
		leave
		ret

;===============================================================================
;	Deletion of synaptic link
;void		synaps_delete(synaps_t** s)
synaps_delete:
		push		rbp
		mov 		rbp, rsp
		pushregs
		;Check params
		or			rdi, 0
		jz			.return
		or			qword [rdi], 0
		jz			.return
		;params ok
		mov			rbx, rdi
		mov			rdi, [rbx]
		call		free
		xor			rdi, rdi
		mov			[rbx], rdi
	.return:
		popregs
		leave
		ret

;===============================================================================
;void		synaps_delete_list(synaps_t** s)
;Only deletes chained output synapses
synaps_delete_list:
		push		rbp
		mov 		rbp, rsp
		pushregs
		;Check params
		or			rdi, 0
		jz			.return
		or			qword [rdi], 0
		jz			.return
		;params ok
		;--------------------
		virtual at rbx
			.s	synaps
		end virtual
		;--------------------
		mov			rbx, [rdi]
		mov			qword [rdi], 0
	.deletion_loop:
		mov			rdi, rbx
		mov			rbx, [.s.outputs.next_ptr]
		push 		rbx
		call 		free
		pop			rbx
		or			rbx, 0
		jnz			.deletion_loop
	.return:
		popregs
		leave
		ret
