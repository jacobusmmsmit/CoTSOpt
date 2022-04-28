using DelimitedFiles
using DataFrames
using CSV
using Turing
using Statistics
using StatsBase
using StatsPlots

default(fontfamily="Computer Modern")
df = CSV.read("data/export_test.csv", DataFrame)
all_data = Array(df[:, 2:end])
true_data = all_data[:, 1]
port_data = [all_data[:, i] for i in 2:size(all_data[:, 2:end], 2)]

nports = length(port_data)
ndays = length(true_data)
p = nports, ndays

@model function export_model(exports, port_data, p)
    nports, ndays = p
    # Set priors
    port_included ~ filldist(Beta(0.01, 0.01), nports)
    σ ~ InverseGamma(2, 3)

    # Predict given sample from prior
    predicted = zeros(eltype(port_included), ndays)
    for i in 1:nports
        predicted .+= port_data[i] .* port_included[i]
    end
    exports ~ MvNormal(predicted, σ)
end

model = export_model(true_data, port_data, p)
chain = sample(model, NUTS(), 5000)

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
    # true_newdata = reduce(hcat, newdata) * (1:nports .∈ Ref(true_ports))
    # plot!(true_newdata, colour=:black, label="True data", ls=:dash, legend=:topleft)
    # my_correlation = round(cor(true_newdata, predicted), sigdigits=3)
    # plot!(title="Predicted Timeseries (Corr = $my_correlation)", xlabel="Day", ylabel="Value")
    return prediction_plot
end

begin
    prediction_plot(port_data, chain, p, 400)
    plot!(true_data, colour=:black, label="True Data", ls=:dash)
    pred_ports = port_included_mean = vec(mean(Array(chain), dims=1)[:, 1:end-1])
    predicted = zeros(ndays)
    for i in 1:nports
        predicted .+= port_data[i] .* pred_ports[i]
    end
    c = round(cor(predicted, true_data), sigdigits=3)
    plot!(title="Predicted Timeseries (Correlation = $c)", xlabel="Month", ylabel="Exports in Tons")
end
savefig("figures/realdata_example.png")

bar(1:length(pred_ports), pred_ports,)