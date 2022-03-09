using Statistics
x = rand(10^7);
data = 1 ./ (x .^ 2);
a,b,c,d = Statistics.quantile!(data, [0, .001, .999, 1]);
#used_bits(d) # Naive required bit-width
println("min=",a,", 0.1%=", b, ", 99.9%=",c,", max=",d)

