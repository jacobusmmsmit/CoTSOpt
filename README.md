# Binary Timeseries Optimisation

This repository explores different ways of solving the binary problem of choosing which time series sum together to give an overall time series of interest.

Currently implemented we have:
- An MCMC approach with `Turing.jl`
- A continuous relaxation approach with `Optim.jl`

Here's an example output using real data:

![Example output](/figures/realdata_example.png)
