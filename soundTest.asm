*= $801
.word (+), 10
.null $9e, "2061"
+ .word 0

*=2061
lda #$09
sta $d413
sta $d414
lda #%00011111
sta $d418
lda #$ff
sta $d40e
sta $d40f
sta $d410
sta $d411
sta $fc
sta $fd
lda #%00100001
sta $d412

- 	lda $d012
	bne -
	bit $d011
	bmi -
	lda $fc
	sec
	sbc #20
	sta $fc
	lda $fd
	sbc #0
	sta $fd
	lda $fd
	sta $d40e
	sta $d410
	lda $fc
	sta $d40f
	sta $d411
	jmp -