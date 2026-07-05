## Description #############################################################################
#
# Functions to get variables from the database.
#
############################################################################################

export get_default_database, get_variable_description, search_variables
export @searchvar
export list_telemetry_databases, get_telemetry_database

"""
    get_default_database() -> Any

Get the default database. This function throws an error if it is not defined yet.
"""
function get_default_database()
    !isassigned(_DEFAULT_TELEMETRY_DATABASE) &&
        error("The default telemetry database has not been assigned.")

    return _DEFAULT_TELEMETRY_DATABASE[]
end

"""
    list_telemetry_databases() -> Vector{String}

List the labels of every telemetry database created so far. Useful when more than one
telemetry database is loaded at the same time (e.g. more than one mission), to find the
label to pass to [`get_telemetry_database`](@ref) or
[`set_default_telemetry_database!`](@ref).
"""
list_telemetry_databases() = sort(collect(keys(_TELEMETRY_DATABASE_REGISTRY)))

"""
    get_telemetry_database(label::AbstractString) -> TelemetryDatabase

Get the telemetry database registered with `label`. Throws an error listing the available
labels if none matches.
"""
function get_telemetry_database(label::AbstractString)
    haskey(_TELEMETRY_DATABASE_REGISTRY, label) || error(
        "No telemetry database registered with label \"$label\". " *
        "Available: $(list_telemetry_databases())."
    )

    return _TELEMETRY_DATABASE_REGISTRY[label]
end

"""
    get_variable_description(label::Symbol, database::TelemetryDatabase) -> TelemetryVariableDescription

Get the description of a variable with `label` in `database`. Notice that `label` can also
be the variable alias. If the variable is not found, the function returns `nothing`.
"""
function get_variable_description(label::Symbol, database::TelemetryDatabase)
    if haskey(database.variables, label)
        return database.variables[label]
    else
        for (k, v) in database.variables
            if v.alias == label
                return v
            end
        end
    end

    throw(KeyError(label))
end
