export EconomicDispatch 

"""
This function populates a particular AbstractPowerModel and populates the fields according to the 
    data in the system and stablishes the device models included which effectively are calls to the construction
    functions. 
"""

function EconomicDispatch(sys,tp)
    m = JuMP.Model()
    #Variable Creation             
    pth = GenerationVariables(m, sys.generators["Thermal"], tp);
    # on_th, start_th, stopth = PowerSimulations.CommitmentVariables(m, system.generators["Thermal"], tp)

    fl = BranchFlowVariables(m, sys.network.branches, tp);
    pcl = PowerSimulations.LoadVariables(m, sys.loads, tp);

    PowerConstraints(m, pth, sys.generators["Thermal"], tp);
    PowerConstraints(m, pcl, [sys.loads[4]], tp);


    KCLBalance(m, sys, fl, pth, pcl, tp);

    CopperPlateNetwork(m, sys, fl, tp);
    objective = PowerSimulations.VariableCostGen(pth, sys.generators["Thermal"]);

    device = sys.loads[4]
    for i in [device.name]
        for t in 1:tp
            objective = objective + 5000*(pcl[i, t] - device.maxrealpower*device.scalingfactor.values[t])
        end
    end

    @objective(m, :Min, objective);

    return m

end