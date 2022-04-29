# Combinatorial Time Series Optimisation (CoTSOpt)

This repository explores different ways of solving the combinatorial problem of choosing which time series sum together to give an overall time series of interest.

Currently implemented we have:
- An MCMC approach with `Turing.jl`
- A continuous relaxation approach with `Optim.jl`

Here's an example output using real data:

![Example output](/figures/realdata_example_traintest.png)
