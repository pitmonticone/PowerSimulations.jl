#################################### Branch Variables ##################################################
get_variable_binary(
    _,
    ::Type{<:PSY.TwoTerminalHVDCLine},
    ::AbstractTwoTerminalDCLineFormulation,
) =
    false
get_variable_binary(
    ::FlowActivePowerVariable,
    ::Type{<:PSY.TwoTerminalHVDCLine},
    ::AbstractTwoTerminalDCLineFormulation,
) = false

get_variable_binary(
    ::HVDCFlowDirectionVariable,
    ::Type{<:PSY.TwoTerminalHVDCLine},
    ::AbstractTwoTerminalDCLineFormulation,
) = true

get_variable_multiplier(::FlowActivePowerVariable, ::Type{<:PSY.TwoTerminalHVDCLine}, _) =
    NaN

get_variable_multiplier(
    ::FlowActivePowerFromToVariable,
    ::Type{<:PSY.TwoTerminalHVDCLine},
    ::AbstractTwoTerminalDCLineFormulation,
) = -1.0

get_variable_multiplier(
    ::FlowActivePowerToFromVariable,
    ::Type{<:PSY.TwoTerminalHVDCLine},
    ::AbstractTwoTerminalDCLineFormulation,
) = 1.0

function get_variable_multiplier(
    ::HVDCLosses,
    d::PSY.TwoTerminalHVDCLine,
    ::HVDCTwoTerminalDispatch,
)
    l1 = PSY.get_loss(d).l1
    l0 = PSY.get_loss(d).l0
    if l1 == 0.0 && l0 == 0.0
        return 0.0
    else
        return -1.0
    end
end

get_variable_lower_bound(
    ::FlowActivePowerVariable,
    d::PSY.TwoTerminalHVDCLine,
    ::HVDCTwoTerminalUnbounded,
) = nothing

get_variable_upper_bound(
    ::FlowActivePowerVariable,
    d::PSY.TwoTerminalHVDCLine,
    ::HVDCTwoTerminalUnbounded,
) = nothing

get_variable_lower_bound(
    ::FlowActivePowerVariable,
    d::PSY.TwoTerminalHVDCLine,
    ::AbstractTwoTerminalDCLineFormulation,
) = nothing

get_variable_upper_bound(
    ::FlowActivePowerVariable,
    d::PSY.TwoTerminalHVDCLine,
    ::AbstractTwoTerminalDCLineFormulation,
) = nothing

get_variable_lower_bound(
    ::HVDCLosses,
    d::PSY.TwoTerminalHVDCLine,
    ::HVDCTwoTerminalDispatch,
) = 0.0

get_variable_upper_bound(
    ::FlowActivePowerFromToVariable,
    d::PSY.TwoTerminalHVDCLine,
    ::HVDCTwoTerminalDispatch,
) = PSY.get_active_power_limits_from(d).max

get_variable_lower_bound(
    ::FlowActivePowerFromToVariable,
    d::PSY.TwoTerminalHVDCLine,
    ::HVDCTwoTerminalDispatch,
) = PSY.get_active_power_limits_from(d).min

get_variable_upper_bound(
    ::FlowActivePowerToFromVariable,
    d::PSY.TwoTerminalHVDCLine,
    ::HVDCTwoTerminalDispatch,
) = PSY.get_active_power_limits_to(d).max

get_variable_lower_bound(
    ::FlowActivePowerToFromVariable,
    d::PSY.TwoTerminalHVDCLine,
    ::HVDCTwoTerminalDispatch,
) = PSY.get_active_power_limits_to(d).min

function get_variable_upper_bound(
    ::HVDCLosses,
    d::PSY.TwoTerminalHVDCLine,
    ::HVDCTwoTerminalDispatch,
)
    l1 = PSY.get_loss(d).l1
    l0 = PSY.get_loss(d).l0
    if l1 == 0.0 && l0 == 0.0
        return 0.0
    else
        return nothing
    end
end

function get_default_time_series_names(
    ::Type{U},
    ::Type{V},
) where {U <: PSY.TwoTerminalHVDCLine, V <: AbstractTwoTerminalDCLineFormulation}
    return Dict{Type{<:TimeSeriesParameter}, String}()
end

function get_default_attributes(
    ::Type{U},
    ::Type{V},
) where {U <: PSY.TwoTerminalHVDCLine, V <: AbstractTwoTerminalDCLineFormulation}
    return Dict{String, Any}()
end

get_initial_conditions_device_model(
    ::OperationModel,
    ::DeviceModel{T, U},
) where {T <: PSY.TwoTerminalHVDCLine, U <: AbstractTwoTerminalDCLineFormulation} =
    DeviceModel(T, U)

#################################### Rate Limits Constraints ##################################################
function _get_flow_bounds(d::PSY.TwoTerminalHVDCLine)
    check_hvdc_line_limits_consistency(d)
    from_min = PSY.get_active_power_limits_from(d).min
    to_min = PSY.get_active_power_limits_to(d).min
    from_max = PSY.get_active_power_limits_from(d).max
    to_max = PSY.get_active_power_limits_to(d).max

    if from_min >= 0.0 && to_min >= 0.0
        min_rate = min(from_min, to_min)
    elseif from_min <= 0.0 && to_min <= 0.0
        min_rate = max(from_min, to_min)
    elseif from_min <= 0.0 && to_min >= 0.0
        min_rate = from_min
    elseif to_min <= 0.0 && from_min >= 0.0
        min_rate = to_min
    end

    if from_max >= 0.0 && to_max >= 0.0
        max_rate = min(from_max, to_max)
    elseif from_max <= 0.0 && to_max <= 0.0
        max_rate = max(from_max, to_max)
    elseif from_max <= 0.0 && to_max >= 0.0
        max_rate = from_max
    elseif from_max >= 0.0 && to_max <= 0.0
        max_rate = to_max
    end

    return min_rate, max_rate
end

add_constraints!(
    ::OptimizationContainer,
    ::Type{<:Union{FlowRateConstraintFromTo, FlowRateConstraintToFrom}},
    ::IS.FlattenIteratorWrapper{<:PSY.TwoTerminalHVDCLine},
    ::DeviceModel{<:PSY.TwoTerminalHVDCLine, HVDCTwoTerminalUnbounded},
    ::NetworkModel{<:PM.AbstractPowerModel},
) = nothing

add_constraints!(
    ::OptimizationContainer,
    ::Type{FlowRateConstraint},
    ::IS.FlattenIteratorWrapper{<:PSY.TwoTerminalHVDCLine},
    ::DeviceModel{<:PSY.TwoTerminalHVDCLine, HVDCTwoTerminalUnbounded},
    ::NetworkModel{<:PM.AbstractPowerModel},
) = nothing

function add_constraints!(
    container::OptimizationContainer,
    ::Type{T},
    devices::Union{Vector{U}, IS.FlattenIteratorWrapper{U}},
    ::DeviceModel{U, HVDCTwoTerminalLossless},
    ::NetworkModel{<:PM.AbstractPowerModel},
) where {T <: FlowRateConstraint, U <: PSY.TwoTerminalHVDCLine}
    time_steps = get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]

    var = get_variable(container, FlowActivePowerVariable(), U)
    constraint_ub =
        add_constraints_container!(container, T(), U, names, time_steps; meta = "ub")
    constraint_lb =
        add_constraints_container!(container, T(), U, names, time_steps; meta = "lb")
    for d in devices
        min_rate, max_rate = _get_flow_bounds(d)
        for t in time_steps
            constraint_ub[PSY.get_name(d), t] = JuMP.@constraint(
                get_jump_model(container),
                var[PSY.get_name(d), t] <= max_rate
            )
            constraint_lb[PSY.get_name(d), t] = JuMP.@constraint(
                get_jump_model(container),
                min_rate <= var[PSY.get_name(d), t]
            )
        end
    end
    return
end

function _add_hvdc_flow_constraints!(
    container::OptimizationContainer,
    devices::Union{Vector{T}, IS.FlattenIteratorWrapper{T}},
    constraint::FlowRateConstraintFromTo,
) where {T <: PSY.TwoTerminalHVDCLine}
    _add_hvdc_flow_constraints!(
        container,
        devices,
        FlowActivePowerFromToVariable(),
        constraint,
    )
end

function _add_hvdc_flow_constraints!(
    container::OptimizationContainer,
    devices::Union{Vector{T}, IS.FlattenIteratorWrapper{T}},
    constraint::FlowRateConstraintToFrom,
) where {T <: PSY.TwoTerminalHVDCLine}
    _add_hvdc_flow_constraints!(
        container,
        devices,
        FlowActivePowerToFromVariable(),
        constraint,
    )
end

function _add_hvdc_flow_constraints!(
    container::OptimizationContainer,
    devices::Union{Vector{T}, IS.FlattenIteratorWrapper{T}},
    var::Union{FlowActivePowerFromToVariable, FlowActivePowerToFromVariable},
    constraint::Union{FlowRateConstraintFromTo, FlowRateConstraintToFrom},
) where {T <: PSY.TwoTerminalHVDCLine}
    time_steps = get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]

    variable = get_variable(container, var, T)
    constraint_ub =
        add_constraints_container!(container, constraint, T, names, time_steps; meta = "ub")
    constraint_lb =
        add_constraints_container!(container, constraint, T, names, time_steps; meta = "lb")
    for d in devices
        check_hvdc_line_limits_consistency(d)
        max_rate = get_variable_upper_bound(var, d, HVDCTwoTerminalDispatch())
        min_rate = get_variable_lower_bound(var, d, HVDCTwoTerminalDispatch())
        for t in time_steps
            constraint_ub[PSY.get_name(d), t] = JuMP.@constraint(
                get_jump_model(container),
                variable[PSY.get_name(d), t] <= max_rate
            )
            constraint_lb[PSY.get_name(d), t] = JuMP.@constraint(
                get_jump_model(container),
                min_rate <= variable[PSY.get_name(d), t]
            )
        end
    end
    return
end

function add_constraints!(
    container::OptimizationContainer,
    ::Type{T},
    devices::IS.FlattenIteratorWrapper{U},
    model::DeviceModel{U, HVDCTwoTerminalDispatch},
    network_model::NetworkModel{CopperPlatePowerModel},
) where {
    T <: Union{FlowRateConstraintFromTo, FlowRateConstraintToFrom},
    U <: PSY.TwoTerminalHVDCLine,
}
    inter_network_branches = U[]
    for d in devices
        ref_bus_from = get_reference_bus(network_model, PSY.get_arc(d).from)
        ref_bus_to = get_reference_bus(network_model, PSY.get_arc(d).to)
        if ref_bus_from != ref_bus_to
            push!(inter_network_branches, d)
        end
    end
    if !isempty(inter_network_branches)
        _add_hvdc_flow_constraints!(container, devices, T())
    end
    return
end

function add_constraints!(
    container::OptimizationContainer,
    ::Type{T},
    devices::IS.FlattenIteratorWrapper{U},
    ::DeviceModel{U, HVDCTwoTerminalDispatch},
    ::NetworkModel{<:PM.AbstractDCPModel},
) where {T <: Union{FlowRateConstraintToFrom, FlowRateConstraintFromTo},
    U <: PSY.TwoTerminalHVDCLine}
    _add_hvdc_flow_constraints!(container, devices, T())
    return
end

function add_constraints!(
    container::OptimizationContainer,
    ::Type{T},
    devices::IS.FlattenIteratorWrapper{U},
    ::DeviceModel{U, HVDCTwoTerminalDispatch},
    ::NetworkModel{<:PM.AbstractDCPModel},
) where {T <: HVDCDirection, U <: PSY.TwoTerminalHVDCLine}
    time_steps = get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]

    tf_var = get_variable(container, FlowActivePowerToFromVariable(), U)
    ft_var = get_variable(container, FlowActivePowerFromToVariable(), U)
    direction_var = get_variable(container, HVDCFlowDirectionVariable(), U)

    constraint_ft_ub =
        add_constraints_container!(container, T(), U, names, time_steps; meta = "ft_ub")
    constraint_tf_ub =
        add_constraints_container!(container, T(), U, names, time_steps; meta = "tf_ub")
    constraint_ft_lb =
        add_constraints_container!(container, T(), U, names, time_steps; meta = "ft_lb")
    constraint_tf_lb =
        add_constraints_container!(container, T(), U, names, time_steps; meta = "tf_lb")
    for d in devices
        min_rate_to, max_rate_to = PSY.get_active_power_limits_to(d)
        min_rate_from, max_rate_from = PSY.get_active_power_limits_to(d)
        name = PSY.get_name(d)
        for t in time_steps
            constraint_tf_ub[name, t] = JuMP.@constraint(
                get_jump_model(container),
                tf_var[name, t] <= max_rate_to * (1 - direction_var[name, t])
            )
            constraint_ft_ub[name, t] = JuMP.@constraint(
                get_jump_model(container),
                ft_var[name, t] <= max_rate_from * (1 - direction_var[name, t])
            )
            constraint_tf_lb[name, t] = JuMP.@constraint(
                get_jump_model(container),
                direction_var[name, t] * min_rate_to <= tf_var[name, t]
            )
            constraint_ft_lb[name, t] = JuMP.@constraint(
                get_jump_model(container),
                direction_var[name, t] * min_rate_from <= tf_var[name, t]
            )
        end
    end
    return
end

function add_constraints!(
    container::OptimizationContainer,
    ::Type{HVDCPowerBalance},
    devices::IS.FlattenIteratorWrapper{T},
    ::DeviceModel{T, <:AbstractTwoTerminalDCLineFormulation},
    ::NetworkModel{<:PM.AbstractDCPModel},
) where {T <: PSY.TwoTerminalHVDCLine}
    time_steps = get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    tf_var = get_variable(container, FlowActivePowerToFromVariable(), T)
    ft_var = get_variable(container, FlowActivePowerFromToVariable(), T)
    direction_var = get_variable(container, HVDCFlowDirectionVariable(), T)

    constraint_ft_ub = add_constraints_container!(
        container,
        HVDCPowerBalance(),
        T,
        names,
        time_steps;
        meta = "ft_ub",
    )
    constraint_tf_ub = add_constraints_container!(
        container,
        HVDCPowerBalance(),
        T,
        names,
        time_steps;
        meta = "tf_ub",
    )
    constraint_ft_lb = add_constraints_container!(
        container,
        HVDCPowerBalance(),
        T,
        names,
        time_steps;
        meta = "tf_lb",
    )
    constraint_tf_lb = add_constraints_container!(
        container,
        HVDCPowerBalance(),
        T,
        names,
        time_steps;
        meta = "ft_lb",
    )
    for d in devices
        l1 = PSY.get_loss(d).l1
        l0 = PSY.get_loss(d).l0
        name = PSY.get_name(d)
        for t in get_time_steps(container)
            if l1 == 0.0 && l0 == 0.0
                constraint_tf_ub[PSY.get_name(d), t] = JuMP.@constraint(
                    get_jump_model(container),
                    tf_var[name, t] - ft_var[name, t] == 0.0
                )
                constraint_ft_ub[PSY.get_name(d), t] = JuMP.@constraint(
                    get_jump_model(container),
                    ft_var[name, t] - tf_var[name, t] == 0.0
                )
            else
                constraint_tf_ub[PSY.get_name(d), t] = JuMP.@constraint(
                    get_jump_model(container),
                    tf_var[name, t] - ft_var[name, t] <= l1 * tf_var[name, t] - l0
                )
                constraint_ft_ub[PSY.get_name(d), t] = JuMP.@constraint(
                    get_jump_model(container),
                    ft_var[name, t] - tf_var[name, t] >= l1 * ft_var[name, t] + l0
                )
            end
            constraint_tf_lb[PSY.get_name(d), t] = JuMP.@constraint(
                get_jump_model(container),
                ft_var[name, t] - tf_var[name, t] >=
                -M_VALUE * (1 - direction_var[name, t])
            )
            constraint_ft_lb[PSY.get_name(d), t] = JuMP.@constraint(
                get_jump_model(container),
                tf_var[name, t] - ft_var[name, t] >= -M_VALUE * (direction_var[name, t])
            )
        end
    end
    return
end

function add_constraints!(
    container::OptimizationContainer,
    ::Type{HVDCLossesAbsoluteValue},
    devices::IS.FlattenIteratorWrapper{T},
    ::DeviceModel{T, <:AbstractTwoTerminalDCLineFormulation},
    ::NetworkModel{<:PM.AbstractDCPModel},
) where {T <: PSY.TwoTerminalHVDCLine}
    time_steps = get_time_steps(container)
    names = [PSY.get_name(d) for d in devices]
    losses = get_variable(container, HVDCLosses(), T)
    tf_var = get_variable(container, FlowActivePowerToFromVariable(), T)
    ft_var = get_variable(container, FlowActivePowerFromToVariable(), T)
    constraint_tf = add_constraints_container!(
        container,
        HVDCLossesAbsoluteValue(),
        T,
        names,
        time_steps;
        meta = "tf",
    )
    constraint_ft = add_constraints_container!(
        container,
        HVDCLossesAbsoluteValue(),
        T,
        names,
        time_steps;
        meta = "ft",
    )
    for d in devices
        name = PSY.get_name(d)
        for t in get_time_steps(container)
            constraint_tf[PSY.get_name(d), t] = JuMP.@constraint(
                get_jump_model(container),
                tf_var[name, t] - ft_var[name, t] <= losses[name, t]
            )
            constraint_ft[PSY.get_name(d), t] = JuMP.@constraint(
                get_jump_model(container),
                -tf_var[name, t] + ft_var[name, t] <= losses[name, t]
            )
        end
    end
    return
end
