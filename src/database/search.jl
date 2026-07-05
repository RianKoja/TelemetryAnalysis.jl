## Description #############################################################################
#
# Function to search variables in the database.
#
############################################################################################

"""
    search_variables(pattern::T, database::TelemetryDatabase = get_default_database(); all::Bool = false) where T<:Union{AbstractString, Regex} -> Nothing

Search for variables registered in `database` in which their label, alias, or description
contains `pattern`. `pattern` can be a string or a regex.

!!! note

    If `pattern` is a string, the search will be case-insensitive.

!!! note

    If `database` is not provided, the default one is used.

If `all` is `true`, `database` is ignored and every registered telemetry database (see
[`list_telemetry_databases`](@ref)) is searched in turn, each preceded by its label.
"""
function search_variables(
    pattern::T,
    database::TelemetryDatabase = get_default_database();
    all::Bool = false
) where T<:Union{AbstractString, Regex}
    if all
        for label in list_telemetry_databases()
            println(label, ":")
            search_variables(pattern, _TELEMETRY_DATABASE_REGISTRY[label])
            println()
        end
        return nothing
    end

    # Prepare the crayons to highlight the output if `stdout` supports it.
    hascolor = get(stdout, :color, false)
    cr = (hascolor ? string(crayon"reset")       : "")
    cy = (hascolor ? string(crayon"yellow bold") : "")
    cc = (hascolor ? string(crayon"cyan")        : "")

    # Vector to store the keys of the variables that matches the search pattern.
    varnames = Symbol[]

    # Check if the comparison must be case-insensitive.
    if pattern isa AbstractString
        case_insensitive = true
        pattern = lowercase(pattern)
    else
        case_insensitive = false
    end

    # Search the variables.
    for (k, v) in database.variables
        label_str = case_insensitive ? lowercase(String(k)) : String(k)

        alias_str = if !isnothing(v.alias)
            case_insensitive ? lowercase(String(v.alias)) : String(v.alias)
        else
            ""
        end

        desc_str = if !isnothing(v.description)
            case_insensitive ? lowercase(v.description) : v.description
        else
            ""
        end

        label_match = contains(label_str, pattern)
        alias_match = contains(alias_str, pattern)
        desc_match  = contains(desc_str,  pattern)

        (label_match || alias_match || desc_match) && push!(varnames, k)
    end

    if !isempty(varnames)
        # Let's sort the names.
        sort!(varnames)

        matrix = hcat(
            map(v -> begin
                alias = database.variables[v].alias
                out = string(v)

                if !isnothing(alias)
                    out *= " (" * String(alias) * ")"
                end

                return out
            end, varnames),
            map(v -> database.variables[v].description, varnames)
        )

        hl1 = TextHighlighter((data, i, j) -> j == 1, crayon"yellow bold")

        table_format = TextTableFormat(
            ;
            @text__no_horizontal_lines,
            @text__no_vertical_lines,
            horizontal_line_after_column_labels = true,
            suppress_vertical_lines_at_column_labels = false,
            vertical_lines_at_data_columns = [1]
        )

        pretty_table(
            matrix;
            alignment                         = [:r, :l],
            column_labels                     = ["Variable Label", "Description"],
            fit_table_in_display_horizontally = true,
            highlighters                      = [hl1],
            table_format                      = table_format
        )

    else
        println("No variable was found!")

    end

    return nothing
end

"""
    search_variables(pattern, label::AbstractString) -> Nothing

Search for variables in the telemetry database registered with `label` (see
[`list_telemetry_databases`](@ref)).
"""
function search_variables(pattern::T, label::AbstractString) where T<:Union{AbstractString, Regex}
    return search_variables(pattern, get_telemetry_database(label))
end

"""
    @searchvar(pattern)
    @searchvar(pattern, database)

Search variables in `database` (a `TelemetryDatabase`, or the label of a registered one) in
which their label, alias, or description contains `pattern`. If `database` is omitted, the
default database is used. For more information, see [`search_variables`](@ref).
"""
macro searchvar(pattern)
    if (pattern isa Symbol)
        str = "$pattern"
    else
        str = pattern
    end

    return esc(:(search_variables($str)))
end

macro searchvar(pattern, database)
    if (pattern isa Symbol)
        str = "$pattern"
    else
        str = pattern
    end

    return esc(:(search_variables($str, $database)))
end
