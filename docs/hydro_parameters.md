# Hydro parameter assumptions

Hydro storages may be crucial for reliability in future, energy-limited systems, so the
parameters of the key large reservoirs are taken from additional sources rather than from
the ISP dataset alone. Reservoir size is defined via the **maximum discharge time at full
power**, which allows default values to be derived from installed power capacity for the
many units that are not explicitly named.

The authoritative source for these values is `get_hydro_parameters` in
[`src/parser/scenario_assumptions.jl`](../src/parser/scenario_assumptions.jl); they are
consumed by [`src/parser/createGenStorages.jl`](../src/parser/createGenStorages.jl).
Discharge times are given in timesteps (hours at hourly resolution) and states of charge
as a factor of the maximum energy capacity.

## Default values (`case = "base"`)

| Region | Parameter | Sub-parameter | Value | Basis |
| --- | --- | --- | --- | --- |
| TAS | `reservoir_discharge_time_units` | Gordon (`GORDON`) | 10000 | Max. storage 4700 GWh at 450 MW ≈ 10000 h [^tas] |
| | | Poatina (`POAT110`) | 20000 | Max. storage 6600 GWh at 325 MW ≈ 20000 h [^tas] |
| | `reservoir_discharge_time_states` | Tasmania (region 4) | 2000 | Total remaining storage 3100 GWh at 1.4 GW ≈ 2000 h [^tas] |
| | `reservoir_initial_soc_units` | Gordon (`GORDON`) | 0.4 | Average 2020–2026: 1827 GWh ⇒ approx. 40 % [^tas] [^tec] |
| | | Poatina (`POAT110`) | 0.3 | Average 2020–2026 energy in storage for the yingina / Great Lake and South Esk catchment ⇒ approx. 30 % [^tas] [^tec] |
| | `reservoir_initial_soc_states` | Tasmania (region 4) | 0.6 | Average 2020–2026: 1946 GWh ⇒ approx. 60 % [^tas] [^tec] |
| VIC | `reservoir_discharge_time_units` | Murray (`MURRAY1`), Tumut (`UPPTUMUT`) | 2100 | Approximated from total Snowy Scheme values: average inflows 2800 GL, average production 4500 GWh, max. active storage 5300 GL, 4.1 GW capacity [^snowy] |
| | | Bogong / McKay (`MCKAY1`) | 130 | From discussions with AGL: 18 GL usable storage in Rocky Valley basin, conversion factor 0.47 ML/MWh |
| | `reservoir_discharge_time_states` | Victoria (region 3) | 200 | Assume smaller reservoirs for the smaller hydro schemes |
| | `reservoir_initial_soc_units` | Murray (`MURRAY1`), Tumut (`UPPTUMUT`) | 0.5 | Approximation informed by Snowy Hydro reporting [^snowywater] |
| | | Bogong / McKay (`MCKAY1`) | 0.5 | Approximation based on historical yearly levels [^kiewa] |
| | `reservoir_initial_soc_states` | Victoria (region 3) | 0.5 | — |
| Other | `reservoir_discharge_time_other` | — | 200 | Approximation based on VIC/TAS small hydro |
| | `reservoir_initial_soc_other` | — | 0.5 | — |
| NEM | `pumped_hydro_initial_soc` | — | 0.5 | Assume similar storage behaviour to reservoir storage |
| | `run_of_river_discharge_time` | — | 0 | Run-of-river modelled without storage |
| | `run_of_river_discharge_efficiency` | — | 1.0 | See note below |
| | `run_of_river_carryover_efficiency` | — | 1.0 | Irrelevant while the discharge time is zero |
| | `reservoir_discharge_efficiency` | — | 1.0 | See note below |
| | `reservoir_carryover_efficiency` | — | 1.0 | Assume no losses in dams |
| | `default_static_inflow` | — | 0.0 | Hourly inflow used if no inflow trace is found for a hydro station, as a factor of grid injection power capacity |

## How the parameters are resolved

For both the reservoir discharge time and the reservoir initial state of charge, the parser
resolves values in the following order of precedence
(`createGenStorages.jl:135-141`, `:167-173`):

1. a unit-specific entry (`*_units`, keyed on the unit alias);
2. a state-specific entry (`*_states`, keyed on region — 3 = VIC, 4 = TAS);
3. the `*_other` fallback.

Two implementation details are worth noting:

- Energy capacity is computed as power capacity × discharge time
  (`createGenStorages.jl:130`, `:143`).
- The initial state of charge is applied by **adding it to the inflow of the first
  timestep** rather than through a dedicated SOC field
  (`createGenStorages.jl:174`, `:178`).


## Excluded parameters

`get_hydro_parameters` also returns `hydro_discharging_cost` and `final_soc_constraint`.
These are only used by SchedNEM and have no effect in PRASNEM, so they are not documented
here.

## References

[^tas]: Hydro Tasmania, *Energy in Storage*. <https://www.hydro.com.au/water#energy_in_storage>

[^tec]: Tasmanian Economic Regulator, *Annual Energy Security Review 2024-25*. <https://www.economicregulator.tas.gov.au/Documents/25%204379%20Annual%20Energy%20Security%20Review%202024-25.PDF> — inflows in Tasmania were below average in the last two water years, so the average storage levels above are likely a conservative estimate.

[^snowy]: Snowy Hydro, *The Snowy Scheme* and *Water*. <https://www.snowyhydro.com.au/generation/the-snowy-scheme/>, <https://www.snowyhydro.com.au/generation/water/>

[^snowywater]: Snowy Hydro, *Water*. <https://www.snowyhydro.com.au/generation/water/>

[^kiewa]: Victorian Water Accounts 2022, local water reports, surface water by river basin — Kiewa. <https://accounts.water.vic.gov.au/2022/local-water-reports/surface-water-by-river-basin/kiewa/>
