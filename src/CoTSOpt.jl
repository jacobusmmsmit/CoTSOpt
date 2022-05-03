module CoTSOpt

export generate_timeseries

"""
    generate_timeseries(n, start=0, ϵ_dist=Normal(0, 1))
Generate a random walk for `n` steps, starting from `start` with noise drawn
from `ϵ_dist`.
"""
function generate_timeseries(n, start=0, ϵ_dist=Normal(0, 1))
    ts = zeros(n)
    ts[1] = start
    for day in 2:n
        ts[day] = ts[day-1] + rand(ϵ_dist)
    end
    return ts
end

end # module