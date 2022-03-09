## radixsort constants 


"""
Limit for the number of LSB passes which are considered
superior to one MSB pass plus sort order verification and
subsorts with InsertionSort.

maybe 2 is too small. Needs benchmarking 
"""
SUPERIOR_LSB_PASSES = 2

"""
minimum of bits required für a meaningful sample.
1<<SAMPLE_BITS_MIN is the minimum required sample size.
"""
SAMPLE_BITS_MIN = 4



"""
minimum problem size to apply radix sort.
If less elements are to be sorted, use standard julia sort.

Not benchmarked so far.
"""
MIN_N_FOR_RADIX = 1<<(2*SAMPLE_BITS_MIN)

## radixsort and helpers, base integration

"""
number of significant bits for type T.

must have the property bucket(e::T,b,1)==0 for all e::T, b>=bitsizeof(T)

This default implementation here is valid for primitive types, 
and the default bucket implementation for those types.

User defined types like integers with a restricted value range
can define bitsizeof and bucket taking into account a priori
known value ranges and a compressed bit sequence. For example,
if UInt_1000_9999 is a user defined type with the integer 
value range 1000:9999, bitsizeof(UInt_1000_9999) could return 14.
    
If T is an AbstractArray subtype or String or BigInteger, 
the number of bits is not a priori restricted. this package will
not use bitsizeof for sorting arrays as elements.
"""
bitsizeof(::Type{T}) where T = (sizeof(T)*8) %UInt


"""
Type alias for an index in a permutation.

Julia inventors decided to use 1-based indexing :-(
But LLVM optimizes "someArray[our0basedIndex+1] :-)

For this (performance) reason, we could use offsets
(0-based index) for a permutation within the radix sort context.

Currently, a permutation is a standard julia (1-based) index

Currently, an index range of UInt32 seems to be sufficient. 
Maybe we need to change to UInt64 in a future, 
when 128 TByte RAM become entry server standard ...
"""
const PIndex  = UInt32
const Permutation = Vector{PIndex}




"""

    bucket(element, offset::UInt, bits::UInt) :: UInt32

returns a radix sort bucket: the value which is used to identify equal elements 
within a radix pass. Think of it as a bit sequence of length *bits*, 
starting at bit offset *offset*, from a bit sequence derived from *element* 
which has the same order properties.

In simple cases like UInt types, it is just a sequence of bits from the internal
memory representation of *element*. In other cases, *element* needs to be transformed 
before bits are extracted. 

To be exact, bucket must fulfil the following properties:

    value range property:
    0 <= bucket(element,offset,bits) < 1<<bits

    order property:
    e1 < e2 <===>  there exists an offset ox with the following properties
                   bucket(e1,ox,1)<bucked(e2,ox,1)
                   bucket(e1,o,1)==bucked(e2,o,1) for all 0 <= o <ox

    bit sequence property:
    bucket(e,o,b1)<<b1 + bucket(e,o+b1,b2) == bucket(e,o,b1+b2)
    for all 0<=o, 0<b1, 0<b2 b1+b2 <= 32


To radix sort an AbstractArray{T}, bucket(element::T,offset,bits) must have
a concrete method implementation, or an error is thrown. For all primitive types T
and for all types <: AbstractVector{E}, for a primitive type E, 
a default implementation is included in this package.

radix sort requires return type UInt32, so bits must be <= 32. This strong typing
allows for simple 

This restriction

"""
function bucket(element, offset::UInt, bits::UInt) :: UInt
    error("bucket not yet implemented for element type "*string(typeof(element)))
end

# we cannot use Unsigned instead of that Union, because user defined subtypes of Unsigned might exist
function bucket(e::T, offset::UInt, bits::UInt) where T <: Union{UInt8,UInt16,UInt32,UInt64,UInt128} 
    (e<<offset)>>>(bitsizeof(T)-bits) %UInt
end

function bucket(e::T, offset::UInt, bits::UInt) where T <: Union{Int8,Int16,Int32,Int64,Int128} 
    bucket(unsigned(xor(e,typemin(T))),offset,bits)
end


function bucket(e::A, offset::UInt, bits::UInt) where A <: AbstractArray{T} where T 
    bucket(unsigned(xor(e,typemin(T))),offset,bits)
end




function radixsort(data::AbstractArray{T}) where T
end



function radixsort(data::AbstractArray{T}) where T
end



function radixsort(data::AbstractArray{T}) where T
end


"""
central radix sort method, for internal use.

Returns the sorted permutation, either perm or perm2.


data: data to sort

perm: index permutation to be used for sorting, defined at least for pfirst:pend-1.
The values in this range are reordered in sorted order

perm2: 2nd permutation. Either ===perm (inplace unstable sort) or an array 
of same size and identical values outside index range pfirst:plast, used for reordering
in the stable sort variant.

pfirst: index in permutation of 1st element to sort

pend: index in permutation of first element NOT to sort

amin: apriori minimum for bucket(e,0,bitsizeof(UInt)),
a lower limit known from type construction or application context
which is guaranteed. The minimum of the concrete data to sort
can be larger. 0 is a valid value, larger values can speed up
sorting. 

amax: apriori maximum for bucket(e,0,bitsizeof(UInt)), the
maximum of the concrete data to sort can be smaller.
typemax(UInt) is a valid value, smaller values can speed up
sorting. 


Preconditions:

 - bucket(data[perm[pstart:pend],0,bitoffset) is constant (preceding passes)

 - 

"""
function radixsort0(data::AbstractArray{T}, perm::Permutation,perm2::Permutation,pfirst::PIndex,pend::PIndex,amin::UInt,amax::UInt) where T :: Permutation
    #test special cases
    n = pend-pfirst # no. of elements to sort
    if n < MIN_N_FOR_RADIX
        if perm===perm2
            sort!(perm,lo,hi,QuickSort,)
        else
    end


    tbits :: UInt = typemax(UInt) # default: assume "infinity"
    if T <: Union{AbstractArray,AbstractString}
    else
        tbits = bitsizeof(T)
    end
    n = pend-pfirst # no. of elements to sort
    nbits = bitsizeof(type(n))- leadingzeroes(n)
    if SUPERIOR_LSB_PASSES*nbits >= tbits-leading_zeroes(amax-amin)
        # we can sort efficiently in a few LSB radix passes
    else
        # problem large enough for sampling?
        sbits = nbits >>> 1 # do sampling with about sqrt(n) elements.
        if sbits < SAMPLE_BITS_MIN
            # problem too small for sampling.
            # use a comparing sort algorithmlibrary 
    end

end





