function D = get_direction_set(n, options)
%direction_set generates the set of polling directions.
%
%   If the user does not input OPTIONS or the OPTIONS does not contain direction_set.
%   D will be [e_1, -e_1, ..., e_n, -e_n], where e_i is the i-th coordinate vector.
%   Otherwise, options.direction_set should be a matrix of n rows, and set D to
%   [d_1, -d_1, ..., d_m, -d_m], where d_i is the i-th column of direction_set, 
%   and m is the number of columns of direction_set. Before doing so, we revise 
%   direction_set in the following way.
%   1. Remove the directions whose norms are too small. 
%   2. Find directions that are almost parallel. Then preserve the first one and remove the others.
%   3. Make the direction set linearly span the full space by adding new columns if necessary.
%      This is done by QR factorization.
%

% Set options to an empty structure if it is not provided.
if nargin < 2
    options = struct();
end

if ~isfield(options, "direction_set")

    % Set the default direction set.
    D = NaN(n, 2*n);
    D(:,1:2:2*n-1) = eye(n);
    D(:,2:2:2*n) = -eye(n);

else

    direction_set = options.direction_set;
    % Determine whether the direction set contains NaN or Inf values and replace those
    % elements with 0.
    if any(isnan(direction_set) | isinf(direction_set), "all")
        warning("Some directions contain NaN or inf, which are replaced with 0.");
        direction_set(isnan(direction_set) | isinf(direction_set)) = 0;
    end

    % Remove the directions whose norms are too small.
    % We include the factor sqrt(n) in the following threshold to reflect the dimension of the problem.
    shortest_direction_norm = 10*sqrt(n)*eps;
    direction_norms = vecnorm(direction_set);
    short_directions = (direction_norms < shortest_direction_norm);
    if any(short_directions)
        warning("The direction set contains directions shorter than %g. They are removed.", ...
            shortest_direction_norm);
        direction_set = direction_set(:, ~short_directions);
        direction_norms = direction_norms(~short_directions);
    end
    
    % Find those directions that are almost parallel. Preserve the first one appearing in the
    % direction set and remove the others.
    parallel_directions = (abs(direction_set'*direction_set) > (1 - 1.0e-10) * (direction_norms' * direction_norms));
    % Parallel_directions is a symmetric binary matrix, where the (i,j)-th element is 1 if and 
    % only if the i-th and j-th vectors are almost parallel in the direction_set. 
    % Triu(parallel_directions, 1) returns a matrix whose strict upper triangular part of 
    % parallel_directions and the other part consists of only zero. Applying `find` to this 
    % matrix, we can get the row and column indices of the 1's in the strict upper triangular
    % part of parallel_directions, the column indices being contained in parallel_direction_indices below. 
    % An index i appears in parallel_direction_indices if and only if there exists a j < i such that
    % the i-th and j-th vectors are almost parallel in the direction_set. Hence we will remove the
    % directions indexed by parallel_direction_indices.
    [~, parallel_direction_indices] = find(triu(parallel_directions, 1));
    % Remove the duplicate indices appearing in the parallel_direction_indices.
    %parallel_direction_indices = unique(parallel_direction_indices);
    % Directions not indexed by parallel_direction_indices are preserved.
    preserved_indices = ~ismember(1:size(direction_set, 2), parallel_direction_indices);
    direction_set = direction_set(:, preserved_indices);
    % If the direction set is empty, we set it to be the identity matrix. Indeed, the removal of 
    % almost parallel directions cannot make an nonempty direction set become empty. Thus the
    % following code can be moved above the removal of almost parallel directions. However, we 
    % keep it here to make the code more robust. 
    if isempty(direction_set)
        direction_set = eye(n);
    end

    % To find the maximal linearly independent set in the direction_set using the rref function in MATLAB.
    % rref returns the reduced row echelon form of the input matrix. Thus we transpose the direction_set first
    % and then do row elimination to find the maximal linearly independent set. 
    reduced_direction_set = rref(direction_set');
    % Find the indices of the columns in the direction_set which is the maximal linearly independent set.
    maximal_linear_independent_set_indices = (diag(reduced_direction_set) <= 0);
    % To obtain the maximal linearly independent set in the direction_set.
    direction_set = direction_set(:, ~maximal_linear_independent_set_indices);

    % If rank(direction_set) < n, we add new columns to direction_set to make the rank become n.
    % We use QR factorization with permutation to find such columns. 
    % The following columns of Q will be added to direction_set.
    % 1. The corresponding diagonal elements of R are tiny.
    % 2. Columns m+1 to n with m being the number of columns in direction_set, provided that m < n.
    [Q, R, ~] = qr(direction_set);
    [~, m] = size(direction_set);
    % deficient_columns contains the indices of the tiny diagonal elements of R(1:min(m, n), 1:min(m, n)). 
    % We must transpose diag(R) since vecnorm will return a row vector. Otherwise, the following
    % comparison will return a matrix due to the implicit expansion.
    deficient_columns = ~(abs(diag(R(1:min(m, n), 1:min(m, n))))' > ...
        10*eps*max(m,n)*vecnorm(R(1:min(m,n), 1:min(m,n))));
    direction_set = [direction_set, Q(:, deficient_columns), Q(:, m+1:end)];

    % Finally, set D to [d_1, -d_1, ..., d_m, -d_m], where d_i is the i-th vector in direction_set.
    [~, m] = size(direction_set);
    D = NaN(n, 2*m);
    D(:, 1:2:2*m-1) = direction_set;
    D(:, 2:2:2*m) = -direction_set;

end

end
