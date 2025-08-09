vlib work
vlog Baud_generator.v Baud_generator_tb.v
vsim -voptargs=+acc work.Baud_generator_tb
add wave *
run -all
#quit -sim