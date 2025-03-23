function [solver_scores, profile_scores] = tuning_optiprofiler(parameters, options)

    clc

    n_solvers = 1;
    solvers = cell(1, n_solvers);
    solver_names = cell(1, n_solvers);
    index = 1;

    % According to the field of parameters, different solvers are tested.
    param_fields = fieldnames(parameters);
    switch true
        case ismember('expand', param_fields) && ismember('shrink', param_fields)
            for i_solver = 1:2
                solvers{index} = @(fun, x0) cbds_expand_shrink(fun, x0, parameters.expand(i_solver), parameters.shrink(i_solver));
                solver_names{index} = sprintf('solver_%d', index);
                index = index + 1;
            end
        case ismember('window_size', param_fields) && ismember('func_tol', param_fields)
            for i_solver = 1:2
                solvers{index} = @(fun, x0) cbds_window_size_fun_tol(fun, x0, parameters.window_size(i_solver), parameters.func_tol(i_solver));
                solver_names{index} = sprintf('solver_%d', index);
                index = index + 1;
            end
        case ismember('window_size', param_fields) && ismember('dist_tol', param_fields)
            for i_solver = 1:2
                solvers{index} = @(fun, x0) cbds_window_size_dist_tol(fun, x0, parameters.window_size(i_solver), parameters.dist_tol(i_solver));
                solver_names{index} = sprintf('solver_%d', index);
                index = index + 1;
            end
        case ismember('window_size', param_fields) && ismember('grad_tol_1', param_fields) && ismember('grad_tol_2', param_fields)
            for i_solver = 1:2
                solvers{index} = @(fun, x0) cbds_window_size_grad_tol_1_grad_tol_2(fun, x0, parameters.window_size(i_solver), parameters.grad_tol_1(i_solver), parameters.grad_tol_2(i_solver));
                solver_names{index} = sprintf('solver_%d', index);
                index = index + 1;
            end
    end
    
    options.solver_names = solver_names;
    if ~isfield(options, 'feature_name')
        error('Please provide the feature name');
    end
    if startsWith(options.feature_name, 'noisy')
        if sum(options.feature_name == '_') > 0
            options.noise_level = 10.^(str2double(options.feature_name(end-1:end)));
        else
            options.noise_level = 1e-3;
        end
        options.feature_name = 'noisy';
    end 
    if startsWith(options.feature_name, 'rotation_noisy')
        options.noise_level = 10.^(str2double(options.feature_name(end-1:end)));
        options.feature_name = 'custom';
    end
    if startsWith(options.feature_name, 'permuted_noisy')
        if sum(options.feature_name == '_') > 0
            options.noise_level = 10.^(str2double(options.feature_name(end-1:end)));
        else
            options.noise_level = 1e-3;
        end
        options.feature_name = 'custom';
        options.permuted = true;
    end
    if startsWith(options.feature_name, 'truncated')
        if sum(options.feature_name == '_') > 0
            options.significant_digits = str2double(options.feature_name(end));
        else
            options.significant_digits = 6;
        end
        switch options.significant_digits
            % Why we set the noise level like this? See the link below:
            % https://github.com/Lht97/to_do_list. 
            case 1
                options.noise_level = 10^(-1) / (2 * sqrt(3));
            case 2
                options.noise_level = 10^(-2) / (2 * sqrt(3));
            case 3
                options.noise_level = 10^(-3) / (2 * sqrt(3));
            case 4
                options.noise_level = 10^(-4) / (2 * sqrt(3));                
            case 5
                options.noise_level = 10^(-5) / (2 * sqrt(3));
            case 6
                options.noise_level = 10^(-6) / (2 * sqrt(3));
            case 7
                options.noise_level = 10^(-7) / (2 * sqrt(3));
            case 8
                options.noise_level = 10^(-8) / (2 * sqrt(3));
        end
        options.feature_name = 'truncated';
    end
    if startsWith(options.feature_name, 'quantized')
        if sum(options.feature_name == '_') > 0
            options.mesh_size = 10.^(-str2double(options.feature_name(end)));
        else
            options.mesh_size = 1e-3;
        end
        options.feature_name = 'quantized';
    end
    if startsWith(options.feature_name, 'random_nan')
        options.nan_rate = str2double(options.feature_name(find(options.feature_name == '_', 1, 'last') + 1:end)) / 100;
        options.feature_name = 'random_nan';
    end
    if startsWith(options.feature_name, 'perturbed_x0')
        if sum(options.feature_name == '_') > 1
            str = split(options.feature_name, '_');
            options.noise_level = str2double(str{end});
        else
            options.noise_level = 1e-3;
        end
        options.feature_name = 'perturbed_x0';
    end

    if ~isfield(options, 'n_runs')
        if strcmpi(options.feature_name, 'plain') || strcmpi(options.feature_name, 'quantized')
            options.n_runs = 1;
        else
            options.n_runs = 3;
        end
    end
    if ~isfield(options, 'solver_verbose')
        options.solver_verbose = 2;
    end
    time_str = char(datetime('now', 'Format', 'yy_MM_dd_HH_mm'));
    options.silent = false;
    options.keep_pool = true;
    options.p_type = 'u';
    if isfield(options, 'dim')
        if strcmpi(options.dim, 'small')
            options.mindim = 2;
            options.maxdim = 5;
        elseif strcmpi(options.dim, 'big')
            options.mindim = 6;
            options.maxdim = 50;
        end
        options = rmfield(options, 'dim');
    end
    if ~isfield(options, 'mindim')
        options.mindim = 2;
    end
    if ~isfield(options, 'maxdim')
        options.maxdim = 5;
    end
    if ~isfield(options, 'run_plain')
        options.run_plain = false;
    end

    options.benchmark_id = [];
    for i = 1:length(solvers)
        if i == 1
            options.benchmark_id = strrep(options.solver_names{i}, '-', '_');
        else
            options.benchmark_id = [options.benchmark_id, '_', strrep(options.solver_names{i}, '-', '_')];
        end
    end
    options.benchmark_id = [options.benchmark_id, '_', num2str(options.mindim), '_', num2str(options.maxdim), '_', num2str(options.n_runs)];
    switch options.feature_name
        case 'noisy'
            options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', int2str(int32(-log10(options.noise_level))), '_no_rotation'];
        case 'custom'
            if isfield(options, 'permuted') && options.permuted
                options.benchmark_id = [options.benchmark_id, '_', 'permuted_noisy', '_', int2str(int32(-log10(options.noise_level)))];
            else
                options.benchmark_id = [options.benchmark_id, '_', 'rotation_noisy', '_', int2str(int32(-log10(options.noise_level)))];
            end
        case 'truncated'
            options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', int2str(options.significant_digits)];
            options = rmfield(options, 'noise_level');
        case 'quantized'
            options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', int2str(int32(-log10(options.mesh_size)))];
        case 'random_nan'
            if 100*options.nan_rate < 10
                options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_0', int2str(int32(options.nan_rate * 100))];
            else
                options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', int2str(int32(options.nan_rate * 100))];
            end
        case 'perturbed_x0'
            if abs(options.noise_level - 1e-3) < eps
                options.benchmark_id = [options.benchmark_id, '_', options.feature_name];
            elseif abs(options.noise_level - 1) < eps
                options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', '01'];
            elseif abs(options.noise_level - 10) < eps
                options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', '10'];
            elseif abs(options.noise_level - 100) < eps
                options.benchmark_id = [options.benchmark_id, '_', options.feature_name, '_', '100'];
            end
    otherwise
        options.benchmark_id = [options.benchmark_id, '_', options.feature_name];
    end
    if options.run_plain
        options.benchmark_id = [options.benchmark_id, '_plain'];
    end
    
    % When tuning with parallel computing, the benchmark_id should be unique. In our test, we use the
    % value of the parameters to make the benchmark_id unique.
    switch true
        case ismember('expand', param_fields) && ismember('shrink', param_fields)
            % Preserve 
            expand_str = num2str(parameters.expand(1), '%.2f');
            expand_str = strrep(expand_str, '.', '');
            shrink_str = num2str(parameters.shrink(1), '%.2f');
            shrink_str = shrink_str(3:end); % Remove '0.'
            options.benchmark_id = [options.benchmark_id, '_', 'expand_', expand_str, '_shrink_', shrink_str];
        case ismember('window_size', param_fields) && ismember('func_tol', param_fields)
            options.benchmark_id = [options.benchmark_id, '_', 'window_size_', num2str(parameters.window_size(1))];
            options.benchmark_id = [options.benchmark_id, '_', 'func_tol_', int2str(int32(-log10(parameters.func_tol(1)))), '_x'];
        case ismember('window_size', param_fields) && ismember('dist_tol', param_fields)
            options.benchmark_id = [options.benchmark_id, '_', 'window_size_', num2str(parameters.window_size(1))];
            options.benchmark_id = [options.benchmark_id, '_', 'dist_tol_', int2str(int32(-log10(parameters.dist_tol(1)))), '_x'];
        case ismember('window_size', param_fields) && ismember('grad_tol_1', param_fields) && ismember('grad_tol_2', param_fields)
            options.benchmark_id = [options.benchmark_id, '_', 'window_size_', num2str(parameters.window_size(1))];
            options.benchmark_id = [options.benchmark_id, '_', 'grad_tol_1_', int2str(int32(-log10(parameters.grad_tol_1(1)))), '_x'];
            options.benchmark_id = [options.benchmark_id, '_', 'grad_tol_2_', int2str(int32(-log10(parameters.grad_tol_2(1)))), '_x'];
    end

    options.benchmark_id = [options.benchmark_id, '_', time_str];
    options.excludelist = {'DIAMON2DLS',...
            'DIAMON2D',...
            'DIAMON3DLS',...
            'DIAMON3D',...
            'DMN15102LS',...
            'DMN15102',...
            'DMN15103LS',...
            'DMN15103',...
            'DMN15332LS',...
            'DMN15332',...
            'DMN15333LS',...
            'DMN15333',...
            'DMN37142LS',...
            'DMN37142',...
            'DMN37143LS',...
            'DMN37143',...
            'ROSSIMP3_mp',...
            'BAmL1SPLS',...
            'FBRAIN3LS',...
            'GAUSS1LS',...
            'GAUSS2LS',...
            'GAUSS3LS',...
            'HYDC20LS',...
            'HYDCAR6LS',...
            'LUKSAN11LS',...
            'LUKSAN12LS',...
            'LUKSAN13LS',...
            'LUKSAN14LS',...
            'LUKSAN17LS',...
            'LUKSAN21LS',...
            'LUKSAN22LS',...
            'METHANB8LS',...
            'METHANL8LS',...
            'SPINLS',...
            'VESUVIALS',...
            'VESUVIOLS',...
            'VESUVIOULS',...
            'YATP1CLS'};

    if strcmp(options.feature_name, 'custom')

        if ~isfield(options, 'permuted')
            % We need mod_x0 to make sure that the linearly transformed problem is mathematically equivalent
            % to the original problem.
            options.mod_x0 = @mod_x0;
            options.mod_affine = @mod_affine;
            options.feature_stamp = strcat('rotation_noisy_', int2str(int32(-log10(options.noise_level))));
        else
            options.mod_x0 = @mod_x0_permuted;
            options.mod_affine = @perm_affine;
            options.feature_stamp = strcat('permuted_noisy_', int2str(int32(-log10(options.noise_level))));
            options = rmfield(options, 'permuted');
        end
        % We only modify mod_fun since we are dealing with unconstrained problems.
        switch options.noise_level
            case 1e-1
                options.mod_fun = @mod_fun_1;
            case 1e-2
                options.mod_fun = @mod_fun_2;
            case 1e-3
                options.mod_fun = @mod_fun_3;
            case 1e-4
                options.mod_fun = @mod_fun_4;
            otherwise
                error('Unknown noise level');
        end
            options = rmfield(options, 'noise_level');
    end

    [solver_scores, profile_scores] = benchmark(solvers, options);
end

function x0 = mod_x0(rand_stream, problem)

    [Q, R] = qr(rand_stream.randn(problem.n));
    Q(:, diag(R) < 0) = -Q(:, diag(R) < 0);
    x0 = Q * problem.x0;
end

function x0 = mod_x0_permuted(rand_stream, problem)

    P = eye(problem.n);
    P = P(rand_stream.randperm(problem.n), :);
    x0 = P * problem.x0;
end

function f = mod_fun_1(x, rand_stream, problem)

    f = problem.fun(x);
    f = f + max(1, abs(f)) * 1e-1 * rand_stream.randn(1);
end

function f = mod_fun_2(x, rand_stream, problem)

    f = problem.fun(x);
    f = f + max(1, abs(f)) * 1e-2 * rand_stream.randn(1);
end

function f = mod_fun_3(x, rand_stream, problem)

    f = problem.fun(x);
    f = f + max(1, abs(f)) * 1e-3 * rand_stream.randn(1);
end

function f = mod_fun_4(x, rand_stream, problem)

    f = problem.fun(x);
    f = f + max(1, abs(f)) * 1e-4 * rand_stream.randn(1);
end

function [A, b, inv] = mod_affine(rand_stream, problem)

    [Q, R] = qr(rand_stream.randn(problem.n));
    Q(:, diag(R) < 0) = -Q(:, diag(R) < 0);
    A = Q';
    b = zeros(problem.n, 1);
    inv = Q;
end

function [A, b, inv] = perm_affine(rand_stream, problem)

    p = rand_stream.randperm(problem.n);
    P = eye(problem.n);
    P = P(p,:);
    A = P';
    b = zeros(problem.n, 1);    
    inv = P;
end

function x = cbds_expand_shrink(fun, x0, expand, shrink)

    option.Algorithm = 'cbds';
    option.expand = expand;
    option.shrink = shrink;
    x = bds_development(fun, x0, option);
    
end

function x = cbds_window_size_fun_tol(fun, x0, window_size, func_tol)

    option.Algorithm = 'cbds';
    option.expand = 2;
    option.shrink = 0.5;
    option.window_size = window_size;
    option.func_tol = func_tol;
    option.use_function_value_stop = true;
    x = bds_development(fun, x0, option);
    
end

function x = cbds_window_size_dist_tol(fun, x0, window_size, dist_tol)

    option.Algorithm = 'cbds';
    option.expand = 2;
    option.shrink = 0.5;
    option.window_size = window_size;
    option.dist_tol = dist_tol;
    option.use_point_stop = true;
    x = bds_development(fun, x0, option);
    
end

function x = cbds_window_size_grad_tol_1_grad_tol_2(fun, x0, window_size, grad_tol_1, grad_tol_2)

    option.Algorithm = 'cbds';
    option.expand = 2;
    option.shrink = 0.5;
    option.window_size = window_size;
    option.grad_tol_1 = grad_tol_1;
    option.grad_tol_2 = grad_tol_2;
    option.use_estimated_gradient_stop = true;
    option.use_function_value_stop = true;
    option.use_point_stop = true;
    x = bds_development(fun, x0, option);
    
end