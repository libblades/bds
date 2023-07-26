parameters.solvers_invoke = ["gsds", "sbds"];
parameters.problems_mindim = 1;
parameters.problems_maxdim = 5;
parameters.sufficient_decrease_factor = [0, 1e-3];
%parameters.powell_factor = [0, 1e-2];
parameters.is_noisy = false;
parameters.noise_level = 1e-5;
parameters.num_random = 10;
parameters.parallel = true;
parameters.version = "now";
parameters.fmin_type = "randomized";
parameters.noise_initial_point = true;
profile_bds(parameters);