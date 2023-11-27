PRAGMA foreign_keys = ON;

-- Study Parameters
CREATE TABLE StudyParameters (
    id TEXT PRIMARY KEY,
    -- Implicit multiplier factor for representing the objective function (usually 1000)
    obj_factor REAL NOT NULL DEFAULT 1000,
    -- Indicates whether: single-node representation, zonal representation, network representation ("DC flow" linear model)
    network_type TEXT NOT NULL DEFAULT 'SingleNode'
        CHECK( 
            network_type IN (
                'SingleNode',
                'Zonal',
                'DCFlow'
            ) 
        ),
    -- Indicates whether: constant number and duration of subperiods, constant number, varying duration of subperiods, varying number, constant duration of subperiods, varying number, varying duration of subperiods
    subperiod_type TEXT NOT NULL DEFAULT 'Constant'
        CHECK( 
            subperiod_type IN (
                'Constant',
                'VariableDuration',
                'VariableNumber',
                'Variable'
            ) 
        ),
    -- How many subperiods in each period
    n_subperiods INTEGER NOT NULL DEFAULT 1,
    -- Duration of each subperiod in hours
    subperiod_duration REAL NOT NULL DEFAULT 1.0,
    -- How each step in the yearly "cycle" should be called - usually "month", "week", or "day" depending on CyclesPerYear
    cycle_name TEXT NOT NULL DEFAULT 'month',
    -- Number of cycles per year (usually 12, 52, or 365), for cyclical multi-year representation
    cycles_per_year INTEGER NOT NULL DEFAULT 12,
    -- Starting year for the study (used to adjust ResourceData and Modification inputs)
    start_year INTEGER NOT NULL DEFAULT 1,
    -- Starting cycle number considered for the study (used to adjust ResourceData and Modification inputs), from 1 to CyclesPerYear
    start_cycle INTEGER NOT NULL DEFAULT 1,
    -- Discount rate per year (dimensionless)
    annual_discount_rate REAL NOT NULL DEFAULT 0.0,
    -- How many sequential periods will be modeled
    n_periods INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE _StudyParameters_n_subperiods (
    study_period INTEGER,
    study_parameters_id TEXT NOT NULL,
    n_subperiods INTEGER NOT NULL,
    FOREIGN KEY (study_parameters_id) REFERENCES StudyParameters (id)
);

CREATE TABLE _StudyParameters_subperiod_duration (
    study_period INTEGER,
    study_parameters_id TEXT NOT NULL,
    subperiod_duration REAL NOT NULL,
    FOREIGN KEY (study_parameters_id) REFERENCES StudyParameters (id)
);

-- Resource 
CREATE TABLE Resource (
    id TEXT PRIMARY KEY,
    -- General descriptor text (optional)
    description TEXT,
    -- Label for grouping together similar resources (optional)
    grouping_label TEXT,
    -- Unit of representation for the resource
    unit TEXT NOT NULL DEFAULT "MWh",
    -- Alternative labeling for "Unit-times-Study.ObjFactor" (optional)
    big_unit TEXT,
    -- Facilitates SDDP correspondence: (0) no direct correspondence, (1) electricity-like variable resource (CDEF, elastic demand, gnd gauging station, power injection), (2) electricity-like fixed resource (battery) (3) hydro inflow gauging station (4) standard fuel (unlimited availability) (5) nonstandard fuel (fuel contracts and/or gas network) (6) electrification process
    aux_resource_type TEXT NOT NULL DEFAULT 'NoDirectCorrespondence'
        CHECK( 
            aux_resource_type IN (
                'NoDirectCorrespondence',
                'ElectricityLikeVariable',
                'ElectricityLikeFixed',
                'HydroInflow',
                'StandardFuel',
                'NonstandardFuel',
                'ElectrificationProcess'
            ) 
        ),
    -- Identifies whether a resource (0) is not shared (assets that point to this resource have "duplicate" resource availabilities), (1) is shared and must be used in full, (2) is shared and may be used partially
    shared_type TEXT NOT NULL DEFAULT 'NotShared'
        CHECK( 
            shared_type IN (
                'NotShared',
                'SharedMustUseFull',
                'SharedMayUsePartial'
            ) 
        ),
    -- Identifies whether resource availability (0) is unlimited (1) is constrained per-subperiod with per-subperiod data (2) is constrained per-subperiod with per-period data (constant across subperiods) (3) is constrained per-period (allows sharing resource between subperiods)
    subperiod_av_type TEXT NOT NULL DEFAULT 'Unlimited'
        CHECK( 
            subperiod_av_type IN (
                'Unlimited',
                'PerSubperiod',
                'PerSubperiodConstant',
                'PerPeriod'
            ) 
        ),
    -- Identifies whether (0) resource availability is expressed in "Units per hour" (standard representation) (1) resource availability is expressed in "Aggregate BigUnits" (sums over subperiods) (2) resource availability is expressed in "p.u." (interpreted as proportional to asset Capacity) (3) resource availability is always zero (battery-like)
    av_unit_type TEXT NOT NULL DEFAULT 'UnitsPerHour'
        CHECK( 
            av_unit_type IN (
                'UnitsPerHour',
                'AggregateBigUnits',
                'PerUnit',
                'AlwaysZero'
            ) 
        ),
    -- Identifies whether the resource cost (0) is always zero (1) is constant across the study (equal to RefCost for all periods and subperiods) (2) varies per-period but not per-subperiod (3) varies per-period and per-subperiod
    subperiod_cost_type TEXT NOT NULL DEFAULT 'AlwaysZero'
        CHECK( 
            subperiod_cost_type IN (
                'AlwaysZero',
                'Constant',
                'PerPeriod',
                'PerSubperiod'
            ) 
        ),
    -- Identifies whether the resource (0) cannot be explicitly stored (1) can be stored between subperiods within each period (but not between periods) (2) can be stored between periods (but is simplified intraperiod) (3) can be stored both between periods and intraperiod
    storage_type TEXT NOT NULL DEFAULT 'NoStorage'
        CHECK( 
            storage_type IN (
                'NoStorage',
                'Intraperiod',
                'Interperiod',
                'Both'
            ) 
        ),
    -- Reference per-period cost in $/Unit, usually overwritten by the referenced ResourceData object
    ref_cost REAL NOT NULL DEFAULT 0.0,
    -- Reference per-period availability in Units, usually overwritten by the referenced ResourceData object
    ref_availability REAL NOT NULL DEFAULT 0.0
);

CREATE TABLE _Resource_ref_cost_vector (
    -- Reference per-period cost in $/Unit, usually overwritten by the referenced ResourceData object
    resource_period INTEGER NOT NULL,
    resource_id TEXT NOT NULL,
    ref_cost REAL NOT NULL,
    FOREIGN KEY (resource_id) REFERENCES Resource (id),
    PRIMARY KEY (resource_period, resource_id)
);

CREATE TABLE _Resource_ref_availability_vector (
    -- Reference per-period availability in Units, usually overwritten by the referenced ResourceData object
    resource_period INTEGER,
    resource_id TEXT NOT NULL,
    ref_availability REAL NOT NULL,
    FOREIGN KEY (resource_id) REFERENCES Resource (id),
    PRIMARY KEY (resource_period, resource_id)
);

-- Conversion Curve
CREATE TABLE ConversionCurve (
    id TEXT PRIMARY KEY,
    -- General descriptor text (optional)
    description TEXT,
    -- unit
    unit TEXT NOT NULL,
    -- vertical_axis_unit_type
    vertical_axis_unit_type TEXT NOT NULL DEFAULT 'AlwaysZero'
        CHECK( 
            vertical_axis_unit_type IN (
                'UnitsPerHour',
                'AggregateBigUnits',
                'PerUnit',
                'AlwaysZero'
            ) 
        ),
    -- horizontal_axis_validation_type
    horizontal_axis_validation_type TEXT NOT NULL DEFAULT 'AlwaysZero'
         CHECK( 
            horizontal_axis_validation_type IN (
                'UnitsPerHour',
                'AggregateBigUnits',
                'PerUnit',
                'AlwaysZero'
            ) 
        )
);

CREATE TABLE _ConversionCurve_max_capacity_fractions (
    id TEXT,
    idx INTEGER NOT NULL,
    -- Fraction of the asset's maximum capacity corresponding to each Segment
    max_capacity_fractions REAL NOT NULL,

    FOREIGN KEY (id) REFERENCES ConversionCurve(id) ON DELETE CASCADE,
    PRIMARY KEY (id, idx)
);

CREATE TABLE _ConversionCurve_conversion_efficiencies (
    id TEXT,
    idx INTEGER NOT NULL,
    -- Resource conversion factor in MWh/Resource.Unit, varying per Segment
    conversion_efficiencies REAL NOT NULL,

    FOREIGN KEY (id) REFERENCES ConversionCurve(id) ON DELETE CASCADE,
    PRIMARY KEY (id, idx)
);

-- Benefit Curve
CREATE TABLE BenefitCurve (
    id TEXT PRIMARY KEY,
    -- General descriptor text (optional)
    description TEXT,
    -- vertical_axis_unit_type
    vertical_axis_unit_type TEXT NOT NULL DEFAULT 'AlwaysZero'
        CHECK( 
            vertical_axis_unit_type IN (
                'UnitsPerHour',
                'AggregateBigUnits',
                'PerUnit',
                'AlwaysZero'
            ) 
        ),
    -- horizontal_axis_validation_type
    horizontal_axis_validation_type TEXT NOT NULL DEFAULT 'AlwaysZero'
         CHECK( 
            horizontal_axis_validation_type IN (
                'UnitsPerHour',
                'AggregateBigUnits',
                'PerUnit',
                'AlwaysZero'
            ) 
        ),
    -- zero_position_type TODO (Bodin: inventei isso aqui. Certamente esses não são os enums)
    zero_position_type TEXT NOT NULL DEFAULT 'ZeroAtOrigin'
        CHECK( 
            zero_position_type IN (
                'ZeroAtOrigin',
                'ZeroAtEnd'
            ) 
        )
);

CREATE TABLE _BenefitCurve_resource_av_fractions (
    benefit_id TEXT PRIMARY KEY,
    segment INTEGER NOT NULL,
    -- Fraction of the asset's maximum capacity corresponding to each Segment
    resource_av_fractions REAL NOT NULL,
    FOREIGN KEY (benefit_id) REFERENCES BenefitCurve(id)
); 

CREATE TABLE _BenefitCurve_consumption_preferences (
    benefit_id TEXT PRIMARY KEY,
    segment INTEGER NOT NULL,
    -- Benefit factor in $/MWh, varying per Segment
    consumption_preferences REAL NOT NULL,
    FOREIGN KEY (benefit_id) REFERENCES BenefitCurve(id)
);

-- Power Assets
CREATE TABLE PowerAsset (
    id TEXT PRIMARY KEY,
    -- General descriptor text on asset physical features (optional)
    description TEXT,
    -- General descriptor text on asset model representation (optional)
    representation_notes TEXT,
    -- Label for grouping together similar assets (optional)
    grouping_label TEXT,
    -- Facilitates SDDP correspondence: (0) no correspondence (1) standard demand ("inelastic" - see options 8 and 9) (2) standard thermal ("unlimited availability" - see option 7) (3) renewable (4) hydro (5) battery (6) power injection (7) non-standard thermal (has fuel contract and/or gas network representation) (8) elastic demand (9) flexible demand (10) electrification demand (11) Csp
    -- TODO Bodin, acho que podemos tirar esses aux da frente de alguns nomes.
    aux_asset_type TEXT NOT NULL DEFAULT 'NoCorrespondence'
        CHECK( 
            aux_asset_type IN (
                'NoCorrespondence',
                'StandardDemand',
                'StandardThermal',
                'Renewable',
                'Hydro',
                'Battery',
                'PowerInjection',
                'NonstandardThermal',
                'ElasticDemand',
                'FlexibleDemand',
                'ElectrificationDemand',
                'Csp'
            ) 
        ),
    -- Indicates whether the asset (0) is generation-like (contribution >0), (1) is demand-like (contribution <0), (2) is neither and can have either positive or negative contribution
    output_sign TEXT NOT NULL DEFAULT 'GenerationLike'
        CHECK( 
            output_sign IN (
                'GenerationLike',
                'DemandLike',
                'Either'
            ) 
        ),
    -- Indicates whether the asset (0) has no network connection (ignore in a "network-representation" run) (1) has a single-bus connection (2) has a multi-bus fixed proportion connection
    bus_connection_type TEXT NOT NULL DEFAULT 'NoConnection'
        CHECK( 
            bus_connection_type IN (
                'NoConnection',
                'SingleBus',
                'MultiBus'
            ) 
        ),
    -- Combines deprecated ConversionType and BenefitType
    curve_type TEXT, -- TODO Bodin: aqui eu me perdi um pouco, não soube dizer o que isso significa
    -- Indicates whether the asset (0) is always on (1) is always off (2) uses a linearized commitment variable representation (3) uses a binary commitment variable representation (4) uses fixed commitment data read from an external data source
    commitment_type TEXT NOT NULL DEFAULT 'AlwaysOn'
        CHECK( 
            commitment_type IN (
                'AlwaysOn',
                'AlwaysOff',
                'Linearized',
                'Binary',
                'External'
            ) 
        ),
    -- Maximum capacity in MW, in absolute terms (for electricity injections or withdrawals)
    capacity REAL NOT NULL DEFAULT 0.0,
    -- Derating factor for reducing available capacity (dimensionless)
    capacity_derating REAL NOT NULL DEFAULT 1.0,
    -- Base direct O&M cost in $/MWh
    output_cost REAL NOT NULL DEFAULT 0.0,
    -- Base resource conversion factor in MWh/Resource.Unit
    conversion_factor REAL NOT NULL DEFAULT 0.0,
    -- Multiplier factor for the availability of the resource (dimensionless)
    resource_av_multiplier REAL NOT NULL DEFAULT 1.0,
    -- Multiplier factor for the cost of the resource (dimensionless)
    resource_cost_multiplier REAL NOT NULL DEFAULT 1.0,
    -- Additive factor to the cost of the resource, in $/Resource.Unit
    resource_cost_adder REAL NOT NULL DEFAULT 0.0,
    
    resource_id TEXT,
    conversion_id TEXT,
    benefit_curve_id TEXT,
    -- TODO Bodin comment: All foreign keys must be in the end of the table definition
    FOREIGN KEY(resource_id) REFERENCES Resource(id),
    FOREIGN KEY(conversion_id) REFERENCES ConversionCurve(id),
    FOREIGN KEY(benefit_curve_id) REFERENCES BenefitCurve(id)
);