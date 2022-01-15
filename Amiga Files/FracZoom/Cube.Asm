NOOFPOINTS	equ	8
NOOFLINES	equ	12

vectPts	dc.w	-500,-500,-500
	dc.w	 500,-500,-500
	dc.w	 500, 500,-500
	dc.w	-500, 500,-500
	dc.w	 500,-500, 500
	dc.w	-500,-500, 500
	dc.w	-500, 500, 500
	dc.w	 500, 500, 500

lines	dc.w	0*4,1*4
	dc.w	1*4,2*4
	dc.w	2*4,3*4
	dc.w	3*4,0*4
	dc.w	4*4,5*4
	dc.w	5*4,6*4
	dc.w	6*4,7*4
	dc.w	7*4,4*4
	dc.w	0*4,5*4
	dc.w	1*4,4*4
	dc.w	2*4,7*4
	dc.w	3*4,6*4
