*
*  Demonstration of input routine with backspace/delete support, length
*  restriction and cursor control (left, right, home, end)
*
*  Written by Alex Peters, 23/6/2005
*  3105178 // apeters@cs.rmit.edu.au
*
*  Still to do:
*    >  make the gets subroutine fully reentrant
*    >  move some very similar code into subroutines
*    >  conjure up some appropriate label names
*    >  comment some parts of the code from the flow charts
*
          org     $1000       ; code space
          move.l  #$7ffe,sp   ; initialise stack pointer

          pea     s_prompt
          bsr     puts        ; display prompt
          add.l   #4,sp

          pea     string      ; push parameter 1: memory location of string
          move.w  #20,-(sp)   ; push parameter 2: maximum length of string
          bsr     gets
          add.l   #6,sp       ; remove parameters

          pea     s_remark
          bsr     puts        ; display remark
          add.l   #4,sp

          pea     string
          bsr     puts        ; display entered string
          add.l   #4,sp

          move.b  #EXIT,d7
          trap    #14         ; return to OS

*
*  The gets subroutine needs me to write a proper description.
*
gets      move.l  6(sp),a1    ; a1 = location of cursor in string
          move.l  a1,a2       ; a2 = location of end of string
          clr.l   d1          ; d1 = cursor position
          clr.l   d2          ; d2 = current string length

gets_key  move.b  #INCH,d7
          trap    #14         ; get key

          cmp.b   #0,d0
          beq     gets_nul    ; branch if a control character follows
          cmp.b   #CR,d0
          beq     gets_cr     ; branch if Enter
          cmp.b   #BKSP,d0
          beq     gets_bsp    ; branch if Backspace

          cmp.w   4(sp),d2    ; compare current length to maximum length
          beq     gets_key    ; ignore if maximum length reached
          cmp.b   #9,d0
          beq     gets_key    ; ignore tabs
          cmp.b   #7,d0
          beq     gets_key    ; ignore bells
          cmp.b   #LF,d0
          beq     gets_key    ; ignore Ctrl+J
          cmp.b   #26,d0
          beq     gets_key    ; ignore Ctrl+Z

*  Update string in memory

          move.l  a2,a3       ; a3 = loop from end of string to cursor loc.
gets_lp1  cmp.l   a1,a3
          beq     gets_lp2    ; fall through if a3 > a1
          sub.l   #1,a3
          move.b  (a3),1(a3)
          bra     gets_lp1

gets_lp2  move.b  d0,(a1)     ; store in memory
          add.w   #1,d2       ; increment string length
          add.l   #1,a2

*  Update display

          move.l  a1,a3
          move.b  #OUTCH,d7
gets_lp3  move.b  (a3)+,d0    ; must rename those labels!
          trap    #14
          cmp.l   a2,a3
          bne     gets_lp3

          add.l   #1,d1
          add.l   #1,a1

*  Restore cursor location

          move.l  a2,a3
          move.b  #BKSP,d0
gets_lp4  cmp.l   a1,a3
          beq     gets_key
          trap    #14
          sub.l   #1,a3
          bra     gets_lp4

gets_nul  trap    #14         ; get control character
          cmp.b   #'K',d0
          beq     gets_la     ; branch on left arrow
          cmp.b   #'M',d0
          beq     gets_ra     ; branch on right arrow
          cmp.b   #'G',d0
          beq     gets_hk     ; branch on home key
          cmp.b   #'O',d0
          beq     gets_ek     ; branch on end key
          cmp.b   #'S',d0
          beq     gets_del    ; branch on Delete key
          bra     gets_key    ; ignore any other control characters

gets_hk   cmp.w   #0,d1
          beq     gets_key    ; branch if can't move left

          move.b  #BKSP,d0    ; }
          move.b  #OUTCH,d7   ; } update display
          trap    #14         ; }

          sub.w   #1,d1       ; decrement cursor location
          sub.l   #1,a1
          bra     gets_hk

gets_ek   cmp.w   d2,d1
          beq     gets_key    ; branch if can't move right

          move.b  #OUTCH,d7   ; }
          move.b  (a1)+,d0    ; } update display
          trap    #14         ; }

          add.w   #1,d1       ; increment cursor location
          bra     gets_ek

gets_la   cmp.w   #0,d1
          beq     gets_key    ; branch if can't move left

          move.b  #BKSP,d0    ; }
          move.b  #OUTCH,d7   ; } update display
          trap    #14         ; }

          sub.w   #1,d1       ; decrement cursor location
          sub.l   #1,a1
          bra     gets_key

gets_ra   cmp.w   d2,d1
          beq     gets_key    ; branch if can't move right

          move.b  #OUTCH,d7   ; }
          move.b  (a1)+,d0    ; } update display
          trap    #14         ; }

          add.w   #1,d1       ; increment cursor location
          bra     gets_key

gets_bsp  cmp.b   #0,d1
          beq     gets_key    ; branch if can't backspace

          move.b  #OUTCH,d7
          move.b  #BKSP,d0
          trap    #14
          sub.l   #1,d1
          sub.l   #1,a1
          sub.l   #1,d2
          sub.l   #1,a2
          move.l  a1,a3
gets_lp5  cmp.l   a2,a3
          beq     gets_lp6
          move.b  1(a3),(a3)
          move.b  (a3)+,d0
          trap    #14
          bra     gets_lp5
gets_lp6  move.b  #' ',d0
          trap    #14
          move.b  #BKSP,d0
          trap    #14
          move.l  a2,a3
          move.b  #BKSP,d0
gets_lp7  cmp.l   a1,a3
          beq     gets_key
          trap    #14
          sub.l   #1,a3
          bra     gets_lp7

gets_del  cmp.b   d1,d2
          beq     gets_key    ; branch if can't delete

          move.b  #OUTCH,d7
          sub.l   #1,d2
          sub.l   #1,a2
          move.l  a1,a3
gets_lp8  cmp.l   a2,a3
          beq     gets_lp9
          move.b  1(a3),(a3)
          move.b  (a3)+,d0
          trap    #14
          bra     gets_lp8
gets_lp9  move.b  #' ',d0
          trap    #14
          move.b  #BKSP,d0
          trap    #14
          move.l  a2,a3
          move.b  #BKSP,d0
gets_lpA  cmp.l   a1,a3
          beq     gets_key
          trap    #14
          sub.l   #1,a3
          bra     gets_lpA

gets_cr   move.b #0,(a2)      ; null-terminate string
          rts

*  The puts (put string) subroutine prints characters to the screen starting at
*  the memory address passed on the stack until a null is reached (this is
*  yoinked from my assignment 4).

puts      move.l  a1,-(sp)         ; }
          move.b  d0,-(sp)         ; } save register values to the stack
          move.b  d1,-(sp)         ; }

          move.l  12(sp),a1        ; initialise memory pointer
          move.b  #248,d7          ; initialise trap parameter

puts_lp   move.b  (a1)+,d0         ; read character, increment memory pointer
          beq     puts_end         ; display no more if a null was read
          trap    #14              ; display character
          bra     puts_lp          ; repeat for each character

puts_end  move.b  (sp)+,d1         ; }
          move.b  (sp)+,d0         ; } restore register values from the stack
          move.l  (sp)+,a1         ; }

          rts                      ; return to caller

*  String definitions

s_prompt  dc.b    CR,LF,'Enter a string no longer than 20 characters: ',0
s_remark  dc.b    CR,LF,'You entered: ',0

*  Data space

          org     $2000
string    ds.b    21               ; 21 bytes including null terminator

*  Constants

BKSP      equ     8
LF        equ     10
CR        equ     13
EXIT      equ     228
INCH      equ     247
OUTCH     equ     248

          end

