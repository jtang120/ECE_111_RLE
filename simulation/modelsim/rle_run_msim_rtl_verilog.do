transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+C:/Users/James\ Tang/Documents/GitHub/ECE_111_RLE {C:/Users/James Tang/Documents/GitHub/ECE_111_RLE/rle.v}

