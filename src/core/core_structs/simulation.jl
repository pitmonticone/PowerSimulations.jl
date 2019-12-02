mutable struct SimulationRef
    raw_dir::String
    models_dir::String
    results_dir::String
    run_count::Dict{Int64, Dict{Int64, Int64}}
    date_ref::Dict{Int64, Dates.DateTime}
    current_time::Dates.DateTime
    reset::Bool
end

function SimulationRef(
    raw_dir::AbstractString,
    models_dir::AbstractString,
    results_dir::AbstractString,
    steps::Int64,
    stages_keys::Base.KeySet,
)
    count_dict = Dict{Int64, Dict{Int64, Int64}}()

    for s in 1:steps
        count_dict[s] = Dict{Int64, Int64}()
        for st in stages_keys
            count_dict[s][st] = 0
        end
    end

    return SimulationRef(
        raw_dir,
        models_dir,
        results_dir,
        count_dict,
        Dict{Int64, Dates.DateTime}(),
        Dates.now(),
        true,
    )
end

mutable struct Simulation
    steps::Int64
    stages::Vector{Stage}
    valid_timeseries::Bool
    daterange::NTuple{2, Dates.DateTime} #Inital Time of the first forecast and Inital Time of the last forecast
    ref::SimulationRef
    simulation_folder::String
    base_name::String
    compiled_status::Bool

    function Simulation(base_name::String,
                        steps::Int64,
                        stages::Dict{Int64, Stage},
                        simulation_folder::String;
                        verbose::Bool = false, kwargs...)

    sim_ref = _initialize_sim_ref(steps, keys(stages))
    #dates, validation, stages_vector = _build_simulation!(
    #                                                      sim_ref,
    #                                                      steps,
    #                                                      stages;
    #                                                      verbose = verbose, kwargs...
    #                                                      )
    #@assert sim_ref.raw != "init"
    #@assert sim_ref.models != "init"
    #@assert sim_ref.results != "init"

    new(
        steps,
        stages_vector,
        validation,
        dates,
        sim_ref,
        simulation_folder,
        base_name,
        false
        )
    end
end

function Simulation(base_name::String,
                    steps::Int64,
                    simulation_folder::String;
                    verbose::Bool = false, kwargs...)
    return Simulation(base_name, steps::Int64, Dict{Int64, Stage}(),
                      simulation_folder; verbose=verbose, kwargs...)
end


################# accessor functions ####################
get_steps(s::Simulation) = s.steps
get_daterange(s::Simulation) = s.daterange

function _prepare_workspace(base_name::AbstractString, folder::AbstractString)
    !isdir(folder) && throw(ArgumentError("Specified folder is not valid"))
    global_path = joinpath(folder, "$(base_name)")
    !isdir(global_path) && mkpath(global_path)
    _sim_path = replace_chars("$(round(Dates.now(), Dates.Minute))", ":", "-")
    simulation_path = joinpath(global_path, _sim_path)
    raw_output = joinpath(simulation_path, "raw_output")
    mkpath(raw_output)
    models_json_ouput = joinpath(simulation_path, "models_json")
    mkpath(models_json_ouput)
    results_path = joinpath(simulation_path, "results")
    mkpath(results_path)

    return raw_output, models_json_ouput, results_path
end
