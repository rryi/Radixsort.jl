# Radixsort

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://rryi.github.io/Radixsort.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://rryi.github.io/Radixsort.jl/dev)
[![Build Status](https://travis-ci.com/rryi/Radixsort.jl.svg?branch=master)](https://travis-ci.com/rryi/Radixsort.jl)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/rryi/Radixsort.jl?svg=true)](https://ci.appveyor.com/project/rryi/Radixsort-jl)
[![Build Status](https://api.cirrus-ci.com/github/rryi/Radixsort.jl.svg)](https://cirrus-ci.com/github/rryi/Radixsort.jl)
[![Coverage](https://codecov.io/gh/rryi/Radixsort.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/rryi/Radixsort.jl)


## Usage Scenario: almost all sorting tasks, including strings, vectors and user defined data types

This package publishes a new sorting algorithm,  based on "radix sort", which has the central property of a computing complexity of O(N) for sorting N elements of an array, in contrast to O(N*log(N)) which is the best possible complexity for sorting algorithms which are based on comparisons (for an in-depth O(...) discussion, see below). 

It is applicable out-of-the box to all Julia predefined primitive types, Julia Strings and all vectors of Julia primitive types. This covers most scenarios for sorting in "natural order". For user defined data types, some methods need to be implemented to support sorting with this radix sort variant.

Strings are sorted lexicographically by code units, in UTF8 code order. For many human languages, this is probably not what the application needs: it regards capitalized letters as smaller than the noncapitalized variant, e.g. "A" < "a", and many human languages have nonascii letters, which all have unicode codes above 127, but often are considered similar to some ascii characters. E. g. for German, letters like "ä", "ß" are regarded variants of "a", "s" or equivalent with respect to sorting order to "ae", "ss" (see DIN 5007). To correctly apply such sort order rules, the strings to sort need to be transformed into strings which can be sorted in natural order (lexicographically, per UTF8 code unit).

Vectors (more precisely: subtypes of AbstractVector{T}) are sorted lexicographically, with the natural sort order of the vector elements of type T.


## Performance

Performance is a key criterion for sort algorithm selection. Radix sort (and in particular, this implementation), does not only has an excellent theoretical compute complexity. Its superiority is evidenced by benchmarks, see [work in progress].


## Stable and Unstable Sort

A sort algorithm is called stable, if the original sequence of equal elements is not changed. 
This implementation has stable and unstable variants. Stable sorting requires more working storage 
and is less performant in many cases.


## Radix Sort Basics

Consider we have a Vector{T} to sort of length N, with T some unsigned integer type. M denotes the cardinality of T, typemax(T)-typemin(T)+1.

Radix sort sorts it by first counting the frequency for every possible value of T (a loop over N), then computes the position of the 1st element for every value of T in the sorted array (loop over M) and then reorderes the elements (loop over N). Computing complexity is then O(N)+O(M), or O(N) for a fixed T. 

For M < N, radix sort is super fast and beats all comparison based sorting argorithms.

For M > N, efficiency degradates. And for an infinite M (like sorting strings or arrays), basic radix sort is not applicable. 

If M is finite but huge, compared to N, one can still apply radix sort, to only the first m significant bits of the elements to sort. This gives 2^m "buckets" of elements which have identical values, with respect to the m most significant bits. The vector of elements is partly sorted: for two buckets i,j with i < j, all elements in bucket i are less than all elements in bucket j. The start end end index per bucket is known from the reordering loop. We have now 2^m sorting tasks, but the element count per task is much smaller. If 2^m > N, we can even arrive a a state where (almost) all buckets contain only 0 or 1 element, and we are done. This will happen if elements are aequidistantly distributed over T. If they are (mostly) uniform distributed, there will be some but few buckets with more than 1, but very few elements. Those buckets can be efficiently sorted by a classical sort algorithm. If the values are not uniformly distributed, there may be buckets with lots of elements, to those buckets a 2nd radix sort pass could make sense. This approach is called MSB radix sort.

Another idea is to apply radix sort the the m least significant m bits first, then re-sort the whole array of elements by the next least significant m mits, and so forth, until after p passes, we arrive at 2^(m\*p) > N and have resorted every bit in some pass. Provided that every radix sort pass is a stable sort, we arrive at a completely sorted array of elements. This is called LSB radix sort. It has a compute complexity of O(N\*log(M)). Like the basic radix sort, it needs no comparisons at all, making it very 
attractive in cases where M is some magnitudes larger than N, but log(M) is small, compared to N. 

## MSB Radix sort with uniformity indicator

The following analysis is considered a new approach - if anyone knows it was already published, please tell me.

Lets look at the overall effort of doing one MSB radix pass using m bits, followed by a pass using bubblesort. After the radix pass, we have 2^m buckets. The effort for the 2nd pass is per bucket a comparison on the bucket count and a subsort if the count exceeds 1. For k elements in the bucket, it has bubblesort worst case complexity O(k^2). 

Regard the elements to sort as a sample of a discrete random variable x with values in T, and look at the probability that x has the value e: p(x=e). Let-s examine the case of a uniform distribution: p(x=e) = 1/M. For simplicity, assume further that M is a power of 2. The scenario further assumes that M is huge, compared to N: if M < N^2, doing LSB radix sort with 2 passes is expected to be superior. A consequence is, that the width of a bucket is always > 1, so we need a subsort for buckets with count>1

The buckets using a MSB radix pass with m bits all have the width M/2^m. p(x in bucket) is (M/2^m)\*1/m = 1/2^m. The number k of elements found in the bucket follows the Bernoulli distribution B(k| 1/2^m, N). 

Lets assume the list to sort is drawn from a random variable x which is uniformly distributed over T. For simplicity, assume further that M is a power of 2. We have p(x=e) = 1/M for all e in T (uniform distribution). We apply a radix pass to the most significant m bits and examine the distribution of the number of elements found in a bucket. A bucket has a width of M/(2^m) elements, p(x in bucket) = 1/M\*(M/2^m)= 1/2^m. The number k of elements found in the bucket follows the Bernoulli distribution B(k| 1/2^m, N). 

The overall effort is bounded by cost(m,N) = C1\*N + C2*(2^m)\*(1+SUM(k=2..N,C3\*k^2*B(k|1/2^m,N))).

C1 covers the counting step and reordering step of the radix pass. Its operations are
 - array initialization of the permutation array: set int array element
 - access to sort element: get array element, some bit shift/mask operations
 - increment count array element: read/write an int array element
 - assign permutation array element: write an int array element

C2 covers count array initialization, summing up, and comparison of the bucket size
 - assign 0 to count array element
 - add count[i] to count[i+1] (before the reordering loop)
 - compare count[i] to count[i+1]

C3 covers a step in a bubblesort pass
 - access to sort element
 - compare two elements (maybe very expensive, e.g. string sort)
 - swap permutation entries (2 int array element assignments)

I expect C2 < C1 < C3. 
C1 and C3 are dependent on type T. 
Assume we have measured C1, C2, C3 by benchmarking, we start with m=Int(log2(N)) and increase m as long as cost(m,N) decreases.

A uniform distribution is the best case for this approach: it has the lowest probability for high worst case bucket count. What about other distributions? We will derive a simple upper limit for cost(m,N): 

Again assume we know the distribution of elements over T. The discrete density p(x=e) is not constant any more, it varies with e. We measure the uniformity of the distribution by `UI = 1/M*max(e in T, p(e))`. The higher UI, the lower the uniformity is. The probability for an element e to be found in a bucket (worst case) is `(UI/M)\*M/2^m = UI/2^m`. Using this probability for the cost function, we arrive at `cost(m,N) = C1\*N + C2*(2^m)\*(1+SUM(k=2..N,C3\*k^2*B(k|UI/2^m,N)))`.

Last but most difficult question: how do we estimate UI? We use a very simple, but highly heuristic approach: we draw a random sample of size s from the elements to sort, build s buckets of equal width and estimate UI by the maximum bucket count. The idea: we hope that the element distribution is "locally uniform" within the sample buckets. There is no evidence for it, it is just a heuristic approach. For a counter example, think of sorting uniformly distributed elements, except N/s values which are constant. The correct UI is near N/s, the estimate is near 1. Of course, we can improve the estimate if we increase s, arriving at the exact value for s=N - but then, the sampling effort is in the range of a radix pass with m=log2(N) bits.




Assume we have measured C1, C2, C3 by benchmarking, we start with m=Int(log2(N)) and increase m as long as cost(m,N) decreases.


strings which are univormlywith a fraction % of them having the same 32 bit , distrubute it over s  of size


The chosen approach is highly heuristic: it is easy to find examples where UI is terribly underestimated. But here is it: we use the UI of a small sample


We can use this value in the cost functionthe worst caseof For the worst case bucket, we can assume  UI=1 for a uniform distribution Let pmax be the  will increase, Clearly, the optimal m will increaseBut we can easily derive a worst case limit for cost(m,N) 

```

```
I expect C1>C2: a counting step is C1 includes 

We are examining the case M much larger than N, so that LSB radix sort needs many passes. We further assume M > N^3. 



Lets have a look at the case we know the elements to sort are uniformly distributed over T. This means p(e)=1/M for e in Tp(e)of 
The new idea this implementation is based upon, is the use of a "uniformity indicator" for the distribution of elements to sort. 

Assume the best case, a uniform distribution. 

If we have a uniform distribution of elements over T, and apply MSB radix sort to m bits with 2^m > N, we arrive at buckets, almost all having 0 or 1 element to sort. 



The less uniform the distribution of elements is, the higher is the expected element count in some buckets. If we had a "uniformity indicator" saying how many elements we have to expect in the bucket with the most elements, we could simply increase m so much, that the probability for a bucket to contain more than 1 different elements gets extremely small (it jumps to 0 when 2^m>=M). Because we talk about probabilities, we still have to check for this case and need to apply a 2nd pass for found cases. 

How do we compute the "uniformity indicator"? Assume we know the distribution of elements to sort a priori. From it, we can derive the discrete density d(e), the probability that a randomly chosen element e of type T has value e. With dmax as maximum over all d(e), we have a simple upper limit for the number of expected elements of a bucket: N\*dmax\*bucketWidth, with bucketWidth the number of integers which are classified by the bucket. Applying radix sort to the m most significant bits, we have a bucket width of M/(2^m). To assure that at most 1 element is expected in a bucket. we solve N\*dmax\*M/(2^m) = 1, and arrive at m=log2(N\*dmax\*M).


expected element count for the biggest bucket is lowered to 1. This is the central new idea for the radix sort implementation in this package. We have a MSB radis pass, followed by a check loop over the buckets, in almost all cases the element count is 1 or 0 and we are done. For the few remaining cases, we apply a classic sort procedure.

How to we compute the "uniformity indicator"? Assume we know the distribution of elements to sort a priori. From it, we can derive the discrete density d(e), the probability that a randomly chosen element e of type T has value e. With dmax as maximum over all d(e), we have a simple upper limit for the number of expected elements of a bucket: N\*dmax\*bucketWidth, with bucketWidth the number of integers which are classified by the bucket. Applying radix sort to the m most significant bits, we have a bucket width of M/(2^m). To assure that at most 1 element is expected in a bucket. we solve N\*dmax\*M/(2^m) = 1, and arrive at m=log2(N\*dmax\*M).

If the distribution is not known, we use a random sample from the elements to sort, compute its distribution and have an estimate of dmax. This is the approach used in the implementation. 

If uniformity is very weak, we may arrive at a m with 2^m is huge, compared to N. In this case, we apply LSB radix sort to the m most significant bits. Assume we have p LSB radix passes, every pass with m/p bits. After the last LSB pass, we have 2^(m/p) buckets which are sorted according to the m most significant bits of the elements. If we had done these passes as MSB radix sort passes, we would get the same sequence of elements, and in the last MSB pass, bucket size would be almost always 1 or 0. So, we expect, that the elements are finally sorted. But there might be a bucked in the last MSB pass having 2 or more elements which are out of order. It is unlikely, but we have to check.

Due to the applied LSB passes, we do not have access to those final buckets of MSB passes. No problem. Remember there is another well known sort algorithm, having O(N) complexity in special cases: bubblesort. If a list is already sorted, bubblesort exits after one pass. We apply bubblesort to the buckets of the last LSB pass. The worst case is, that there is a bucket of the hypothetical last MSB pass with k elements in inverse order. It is located in one of the buckets of the last LSB pass. bubblesoft for this bucket will then need k passes, to establish the correct order. The case is very unlikely, ant not that expensive: the number of elements is far below N.

## sorting elements of type T with infinite cardinality (strings, vectors)

MSB radix sort is applicable to data types of extreme or even infinite cardinality, in contrast to LSB radix sort. The uniformity indicator allows to significantly reduce the number of bits needed for the radix sort part, and to verify correctness with usually one bubblesort pass. 

## outlier optimization

A common case is that only a small fraction of the value range of T does occur in the array to sort. We could compute min and max over all elements and restrict radix sort to the subtype T' with cardinality M' = max-min+1. This is done in many radix sort implementations, it can significantly reduce M to M', the number of buckets. 

It has two weak points: it requires an additional pass of complexity O(N), and it might turn out that a few outliers exist, which result in a still very large M', so that the benefit of using T' instead of T is overcompensated by the effort to calculate min and max.

I propose a different approach: together with the sampling to estimate dmax, we can easily compute smin and smax, the sample minimum and maximum. If smax-smin is already of the magnitude of M, we can dismiss the exact computation of min and max. And we get even more information from the sample: we can check if there exists values omin, omax which are condidered "minimum and maximum, except very few outliers" with the property that omax-omin is orders of magnitude smaller than smax-smin. We can then apply radix sort to the element range omin:omax, leaving out outliers, and sort those outliers separately. 

In the implementation here, this aproach is applied, however it uses simple heuristic decision rules and is considered experimental.

