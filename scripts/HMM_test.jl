using Turing
using StatsPlots
using Random
using Distributions

include("../src/CoTSOpt.jl")

Random.seed!(26062022)

nports = 5
ndays = 100
port_data = [rand(ndays) .* i for i in 1:nports]

# True data:
ntrue_ports = 2
true_ports = sample(1:nports, ntrue_ports, replace=false)
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

plot(true_data, label="True")
plot!(perturbed_data, label="Perturbed")

# Next steps:
# The emission data is `perturbed_data`
# The observed data is `port_data`
# The parameters are binary variables of the sum
# Need to write down the transition probabilities of the three parts:
# Initial distribution of x_1
# Transitions y_t given x_t
# Transitions x_t given x_t-1

# Note:
# Variables which are sampled from particle samplers like PG or SMC need to be TArrays. Others can be normal arrays which are going to be faster

# Turing model definition.
@model function BayesHmm(data, ?)
    # Get observation length.
    N = length(data)

    # State sequence.
    s = tzeros(Int, N)

    # Emission matrix.
    m = Vector(undef, K)

    # Transition matrix.
    T = Vector{Vector}(undef, K)

    # Assign distributions to each element
    # of the transition matrix and the
    # emission matrix.
    for i in 1:K
        T[i] ~ Dirichlet(ones(K) / K)
        m[i] ~ Normal(i, 0.5)
    end

    # Observe each point of the input.
    s[1] ~ Categorical(K)
    y[1] ~ Normal(m[s[1]], 0.1)

    for i in 2:N
        s[i] ~ Categorical(vec(T[s[i-1]]))
        y[i] ~ Normal(m[s[i]], 0.1)
    end
end;