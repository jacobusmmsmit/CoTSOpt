using JuMP
using Random
using StatsBase
using Distributions
using Plots
using Ipopt
using Juniper
using CSV
using DataFrames

Random.seed!(03052022)

default(fontfamily="Computer Modern")

df = CSV.read("data/export_test.csv", DataFrame)
all_data = Array(df[:, 2:end])
train_ndays = floor(Int, size(all_data, 1) / 1.3)
test_ndays = size(all_data, 1) - train_ndays

train_data = all_data[1:train_ndays, 1]
train_port_data = [all_data[1:train_ndays, i] for i in 2:size(all_data[:, 2:end], 2)]
test_data = all_data[train_ndays+1:train_ndays+test_ndays, 1]
test_port_data = [all_data[train_ndays+1:train_ndays+test_ndays, i] for i in 2:size(all_data[:, 2:end], 2)]

A = reduce(hcat, train_port_data)
b = train_data
m, n = size(A)

nl_solver = optimizer_with_attributes(Ipopt.Optimizer, "print_level" => 0)
minlp_solver = optimizer_with_attributes(Juniper.Optimizer, "nl_solver" => nl_solver)
model = Model(minlp_solver)
@variable(model, x[1:n], Bin) # define binary variable x
# @constraint(model, sum(x) == 3) # If it is known that a certain number are optimal
@objective(model, Min, sum(abs2, A * x - b))
optimize!(model)
xs = value.(x)
begin
    # best_cor = cor(A * b, c)
    plot()
    # Plot training data
    plot!(1:train_ndays, A * xs, colour="#002dbf", lw=3, alpha=0.5, label="Training prediction")
    plot!(1:train_ndays, b, label="True data", ls=:dash, colour=:black)
    # Plot testing data
    A_test = reduce(hcat, test_port_data)
    c_test = test_data
    pred_cor = round(cor(A_test * xs, c_test), sigdigits=3)
    plot!(train_ndays+1:train_ndays+test_ndays, A_test * xs, colour="#bf0c00", lw=3, alpha=0.5, label="Testing prediction")
    plot!(train_ndays+1:train_ndays+test_ndays, c_test, label="", ls=:dash, colour=:black)
    plot!(title="JuMP Timeseries (Test Correlation = $pred_cor)")
    plot!(xlabel="Month", ylabel="Exports in Tons")
    plot!(legend_position=:topleft)
end

savefig("figures/jump_realdata_example.pdf")