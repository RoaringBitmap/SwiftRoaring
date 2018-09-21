import croaring

/**
* This class contains different values about a given RoaringBitmap
*/
public typealias RoaringStatistics = roaring_statistics_t

/**
* Swift wrapper for CRoaring (a C/C++ implementation at https://github.com/RoaringBitmap/CRoaring)
*/
public class RoaringBitmap: Sequence {
    var ptr: UnsafeMutablePointer<roaring_bitmap_t>
    
    /////////////////////////////////////////////////////////////////////////////
    ///                             CONSTRUCTORS                              ///
    /////////////////////////////////////////////////////////////////////////////
    /**
    * Creates a new bitmap (initially empty)
    */
    public init() {
        self.ptr = croaring.roaring_bitmap_create()!
    }

    /**
    * Creates a new bitmap using a given ptr
    */
    public init(ptr: UnsafeMutablePointer<roaring_bitmap_t>) {
        self.ptr = ptr
    }

    /**
    * Add all the values between min (included) and max (excluded) that are at a
    * distance k*step from min.
    */
    public init(min: UInt64, max: UInt64, step: UInt32) {
        self.ptr = croaring.roaring_bitmap_from_range(min, max, step)!
    }

    /**
    * Creates a new bitmap (initially empty) with a provided
    * container-storage capacity (it is a performance hint).
    */
    public init(capacity: UInt32) {
        self.ptr = croaring.roaring_bitmap_create_with_capacity(capacity)!
    }

    /**
    * Creates a new bitmap from a pointer of uint32_t integers
    */
    public init(values: [UInt32]) {
        let ptr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: values)
        self.ptr = croaring.roaring_bitmap_of_ptr(values.count, ptr)!
    }
    
    deinit {
        self.free()
    }
    

    /////////////////////////////////////////////////////////////////////////////
    ///                             OPERATORS                                 ///
    /////////////////////////////////////////////////////////////////////////////

    /**
    * Computes the intersection between two bitmaps and returns new bitmap. The
    * caller is
    * responsible for memory management.
    *
    */
    public func and(_ x: RoaringBitmap) -> RoaringBitmap {
        let x2 = RoaringBitmap(ptr: croaring.roaring_bitmap_and(self.ptr, x.ptr))
        return x2
    }
    /**
    * Computes the intersection between two bitmaps and returns new bitmap. The
    * caller is
    * responsible for memory management.
    *
    */
    public static func &(left: RoaringBitmap, right: RoaringBitmap) -> RoaringBitmap{
        return left.and(right)
    }

    /**
    * Inplace version modifies x1, x1 == x2 is allowed
    */
    public func andInplace(_ x: RoaringBitmap) {
        croaring.roaring_bitmap_and_inplace(self.ptr, x.ptr)

    }
    /**
    * Inplace version modifies x1, x1 == x2 is allowed
    */
    public static func &=(left: RoaringBitmap, right: RoaringBitmap){
        left.andInplace(right)
    }

    /**
    * Computes the size of the intersection between two bitmaps.
    *
    */
    public func andCardinality(_ x: RoaringBitmap) -> UInt64 {
        return croaring.roaring_bitmap_and_cardinality(self.ptr, x.ptr)

    }

    /**
    * Check whether two bitmaps intersect.
    *
    */
    public func intersect(_ x: RoaringBitmap) -> Bool {
        return croaring.roaring_bitmap_intersect(self.ptr, x.ptr)

    }

    /**
    * Computes the Jaccard index between two bitmaps. (Also known as the Tanimoto
    * distance,
    * or the Jaccard similarity coefficient)
    *
    * The Jaccard index is undefined if both bitmaps are empty.
    *
    */
    public func jaccardIndex(_ x: RoaringBitmap) -> Double {
        return croaring.roaring_bitmap_jaccard_index(self.ptr, x.ptr)

    }

    /**
    * Computes the size of the union between two bitmaps.
    *
    */
    public func orCardinality(_ x: RoaringBitmap) -> UInt64 {
        return croaring.roaring_bitmap_or_cardinality(self.ptr, x.ptr)

    }

    /**
    * Computes the size of the difference (andnot) between two bitmaps.
    *
    */
    public func andNotCardinality(_ x: RoaringBitmap) -> UInt64 {
        return croaring.roaring_bitmap_andnot_cardinality(self.ptr, x.ptr)

    }

    /**
    * Computes the size of the symmetric difference (andnot) between two bitmaps.
    *
    */
    public func xorCardinality(_ x: RoaringBitmap) -> UInt64 {
        return croaring.roaring_bitmap_xor_cardinality(self.ptr, x.ptr)

    }

    /**
    * Computes the union between two bitmaps and returns new bitmap. The caller is
    * responsible for memory management.
    */
    public func or(_ x: RoaringBitmap) -> RoaringBitmap {
        let x2 = RoaringBitmap(ptr: croaring.roaring_bitmap_or(self.ptr, x.ptr))
        return x2

    }
    /**
    * Computes the union between two bitmaps and returns new bitmap. The caller is
    * responsible for memory management.
    */
    public static func |(left: RoaringBitmap, right: RoaringBitmap) -> RoaringBitmap{
        return left.or(right)
    }

    /**
    * Inplace version of roaring_bitmap_or, modifies x1. TDOO: decide whether x1 ==
    *x2 ok
    *
    */
    public func orInplace(_ x: RoaringBitmap) {
        croaring.roaring_bitmap_or_inplace(self.ptr, x.ptr)

    }
    /**
    * Inplace version of roaring_bitmap_or, modifies x1. TDOO: decide whether x1 ==
    *x2 ok
    *
    */
    public static func |=(left: RoaringBitmap, right: RoaringBitmap){
        left.orInplace(right)
    }

    /**
    * Compute the union of 'number' bitmaps. See also roaring_bitmap_or_many_heap.
    * Caller is responsible for freeing the
    * result.
    *
    */
    public func orMany(_ xs: [RoaringBitmap]) -> RoaringBitmap {
        var ptrArray: [UnsafePointer<roaring_bitmap_t>?] = []
        for x in xs {
            ptrArray.append(x.ptr)
        }
        ptrArray.append(self.ptr)
        let ptrArrayPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: ptrArray)
        return RoaringBitmap(ptr: croaring.roaring_bitmap_or_many(ptrArray.count, ptrArrayPtr))

    }

    /**
    * Compute the union of 'number' bitmaps using a heap. This can
    * sometimes be faster than roaring_bitmap_or_many which uses
    * a naive algorithm. Caller is responsible for freeing the
    * result.
    *
    */
    public func orManyHeap(_ xs: [RoaringBitmap]) -> RoaringBitmap {
        var ptrArray: [UnsafePointer<roaring_bitmap_t>?] = []
        for x in xs {
            ptrArray.append(x.ptr)
        }
        ptrArray.append(self.ptr)
        let ptrArrayPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: ptrArray)
        return RoaringBitmap(ptr: croaring.roaring_bitmap_or_many_heap(UInt32(ptrArray.count), ptrArrayPtr))

    }

    /**
    * Computes the symmetric difference (xor) between two bitmaps
    * and returns new bitmap. The caller is responsible for memory management.
    */
    public func xor(_ x: RoaringBitmap) -> RoaringBitmap {
        let x2 = RoaringBitmap(ptr: croaring.roaring_bitmap_xor(self.ptr, x.ptr))
        return x2

    }
    /**
    * Computes the symmetric difference (xor) between two bitmaps
    * and returns new bitmap. The caller is responsible for memory management.
    */
    public static func ^(left: RoaringBitmap, right: RoaringBitmap) -> RoaringBitmap{
        return left.xor(right)
    }

    /**
    * Inplace version of roaring_bitmap_xor, modifies x1. x1 != x2.
    *
    */
    public func xorInplace(_ x: RoaringBitmap) {
        croaring.roaring_bitmap_xor_inplace(self.ptr, x.ptr)

    }
    /**
    * Inplace version of roaring_bitmap_xor, modifies x1. x1 != x2.
    *
    */
    public static func ^=(left: RoaringBitmap, right: RoaringBitmap){
        left.xorInplace(right)
    }

    /**
    * Compute the xor of 'number' bitmaps.
    * Caller is responsible for freeing the
    * result.
    *
    */
    public func xorMany(_ xs: [RoaringBitmap]) -> RoaringBitmap {
        var ptrArray: [UnsafePointer<roaring_bitmap_t>?] = []
        for x in xs {
            ptrArray.append(x.ptr)
        }
        ptrArray.append(self.ptr)
        let ptrArrayPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: ptrArray)
        return RoaringBitmap(ptr: croaring.roaring_bitmap_xor_many(ptrArray.count, ptrArrayPtr))

    }


    /**
    * Computes the  difference (andnot) between two bitmaps
    * and returns new bitmap. The caller is responsible for memory management.
    */
    public func andNot(_ x: RoaringBitmap) -> RoaringBitmap {
        let x2 = RoaringBitmap(ptr: croaring.roaring_bitmap_andnot(self.ptr, x.ptr))
        return x2

    }
    /**
    * Computes the  difference (andnot) between two bitmaps
    * and returns new bitmap. The caller is responsible for memory management.
    */
    public static func -(left: RoaringBitmap, right: RoaringBitmap) -> RoaringBitmap{
        return left.andNot(right)
    }

    /**
    * Inplace version of roaring_bitmap_andnot, modifies x1. x1 != x2.
    *
    */
    public func andNotInplace(_ x: RoaringBitmap) {
        croaring.roaring_bitmap_andnot_inplace(self.ptr, x.ptr)

    }
    /**
    * Inplace version of roaring_bitmap_andnot, modifies x1. x1 != x2.
    *
    */
    public static func -=(left: RoaringBitmap, right: RoaringBitmap){
        left.andNotInplace(right)
    }

    /**
    * Return true if the two bitmaps contain the same elements.
    */
    public func equals(_ x: RoaringBitmap) -> Bool {
        return croaring.roaring_bitmap_equals(self.ptr, x.ptr)

    }
    /**
    * Return true if the two bitmaps contain the same elements.
    */
    public static func ==(left: RoaringBitmap, right: RoaringBitmap) -> Bool{
        return left.equals(right)
    }
    /**
    * Return true if the two bitmaps DO NOT contain the same elements.
    */
    public static func !=(left: RoaringBitmap, right: RoaringBitmap) -> Bool {
        return !(left == right)
    }

    /**
    * Return true if all the elements of ra1 are also in ra2.
    */
    public func isSubset(_ x: RoaringBitmap) -> Bool {
        return croaring.roaring_bitmap_is_subset(self.ptr, x.ptr)

    }

    /**
    * Return true if all the elements of ra1 are also in ra2 and ra2 is strictly
    * greater
    * than ra1.
    */
    public func isStrictSubset(_ x: RoaringBitmap) -> Bool {
        return croaring.roaring_bitmap_is_strict_subset(self.ptr, x.ptr)

    }

    /**
    * (For expert users who seek high performance.)
    *
    * Computes the union between two bitmaps and returns new bitmap. The caller is
    * responsible for memory management.
    *
    * The lazy version defers some computations such as the maintenance of the
    * cardinality counts. Thus you need
    * to call roaring_bitmap_repair_after_lazy after executing "lazy" computations.
    * It is safe to repeatedly call roaring_bitmap_lazy_or_inplace on the result.
    * The bitsetconversion conversion is a flag which determines
    * whether container-container operations force a bitset conversion.
    **/
    public func lazyOr(_ x: RoaringBitmap, bitsetconversion: Bool) -> RoaringBitmap {
        let x2 = RoaringBitmap(ptr: croaring.roaring_bitmap_lazy_or(self.ptr, x.ptr, bitsetconversion))
        return x2

    }

    /**
    * (For expert users who seek high performance.)
    * Inplace version of roaring_bitmap_lazy_or, modifies x1
    * The bitsetconversion conversion is a flag which determines
    * whether container-container operations force a bitset conversion.
    */
    public func lazyOrInplace(_ x: RoaringBitmap, bitsetconversion: Bool) {
        croaring.roaring_bitmap_lazy_or_inplace(self.ptr, x.ptr, bitsetconversion)

    }

    /**
    * (For expert users who seek high performance.)
    *
    * Execute maintenance operations on a bitmap created from
    * roaring_bitmap_lazy_or
    * or modified with roaring_bitmap_lazy_or_inplace.
    */
    public func repairAfterLazy() {
        croaring.roaring_bitmap_repair_after_lazy(self.ptr)

    }

    /**
    * Computes the symmetric difference between two bitmaps and returns new bitmap.
    *The caller is
    * responsible for memory management.
    *
    * The lazy version defers some computations such as the maintenance of the
    * cardinality counts. Thus you need
    * to call roaring_bitmap_repair_after_lazy after executing "lazy" computations.
    * It is safe to repeatedly call roaring_bitmap_lazy_xor_inplace on the result.
    *
    */
    public func lazyXor(_ x: RoaringBitmap) -> RoaringBitmap {
        let x2 = RoaringBitmap(ptr: croaring.roaring_bitmap_lazy_xor(self.ptr, x.ptr))
        return x2

    }

    /**
    * (For expert users who seek high performance.)
    * Inplace version of roaring_bitmap_lazy_xor, modifies x1. x1 != x2
    *
    */
    public func lazyXorInplace(_ x: RoaringBitmap) {
        croaring.roaring_bitmap_lazy_xor_inplace(self.ptr, x.ptr)

    }

    /**
    * compute the negation of the roaring bitmap within a specified
    * interval: [range_start, range_end). The number of negated values is
    * range_end - range_start.
    * Areas outside the range are passed through unchanged.
    */
    public func flip(rangeStart: UInt64, rangeEnd: UInt64) -> RoaringBitmap {
        let x2 = RoaringBitmap(ptr: croaring.roaring_bitmap_flip(self.ptr, rangeStart, rangeEnd))
        return x2

    }

    /**
    * compute (in place) the negation of the roaring bitmap within a specified
    * interval: [range_start, range_end). The number of negated values is
    * range_end - range_start.
    * Areas outside the range are passed through unchanged.
    */
    public func flipInplace(rangeStart: UInt64, rangeEnd: UInt64) {
        croaring.roaring_bitmap_flip_inplace(self.ptr, rangeStart, rangeEnd)
    }

    /////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////


    /**
    * Copies a  bitmap. This does memory allocation. The caller is responsible for
    * memory management.
    *
    */
    public func copy() -> RoaringBitmap {
        let cpy = RoaringBitmap(ptr: croaring.roaring_bitmap_copy(self.ptr))
        return cpy
    }

    /**
    * Copies a  bitmap from src to dest. It is assumed that the pointer dest
    * is to an already allocated bitmap. The content of the dest bitmap is
    * freed/deleted.
    *
    * It might be preferable and simpler to call roaring_bitmap_copy except
    * that roaring_bitmap_overwrite can save on memory allocations.
    *
    */
    // func overwrite(dest: RoaringBitmap) -> Bool {
    //     return croaring.roaring_bitmap_overwrite(dest.ptr, self.ptr)
    // }

    /**
    * Add value x
    *
    */
    public func add(value:UInt32) {
        croaring.roaring_bitmap_add(self.ptr, value)
    }

    /**
    * Add value n_args from pointer vals, faster than repeatedly calling
    * roaring_bitmap_add
    *
    */
    public func addMany(values: [UInt32]) {
        let ptr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: values)
        croaring.roaring_bitmap_add_many(self.ptr, values.count, ptr)
    }

    /**
    * Add value x
    * Returns true if a new value was added, false if the value was already existing.
    */
    public func addCheck(value:UInt32) -> Bool {
        return croaring.roaring_bitmap_add_checked(self.ptr, value)
    }

    /**
    * Add all values in range [min, max]
    */
    public func addRangeClosed(min: UInt32, max: UInt32) {
        croaring.roaring_bitmap_add_range_closed(self.ptr, min, max)
    }

    /**
    * Add all values in range [min, max)
    */
    public func addRange(min: UInt64, max: UInt64) {
        croaring.roaring_bitmap_add_range(self.ptr, min, max)
    }

    /**
    * Remove value x
    *
    */
    public func remove(value:UInt32) {
        croaring.roaring_bitmap_remove(self.ptr, value)
    }

    /** Remove all values in range [min, max] */
    public func removeRangeClosed(min: UInt32, max: UInt32) {
        croaring.roaring_bitmap_remove_range_closed(self.ptr, min, max)
    }

    /** Remove all values in range [min, max) */
    public func removeRange(min: UInt64, max: UInt64) {
        croaring.roaring_bitmap_remove_range(self.ptr, min, max)
    }

    // /** Remove multiple values */
    // func removeMany(n_args: size_t, vals: [UInt32]) {
    //    let ptr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: vals)
    //     croaring.roaring_bitmap_remove_many(self.ptr, n_args, ptr)
    // }

    /**
    * Remove value x
    * Returns true if a new value was removed, false if the value was not existing.
    */
    public func removeCheck(value:UInt32) -> Bool {
        return croaring.roaring_bitmap_remove_checked(self.ptr, value)
    }

    /**
    * Frees the memory.
    */
    private func free() {
        croaring.roaring_bitmap_free(self.ptr)
    }

    /**
    * Empties the bitmap.
    */
    public func clear() {
        croaring.roaring_bitmap_clear(self.ptr)
    }

    /**
    * Get the cardinality of the bitmap (number of elements).
    */
    public func count() -> UInt64 {
        return croaring.roaring_bitmap_get_cardinality(self.ptr)
    }

    /**
    * Check if value x is present
    */
    public func contains(value: UInt32) -> Bool {
        return croaring.roaring_bitmap_contains(self.ptr, value)
    }

    /**
    * Check whether a range of values from range_start (included) to range_end (excluded) is present
    */
    public func containsRange(start: UInt64, end: UInt64) -> Bool {
        return croaring.roaring_bitmap_contains_range(self.ptr, start, end)
    }
    /**
    * Check whether the bitmap is empty
    */
    public func isEmpty() -> Bool {
        return croaring.roaring_bitmap_is_empty(self.ptr)
    }
       
    /**
    * Print the content of the bitmap.
    */
    public func print() {
        croaring.roaring_bitmap_printf(self.ptr)
    }

    /**
    * Describe the inner structure of the bitmap.
    */
    public func describe() {
        croaring.roaring_bitmap_printf_describe(self.ptr)
    }

    /**
    * Convert the bitmap to an array. Write the output to "ans",
    * caller is responsible to ensure that there is enough memory
    * allocated
    * (e.g., ans = malloc(roaring_bitmap_get_cardinality(mybitmap)
    *   * sizeof(uint32_t))
    */
    public func toArray() -> [UInt32] {
        let count = (Int(self.count()) * MemoryLayout<UInt32>.size)/4
        var array = [UInt32](repeating: 0, count: count)
        //let arrayPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: array)
        croaring.roaring_bitmap_to_uint32_array(self.ptr, &array)
        return array
    }


    // /**
    // * Convert the bitmap to an array from "offset" by "limit". Write the output to "ans".
    // * so, you can get data in paging.
    // * caller is responsible to ensure that there is enough memory
    // * allocated
    // * (e.g., ans = malloc(roaring_bitmap_get_cardinality(limit)
    // *   * sizeof(uint32_t))
    // * Return false in case of failure (e.g., insufficient memory)
    // */
    // public func toArrayRange(offset: size_t, limit: size_t) -> [UInt32] {
    //     let array: [UInt32] = []
    //     _ = croaring.roaring_bitmap_range_uint32_array(self.ptr, offset, limit, array)
    //     return array
    // }

    /**
    *  Remove run-length encoding even when it is more space efficient
    *  return whether a change was applied
    */
    
    public func removeRunCompression() -> Bool {
        return croaring.roaring_bitmap_remove_run_compression(self.ptr)
    }
    

    /** convert array and bitmap containers to run containers when it is more
    * efficient;
    * also convert from run containers when more space efficient.  Returns
    * true if the result has at least one run container.
    * Additional savings might be possible by calling shrinkToFit().
    */
    public func runOptimize() -> Bool {
        return croaring.roaring_bitmap_run_optimize(self.ptr)
    }

    /**
    * If needed, reallocate memory to shrink the memory usage. Returns
    * the number of bytes saved.
    */
    public func shrinkToFit() -> size_t {
        return croaring.roaring_bitmap_shrink_to_fit(self.ptr)
    }

    /**
    * write the bitmap to an output pointer, this output buffer should refer to
    * at least roaring_bitmap_size_in_bytes(ra) allocated bytes.
    *
    * see roaring_bitmap_portable_serialize if you want a format that's compatible
    * with Java and Go implementations
    *
    * this format has the benefit of being sometimes more space efficient than
    * roaring_bitmap_portable_serialize
    * e.g., when the data is sparse.
    *
    * Returns how many bytes were written which should be
    * roaring_bitmap_size_in_bytes(ra).
    */
    public func serialize(buffer: [Int8]) -> size_t {
        let ptr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: buffer)
        return croaring.roaring_bitmap_serialize(self.ptr, ptr)
    }

    /**  use with roaring_bitmap_serialize
    * see roaring_bitmap_portable_deserialize if you want a format that's
    * compatible with Java and Go implementations
    */
    public static func deserialize(buffer: [Int8]) -> RoaringBitmap {
        let bufferPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: buffer)
        return RoaringBitmap(ptr: croaring.roaring_bitmap_deserialize(bufferPtr)!)
    }

    /**
    * How many bytes are required to serialize this bitmap (NOT compatible
    * with Java and Go versions)
    */
    public func sizeInBytes() -> size_t {
        return croaring.roaring_bitmap_size_in_bytes(self.ptr)
    }

    /**
    * read a bitmap from a serialized version. This is meant to be compatible with
    * the Java and Go versions. See format specification at
    * https://github.com/RoaringBitmap/RoaringFormatSpec
    * In case of failure, a null pointer is returned.
    * This function is unsafe in the sense that if there is no valid serialized
    * bitmap at the pointer, then many bytes could be read, possibly causing a buffer
    * overflow. For a safer approach,
    * call roaring_bitmap_portable_deserialize_safe.
    */
    public static func portableDeserialize(buffer: [Int8]) -> RoaringBitmap {
        let bufferPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: buffer)
        return RoaringBitmap(ptr: croaring.roaring_bitmap_portable_deserialize(bufferPtr)!)
    }

    /**
    * read a bitmap from a serialized version in a safe manner (reading up to maxbytes).
    * This is meant to be compatible with
    * the Java and Go versions. See format specification at
    * https://github.com/RoaringBitmap/RoaringFormatSpec
    * In case of failure, a null pointer is returned.
    */
    public static func portableDeserializeSafe(buffer: [Int8], maxbytes: size_t) -> RoaringBitmap {
        let bufferPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: buffer)        
        return RoaringBitmap(ptr: croaring.roaring_bitmap_portable_deserialize_safe(bufferPtr, maxbytes)!)
    }

    /**
    * Check how many bytes would be read (up to maxbytes) at this pointer if there
    * is a bitmap, returns zero if there is no valid bitmap.
    * This is meant to be compatible with
    * the Java and Go versions. See format specification at
    * https://github.com/RoaringBitmap/RoaringFormatSpec
    */
    public static func portableDeserializeSize(buffer: [Int8], maxbytes: size_t) -> size_t {
        let bufferPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: buffer)
        return croaring.roaring_bitmap_portable_deserialize_size(bufferPtr, maxbytes)
    }


    /**
    * How many bytes are required to serialize this bitmap (meant to be compatible
    * with Java and Go versions).  See format specification at
    * https://github.com/RoaringBitmap/RoaringFormatSpec
    */
    public func portableSizeInBytes() -> size_t {
        return croaring.roaring_bitmap_portable_size_in_bytes(self.ptr)
    }

    /**
    * write a bitmap to a char buffer.  The output buffer should refer to at least
    *  roaring_bitmap_portable_size_in_bytes(ra) bytes of allocated memory.
    * This is meant to be compatible with
    * the
    * Java and Go versions. Returns how many bytes were written which should be
    * roaring_bitmap_portable_size_in_bytes(ra).  See format specification at
    * https://github.com/RoaringBitmap/RoaringFormatSpec
    */
    public func portableSerialize(buffer: [Int8]) -> size_t {
        let bufferPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: buffer)
        return croaring.roaring_bitmap_portable_serialize(self.ptr, bufferPtr)
    }

    /**
    * If the size of the roaring bitmap is strictly greater than rank, then this
    function returns true and set the value to the the given rank.
    Otherwise, it returns false.
    */
    public func select(rank: UInt32, value: UInt32) -> Bool {
        var cpy = value
        return croaring.roaring_bitmap_select(self.ptr, rank, &cpy)

    }
    
    /**
    * roaring_bitmap_rank returns the number of integers that are smaller or equal
    * to x.
    */
    public func rank(value: UInt32) -> UInt64 {
        return croaring.roaring_bitmap_rank(self.ptr, value)

    }

    /**
    * roaring_bitmap_smallest returns the smallest value in the set.
    * Returns UINT32_MAX if the set is empty.
    */
    public func minimum() -> UInt32 {
        return croaring.roaring_bitmap_minimum(self.ptr)

    }

    /**
    * roaring_bitmap_smallest returns the greatest value in the set.
    * Returns 0 if the set is empty.
    */
    public func maximum() -> UInt32 {
        return croaring.roaring_bitmap_maximum(self.ptr)

    }

    /**
    *  (For advanced users.)
    * Collect statistics about the bitmap, see RoaringStatistics.swift for
    * a description of RoaringStatistics
    */
    
    public func statistics() -> RoaringStatistics {
        var stats = RoaringStatistics()
        croaring.roaring_bitmap_statistics(self.ptr, &stats)
        return stats
    }

    /**
    * Creates a RoaringBitmapIterator.
    */
    public func makeIterator() -> RoaringBitmapIterator {
        return RoaringBitmapIterator(ptr: self.ptr)
    }

    /**
    * code used to iterate through values in a roaring bitmap
    */
    public struct RoaringBitmapIterator: IteratorProtocol {
        private var i: UnsafeMutablePointer<roaring_uint32_iterator_t>
        
        init(ptr: UnsafeMutablePointer<roaring_bitmap_t>) {
            self.i = croaring.roaring_create_iterator(ptr)
        }
        
        mutating public func next() -> UInt32? {
            if(i.pointee.has_value){
                let val = i.pointee.current_value 
                croaring.roaring_advance_uint32_iterator(self.i)
                return val
            }
            return nil
        }
        
    }

}