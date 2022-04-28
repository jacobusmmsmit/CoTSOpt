using Turing
using Optim
using StatsPlots
using Statistics
default(fontfamily="Computer Modern")

function generate_timeseries(ndays, start=0, ϵ_dist=Normal(0, 1))
    ts = zeros(ndays)
    ts[1] = start
    for day in 2:ndays
        ts[day] = ts[day-1] + rand(ϵ_dist)
    end
    return ts
end

# Generate ports:
nports = 50
ndays = 200
port_data = [generate_timeseries(ndays) * exp(i / nports) / 2 for i in 1:nports]

# True data is a sum of some of the ports
ntrue_ports = 20
true_ports = sample(1:nports, ntrue_ports, replace=false)
true_data = zeros(ndays)
for i in 1:nports
    if i in true_ports
        true_data .+= port_data[i]
    end
end

# Perturbed data with a normal distribution with constant variance
σ² = 5
perturbed_data = true_data .+ rand(Normal(0, σ²), ndays)
p = (nports, ndays)

# The model's prior forces the parameters between 0 and 1
@model function export_model(exports, port_data, p)
    nports, ndays = p
    # Set priors
    port_included ~ filldist(Beta(0.1, 0.1), nports)
    σ ~ InverseGamma(2, 3)

    # Predict given sample from prior
    predicted = zeros(eltype(port_included), ndays)
    for i in 1:nports
        predicted .+= port_data[i] .* port_included[i]
    end
    exports ~ MvNormal(predicted, σ)
end

model = export_model(perturbed_data, port_data, p)
chain = sample(model, NUTS(), 1000)

plot(chain)

function prediction_plot(newdata, chain, p, nsamples=10)
    nports, _ = p
    chain_array = Array(chain) # Pull the parameter samples
    ndays_newdata = size(newdata[1])
    prediction_plot = plot()
    predicted = zeros(ndays_newdata)
    for _ in 1:nsamples
        predicted .= 0
        port_included_sample = chain_array[rand(1:size(chain_array, 1)), 1:nports]
        for i in 1:nports
            predicted .+= newdata[i] .* port_included_sample[i]
        end
        plot!(predicted, label="", colour=:grey, alpha=5 / nsamples, lw=2)
    end
    # quantiles = map(x -> quantile(x, [0.25, 0.75]), eachcol(chain_array))[1:end-1]
    # quantiles_long = first.(quantiles), last.(quantiles)
    # pred_quantile_upper = zeros(ndays_newdata)
    # pred_quantile_lower = zeros(ndays_newdata)
    # for i in 1:nports
    #     pred_quantile_lower .+= newdata[i] .* quantiles_long[1][i]
    #     pred_quantile_upper .+= newdata[i] .* quantiles_long[2][i]
    # end

    port_included_mean = vec(mean(chain_array, dims=1)[:, 1:end-1])
    predicted .= 0
    for i in 1:nports
        predicted .+= newdata[i] .* port_included_mean[i]
    end
    # pred_quantile_lower .= predicted .- pred_quantile_lower
    # pred_quantile_upper .-= predicted
    plot!(predicted, colour=:red, alpha=0.5, lw=2, label="Prediction")
    true_newdata = reduce(hcat, newdata) * (1:nports .∈ Ref(true_ports))
    plot!(true_newdata, colour=:black, label="True data", ls=:dash, legend=:topleft)
    my_correlation = round(cor(true_newdata, predicted), sigdigits=3)
    plot!(title="Predicted Timeseries (Corr = $my_correlation)", xlabel="Day", ylabel="Value")
    return prediction_plot
end

newdata = [generate_timeseries(ndays) for _ in 1:nports]
prediction_plot(newdata, chain, p, 400)
savefig("figures/example_prediction_2.pdf")