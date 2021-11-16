
struct OptimizationResultCacheKey
    model::Symbol
    key::OptimizationContainerKey
end

# Priority for keeping data in cache to serve reads. Currently unused.
IS.@scoped_enum(CachePriority, LOW = 1, MEDIUM = 2, HIGH = 3,)

struct CacheFlushRule
    keep_in_cache::Bool
    priority::CachePriority
end

CacheFlushRule() = CacheFlushRule(false, CachePriority.LOW)

"""
Informs the flusher on what data to keep in cache.
"""
struct CacheFlushRules
    data::Dict{OptimizationResultCacheKey, CacheFlushRule}
    min_flush_size::Int
    max_size::Int
end

const MIN_CACHE_FLUSH_SIZE_MiB = MiB

function CacheFlushRules(; max_size = GiB, min_flush_size = MIN_CACHE_FLUSH_SIZE_MiB)
    return CacheFlushRules(
        Dict{OptimizationResultCacheKey, CacheFlushRule}(),
        min_flush_size,
        max_size,
    )
end

function add_rule!(
    rules::CacheFlushRules,
    model_name,
    op_container_key,
    keep_in_cache,
    priority,
)
    key = OptimizationResultCacheKey(model_name, op_container_key)
    rules.data[key] = CacheFlushRule(keep_in_cache, priority)
end

function get_rule(x::CacheFlushRules, model, op_container_key)
    return get_rule(x, OptimizationResultCacheKey(model, op_container_key))
end

get_rule(x::CacheFlushRules, key::OptimizationResultCacheKey) = x.data[key]

mutable struct CacheStats
    hits::Int
    misses::Int
end

CacheStats() = CacheStats(0, 0)

function get_cache_hit_percentage(x::CacheStats)
    total = x.hits + x.misses
    total == 0 && return 0.0
    return x.hits / (total) * 100
end
