# ------------------------------------------------------------------------------------------- #

.data
str_hello:			.asciiz	"\nThe longest idenfier finder\nPlease enter the input file name: "
str_not_found:			.asciiz "\nFile not found"
str_newpath:			.asciiz "\nDo you want to eneter new path of the file (1 - yes | 0 - no) ? \n"      
str_curr_identifier:		.asciiz "\nThe longest identifier: "
str_len_curr_identifier:	.asciiz "\n\n\nThe lenght of the longest identifier: "
newline:			.asciiz "\n"

inbuf:				.space	512				#input buffer
id:				.space	512				#id buffer
curr_id:			.space	512				#curr_id buffer

# ------------------------------------------------------------------------------------------- #
#
#	t0 - ptr to current char in input buffer
#	t1 - ptr to current char in id buffer
#	t2 - ptr to current char in curr_id (the longest id) buffer
#
#	t4 - lenght of the longest identifier
#	t5 - lenght of the current captured identifier	
#	t8 - helper to copy identifier
#	t9 - amount data in the input buffer
#
#	$s4 - current the longest identifier
#	$s5 - currently capture identfier
#
# ------------------------------------------------------------------------------------------- #

.text
.globl main

main:
	li	$v0, 4
	la	$a0, str_hello			#print command to input file name
	syscall

# -------------------------------------------------------------------------------------------#
#				Reading the input_file path	
# -------------------------------------------------------------------------------------------#	
			
	li	$v0, 8				
	la	$a0, inbuf			#put pathfile into 
	li	$a1, 512
	syscall
	
	la	$t0, 0
	move 	$t0, $a0			#ptr to current char in input buffer
	
	la	$t1, id
	la	$t2, curr_id


# -------------------------------------------------------------------------------------------#
#				Removing the '\n' from input_file path	
# -------------------------------------------------------------------------------------------#	

clean_filename:
	li	$t3, 0
	lbu 	$t3, ($t0)
	addiu	$t0, $t0, 1
	bne	$t3, '\n', clean_filename
	subiu	$t0, $t0, 1
	sb	$zero, ($t0)

# -------------------------------------------------------------------------------------------#
#					Opening file	
# -------------------------------------------------------------------------------------------#	

open_file:
  	li	$v0, 13
	la	$a0, inbuf			#opening file to read
	li	$a1, 0
  	li	$a2, 0
  	syscall
  	
  	move	$t9, $v0			#descriptor of file to read
  	blt	$t9, 0, file_str_not_found	#check if it's correctly opened
  	

	move	$a0, $t0
	li	$a1, 512
	jal	clear_buf

	move	$a0, $t1
	li	$a1, 512
	jal	clear_buf

	move	$a0, $t2
	li	$a1, 512
	jal	clear_buf
	
	la 	$t4, 0				# lenght counter = 0
	la 	$t5, 0
	
	move	$t2, $t0			#ptr to last char in inbuf
		
	li	$s7, 0				#EOF flague for getc
	
	

main_loop:
	jal	getc
	
	move	$a0, $t1
	li	$a1, 512
	jal	clear_buf

	li	$t5, 0
	la	$s5, id
	
	beq	$v0, '/', loop_comment		
	beq	$v0, '#', loop_single_line
	beq	$v0, '"', loop_dquotes
	beq	$v0, 39, loop_quote				# ' - 39 ASCII
	beq	$v0, ' ', main_loop
	bgt	$v0, 'z', main_loop				# if > 'z' is not valcurr_id
	bge	$v0, 'a', capture_curr_identifier		# in range <'a';'z'> 
	beq	$v0, '_', capture_curr_identifier		# equal to '_'
	bgt	$v0, 'Z', main_loop				# if in range ('Z';a)\{'_'} is not valcurr_id
	bge	$v0, 'A', capture_curr_identifier		# in range <'A';'Z'> 
	bgt	$v0, '9', main_loop				# if in range ('9';'A') is not valcurr_id
	bge	$v0, '0', loop_sequency_starts_from_digit	# in range <'0';'9'> 
	
	b	main_loop


# -------------------------------------------------------------------------------------------#
#		The loop is resposible for skipping the comment's, quotes areas 	
# -------------------------------------------------------------------------------------------#

loop_comment:
	jal 	getc
	
	beq	$v0,'/',loop_single_line	
	bne	$v0,'/',loop_comment_multi_line

loop_comment_multi_line:
	jal 	getc
	
	beq 	$v0,'/',main_loop
	b 	loop_comment_multi_line

loop_dquotes:
	jal 	getc

	beq 	$v0,'"',main_loop
	b 	loop_dquotes

loop_quote:
	jal 	getc

	beq 	$v0,39,main_loop
	b 	loop_quote
		
loop_single_line:
	jal 	getc
	beq 	$v0,'\n',main_loop
	b loop_single_line	
	
loop_sequency_starts_from_digit:
	jal 	getc
	beq 	$v0,';',main_loop
	beq 	$v0,' ',main_loop
	beq 	$v0,'\n',main_loop
	b loop_single_line	

# -------------------------------------------------------------------------------------------#
#			Calculate the lenght of the curr_identifier $t5 
#			and storing the new curr_identifier to the $s5  			
# -------------------------------------------------------------------------------------------#
capture_curr_identifier:
	sb	$v0, 0($s5)
	addi 	$s5, $s5, 1			
	addi	$t5, $t5, 1			
	
	jal	getc
	bgt	$v0, 'z', compare_len			# if > 'z' is not valcurr_id
	bge	$v0, 'a', capture_curr_identifier		# in range <'a';'z'> 
	beq	$v0, '_', capture_curr_identifier		# equal to '_'
	bgt	$v0, 'Z', compare_len			# if in range ('Z';a)\{'_'} is not valcurr_id
	bge	$v0, 'A', capture_curr_identifier		# in range <'A';'Z'> 
	bgt	$v0, '9', compare_len			# if in range ('9';'A') is not valcurr_id
	bge	$v0, '0', capture_curr_identifier		# in range <'0';'9'> 
	

# -------------------------------------------------------------------------------------------#
#		Comparing obtained lenght of current curr_identifier with max_len
#			If $t5 > $t4 => $t4 = $t5 and store actual 
#			identifier to the $s4 (the longest identifier)		
# -------------------------------------------------------------------------------------------#

compare_len:
	la 	$s4, curr_id
	la	$s5, id
	
	bge	$t4, $t5, main_loop
	addi	$t4, $t5, 0
	
	li	$t8, 0
	b 	copy_curr_identifier
	
	li	$v0, 1		
	move	$a0, $t4
	syscall

	b main_loop


# -------------------------------------------------------------------------------------------#
#    Helper loop responsible for store actual identifier to the $s4 (the longest identifier)
# -------------------------------------------------------------------------------------------#
copy_curr_identifier:
	lb	$a0, 0($s5)
	li 	$v0, 1
	sb	$a0, 0($s4)

	addi	$s4,$s4,1
	addi	$s5,$s5,1
	
	addi	$t8, $t8, 1			
	bge	$t8,$t5, main_loop
	
	j copy_curr_identifier
	
# -------------------------------------------------------------------------------------------#
#    				Checking that file with this path exist
# -------------------------------------------------------------------------------------------#

file_str_not_found:
	la	$a0, str_not_found
	li	$v0, 4
	syscall					
	
	move	$t9, $zero			#reseting descriptors

	la	$t0, inbuf

	move	$a0, $t0
	li	$a1, 512
	jal	clear_buf			#clear inbuf
	
	j	main				
	
# -------------------------------------------------------------------------------------------#
#    		Method getc and get_inbuf, which is repsonsible for read data to inbuf
# -------------------------------------------------------------------------------------------#

getc:
	beq	$t0, $t2, get_inbuf
	addiu	$t0, $t0, 1
	lb	$a3, ($t0)
	beqz	$a3, EOF
	lbu	$v0, ($t0)
	sb	$zero, ($t0)
	
	jr	$ra

get_inbuf:
	bnez	$s7, EOF
	move 	$a0, $t9      			#read first 512 chars of 
	
	beq	$v0, -1, close_file
	
	li   	$v0, 14	
	la   	$a1, inbuf
	li  	$a2, 512	
	syscall
	
	
	seq	$s7, $v0, $zero			#EOF flague = 1 if last "package" of data loaded 
	la	$t0, inbuf
	addiu	$t2, $t0, 511	
	
	la	$a3, inbuf
	la	$t0, inbuf			#set t0 to the begining
	lbu	$v0, ($t0)			#return to caller of getc if loading 1st sign
	
	jr	$ra

# -------------------------------------------------------------------------------------------#
#    				Helpers resposible for clearing buffers
# -------------------------------------------------------------------------------------------#

clear_buf:
	lbu	$s0, ($a0)			#ptr to buffer's begining; a1 stores max number of chars in buffer
	addiu	$s1, $s1, 1
	beq	$s1, $a1, clear_last		#if 0 or buffer is reached
	seq 	$s2, $s0, $zero 
	sb	$zero, ($a0)
	addiu	$a0, $a0, 1
	beqz	$s2, clear_buf
	
	jr	$ra
	
clear_last:
	sb	$zero, ($a0)
	jr	$ra


# -------------------------------------------------------------------------------------------#
#    		Closing the input file, and printing the obtained results
# -------------------------------------------------------------------------------------------#

EOF:
	li	$v0, -1
	jr	$ra
	
close_file:
	li	$v0, 16				#close file to read
	move	$a0, $t9
	syscall


	li	$v0,4	
	la	$a0, str_len_curr_identifier
	syscall

	li	$v0, 1
	move	$a0, $t4
	syscall

	li	$v0, 4
	la	$a0, str_curr_identifier
	syscall

	li	$v0, 4
	la 	$s4, curr_id
	move 	$a0, $s4 
	syscall    
	
	
	move	$a0, $t0
	li	$a1, 512
	jal	clear_buf			#clear inbuf
	
	move	$a0, $t1
	li	$a1, 512	
	jal	clear_buf			#clear id
	
	move	$a0, $t2
	li	$a1, 8	
	jal	clear_buf			#clear curr_id
	
# -------------------------------------------------------------------------------------------#
#    			Terminete program or enter new path - question
# -------------------------------------------------------------------------------------------#	
	
	li	$v0, 4
	la	$a0, str_newpath
	syscall
		
	li 	$v0, 5
	syscall
	move	$t0, $v0
	beq	$t0, 1, main
			
	
	li     $v0, 10
	syscall
