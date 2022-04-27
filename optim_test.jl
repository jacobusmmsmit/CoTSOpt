using Optim
using LinearAlgebra
using StatsBase
using Distributions
using Random
using StatsPlots

Random.seed!(27042022)

nports = 5
ndays = 100
port_data = [rand(ndays) .* i for i in 1:nports]

# True data:
ntrue_ports = 2
true_ports = sample(1:nports, ntrue_ports, replace = false)
true_ports_bin = 1:nports .∈ Ref(true_ports)
true_data = zeros(ndays)
for i in 1:nports
    if i in true_ports
        true_data .+= port_data[i]
    end
end
σ² = 0.2
perturbed_data = true_data .+ rand(Normal(0, σ²), ndays)
p = (nports, ndays)

dx(x) = (x-1)x

lower = zeros(nports)
upper = ones(nports)

cost(xs, port_data, true_data, λ) = norm(true_data .- sum(port_data .* xs))/ndays + sum(abs2, λ * dx.(xs))

initial_x = rand((0.99, 0.01), nports)
initial_x = [0.5 for _ in 1:nports]
inner_optimizer = LBFGS()
# Solve unperturbed problem:
results = optimize(x -> cost(x, port_data, true_data, 0.0), lower, upper, initial_x, Fminbox(inner_optimizer))
pred_ports = Optim.minimizer(results)
resval = Optim.minimum(results)

# Solve perturbed problem:
begin
    start_x = initial_x
    maxiters = 100
    curriter = 1
    λ = 0.0
    λ_increment = 0.01
    λ_best = 0.0
    min_resval = Inf
    while curriter <= maxiters
        curriter += 1
        @show λ
        results2 = optimize(x -> cost(x, port_data, perturbed_data, λ), lower, upper, initial_x, Fminbox(inner_optimizer))
        start_x = Optim.minimizer(results2)
        resval_perturbed = Optim.minimum(results2)
        if cost(start_x, port_data, true_data, 0.0) < min_resval
            println("Better!")
            min_resval = resval_perturbed
            λ_best = λ
        end
        λ += λ_increment
        println(cost(start_x, port_data, true_data, 0.0))
    end
    println("Optimal λ = ", λ_best)
    perturbed_results = optimize(x -> cost(x, port_data, perturbed_data, λ_best), lower, upper, initial_x, Fminbox(inner_optimizer))
    pred_ports_perturbed = Optim.minimizer(perturbed_results)
end

groupedbar([true_ports_bin pred_ports_perturbed], ylims = (0, 1), barwidth = 0.3, xticks = 1:nports, labels = ["True" "Perturbed" "Perturbed"])