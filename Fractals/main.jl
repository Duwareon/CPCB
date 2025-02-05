#!/usr/bin/env julia 
using Images

function explodes(f, z, mu, tau, iterations)
	for i in 1:iterations
		z = f(z, mu)
		if abs(z) > abs(tau)
			return true, i
			continue
		end
	end
	return false, 0
end

function get_range(center, scale, res)
	return range(center-scale, center+scale, res)
end

function fractal(f, mu, tau, iterations, xres, yres, xcenter, ycenter, xscale, yscale)
	data = Vector{Vector{ComplexF64}}()
	for i in 1:Threads.nthreads() push!(data, ComplexF64[]) end

	image = zeros(Float64, yres, xres)

	Threads.@threads for (i, x) in collect(enumerate(get_range(xcenter, xscale, xres)))
		for (j, y) in collect(enumerate(get_range(ycenter, yscale, yres)))
			z = x + (y)im
			cond, final = explodes(f, z, mu, tau, iterations)
			if cond
				push!(data[Threads.threadid()], z)
				image[j, i] = (final/iterations)
			end
		end
	end
	data_combined = reduce(vcat, data)
	return data_combined, image
end

f(z, mu) = (z^5) + (z^3) + mu
mu = (-0.7-0.5im)*0.8

res = 10000
scale = [1.0, 1.5]
center = [0, 0]

xres = trunc(Int, res*scale[1])
yres = trunc(Int, res*scale[2])

tau = 100
iterations = 30

runtime = @elapsed begin
	data, image = fractal(f, mu, tau, iterations, xres, yres, center[1], center[2], scale[1], scale[2])
end
println("runtime: $runtime")

save("output.png", image)
#plot(image)
#readline()
