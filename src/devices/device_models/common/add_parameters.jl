function include_parameters(canonical_model::CanonicalModel,
                            data::Matrix,
                            param_reference::UpdateRef,
                            axs...)

    _add_param_container!(canonical_model, param_reference, axs...)
    param = par(canonical_model, param_reference)

    Cidx = CartesianIndices(length.(axs))

    for idx in Cidx
        param.data[idx] = PJ.add_parameter(canonical_model.JuMPmodel, data[idx])
    end

    return

end

function include_parameters(canonical_model::CanonicalModel,
                            ts_data::Vector{Tuple{String, Int64, Float64, Vector{Float64}}},
                            param_reference::UpdateRef,
                            expression::Symbol,
                            multiplier::Float64 = 1.0)


    time_steps = model_time_steps(canonical_model)
    _add_param_container!(canonical_model, param_reference, (r[1] for r in ts_data), time_steps)
    param = par(canonical_model, param_reference)
    expr = exp(canonical_model, expression)

    for t in time_steps, r in ts_data
        param[r[1], t] = PJ.add_parameter(canonical_model.JuMPmodel, r[4][t]);
        _add_to_expression!(expr, r[2], t, param[r[1], t], r[3] * multiplier)
    end

    return

end
