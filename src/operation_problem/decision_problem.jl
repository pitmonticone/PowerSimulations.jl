"""Default PowerSimulations Operation Problem Type"""
struct GenericOpProblem <: PowerSimulationsDecisionProblem end

"""
    DecisionProblem(::Type{M},
    template::ProblemTemplate,
    sys::PSY.System,
    jump_model::Union{Nothing, JuMP.Model}=nothing;
    kwargs...) where {M<:AbstractDecisionProblem,
                      T<:PM.AbstractPowerFormulation}

This builds the optimization problem of type M with the specific system and template.

# Arguments

- `::Type{M} where M<:AbstractDecisionProblem`: The abstract operation model type
- `template::ProblemTemplate`: The model reference made up of transmission, devices,
                                          branches, and services.
- `sys::PSY.System`: the system created using Power Systems
- `jump_model::Union{Nothing, JuMP.Model}`: Enables passing a custom JuMP model. Use with care

# Output

- `problem::DecisionProblem`: The operation model containing the model type, built JuMP model, Power
Systems system.

# Example

```julia
template = ProblemTemplate(CopperPlatePowerModel, devices, branches, services)
OpModel = DecisionProblem(MockOperationProblem, template, system)
```

# Accepted Key Words

- `optimizer`: The optimizer that will be used in the optimization model.
- `horizon::Int`: Manually specify the length of the forecast Horizon
- `warm_start::Bool`: True will use the current operation point in the system to initialize variable values. False initializes all variables to zero. Default is true
- `constraint_duals::Vector{Symbol}`: Vector with the duals to query from the optimization model
- `system_to_file::Bool:`: True to create a copy of the system used in the model. Default true.
- `export_pwl_vars::Bool`: True to export all the pwl intermediate variables. It can slow down significantly the solve time. Default to false.
- `allow_fails::Bool`: True to allow the simulation to continue even if the optimization step fails. Use with care, default to false.
- `optimizer_log_print::Bool`: True to print the optimizer solve log. Default to false.
- `direct_mode_optimizer::Bool` True to use the solver in direct mode. Creates a [JuMP.direct_model](https://jump.dev/JuMP.jl/dev/reference/models/#JuMP.direct_model). Default to false.
- `initial_time::Dates.DateTime`: Initial Time for the model solve
- `time_series_cache_size::Int`: Size in bytes to cache for each time array. Default is 1 MiB. Set to 0 to disable.
"""
mutable struct DecisionProblem{M <: AbstractDecisionProblem} <: OperationsProblem
    template::ProblemTemplate
    sys::PSY.System
    internal::Union{Nothing, ProblemInternal}
    ext::Dict{String, Any}

    function DecisionProblem{M}(
        template::ProblemTemplate,
        sys::PSY.System,
        settings::Settings,
        jump_model::Union{Nothing, JuMP.Model} = nothing,
    ) where {M <: AbstractDecisionProblem}
        internal = ProblemInternal(OptimizationContainer(sys, settings, jump_model))
        new{M}(template, sys, internal, Dict{String, Any}())
    end
end

function DecisionProblem{M}(
    template::ProblemTemplate,
    sys::PSY.System,
    jump_model::Union{Nothing, JuMP.Model} = nothing;
    optimizer = nothing,
    horizon = UNSET_HORIZON,
    warm_start = true,
    constraint_duals = Vector{Symbol}(),
    system_to_file = true,
    export_pwl_vars = false,
    allow_fails = false,
    optimizer_log_print = false,
    direct_mode_optimizer = false,
    initial_time = UNSET_INI_TIME,
    time_series_cache_size::Int = IS.TIME_SERIES_CACHE_SIZE_BYTES,
) where {M <: AbstractDecisionProblem}
    settings = Settings(
        sys;
        horizon = horizon,
        initial_time = initial_time,
        optimizer = optimizer,
        use_parameters = use_parameters,
        time_series_cache_size = time_series_cache_size,
        warm_start = warm_start,
        balance_slack_variables = balance_slack_variables,
        services_slack_variables = services_slack_variables,
        constraint_duals = constraint_duals,
        system_to_file = system_to_file,
        export_pwl_vars = export_pwl_vars,
        allow_fails = allow_fails,
        PTDF = PTDF,
        optimizer_log_print = optimizer_log_print,
        direct_mode_optimizer = direct_mode_optimizer,
        use_forecast_data = use_forecast_data,
    )
    return DecisionProblem{M}(template, sys, settings, jump_model)
end

"""
    DecisionProblem(::Type{M},
    template::ProblemTemplate,
    sys::PSY.System,
    optimizer::MOI.OptimizerWithAttributes,
    jump_model::Union{Nothing, JuMP.Model}=nothing;
    kwargs...) where {M<:AbstractDecisionProblem}
This builds the optimization problem of type M with the specific system and template
# Arguments
- `::Type{M} where M<:AbstractDecisionProblem`: The abstract operation model type
- `template::ProblemTemplate`: The model reference made up of transmission, devices,
                                          branches, and services.
- `sys::PSY.System`: the system created using Power Systems
- `jump_model::Union{Nothing, JuMP.Model}`: Enables passing a custom JuMP model. Use with care
# Output
- `Stage::DecisionProblem`: The operation model containing the model type, unbuilt JuMP model, Power
Systems system.
# Example
```julia
template = ProblemTemplate(CopperPlatePowerModel, devices, branches, services)
problem = DecisionProblem(MyOpProblemType template, system, optimizer)
```
# Accepted Key Words
- `initial_time::Dates.DateTime`: Initial Time for the model solve
- `PTDF::PTDF`: Passes the PTDF matrix into the optimization model for StandardPTDFModel networks.
- `warm_start::Bool` True will use the current operation point in the system to initialize variable values. False initializes all variables to zero. Default is true
- `balance_slack_variables::Bool` True will add slacks to the system balance constraints
- `services_slack_variables::Bool` True will add slacks to the services requirement constraints
- `export_pwl_vars::Bool` True will write the results of the piece-wise-linear intermediate variables. Slows down the simulation process significantly
- `allow_fails::Bool` True will allow the simulation to continue if the optimizer can't find a solution. Use with care, can lead to unwanted behaviour or results
- `optimizer_log_print::Bool` Uses JuMP.unset_silent() to print the optimizer's log. By default all solvers are set to `MOI.Silent()`
"""
function DecisionProblem(
    ::Type{M},
    template::ProblemTemplate,
    sys::PSY.System,
    jump_model::Union{Nothing, JuMP.Model} = nothing;
    kwargs...,
) where {M <: AbstractDecisionProblem}
    return DecisionProblem{M}(template, sys, jump_model; kwargs...)
end

function DecisionProblem(
    template::ProblemTemplate,
    sys::PSY.System,
    jump_model::Union{Nothing, JuMP.Model} = nothing;
    kwargs...,
)
    return DecisionProblem{GenericOpProblem}(template, sys, jump_model; kwargs...)
end

"""
    DecisionProblem(filename::AbstractString)

Construct an DecisionProblem from a serialized file.

# Arguments
- `filename::AbstractString`: path to serialized file
- `jump_model::Union{Nothing, JuMP.Model}` = nothing: The JuMP model does not get
   serialized. Callers should pass whatever they passed to the original problem.
- `optimizer::Union{Nothing,MOI.OptimizerWithAttributes}` = nothing: The optimizer does
   not get serialized. Callers should pass whatever they passed to the original problem.
"""
function DecisionProblem(
    filename::AbstractString;
    jump_model::Union{Nothing, JuMP.Model} = nothing,
    optimizer::Union{Nothing, MOI.OptimizerWithAttributes} = nothing,
    kwargs...,
)
    return deserialize_problem(
        DecisionProblem,
        filename;
        jump_model = jump_model,
        optimizer = optimizer,
        kwargs...,
    )
end

function get_time_series_values!(
    time_series_type::Type{<:IS.TimeSeriesData},
    problem::DecisionProblem,
    component,
    name,
    initial_time,
    horizon;
    ignore_scaling_factors = true,
)
    if !use_time_series_cache(get_settings(problem))
        return IS.get_time_series_values(
            time_series_type,
            component,
            name,
            start_time = initial_time,
            len = horizon,
            ignore_scaling_factors = true,
        )
    end

    cache = get_time_series_cache(problem)
    key = TimeSeriesCacheKey(IS.get_uuid(component), time_series_type, name)
    if haskey(cache, key)
        ts_cache = cache[key]
    else
        ts_cache = make_time_series_cache(
            time_series_type,
            component,
            name,
            initial_time,
            horizon,
            ignore_scaling_factors = true,
        )
        cache[key] = ts_cache
    end

    ts = IS.get_time_series_array!(ts_cache, initial_time)
    return TimeSeries.values(ts)
end

function make_time_series_cache(
    time_series_type::Type{T},
    component,
    name,
    initial_time,
    horizon;
    ignore_scaling_factors = true,
) where {T <: IS.TimeSeriesData}
    key = TimeSeriesCacheKey(IS.get_uuid(component), T, name)
    if T <: IS.SingleTimeSeries
        cache = IS.StaticTimeSeriesCache(
            PSY.SingleTimeSeries,
            component,
            name,
            start_time = initial_time,
            ignore_scaling_factors = ignore_scaling_factors,
        )
    elseif T <: IS.Deterministic
        cache = IS.ForecastCache(
            IS.AbstractDeterministic,
            component,
            name,
            start_time = initial_time,
            horizon = horizon,
            ignore_scaling_factors = ignore_scaling_factors,
        )
    elseif T <: IS.Probabilistic
        cache = IS.ForecastCache(
            IS.Probabilistic,
            component,
            name,
            start_time = initial_time,
            horizon = horizon,
            ignore_scaling_factors = ignore_scaling_factors,
        )
    else
        error("not supported yet: $T")
    end

    @debug "Made time series cache for $(summary(component))" name initial_time
    return cache
end

function get_initial_conditions(
    problem::DecisionProblem,
    ic::InitialConditionType,
    device::PSY.Device,
)
    key = ICKey(ic, device)
    return get_initial_conditions(get_optimization_container(problem), key)
end

set_console_level!(problem::DecisionProblem, val) =
    get_internal(problem).console_level = val
set_file_level!(problem::DecisionProblem, val) = get_internal(problem).file_level = val
set_executions!(problem::DecisionProblem, val::Int) =
    problem.internal.simulation_info.executions = val
set_execution_count!(problem::DecisionProblem, val::Int) =
    get_simulation_info(problem).execution_count = val
set_initial_time!(problem::DecisionProblem, val::Dates.DateTime) =
    set_initial_time!(get_settings(problem), val)
set_simulation_info!(problem::DecisionProblem, info::SimulationInfo) =
    problem.internal.simulation_info = info
function set_status!(problem::DecisionProblem, status::BuildStatus)
    problem.internal.status = status
    return
end
set_output_dir!(problem::DecisionProblem, path::AbstractString) =
    get_internal(problem).output_dir = path

function reset!(problem::DecisionProblem{T}) where {T <: AbstractDecisionProblem}
    if built_for_simulation(problem::DecisionProblem)
        set_execution_count!(problem, 0)
    end
    container = OptimizationContainer(get_system(problem), get_settings(problem), nothing)
    problem.internal.optimization_container = container
    empty_time_series_cache!(problem)
    set_status!(problem, BuildStatus.EMPTY)
    return
end

function advance_execution_count!(problem::DecisionProblem)
    info = get_simulation_info(problem)
    info.execution_count += 1
    # Reset execution count at the end of step
    if get_execution_count(problem) == get_executions(problem)
        info.execution_count = 0
    end
    return
end

function build_pre_step!(problem::DecisionProblem)
    TimerOutputs.@timeit BUILD_PROBLEMS_TIMER "Build pre-step" begin
        if !is_empty(problem)
            @info "OptimizationProblem status not BuildStatus.EMPTY. Resetting"
            reset!(problem)
        end
        settings = get_settings(problem)
        if !get_use_parameters(settings)
            set_use_parameters!(settings, built_for_simulation(problem))
            @debug "Set use_parameters = true for use in simulation"
        end
        # Initial time are set here because the information is specified in the
        # Simulation Sequence object and not at the problem creation.
        @info "Initializing Optimization Container"
        optimization_container_init!(
            get_optimization_container(problem),
            get_transmission_model(get_template(problem)),
            get_system(problem),
        )
        set_status!(problem, BuildStatus.IN_PROGRESS)
    end
    return
end

function initialize_simulation_info!(problem::DecisionProblem, ::FeedForwardChronology)
    @assert built_for_simulation(problem)
    system = get_system(problem)
    resolution = get_resolution(problem)
    interval = IS.time_period_conversion(PSY.get_forecast_interval(system))
    end_of_interval_step = Int(interval / resolution)
    get_simulation_info(problem).end_of_interval_step = end_of_interval_step
end

function initialize_simulation_info!(problem::DecisionProblem, ::RecedingHorizon)
    @assert built_for_simulation(problem)
    get_simulation_info(problem).end_of_interval_step = 1
end

function _build!(problem::DecisionProblem{<:AbstractDecisionProblem}, serialize::Bool)
    TimerOutputs.@timeit BUILD_PROBLEMS_TIMER "Problem $(get_name(problem))" begin
        try
            build_pre_step!(problem)
            problem_build!(problem)
            serialize && serialize_problem(problem)
            serialize && serialize_optimization_model(problem)
            set_status!(problem, BuildStatus.BUILT)
            log_values(get_settings(problem))
            !built_for_simulation(problem) && @info "\n$(BUILD_PROBLEMS_TIMER)\n"
        catch e
            set_status!(problem, BuildStatus.FAILED)
            bt = catch_backtrace()
            @error "Operation Problem Build Failed" exception = e, bt
        end
    end
    return get_status(problem)
end

"""Implementation of build for any DecisionProblem"""
function build!(
    problem::DecisionProblem{<:AbstractDecisionProblem};
    output_dir::String,
    console_level = Logging.Error,
    file_level = Logging.Info,
    disable_timer_outputs = false,
    serialize = true,
)
    mkpath(output_dir)
    set_output_dir!(problem, output_dir)
    set_console_level!(problem, console_level)
    set_file_level!(problem, file_level)
    TimerOutputs.reset_timer!(BUILD_PROBLEMS_TIMER)
    disable_timer_outputs && TimerOutputs.disable_timer!(BUILD_PROBLEMS_TIMER)
    logger = configure_logging(problem.internal, "w")
    try
        Logging.with_logger(logger) do
            return _build!(problem, serialize)
        end
    finally
        close(logger)
    end
end

"""
Default implementation of build method for Operational Problems for models conforming with  PowerSimulationsDecisionProblem specification. Overload this function to implement a custom build method
"""
function problem_build!(problem::DecisionProblem{<:PowerSimulationsDecisionProblem})
    build_impl!(
        get_optimization_container(problem),
        get_template(problem),
        get_system(problem),
    )
end

serialize_optimization_model(::DecisionProblem) = nothing
serialize_problem(::DecisionProblem) = nothing

function serialize_optimization_model(
    op_problem::DecisionProblem{<:PowerSimulationsDecisionProblem},
)
    name = get_name(op_problem)
    problem_name = isempty(name) ? "OptimizationModel" : "$(name)_OptimizationModel"
    json_file_name = "$problem_name.json"
    json_file_name = joinpath(get_output_dir(op_problem), json_file_name)
    serialize_optimization_model(get_optimization_container(op_problem), json_file_name)
end

struct DecisionProblemSerializationWrapper
    template::ProblemTemplate
    sys::Union{Nothing, String}
    settings::Settings
    op_problem_type::DataType
end

function serialize_problem(op_problem::DecisionProblem{<:PowerSimulationsDecisionProblem})
    # A PowerSystem cannot be serialized in this format because of how it stores
    # time series data. Use its specialized serialization method instead.
    problem_name = isempty(get_name(op_problem)) ? "OperationProblem" : get_name(op_problem)
    sys_to_file = get_system_to_file(get_settings(op_problem))
    if sys_to_file
        sys = get_system(op_problem)
        sys_filename = joinpath(get_output_dir(op_problem), make_system_filename(sys))
        # Skip serialization if the system is already in the folder
        !ispath(sys_filename) && PSY.to_json(sys, sys_filename)
    else
        sys_filename = nothing
    end
    optimization_container = get_optimization_container(op_problem)
    obj = DecisionProblemSerializationWrapper(
        op_problem.template,
        sys_filename,
        optimization_container.settings_copy,
        typeof(op_problem),
    )
    bin_file_name = "$problem_name.bin"
    bin_file_name = joinpath(get_output_dir(op_problem), bin_file_name)
    Serialization.serialize(bin_file_name, obj)
    @info "Serialized DecisionProblem to" bin_file_name
end

function deserialize_problem(::Type{DecisionProblem}, filename::AbstractString; kwargs...)
    obj = Serialization.deserialize(filename)
    if !(obj isa DecisionProblemSerializationWrapper)
        throw(IS.DataFormatError("deserialized object has incorrect type $(typeof(obj))"))
    end
    sys = get(kwargs, :system, nothing)
    settings = restore_from_copy(obj.settings; optimizer = kwargs[:optimizer])
    if sys === nothing
        if obj.sys === nothing && !settings[:sys_to_file]
            throw(
                IS.DataFormatError(
                    "Operations Problem System was not serialized and a System has not been specified.",
                ),
            )
        elseif !ispath(obj.sys)
            throw(IS.DataFormatError("PowerSystems.System file $(obj.sys) does not exist"))
        end
        sys = PSY.System(obj.sys)
    end

    return obj.op_problem_type(obj.template, sys, kwargs[:jump_model]; settings...)
end

function calculate_aux_variables!(problem::DecisionProblem)
    optimization_container = get_optimization_container(problem)
    system = get_system(problem)
    aux_vars = get_aux_variables(optimization_container)
    for key in keys(aux_vars)
        calculate_aux_variable_value!(optimization_container, key, system)
    end
    return
end

function solve_impl(problem::DecisionProblem; optimizer = nothing)
    if !is_built(problem)
        error(
            "Operations Problem Build status is $(get_status(problem)). Solve can't continue",
        )
    end
    model = get_jump_model(problem)
    if optimizer !== nothing
        JuMP.set_optimizer(model, optimizer)
    end
    if model.moi_backend.state == MOIU.NO_OPTIMIZER
        @error("No Optimizer has been defined, can't solve the operational problem")
        return RunStatus.FAILED
    end
    @assert model.moi_backend.state != MOIU.NO_OPTIMIZER
    status = RunStatus.RUNNING
    timed_log = get_solve_timed_log(problem)
    _, timed_log[:timed_solve_time], timed_log[:solve_bytes_alloc], timed_log[:sec_in_gc] =
        @timed JuMP.optimize!(model)
    model_status = JuMP.primal_status(model)
    if model_status != MOI.FEASIBLE_POINT::MOI.ResultStatusCode
        return RunStatus.FAILED
    else
        calculate_aux_variables!(problem::DecisionProblem)
        status = RunStatus.SUCCESSFUL
    end
    return status
end

"""
Default solve method the operational model for a single instance. Solves problems
    that conform to the requirements of DecisionProblem{<:  PowerSimulationsDecisionProblem}
# Arguments
- `op_problem::OperationModel = op_problem`: operation model
# Examples
```julia
results = solve!(OpModel)
```
# Accepted Key Words
- `output_dir::String`: If a file path is provided the results
automatically get written to feather files
- `optimizer::MOI.OptimizerWithAttributes`: The optimizer that is used to solve the model
"""
function solve!(problem::DecisionProblem{<:PowerSimulationsDecisionProblem}; kwargs...)
    status = solve_impl(problem; kwargs...)
    set_run_status!(problem, status)
    return status
end

function write_problem_results!(
    step::Int,
    problem::DecisionProblem{<:PowerSimulationsDecisionProblem},
    start_time::Dates.DateTime,
    store::SimulationStore,
    exports,
)
    stats = OptimizerStats(problem, step)
    write_optimizer_stats!(store, get_name(problem), stats, start_time)
    write_model_results!(store, problem, start_time; exports = exports)
    return
end

function write_problem_results!(
    ::Int,
    ::DecisionProblem{T},
    ::Dates.DateTime,
    ::SimulationStore,
    _,
) where {T <: AbstractDecisionProblem}
    @info "Write results to Store not implemented for problems $T"
    return
end

"""
Default solve method for an operational model used inside of a Simulation. Solves problems that conform to the requirements of DecisionProblem{<:  PowerSimulationsDecisionProblem}

# Arguments
- `step::Int`: Simulation Step
- `op_problem::OperationModel`: operation model
- `start_time::Dates.DateTime`: Initial Time of the simulation step in Simulation time.
- `store::SimulationStore`: Simulation output store

# Accepted Key Words
- `exports`: realtime export of output. Use wisely, it can have negative impacts in the simulation times
"""
function solve!(
    step::Int,
    problem::DecisionProblem{<:AbstractDecisionProblem},
    start_time::Dates.DateTime,
    store::SimulationStore;
    exports = nothing,
)
    solve_status = solve!(problem)
    if solve_status == RunStatus.SUCCESSFUL
        write_problem_results!(step, problem, start_time, store, exports)
        advance_execution_count!(problem)
    end

    return solve_status
end

function write_model_results!(store, problem, timestamp; exports = nothing)
    optimization_container = get_optimization_container(problem)
    if exports !== nothing
        export_params = Dict{Symbol, Any}(
            :exports => exports,
            :exports_path => joinpath(exports.path, get_name(problem)),
            :file_type => get_export_file_type(exports),
            :resolution => get_resolution(problem),
            :horizon => get_horizon(get_settings(problem)),
        )
    else
        export_params = nothing
    end

    # This line should only be called if the problem is exporting duals. Otherwise ignore.
    if is_milp(get_optimization_container(problem))
        @warn "Problem $(get_simulation_info(problem).name) is a MILP, duals can't be exported"
    else
        _write_model_dual_results!(
            store,
            optimization_container,
            problem,
            timestamp,
            export_params,
        )
    end

    _write_model_parameter_results!(
        store,
        optimization_container,
        problem,
        timestamp,
        export_params,
    )
    _write_model_variable_results!(
        store,
        optimization_container,
        problem,
        timestamp,
        export_params,
    )
    _write_model_aux_variable_results!(
        store,
        optimization_container,
        problem,
        timestamp,
        export_params,
    )
    return
end

function _write_model_dual_results!(
    store,
    optimization_container,
    problem,
    timestamp,
    exports,
)
    problem_name_str = get_name(problem)
    problem_name = Symbol(problem_name_str)
    if exports !== nothing
        exports_path = joinpath(exports[:exports_path], "duals")
        mkpath(exports_path)
    end

    for name in get_constraint_duals(optimization_container.settings)
        constraint = get_constraint(optimization_container, name)
        write_result!(
            store,
            problem_name,
            STORE_CONTAINER_DUALS,
            name,
            timestamp,
            constraint,
            [name],
        )

        if exports !== nothing &&
           should_export_dual(exports[:exports], timestamp, problem_name_str, name)
            horizon = exports[:horizon]
            resolution = exports[:resolution]
            file_type = exports[:file_type]
            df = axis_array_to_dataframe(constraint, [name])
            time_col = range(timestamp, length = horizon, step = resolution)
            DataFrames.insertcols!(df, 1, :DateTime => time_col)
            export_result(file_type, exports_path, name, timestamp, df)
        end
    end
end

function _write_model_parameter_results!(
    store,
    optimization_container,
    problem,
    timestamp,
    exports,
)
    problem_name_str = get_name(problem)
    problem_name = Symbol(problem_name_str)
    if exports !== nothing
        exports_path = joinpath(exports[:exports_path], "parameters")
        mkpath(exports_path)
    end

    parameters = get_parameters(optimization_container)
    (isnothing(parameters) || isempty(parameters)) && return
    horizon = get_horizon(get_settings(problem))

    for (name, container) in parameters
        !isa(container.update_ref, UpdateRef{<:PSY.Component}) && continue
        param_array = get_parameter_array(container)
        multiplier_array = get_multiplier_array(container)
        @assert_op length(axes(param_array)) == 2
        num_columns = size(param_array)[1]
        data = Array{Float64}(undef, horizon, num_columns)
        for r_ix in param_array.axes[2], (c_ix, name) in enumerate(param_array.axes[1])
            val1 = _jump_value(param_array[name, r_ix])
            val2 = multiplier_array[name, r_ix]
            data[r_ix, c_ix] = val1 * val2
        end

        write_result!(
            store,
            problem_name,
            STORE_CONTAINER_PARAMETERS,
            name,
            timestamp,
            data,
            param_array.axes[1],
        )

        if exports !== nothing &&
           should_export_parameter(exports[:exports], timestamp, problem_name_str, name)
            resolution = exports[:resolution]
            file_type = exports[:file_type]
            df = DataFrames.DataFrame(data, param_array.axes[1])
            time_col = range(timestamp, length = horizon, step = resolution)
            DataFrames.insertcols!(df, 1, :DateTime => time_col)
            export_result(file_type, exports_path, name, timestamp, df)
        end
    end
end

function _write_model_variable_results!(
    store,
    optimization_container,
    problem,
    timestamp,
    exports,
)
    problem_name_str = get_name(problem)
    problem_name = Symbol(problem_name_str)
    if exports !== nothing
        exports_path = joinpath(exports[:exports_path], "variables")
        mkpath(exports_path)
    end

    for (name, variable) in get_variables(optimization_container)
        write_result!(
            store,
            problem_name,
            STORE_CONTAINER_VARIABLES,
            name,
            timestamp,
            variable,
        )

        if exports !== nothing &&
           should_export_variable(exports[:exports], timestamp, problem_name_str, name)
            horizon = exports[:horizon]
            resolution = exports[:resolution]
            file_type = exports[:file_type]
            df = axis_array_to_dataframe(variable)
            time_col = range(timestamp, length = horizon, step = resolution)
            DataFrames.insertcols!(df, 1, :DateTime => time_col)
            export_result(file_type, exports_path, name, timestamp, df)
        end
    end
end

function _write_model_aux_variable_results!(
    store,
    optimization_container,
    problem,
    timestamp,
    exports,
)
    problem_name_str = get_name(problem)
    problem_name = Symbol(problem_name_str)
    if exports !== nothing
        # TODO: Should the export go to a folder aux_variables
        exports_path = joinpath(exports[:exports_path], "variables")
        mkpath(exports_path)
    end

    for (key, variable) in get_aux_variables(optimization_container)
        name = encode_key(key)
        write_result!(
            store,
            problem_name,
            STORE_CONTAINER_VARIABLES,
            name,
            timestamp,
            variable,
        )

        if exports !== nothing &&
           should_export_variable(exports[:exports], timestamp, problem_name_str, name)
            horizon = exports[:horizon]
            resolution = exports[:resolution]
            file_type = exports[:file_type]
            df = axis_array_to_dataframe(variable)
            time_col = range(timestamp, length = horizon, step = resolution)
            DataFrames.insertcols!(df, 1, :DateTime => time_col)
            export_result(file_type, exports_path, name, timestamp, df)
        end
    end
end

# Here because requires the problem to be defined
# This is a method a user defining a custom cache will have to define. This is the definition
# in PSI for the building the TimeStatusChange
function get_initial_cache(cache::AbstractCache, problem::DecisionProblem)
    throw(ArgumentError("Initialization method for cache $(typeof(cache)) not defined"))
end

function get_initial_cache(cache::TimeStatusChange, problem::DecisionProblem)
    ini_cond_on = get_initial_conditions(
        get_optimization_container(problem),
        InitialTimeDurationOn,
        cache.device_type,
    )

    ini_cond_off = get_initial_conditions(
        get_optimization_container(problem),
        InitialTimeDurationOff,
        cache.device_type,
    )

    device_axes = Set((
        PSY.get_name(ic.device) for ic in Iterators.Flatten([ini_cond_on, ini_cond_off])
    ),)
    value_array = JuMP.Containers.DenseAxisArray{Dict{Symbol, Any}}(undef, device_axes)

    for ic in ini_cond_on
        device_name = PSY.get_name(ic.device)
        condition = get_condition(ic)
        status = (condition > 0.0) ? 1.0 : 0.0
        value_array[device_name] = Dict(:count => condition, :status => status)
    end

    for ic in ini_cond_off
        device_name = PSY.get_name(ic.device)
        condition = get_condition(ic)
        status = (condition > 0.0) ? 0.0 : 1.0
        if value_array[device_name][:status] != status
            throw(
                IS.ConflictingInputsError(
                    "Initial Conditions for $(device_name) are not compatible. The values provided are invalid",
                ),
            )
        end
    end

    return value_array
end

function get_initial_cache(cache::StoredEnergy, problem::DecisionProblem)
    ini_cond_level = get_initial_conditions(
        get_optimization_container(problem),
        InitialEnergyLevel,
        cache.device_type,
    )

    device_axes = Set([PSY.get_name(ic.device) for ic in ini_cond_level],)
    value_array = JuMP.Containers.DenseAxisArray{Float64}(undef, device_axes)
    for ic in ini_cond_level
        device_name = PSY.get_name(ic.device)
        condition = get_condition(ic)
        value_array[device_name] = condition
    end
    return value_array
end

function get_timestamps(problem::DecisionProblem)
    start_time = get_initial_time(get_optimization_container(problem))
    resolution = get_resolution(problem)
    horizon = get_horizon(problem)
    return range(start_time, length = horizon, step = resolution)
end

function write_data(problem::DecisionProblem, output_dir::AbstractString; kwargs...)
    write_data(get_optimization_container(problem), output_dir; kwargs...)
    return
end

struct ProblemSerializationWrapper
    template::ProblemTemplate
    sys::String
    settings::Settings
    problem_type::DataType
end

################ Functions to debug optimization models#####################################
"""
Each Tuple corresponds to (con_name, internal_index, moi_index)
"""
function get_all_constraint_index(problem::DecisionProblem)
    con_index = Vector{Tuple{ConstraintKey, Int, Int}}()
    optimization_container = get_optimization_container(problem)
    for (key, value) in get_constraints(optimization_container)
        for (idx, constraint) in enumerate(value)
            moi_index = JuMP.optimizer_index(constraint)
            push!(con_index, (key, idx, moi_index.value))
        end
    end
    return con_index
end

"""
Each Tuple corresponds to (con_name, internal_index, moi_index)
"""
function get_all_var_index(problem::DecisionProblem)
    var_keys = get_all_var_keys(problem)
    return [(encode_key(v[1]), v[2], v[3]) for v in var_keys]
end

function get_all_var_keys(problem::DecisionProblem)
    var_index = Vector{Tuple{VariableKey, Int, Int}}()
    optimization_container = get_optimization_container(problem)
    for (key, value) in get_variables(optimization_container)
        for (idx, variable) in enumerate(value)
            moi_index = JuMP.optimizer_index(variable)
            push!(var_index, (key, idx, moi_index.value))
        end
    end
    return var_index
end

function get_con_index(problem::DecisionProblem, index::Int)
    optimization_container = get_optimization_container(problem)
    constraints = get_constraints(optimization_container)
    for i in get_all_constraint_index(problem::DecisionProblem)
        if i[3] == index
            return constraints[i[1]].data[i[2]]
        end
    end
    @info "Index not found"
    return
end

function get_var_index(problem::DecisionProblem, index::Int)
    optimization_container = get_optimization_container(problem)
    variables = get_variables(optimization_container)
    for i in get_all_var_keys(problem)
        if i[3] == index
            return variables[i[1]].data[i[2]]
        end
    end
    @info "Index not found"
    return
end
