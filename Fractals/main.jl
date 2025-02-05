#!/usr/bin/env julia
using Luxor, Colors, Images

function explodes(f, z, mu, tau, iterations)
	for i in 1:iterations
		z = f(z, mu)
		if abs(z) > abs(tau)
			return true
			continue
		end
	end
	return false
end

function get_range(center, scale, res)
	return range(center-scale, center+scale, res)
end

function fractal(f, mu, tau, iterations, xres, yres, xcenter, ycenter, xscale, yscale)
	data = Vector{Vector{ComplexF64}}()
	for i in 1:Threads.nthreads() push!(data, ComplexF64[]) end

	image = ones(ARGB32, xres, yres)

	Threads.@threads for (i, x) in collect(enumerate(get_range(xcenter, xscale, xres)))
		for (j, y) in collect(enumerate(get_range(ycenter, yscale, yres)))
			z = x + (y)im
			if !explodes(f, z, mu, tau, iterations)
				push!(data[Threads.threadid()], z)
				image[i, j] = colorant"black"
			end
		end
	end
	data_combined = reduce(vcat, data)
	return data_combined, image
end

f(z, mu) = sin(z) + 1/z + mu
mu = 0.1 - 0.2im

res = 10000
center = [0, 0]
scale = [1,1.2]

tau = 100
iterations = 100

runtime = @elapsed begin
	data, image = fractal(f, mu, tau, iterations, res, res, center[1], center[2], scale[1], scale[2])
end
println("runtime: ", runtime, ", points: ", length(data))

Drawing(image, "output.png")
finish()
