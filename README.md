# Combinatorial Time Series Optimisation (CoTSOpt)

This repository explores different ways of solving the combinatorial problem of choosing which time series sum together to give an overall time series of interest. 
Currently it is in a very early exploratory stage, and so the code is not at all engineered properly. Files in the (currently non-existant) `src` folder will represent the documented public API of the code, and `scripts` will contain the exploration and application of this API.

By the end of this project I hope to have:
- A fully documented API, allowing users to solve CoTS problems with various methods,
- A brief document motivating, exploring, and explaining the theory of the problem

Current methods I am exploring are:
- A basic MCMC approach with `Turing.jl`
- A continuous relaxation approach with `Optim.jl`
- A pure binary optimisation approach with `JuMP.jl` and `Juniper.jl`

Methods I have on my radar are:
- Hidden markov models

Here's an example output of the MCMC approach using real data:

![Example output](/figures/train_test_example.png)

and the same problem using JuMP instead:

![Example output JuMP](/figures/jump_realdata_example.png)
