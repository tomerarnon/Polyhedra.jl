export convexhull, convexhull!, conichull

const HAny{T} = Union{HRep{T}, HRepElement{T}}
const VAny{T} = Union{VRep{T}, VRepElement{T}}

"""
    intersect(P1::HRep, P2::HRep)

Takes the intersection of `P1` and `P2` ``\\{\\, x : x \\in P_1, x \\in P_2 \\,\\}``.
It is very efficient between two H-representations or between two polyhedron for which the H-representation has already been computed.
However, if `P1` (resp. `P2`) is a polyhedron for which the H-representation has not been computed yet, it will trigger a representation conversion which is costly.
See the [Polyhedral Computation FAQ](http://www.cs.mcgill.ca/~fukuda/soft/polyfaq/node25.html) for a discussion on this operation.

The type of the result will be chosen closer to the type of `P1`. For instance, if `P1` is a polyhedron (resp. H-representation) and `P2` is a H-representation (resp. polyhedron), `intersect(P1, P2)` will be a polyhedron (resp. H-representation).
If `P1` and `P2` are both polyhedra (resp. H-representation), the resulting polyhedron type (resp. H-representation type) will be computed according to the type of `P1`.
The coefficient type however, will be promoted as required taking both the coefficient type of `P1` and `P2` into account.
"""
function Base.intersect(p::HRep...)
    T = promote_coefficient_type(p)
    similar(p, hmap((i, x) -> convert(similar_type(typeof(x), T), x), FullDim(p[1]), T, p...)...)
end
Base.intersect(p::HRep, el::HRepElement) = p ∩ intersect(el)
Base.intersect(el::HRepElement, p::HRep) = p ∩ el

Base.intersect(hps::HyperPlane...) = hrep([hps...])
Base.intersect(hss::HalfSpace...) = hrep([hss...])
Base.intersect(h1::HyperPlane{T}, h2::HalfSpace{T}) where {T} = hrep([h1], [h2])
Base.intersect(h1::HalfSpace{T}, h2::HyperPlane{T}) where {T} = h2 ∩ h1
Base.intersect(p1::HAny{T}, p2::HAny{T}, ps::HAny{T}...) where {T} = intersect(p1 ∩ p2, ps...)
function Base.intersect(p::HAny...)
    T = promote_type(coefficient_type.(p)...)
    f(p) = convert(similar_type(typeof(p), T), p)
    intersect(f.(p)...)
end


"""
    intersect!(p::HRep, h::Union{HRepresentation, HRepElement})

Same as [`intersect`](@ref) except that `p` is modified to be equal to the intersection.
"""
function Base.intersect!(p::HRep, ::Union{HRepresentation, HRepElement})
    error("intersect! not implemented for $(typeof(p)). It probably does not support in-place modification, try `intersect` (without the `!`) instead.")
end
function Base.intersect!(p::Polyhedron, h::Union{HRepresentation, HRepElement})
    resethrep!(p, hrep(p) ∩ h)
end

"""
    convexhull(P1::VRep, P2::VRep)

Takes the convex hull of `P1` and `P2` ``\\{\\, \\lambda x + (1-\\lambda) y : x \\in P_1, y \\in P_2 \\,\\}``.
It is very efficient between two V-representations or between two polyhedron for which the V-representation has already been computed.
However, if `P1` (resp. `P2`) is a polyhedron for which the V-representation has not been computed yet, it will trigger a representation conversion which is costly.

The type of the result will be chosen closer to the type of `P1`. For instance, if `P1` is a polyhedron (resp. V-representation) and `P2` is a V-representation (resp. polyhedron), `convexhull(P1, P2)` will be a polyhedron (resp. V-representation).
If `P1` and `P2` are both polyhedra (resp. V-representation), the resulting polyhedron type (resp. V-representation type) will be computed according to the type of `P1`.
The coefficient type however, will be promoted as required taking both the coefficient type of `P1` and `P2` into account.
"""
function convexhull(p::VRep...)
    T = promote_coefficient_type(p)
    similar(p, vmap((i, x) -> convert(similar_type(typeof(x), T), x), FullDim(p[1]), T, p...)...)
end
convexhull(p::VRep, el::VRepElement) = convexhull(p, convexhull(el))
convexhull(el::VRepElement, p::VRep) = convexhull(p, el)

convexhull(ps::AbstractVector...) = vrep([ps...])
convexhull(ls::Line...) = vrep([ls...])
convexhull(rs::Ray...) = vrep([rs...])
convexhull(p::AbstractVector{T}, r::Union{Line{T}, Ray{T}}) where {T} = vrep([p], [r])
convexhull(r::Union{Line{T}, Ray{T}}, p::AbstractVector{T}) where {T} = convexhull(p, r)
convexhull(l::Line{T}, r::Ray{T}) where {T} = vrep([l], [r])
convexhull(r::Ray{T}, l::Line{T}) where {T} = convexhull(l, r)
convexhull(p1::VAny{T}, p2::VAny{T}, ps::VAny{T}...) where {T} = convexhull(convexhull(p1, p2), ps...)
function convexhull(p::VAny...)
    T = promote_type(coefficient_type.(p)...)
    f(p) = convert(similar_type(typeof(p), T), p)
    convexhull(f.(p)...)
end

"""
    convexhull!(p1::VRep, p2::VRep)

Same as [`convexhull`](@ref) except that `p1` is modified to be equal to the convex hull.
"""
function convexhull!(p::VRep, ine::VRepresentation)
    error("convexhull! not implemented for $(typeof(p)). It probably does not support in-place modification, try `convexhull` (without the `!`) instead.")
end
function convexhull!(p::Polyhedron, v::VRepresentation)
    resetvrep!(p, convexhull(vrep(p), v))
end

# conify: same than conichull except that conify(::VRepElement) returns a VRepElement and not a V-representation
conify(v::VRep) = vrep(lines(v), [collect(rays(v)); Ray.(collect(points(v)))])
conify(v::VCone) = v
conify(p::AbstractVector) = Ray(p)
conify(r::Union{Line, Ray}) = r

conichull(p...) = convexhull(conify.(p)...)

function sumpoints(::FullDim, ::Type{T}, p1, p2) where {T}
    _tout(p) = convert(similar_type(typeof(p), T), p)
    ps = [_tout(po1 + po2) for po1 in points(p1) for po2 in points(p2)]
    tuple(ps)
end
sumpoints(::FullDim, ::Type{T}, p1::Rep, p2::VCone) where {T} = change_coefficient_type.(preps(p1), T)
sumpoints(::FullDim, ::Type{T}, p1::VCone, p2::Rep) where {T} = change_coefficient_type.(preps(p2), T)

function Base.:+(p1::VRep{T1}, p2::VRep{T2}) where {T1, T2}
    T = typeof(zero(T1) + zero(T2))
    similar((p1, p2), FullDim(p1), T, sumpoints(FullDim(p1), T, p1, p2)..., change_coefficient_type.(rreps(p1, p2), T)...)
end
Base.:+(p::Rep, el::Union{Line, Ray}) = p + vrep([el])
Base.:+(el::Union{Line, Ray}, p::Rep) = p + el

# p1 has priority
function usehrep(p1::Polyhedron, p2::Polyhedron)
    hrepiscomputed(p1) && (!vrepiscomputed(p1) || hrepiscomputed(p2))
end

function hcartesianproduct(p1::HRep, p2::HRep)
    d = sum_fulldim(FullDim(p1), FullDim(p2))
    T = promote_coefficient_type((p1, p2))
    f = (i, x) -> zeropad(x, i == 1 ? FullDim(p2) : neg_fulldim(FullDim(p1)))
    similar((p1, p2), d, T, hmap(f, d, T, p1, p2)...)
end
function vcartesianproduct(p1::VRep, p2::VRep)
    d = sum_fulldim(FullDim(p1), FullDim(p2))
    T = promote_coefficient_type((p1, p2))
    # Always type of first arg
    f1 = (i, x) -> zeropad(x, FullDim(p2))
    f2 = (i, x) -> zeropad(x, neg_fulldim(FullDim(p1)))
    q1 = similar(p1, d, T, vmap(f1, d, T, p1)...)
    q2 = similar(p2, d, T, vmap(f2, d, T, p2)...)
    q1 + q2
end
cartesianproduct(p1::HRep, p2::HRep) = hcartesianproduct(p1, p2)
cartesianproduct(p1::VRep, p2::VRep) = vcartesianproduct(p1, p2)

function cartesianproduct(p1::Polyhedron, p2::Polyhedron)
    if usehrep(p1, p2)
        hcartesianproduct(p1, p2)
    else
        vcartesianproduct(p1, p2)
    end
end

"""
    *(p1::Rep, p2::Rep)

Cartesian product between the polyhedra `p1` and `p2`.
"""
Base.:(*)(p1::Rep, p2::Rep) = cartesianproduct(p1, p2)

"""
    \\(P::AbstractMatrix, p::HRep)

Transform the polyhedron represented by ``p`` into ``P^{-1} p`` by transforming each halfspace ``\\langle a, x \\rangle \\le \\beta`` into ``\\langle P^\\top a, x \\rangle \\le \\beta`` and each hyperplane ``\\langle a, x \\rangle = \\beta`` into ``\\langle P^\\top a, x \\rangle = \\beta``.
"""
Base.:(\)(P::AbstractMatrix, rep::HRep) = rep / P'

"""
    /(p::HRep, P::AbstractMatrix)

Transform the polyhedron represented by ``p`` into ``P^{-T} p`` by transforming each halfspace ``\\langle a, x \\rangle \\le \\beta`` into ``\\langle P a, x \\rangle \\le \\beta`` and each hyperplane ``\\langle a, x \\rangle = \\beta`` into ``\\langle P a, x \\rangle = \\beta``.
"""
function Base.:(/)(p::HRep{Tin}, P::AbstractMatrix) where {Tin}
    if size(P, 2) != fulldim(p)
        throw(DimensionMismatch("The number of rows of P must match the dimension of the H-representation"))
    end
    f = (i, h) -> h / P
    # FIXME For a matrix P of StaticArrays, `d` should be type stable
    d = size(P, 1)
    T = _promote_type(Tin, eltype(P))
    similar(p, d, T, hmap(f, d, T, p)...)
end

"""
    *(P::AbstractMatrix, p::VRep)

Transform the polyhedron represented by ``p`` into ``P p`` by transforming each element of the V-representation (points, symmetric points, rays and lines) `x` into ``P x``.
"""
function Base.:(*)(P::AbstractMatrix, p::VRep{Tin}) where {Tin}
    if size(P, 2) != fulldim(p)
        throw(DimensionMismatch("The number of rows of P must match the dimension of the V-representation"))
    end
    f = (i, v) -> P * v
    # For a matrix P of StaticArrays, `d` should be type stable
    d = size(P, 1)
    T = _promote_type(Tin, eltype(P))
    similar(p, d, T, vmap(f, d, T, p)...)
end
