# PRASNEM

[![Build Status](https://github.com/ARPST-UniMelb/PRASNEM.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ARPST-UniMelb/PRASNEM.jl/actions/workflows/CI.yml?query=branch%3Amain)

The goal of this package is to provide a model of the Australian National Electricity Market (NEM) to use in the Probabilistic Resource Adequacy Suite (PRAS) to perform resource adequacy / reliability studies. 

PRAS is developed and maintained by NLR and can be found here: https://github.com/NatLabRockies/PRAS

> [!NOTE]
> The created systems are fully compatible with the standard PRAS release. Optionally, a customised PRAS version is available at https://github.com/ARPST-UniMelb/PRAS, which enables the `additional_offset_DispatchProblem` attribute set by PRASNEM (adjusting the charging merit order so that storages/DER also charge from generators further away). The standard PRAS version simply ignores this attribute.

This repository contains:
- All the parser scripts to create a PRAS model from ISP data
- Some PRAS model files, ready to go

> [!CAUTION]
> The current release is fully functional and has been extensively tested; however, bugs or other issues may still arise. We would greatly appreciate any feedback or bug reports submitted via https://github.com/ARPST-UniMelb/PRASNEM.jl/issues 

> [!NOTE]
> If you are using this or the related repositories for your work, please cite the final report of AR-PST Stage 5:
> 
> T. Kopka, M. Yasirroni, P. Apablaza, B. Moya, S. Mhanna, and P. Mancarella, “Resource Adequacy, Risk, and Resilience in Low-Carbon Energy System Planning: Methods, Tools, and Metrics,” Australian Research in Power Systems Transition (AR-PST), Jun. 2026. [Online]. Available: https://www.csiro.au/en/research/technology-space/energy/Electricity-transition/AR-PST/Stage-5


## Getting Started

Clone the repository by executing the following function
```sh
git clone "https://github.com/ARPST-UniMelb/PRASNEM.jl"
```

Then start a Julia REPL within the folder and activate and instantiate the local environment:
```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

Now you can create PRAS files using PRASNEM and data from [PISP.jl](https://github.com/ARPST-UniMelb/PISP.jl):
Example:
```Julia
using PRASNEM
using Dates

start_dt = DateTime("2025-01-07 00:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
end_dt = DateTime("2025-01-13 23:00:00", dateformat"yyyy-mm-dd HH:MM:SS")
input_folder = joinpath(pwd(), "src", "sample_data", "nem12")
output_folder = joinpath(pwd(), "src", "sample_data", "pras_files")
timeseries_folder = joinpath(input_folder, "schedule-1w")
sys = PRASNEM.create_pras_system(start_dt, end_dt, input_folder, timeseries_folder; output_folder=output_folder, regions_selected=collect(1:12));
```

#### Evaluating reliability
Example if system was created above and is available in memory:
```Julia
PRASNEM.run_pras_study(sys; sample_number=100)
```

Example if reading system from file:
```Julia
using PRASNEM
file_name = "src/sample_data/pras_files/2025-01-07_to_2025-01-13_s2_123456789101112_regions.pras"
PRASNEM.run_pras_study(file_name; sample_number=100)
```

Or if just PRAS should be used:
```Julia
using PRAS

file_name = "src/sample_data/pras_files/2025-01-07_to_2025-01-13_s2_123456789101112_regions.pras"
sys = SystemModel(file_name)
sf, = assess(sys, SequentialMonteCarlo(samples=100), Shortfall())

println(LOLE(sf))
println(NEUE(sf))
```

## Optional parameters of PRASNEM.create_pras_system
There are multiple optional parameters that can be adjusted when creating the pras system:
| Parameter           | Default       | Description                                                                                                                        |
| ------------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| output_folder       | ""            | Folder to save the PRAS file. If empty, the PRAS file is not saved.                                                                |
| regions_selected    | collect(1:12) | Array of region IDs to include (needs to be in ascending order). Empty array for copperplate model.                                |
| scenario            | 2             | ISP scenario to use (1: progressive change, 2: step change, 3: green hydrogen exports)                                             |
| gentech_excluded    | []            | Array of generator technologies to exclude (can be fuel or technology, e.g. "Coal", "RoofPV", ...)                                 |
| alias_excluded      | []            | Array of generator/storage/DER aliases to exclude (e.g. "GSTONE1")                                                                 |
| investment_filter   | [0]           | Array indicating which assets to include based on investment status (if investment candidate or not)                               |
| active_filter       | [1]           | Array indicating which assets to include based on their active status                                                              |
| line_alias_included | []            | Array of line aliases to include even if they would be filtered out due to investment/active status                                |
| DER_parameters      | `PRASNEM.get_DER_parameters()` | Dict with DER scenario, as defined in `PRASNEM.get_DER_parameters()` function.                                    |
| hydro_parameters    | `PRASNEM.get_hydro_parameters()` | Dict with hydro parameters (e.g. initial SOC of reservoirs, reservoir sizes, efficiencies).                     |

## Tips for more efficient usage

- **Using the optional parameter output_folder**:If you are using the same systems regularly, try to specify an ```output_folder```. If the PRAS-file is saved there, the function ```create_pras_system``` will automatically load this file instead of creating the same system again from scratch.
- **Fixing the seed of PRAS runs**: While fixing the seed of a simulation in PRAS will ensure the same result for a given system, it might not result in the same samples for a system with different components. Therefore, the standard deviation which is also computed by PRAS is important to consider. If exactly the same outage samples are required, consider using the same system for both cases but just "disabling" the studied components by setting the capacities to zero. (More details see [PRAS github](https://github.com/NatLabRockies/PRAS/issues/37).)

## Overview of PRASNEM.jl functions

The core function of PRASNEM.jl is ```create_pras_system()```, as outlined above. Additionally, the following functions are provided in this package.

|    Location     |              Function              |                                                                             Details                                                                             |
| :-------------: | :--------------------------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------: |
|  ```/parser```  |    **```create_pras_system```**    |                                Main function to parse data output from PISP into the PRAS format. See optional parameters above.                                |
| ```/updating``` | ```remove_intraarea_constraints``` |                                 Function to increase all limits of lines/interfaces between the subnodes within an area/state.                                  |
| ```/updating``` |       ```redistribute_DR!```        | Distributes the demandresponse capabilities across the sub-nodes within each area according to a specified "mode" (default / equal / max demand / total energy) |
| ```/updating``` |     ```updateEnergyDerating!```     |                       Derates short-term energy storage capacities based on their duration (AEMO derating mapping by default)                        |
| ```/updating``` |  ```updateStorageOutageDerating!```  |                Converts storage/genstorage failure and repair rates into a capacity derating (and sets the outage rates to zero)                 |
| ```/updating``` | ```updateStorageMarketDecisionDispatch!``` |             Limits storage/genstorage charging to the timesteps when it is expected to charge (based on a dispatch result)              |
| ```/updating``` | ```updateStorageExpectationDispatch!``` |        Adjusts the load with the expected storage/genstorage dispatch and disables the storages/genstorages (capacities set to zero)         |
| ```/updating``` |  ```updateDRExpectationDispatch!```  |                          Includes the expected demand response dispatch within the load and disables the demand response                           |
| ```/updating``` |  ```updateVPPExpectationDispatch!```  |                              Includes the expected VPP dispatch within the load and disables the VPP storages                               |
| ```/updating``` |     ```updateUnitCommitment!```     |                                 Updates the generator capacities based on commitment status (based on a dispatch result)                                  |
| ```/updating``` |        ```updateRamping!```         |                                Updates the generator capacities based on the expected ramping profiles (based on a dispatch result)                                 |
| ```/updating``` |  ```applyGenHeatwaveDerating!```  |                    Applies heatwave derating to wind, large PV, roof PV and thermal generators based on derating timeseries files                     |
| ```/updating``` |  ```applyLineHeatwaveDerating!```  |                Applies heatwave derating to lines based on derating timeseries files (interface limits are updated accordingly)                 |
| ```/updating``` |   ```updateVREDroughtLength!```    |          Simulates a prolonged VRE drought by repeating the worst residual demand day for a specified number of consecutive days           |
| ```/analysis``` |          ```NEUE_area```           |                       Returns the normalised expected unserved energy (NEUE) for each area (sub-regional results are weighted by demand)                        |
| ```/analysis``` |      ```get_event_details```       |                                        Returns event details (duration, sum, max) for a given (time-)vector of shortfall                                        |
| ```/analysis``` |    ```get_all_event_details```     |                     Returns a DataFrame with event details for each region/area and sample, given shortfall samples (optionally with storage energy before each event)                      |
| ```/analysis``` |   ```get_region_area_map``` / ```get_region_names```   |                            Helper functions with the region-to-area mapping and region names of the ISP24 12-bus system                             |
| ```/analysis``` |     ```plot_PRAS_dispatch```      |                          Runs a PRAS assessment and plots the dispatch stack for a selected sample, time window and regions                           |
| ```/studies```  |        ```run_pras_study```        |                                               Runs a PRAS study and returns adequacy values, given a PRAS-system                                                |
| ```/studies```  |  ```assess_event_level_details```  |                             Runs a PRAS assessment and returns the event details DataFrame (optionally including storage energy)                              |


## Further PRAS functions
For reference, these are a number of possible outputs from PRAS (full list can be found in the PRAS documentation [here](https://natlabrockies.github.io/PRAS/stable/PRAS/results/)):
```Julia
using PRAS

# Assuming that sys is already in memory (see above)
nsamples = 100
shortfalls, surplus, genavail, storage_energy, generator_storage_energy, flow = assess(
    sys, SequentialMonteCarlo(samples=nsamples),
    Shortfall(), Surplus(), GeneratorAvailability(), StorageEnergy(), GeneratorStorageEnergy(), Flow());
```
