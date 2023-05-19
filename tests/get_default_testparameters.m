function constant_value = get_default_testparameters(constant_name)
%GET_DEFAULT_PARAMETERS Get the constants needed by TESTBDS_INPUT.
%   CONSTANT_VALUE = GET_DEFAULT_TESTPARAMETERS(CONSTANT_NAME) returns the value
%   of the constant named CONSTANT_VALUE.
switch constant_name
    case {"maxfun_dim"}
        constant_value = 1000;
    case {"maxfun"}
        constant_value = 1e4;
    case {"expand"}
        constant_value = 2;
    case {"shrink"}
        constant_value = 0.5;
    case {"sufficient_decrease_factor"}
        constant_value = 1e-3;
    case {"tol"}
        constant_value = 1e-12;
    case {"ftarget"}
        constant_value = -inf;
    case {"polling"}
        constant_value = "opportunistic";
    case {"polling_inner"}
        constant_value = "opportunistic";
    case {"polling_blocks"}
        constant_value = "Gauss-Seidel";
    case {"cycling_inner"}
        constant_value = 1;
    case {"memory"}
        constant_value = true;
    case {"nb_generator"}
        constant_value = 0.5;
    case {"nb_tag"}
        constant_value = "n";
    case {"problems_type"}
        constant_value = "u";
    case {"problems_mindim"}
        constant_value = 6;
    case {"problems_maxdim"}
        constant_value = 60;
    case {"direction"}
        constant_value = "canonical";
    case {"num_solvers"}
        constant_value = 2;
    case {"solvers_invoke"}
        constant_value = "blockwise_direct_search";
    case {"solvers_label"}
        constant_value = "no-label";
    case {"solvers_tag"}
        constant_value = "none";
    otherwise
        constant_value = "Unknown constant name";
end
end
