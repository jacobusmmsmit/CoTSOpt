using Turing
using StatsPlots
using Statistics

# Generate ports:
nports = 30
ndays = 1000
port_data = [rand(ndays) for _ in 1:nports]
# True data:
ntrue_ports = 2
true_ports = sample(1:nports, ntrue_ports, replace = false)
true_data = zeros(ndays)
for i in 1:nports
    if i in true_ports
        true_data .+= port_data[i]
    end
end
p = (nports, ndays)

@model function export_model(exports, port_data, p)
    # Unpack parameters
    nports, ndays = p

    # Set priors
    port_included = zeros(nports)
    port_included .~ Beta(0.1, 0.1)
    σ ~ LogNormal(0.01, 0.075)
    predicted = zeros(ndays)
    for i in 1:nports
        predicted .+= port_data[i] .* port_included[i]
    end
    exports ~ MvNormal(predicted, σ)
end

model = export_model(true_data, port_data, p)
chain = sample(model, MH(), 1000)

plot(chain)

chain