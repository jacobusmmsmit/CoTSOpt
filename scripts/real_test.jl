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
train_ndays = floor(Int, size(all_data, 1) / 1.3)
test_ndays = size(all_data, 1) - train_ndays

train_data = all_data[1:train_ndays, 1]
train_port_data = [all_data[1:train_ndays, i] for i in 2:size(all_data[:, 2:end], 2)]
test_data = all_data[train_ndays+1:train_ndays+test_ndays, 1]
test_port_data = [all_data[train_ndays+1:train_ndays+test_ndays, i] for i in 2:size(all_data[:, 2:end], 2)]

nports = length(port_data)
p = nports, train_ndays

@model function export_model(exports, port_data, p)
    nports, ndays = p
    # Set priors
    port_included ~ filldist(Beta(1 / 300, 1 / 300), nports)
    σ ~ InverseGamma(2, 3)

    # Predict given sample from prior
    predicted = zeros(eltype(port_included), ndays)
    for i in 1:nports
        predicted .+= port_data[i] .* port_included[i]
    end
    exports ~ MvNormal(predicted, σ)
end

model = export_model(train_data, train_port_data, p)
chain = sample(model, NUTS(), 1000)

function prediction_plot(train_data, test_data, chain, p; nsamples=10)
    nports, _ = p
    chain_array = Array(chain) # Pull the parameter samples

    ndays_train_data = length(train_data[1])
    ndays_test_data = length(test_data[1])
    println(ndays_train_data)
    prediction_plot = plot()

    train_predicted = zeros(ndays_train_data)
    for _ in 1:nsamples
        train_predicted .= 0
        port_included_sample = chain_array[rand(1:size(chain_array, 1)), 1:nports]
        for i in 1:nports
            train_predicted .+= train_data[i] .* port_included_sample[i]
        end
        plot!(1:ndays_train_data, train_predicted, label="", colour=:grey, alpha=5 / nsamples, lw=2)
    end
    port_included_mean = vec(mean(chain_array, dims=1)[:, 1:end-1])
    train_predicted .= 0
    for i in 1:nports
        train_predicted .+= train_data[i] .* port_included_mean[i]
    end
    plot!(1:ndays_train_data, train_predicted, colour=:blue, alpha=0.5, lw=2, label="Training Prediction")

    test_predicted = zeros(ndays_test_data)
    for _ in 1:nsamples
        test_predicted .= 0
        port_included_sample = chain_array[rand(1:size(chain_array, 1)), 1:nports]
        for i in 1:nports
            test_predicted .+= test_data[i] .* port_included_sample[i]
        end
        plot!(ndays_train_data+1:ndays_train_data+ndays_test_data, test_predicted, label="", colour=:grey, alpha=5 / nsamples, lw=2)
    end
    port_included_mean = vec(mean(chain_array, dims=1)[:, 1:end-1])
    test_predicted .= 0
    for i in 1:nports
        test_predicted .+= test_data[i] .* port_included_mean[i]
    end
    plot!(ndays_train_data+1:ndays_train_data+ndays_test_data, test_predicted, colour=:red, alpha=0.5, lw=2, label="Test Prediction")
    return prediction_plot
end

begin
    prediction_plot(train_port_data, test_port_data, chain, p, nsamples=400)
    plot!(all_data[:, 1], colour=:black, label="True Data", ls=:dash)
    pred_ports = vec(mean(Array(chain), dims=1)[:, 1:end-1])
    predicted = zeros(test_ndays)
    for i in 1:nports
        predicted .+= test_port_data[i] .* pred_ports[i]
    end
    c = round(cor(predicted, test_data), sigdigits=3)
    plot!(title="Predicted Timeseries (Test Correlation = $c)", xlabel="Month", ylabel="Exports in Tons")
end

savefig("figures/realdata_example_traintest.png")
bar(1:length(pred_ports), pred_ports, label="")