m = Model(with_optimizer(CbcOptimizer))

@variable(m, 0 ≤ x[1:length(c)] ≤ 10_000, Int)
