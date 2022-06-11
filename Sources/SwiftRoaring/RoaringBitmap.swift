import Foundation
import croaring

///
/// This class contains different values about a given RoaringBitmap
///
public typealias RoaringStatistics = roaring_statistics_t

///
/// Swift wrapper for CRoaring (a C/C++ implementation at https://github.com/RoaringBitmap/CRoaring)
///
public final class RoaringBitmap: Sequence, Equatable, CustomStringConvertible,
                                  Hashable, ExpressibleByArrayLiteral, SetAlgebra, Codable {

    @usableFromInline
    var ptr: UnsafeMutablePointer<roaring_bitmap_t>

    public typealias Element = UInt32

    /////////////////////////////////////////////////////////////////////////////
    ///                             CONSTRUCTORS                              ///
    /////////////////////////////////////////////////////////////////////////////
    ///
    /// Creates a new bitmap (initially empty)
    ///
    required public init() {
        self.ptr = croaring.roaring_bitmap_create()!
    }

    ///
    /// Creates a new bitmap using a given ptr
    ///
    required public init(ptr: UnsafeMutablePointer<roaring_bitmap_t>) {
        self.ptr = ptr
    }

    ///
    /// Add all the values between min (included) and max (excluded) that are at a
    /// distance k*step from min.
    ///
    public init(min: UInt64, max: UInt64, step: UInt32) {
        self.ptr = croaring.roaring_bitmap_from_range(min, max, step)!
    }

    public init(range: Range<UInt64>, step: UInt32) {
        self.ptr = croaring.roaring_bitmap_from_range(
            range.lowerBound,
            range.upperBound,
            step
        )!
    }

    ///
    /// Creates a new bitmap (initially empty) with a provided
    /// container-storage capacity (it is a performance hint).
    ///
    public init(capacity: UInt32) {
        self.ptr = croaring.roaring_bitmap_create_with_capacity(capacity)!
    }

    ///
    /// Creates a new bitmap from a pointer of `uint32_t` integers
    ///
    public init(values: [UInt32]) {
        self.ptr = croaring.roaring_bitmap_of_ptr(values.count, values)!
    }

    public required init(arrayLiteral: Element...) {
        self.ptr = croaring.roaring_bitmap_create()!
        for i in arrayLiteral { add(i) }

    }

    deinit {
        self.free()
    }

    /////////////////////////////////////////////////////////////////////////////
    ///                             OPERATORS                                 ///
    /////////////////////////////////////////////////////////////////////////////

    ///
    /// Computes the intersection between two bitmaps and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public func intersection(_ other: RoaringBitmap) -> Self {
        return Self(ptr: croaring.roaring_bitmap_and(self.ptr, other.ptr))
    }
    ///
    /// Computes the intersection between two bitmaps and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public static func &(lhs: RoaringBitmap, rhs: RoaringBitmap) -> Self {
        Self(ptr: croaring.roaring_bitmap_and(lhs.ptr, rhs.ptr))
    }

    ///
    /// Inplace version modifies x1, x1 == x2 is allowed
    ///
    @inlinable @inline(__always)
    public func formIntersection(_ other: RoaringBitmap) {
        croaring.roaring_bitmap_and_inplace(self.ptr, other.ptr)
    }
    ///
    /// Inplace version modifies x1, x1 == x2 is allowed
    ///
    @inlinable @inline(__always)
    public static func &=(lhs: RoaringBitmap, rhs: RoaringBitmap) {
        lhs.formIntersection(rhs)
    }

    ///
    /// Computes the size of the intersection between two bitmaps.
    ///
    @inlinable @inline(__always)
    public func intersectionCount(_ other: RoaringBitmap) -> UInt64 {
        return croaring.roaring_bitmap_and_cardinality(self.ptr, other.ptr)
    }

    ///
    /// Check whether two bitmaps intersect.
    ///
    @inlinable @inline(__always)
    public func intersect(_ other: RoaringBitmap) -> Bool {
        return croaring.roaring_bitmap_intersect(self.ptr, other.ptr)
    }

    ///
    /// Computes the Jaccard index between two bitmaps. (Also known as the Tanimoto
    /// distance, or the Jaccard similarity coefficient).
    ///
    /// The Jaccard index is undefined if both bitmaps are empty.
    ///
    @inlinable @inline(__always)
    public func jaccardIndex(_ other: RoaringBitmap) -> Double {
        return croaring.roaring_bitmap_jaccard_index(self.ptr, other.ptr)
    }

    ///
    /// Computes the size of the union between two bitmaps.
    ///
    public func unionCount(_ other: RoaringBitmap) -> UInt64 {
        return croaring.roaring_bitmap_or_cardinality(self.ptr, other.ptr)
    }

    ///
    /// Computes the size of the difference (andnot) between two bitmaps.
    ///
    @inlinable @inline(__always)
    public func subtractingCount(_ other: RoaringBitmap) -> UInt64 {
        return croaring.roaring_bitmap_andnot_cardinality(self.ptr, other.ptr)
    }

    ///
    /// Returns the number of elements in range [min, max).
    ///
    @inlinable @inline(__always)
    public func rangeCardinality(min: UInt64, max: UInt64) -> UInt64 {
        return croaring.roaring_bitmap_range_cardinality(self.ptr, min, max)
    }

    ///
    /// Computes the size of the symmetric difference (andnot) between two bitmaps.
    ///
    @inlinable @inline(__always)
    public func symmetricDifferenceCount(_ other: RoaringBitmap) -> UInt64 {
        return croaring.roaring_bitmap_xor_cardinality(self.ptr, other.ptr)
    }

    ///
    /// Computes the union between two bitmaps and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public func union(_ other: RoaringBitmap) -> Self {
        return Self(ptr: croaring.roaring_bitmap_or(self.ptr, other.ptr))
    }
    ///
    /// Computes the union between two bitmaps and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public static func |(lhs: RoaringBitmap, rhs: RoaringBitmap) -> Self {
        return Self(ptr: croaring.roaring_bitmap_or(lhs.ptr, rhs.ptr))
    }

    ///
    /// Inplace version of `roaring_bitmap_or`, modifies x1.
    ///
    @inlinable @inline(__always)
    public func formUnion(_ other: RoaringBitmap) {
        croaring.roaring_bitmap_or_inplace(self.ptr, other.ptr)
    }
    ///
    /// Inplace version of `roaring_bitmap_or`, modifies x1.
    ///
    @inlinable @inline(__always)
    public static func |=(lhs: RoaringBitmap, rhs: RoaringBitmap) {
        lhs.formUnion(rhs)
    }

    @inlinable @inline(__always)
    func combine(with others: [RoaringBitmap]) -> ContiguousArray<UnsafePointer<roaring_bitmap_t>?> {
        var out = ContiguousArray<UnsafePointer<roaring_bitmap_t>?>(capacity: others.count + 1)
        out.append(self.ptr)

        for ptr in others {
            out.append(ptr.ptr)
        }
        return out
    }

    ///
    /// Compute the union of 'number' bitmaps. See also `roaring_bitmap_or_many_heap`.
    ///
    public func unionMany(_ others: [RoaringBitmap]) -> Self {
        var ptrs = self.combine(with: others)

        return ptrs.withUnsafeMutableBufferPointer { ptrs in
            Self(ptr: croaring.roaring_bitmap_or_many(ptrs.count, ptrs.baseAddress!))
        }
    }
    ///
    /// Compute the union of 'number' bitmaps using a heap. This can
    /// sometimes be faster than `roaring_bitmap_or_many` which uses
    /// a naive algorithm.
    ///
    public func unionManyHeap(_ others: [RoaringBitmap]) -> Self {
        var ptrs = self.combine(with: others)

        return ptrs.withUnsafeMutableBufferPointer { ptrs in
            Self(ptr: croaring.roaring_bitmap_or_many_heap(UInt32(ptrs.count), ptrs.baseAddress!))
        }
    }

    ///
    /// Computes the symmetric difference (xor) between two bitmaps
    /// and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public func symmetricDifference(_ other: RoaringBitmap) -> Self {
        return Self(ptr: croaring.roaring_bitmap_xor(self.ptr, other.ptr))
    }
    ///
    /// Computes the symmetric difference (xor) between two bitmaps
    /// and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public static func ^(lhs: RoaringBitmap, rhs: RoaringBitmap) -> Self {
        return Self(ptr: croaring.roaring_bitmap_xor(lhs.ptr, rhs.ptr))
    }

    ///
    /// Inplace version of `roaring_bitmap_xor`, modifies x1. x1 != x2.
    ///
    @inlinable @inline(__always)
    public func formSymmetricDifference(_ other: RoaringBitmap) {
        croaring.roaring_bitmap_xor_inplace(self.ptr, other.ptr)
    }
    ///
    /// Inplace version of `roaring_bitmap_xor`, modifies x1. x1 != x2.
    ///
    @inlinable @inline(__always)
    public static func ^=(lhs: RoaringBitmap, rhs: RoaringBitmap) {
        lhs.formSymmetricDifference(rhs)
    }

    ///
    /// Compute the xor of 'number' bitmaps.
    ///
    public func symmetricDifferenceMany(_ others: [RoaringBitmap]) -> Self {
        var ptrs = self.combine(with: others)

        return ptrs.withUnsafeMutableBufferPointer { ptrs in
            Self(ptr: croaring.roaring_bitmap_xor_many(ptrs.count, ptrs.baseAddress!))
        }
    }

    ///
    /// Computes the  difference (andnot) between two bitmaps and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public func subtracting(_ other: RoaringBitmap) -> Self {
        return Self(ptr: croaring.roaring_bitmap_andnot(self.ptr, other.ptr))
    }
    ///
    /// Computes the  difference (andnot) between two bitmaps and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public static func -(lhs: RoaringBitmap, rhs: RoaringBitmap) -> Self {
        return Self(ptr: croaring.roaring_bitmap_andnot(lhs.ptr, rhs.ptr))
    }

    ///
    /// Inplace version of `roaring_bitmap_andnot`, modifies x1. x1 != x2.
    ///
    @inlinable @inline(__always)
    public func subtract(_ other: RoaringBitmap) {
        croaring.roaring_bitmap_andnot_inplace(self.ptr, other.ptr)
    }
    ///
    /// Inplace version of `roaring_bitmap_andnot`, modifies x1. x1 != x2.
    ///
    @inlinable @inline(__always)
    public static func -=(lhs: RoaringBitmap, rhs: RoaringBitmap) {
        lhs.subtract(rhs)
    }

    ///
    /// Return true if the two bitmaps contain the same elements.
    ///
    @inlinable @inline(__always)
    public static func ==(lhs: RoaringBitmap, rhs: RoaringBitmap) -> Bool {
        return croaring.roaring_bitmap_equals(lhs.ptr, rhs.ptr)
    }

    ///
    /// Return true if all the elements of ra1 are also in ra2.
    ///
    @inlinable @inline(__always)
    public func isSubset(of other: RoaringBitmap) -> Bool {
        return croaring.roaring_bitmap_is_subset(self.ptr, other.ptr)
    }

    ///
    /// Return true if all the elements of ra1 are also in ra2 and ra2 is strictly greater than ra1.
    ///
    @inlinable @inline(__always)
    public func isStrictSubset(of other: RoaringBitmap) -> Bool {
        return croaring.roaring_bitmap_is_strict_subset(self.ptr, other.ptr)
    }

    ///
    /// Return true if ra1 and ra2 have no elements in common.
    ///
    @inlinable @inline(__always)
    public func isDisjoint(with other: RoaringBitmap) -> Bool {
        return !croaring.roaring_bitmap_intersect(self.ptr, other.ptr)
    }

    ///
    /// (For expert users who seek high performance.)
    ///
    /// Computes the union between two bitmaps and returns new bitmap.
    ///
    /// The lazy version defers some computations such as the maintenance of the
    /// cardinality counts. Thus you need to call
    /// `roaring_bitmap_repair_after_lazy` after executing "lazy" computations.
    /// It is safe to repeatedly call `roaring_bitmap_lazy_or_inplace` on the result.
    /// The bitsetconversion conversion is a flag which determines
    /// whether container-container operations force a bitset conversion.
    ///
    @inlinable @inline(__always)
    public func lazyUnion(_ other: RoaringBitmap, bitsetconversion: Bool) -> Self {
        return Self(ptr: croaring.roaring_bitmap_lazy_or(self.ptr, other.ptr, bitsetconversion))
    }

    ///
    /// (For expert users who seek high performance.)
    /// Inplace version of `roaring_bitmap_lazy_or`, modifies x1
    /// The bitsetconversion conversion is a flag which determines
    /// whether container-container operations force a bitset conversion.
    ///
    @inlinable @inline(__always)
    public func formLazyUnion(_ other: RoaringBitmap, bitsetconversion: Bool) {
        croaring.roaring_bitmap_lazy_or_inplace(self.ptr, other.ptr, bitsetconversion)
    }

    ///
    /// (For expert users who seek high performance.)
    ///
    /// Execute maintenance operations on a bitmap created from
    /// `roaring_bitmap_lazy_or` or modified with
    /// `roaring_bitmap_lazy_or_inplace`.
    ///
    @inlinable @inline(__always)
    public func repairAfterLazy() {
        croaring.roaring_bitmap_repair_after_lazy(self.ptr)
    }

    ///
    /// Computes the symmetric difference between two bitmaps and returns new bitmap.
    ///
    /// The lazy version defers some computations such as the maintenance of the
    /// cardinality counts. Thus you need to call `roaring_bitmap_repair_after_lazy`
    /// after executing "lazy" computations.
    /// It is safe to repeatedly call `roaring_bitmap_lazy_xor_inplace` on the result.
    ///
    @inlinable @inline(__always)
    public func lazySymmetricDifference(_ other: RoaringBitmap) -> Self {
        return Self(ptr: croaring.roaring_bitmap_lazy_xor(self.ptr, other.ptr))
    }

    ///
    /// (For expert users who seek high performance.)
    /// Inplace version of `roaring_bitmap_lazy_xor`, modifies x1. x1 != x2
    ///
    @inlinable @inline(__always)
    public func formLazySymmetricDifference(_ other: RoaringBitmap) {
        croaring.roaring_bitmap_lazy_xor_inplace(self.ptr, other.ptr)
    }

    ///
    /// compute the negation of the roaring bitmap within a specified
    /// interval: [range_start, range_end). The number of negated values is
    /// range_end - range_start.
    /// Areas outside the range are passed through unchanged.
    ///
    @inlinable @inline(__always)
    public func flip(rangeStart: UInt64, rangeEnd: UInt64) -> Self {
        return Self(ptr: croaring.roaring_bitmap_flip(self.ptr, rangeStart, rangeEnd))
    }

    @inlinable @inline(__always)
    public func flip(_ range: Range<UInt64>) -> Self {
        Self(ptr: croaring.roaring_bitmap_flip(
            self.ptr,
            range.lowerBound,
            range.upperBound
        ))
    }

    ///
    /// compute (in place) the negation of the roaring bitmap within a specified
    /// interval: [range_start, range_end). The number of negated values is
    /// range_end - range_start.
    /// Areas outside the range are passed through unchanged.
    ///
    @inlinable @inline(__always)
    public func flipInplace(rangeStart: UInt64, rangeEnd: UInt64) {
        croaring.roaring_bitmap_flip_inplace(self.ptr, rangeStart, rangeEnd)
    }

    @inlinable @inline(__always)
    public func flipInPlace(_ range: Range<UInt64>) {
        croaring.roaring_bitmap_flip_inplace(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    /////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////

    ///
    /// Copies a  bitmap. This does memory allocation.
    ///
    @inlinable @inline(__always)
    public func copy() -> Self {
        return Self(ptr: croaring.roaring_bitmap_copy(self.ptr))
    }

    ///
    /// Copies a  bitmap from src to dest. It is assumed that the pointer dest
    /// is to an already allocated bitmap. The content of the dest bitmap is
    /// freed/deleted.
    ///
    /// It might be preferable and simpler to call `roaring_bitmap_copy` except
    /// that `roaring_bitmap_overwrite` can save on memory allocations.
    ///
    ///
    // func overwrite(dest: RoaringBitmap) -> Bool {
    //     return croaring.roaring_bitmap_overwrite(dest.ptr, self.ptr)
    // }

    ///
    /// Add value x
    ///
    @inlinable @inline(__always)
    public func add(_ value: UInt32) {
        croaring.roaring_bitmap_add(self.ptr, value)
    }

    ///
    /// Add value `n_args` from pointer vals, faster than repeatedly calling
    /// `roaring_bitmap_add`
    ///
    @inlinable @inline(__always)
    public func addMany(values: [UInt32]) {
        croaring.roaring_bitmap_add_many(self.ptr, values.count, values)
    }

    ///
    /// Add value x
    /// Returns true if a new value was added, false if the value was already existing.
    ///
    @inlinable @inline(__always)
    public func addCheck(_ value: UInt32) -> Bool {
        return croaring.roaring_bitmap_add_checked(self.ptr, value)
    }

    ///
    /// Add all values in range [min, max]
    ///
    @inlinable @inline(__always)
    public func addRangeClosed(min: UInt32, max: UInt32) {
        croaring.roaring_bitmap_add_range_closed(self.ptr, min, max)
    }

    @inlinable @inline(__always)
    public func add(_ range: ClosedRange<UInt32>) {
        croaring.roaring_bitmap_add_range_closed(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// Add all values in range [min, max)
    ///
    @inlinable @inline(__always)
    public func addRange(min: UInt64, max: UInt64) {
        croaring.roaring_bitmap_add_range(self.ptr, min, max)
    }

    @inlinable @inline(__always)
    public func add(_ range: Range<UInt64>) {
        croaring.roaring_bitmap_add_range(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(_ newMember: UInt32) -> (inserted: Bool, memberAfterInsert: UInt32) {
        let inserted = self.addCheck(newMember)
        return (inserted, newMember)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func update(with newMember: UInt32) -> UInt32? {
        guard self.addCheck(newMember) else { return newMember }
        return nil
    }

    ///
    /// Remove value x
    ///
    @inlinable @inline(__always)
    @discardableResult
    public func remove(_ value: UInt32) -> UInt32? {
        guard self.removeCheck(value) else { return value }
        return nil
    }

    ///
    /// Remove all values in range [min, max]
    ///
    @inlinable @inline(__always)
    public func removeRangeClosed(min: UInt32, max: UInt32) {
        croaring.roaring_bitmap_remove_range_closed(self.ptr, min, max)
    }

    ///
    /// Remove all values in range [min, max)
    ///
    @inlinable @inline(__always)
    public func removeRange(min: UInt64, max: UInt64) {
        croaring.roaring_bitmap_remove_range(self.ptr, min, max)
    }

    // /** Remove multiple values */
    // func removeMany(n_args: size_t, vals: [UInt32]) {
    //    let ptr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: vals)
    //     croaring.roaring_bitmap_remove_many(self.ptr, n_args, ptr)
    // }

    ///
    /// Remove value x
    /// Returns true if a new value was removed, false if the value was not existing.
    ///
    @inlinable @inline(__always)
    public func removeCheck(_ value: UInt32) -> Bool {
        return croaring.roaring_bitmap_remove_checked(self.ptr, value)
    }

    ///
    /// Frees the memory.
    ///
    @inline(__always)
    private func free() {
        croaring.roaring_bitmap_free(self.ptr)
    }

    ///
    /// Empties the bitmap.
    ///
    @inlinable @inline(__always)
    public func clear() {
        croaring.roaring_bitmap_clear(self.ptr)
    }

    @inlinable @inline(__always)
    public func removeAll() {
        self.clear()
    }

    @inlinable @inline(__always)
    public func removeAll(
           where shouldBeRemoved: (UInt32) -> Bool
       ) {
           for i in self where shouldBeRemoved(i) {
               self.remove(i)
           }
       }

    ///
    /// Get the cardinality of the bitmap (number of elements).
    ///
    @inlinable @inline(__always)
    public var count: UInt64 {
        return croaring.roaring_bitmap_get_cardinality(self.ptr)
    }

    ///
    /// Check if value x is present
    ///
    @inlinable @inline(__always)
    public func contains(_ value: UInt32) -> Bool {
        return croaring.roaring_bitmap_contains(self.ptr, value)
    }

    ///
    /// Check whether a range of values from `range_start` (included) to `range_end` (excluded) is present
    ///
    @inlinable @inline(__always)
    public func containsRange(start: UInt64, end: UInt64) -> Bool {
        return croaring.roaring_bitmap_contains_range(self.ptr, start, end)
    }

    @inlinable @inline(__always)
    public func contains(_ range: Range<UInt64>) -> Bool {
        return croaring.roaring_bitmap_contains_range(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }
    ///
    /// Check whether the bitmap is empty
    ///
    @inlinable @inline(__always)
    public var isEmpty: Bool {
        return croaring.roaring_bitmap_is_empty(self.ptr)
    }

    ///
    /// Print the content of the bitmap.
    ///
    @inlinable @inline(__always)
    public func print() {
        croaring.roaring_bitmap_printf(self.ptr)
    }

    ///
    /// Describe the inner structure of the bitmap.
    ///
    @inlinable @inline(__always)
    public func describe() {
        croaring.roaring_bitmap_printf_describe(self.ptr)
    }

    ///
    /// Convert the bitmap to an array.
    ///
    public func toArray() -> [UInt32] {
        let count = (Int(self.count) * MemoryLayout<UInt32>.size)/4
        var array = [UInt32](repeating: 0, count: count)
        // let arrayPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: array)
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

    ///
    ///  Remove run-length encoding even when it is more space efficient
    ///  return whether a change was applied
    ///
    @inlinable @inline(__always)
    public func removeRunCompression() -> Bool {
        return croaring.roaring_bitmap_remove_run_compression(self.ptr)
    }

    ///
    /// convert array and bitmap containers to run containers when it is more
    /// efficient;
    /// also convert from run containers when more space efficient.  Returns
    /// true if the result has at least one run container.
    /// Additional savings might be possible by calling shrinkToFit().
    ///
    @inlinable @inline(__always)
    public func runOptimize() -> Bool {
        return croaring.roaring_bitmap_run_optimize(self.ptr)
    }

    ///
    /// If needed, reallocate memory to shrink the memory usage. Returns
    /// the number of bytes saved.
    ///
    @inlinable @inline(__always)
    public func shrink() -> size_t {
        return croaring.roaring_bitmap_shrink_to_fit(self.ptr)
    }

    ///
    /// write the bitmap to an output pointer, this output buffer should refer to
    /// at least `roaring_bitmap_size_in_bytes(ra)` allocated bytes.
    ///
    /// see `roaring_bitmap_portable_serialize` if you want a format that's compatible
    /// with Java and Go implementations
    ///
    /// this format has the benefit of being sometimes more space efficient than
    /// `roaring_bitmap_portable_serialize`
    /// e.g., when the data is sparse.
    ///
    /// Returns how many bytes were written which should be
    /// `roaring_bitmap_size_in_bytes(ra)`.
    ///
    @inlinable @inline(__always)
    public func serialize(buffer: inout [Int8]) -> size_t {
        return croaring.roaring_bitmap_serialize(self.ptr, &buffer)
    }

    ///
    /// use with roaring_bitmap_serialize
    /// see `roaring_bitmap_portable_deserialize` if you want a format that's
    /// compatible with Java and Go implementations
    ///
    @inlinable @inline(__always)
    public static func deserialize(buffer: [Int8]) -> Self {
        return Self(ptr: croaring.roaring_bitmap_deserialize(buffer)!)
    }

    ///
    /// Encodable conformance
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        let count = self.sizeInBytes()
        var data = Data(count: count)

        data.withUnsafeMutableBytes {
            let ptr = $0.baseAddress!.assumingMemoryBound(to: Int8.self)
            croaring.roaring_bitmap_serialize(self.ptr, ptr)
        }
        try container.encode(data.base64EncodedString())
    }

    ///
    /// Decodable conformance
    ///
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()

        let buffer = try container.decode(String.self)
        let data = Data(base64Encoded: buffer)
        self.ptr = data!.withUnsafeBytes {
            croaring.roaring_bitmap_deserialize($0)!
        }
    }

    ///
    /// How many bytes are required to serialize this bitmap (NOT compatible
    /// with Java and Go versions)
    ///
    @inlinable @inline(__always)
    public func sizeInBytes() -> size_t {
        return croaring.roaring_bitmap_size_in_bytes(self.ptr)
    }

    ///
    /// read a bitmap from a serialized version. This is meant to be compatible with
    /// the Java and Go versions. See format specification at
    /// https://github.com/RoaringBitmap/RoaringFormatSpec
    /// In case of failure, a null pointer is returned.
    /// This function is unsafe in the sense that if there is no valid serialized
    /// bitmap at the pointer, then many bytes could be read, possibly causing a buffer
    /// overflow. For a safer approach,
    /// call `roaring_bitmap_portable_deserialize_safe`.
    ///
    @inlinable @inline(__always)
    public static func portableDeserialize(buffer: [Int8]) -> Self {
        return Self(ptr: croaring.roaring_bitmap_portable_deserialize(buffer)!)
    }

    ///
    /// read a bitmap from a serialized version in a safe manner (reading up to maxbytes).
    /// This is meant to be compatible with
    /// the Java and Go versions. See format specification at
    /// https://github.com/RoaringBitmap/RoaringFormatSpec
    /// In case of failure, a null pointer is returned.
    ///
    @inlinable @inline(__always)
    public static func portableDeserializeSafe(buffer: [Int8], maxbytes: size_t) -> Self {
        return Self(ptr: croaring.roaring_bitmap_portable_deserialize_safe(buffer, maxbytes)!)
    }

    ///
    /// Check how many bytes would be read (up to maxbytes) at this pointer if there
    /// is a bitmap, returns zero if there is no valid bitmap.
    /// This is meant to be compatible with
    /// the Java and Go versions. See format specification at
    /// https://github.com/RoaringBitmap/RoaringFormatSpec
    ///
    @inlinable @inline(__always)
    public static func portableDeserializeSize(buffer: [Int8], maxbytes: size_t) -> size_t {
        return croaring.roaring_bitmap_portable_deserialize_size(buffer, maxbytes)
    }

    ///
    /// How many bytes are required to serialize this bitmap (meant to be compatible
    /// with Java and Go versions).  See format specification at
    /// https://github.com/RoaringBitmap/RoaringFormatSpec
    ///
    @inlinable @inline(__always)
    public func portableSizeInBytes() -> size_t {
        return croaring.roaring_bitmap_portable_size_in_bytes(self.ptr)
    }

    ///
    /// write a bitmap to a char buffer.  The output buffer should refer to at least
    /// `roaring_bitmap_portable_size_in_bytes(ra)` bytes of allocated memory.
    /// This is meant to be compatible with
    /// the
    /// Java and Go versions. Returns how many bytes were written which should be
    /// `roaring_bitmap_portable_size_in_bytes(ra)`.  See format specification at
    /// https://github.com/RoaringBitmap/RoaringFormatSpec
    ///
    @inlinable @inline(__always)
    public func portableSerialize(buffer: inout [Int8]) -> size_t {
        return croaring.roaring_bitmap_portable_serialize(self.ptr, &buffer)
    }

    ///
    /// If the size of the roaring bitmap is strictly greater than rank, then this
    /// function returns true and set the value to the the given rank.
    /// Otherwise, it returns false.
    ///
    @inlinable @inline(__always)
    public func select(rank: UInt32, value: UInt32) -> Bool {
        var cpy = value
        return croaring.roaring_bitmap_select(self.ptr, rank, &cpy)
    }

    ///
    /// Returns the number of integers that are smaller or equal  to x.
    ///
    @inlinable @inline(__always)
    public func rank(value: UInt32) -> UInt64 {
        return croaring.roaring_bitmap_rank(self.ptr, value)
    }

    ///
    /// Returns the smallest value in the set.
    /// Returns nil if the set is empty.
    ///
    @inlinable @inline(__always)
    public func min() -> UInt32? {
        guard !self.isEmpty else { return nil }
        return croaring.roaring_bitmap_minimum(self.ptr)
    }

    @inlinable @inline(__always)
    public var first: UInt32? {
        return self.min()
    }

    @inlinable @inline(__always)
    public func dropFirst() -> UInt32? {
        guard let first = self.first else { return nil }
        self.remove(first)
        return first
    }

    ///
    /// Returns the greatest value in the set.
    /// Returns nil if the set is empty.
    ///
    @inlinable @inline(__always)
    public func max() -> UInt32? {
        guard !self.isEmpty else { return nil }
        return croaring.roaring_bitmap_maximum(self.ptr)
    }

    @inlinable @inline(__always)
    public var last: UInt32? {
        return self.max()
    }

    @inlinable @inline(__always)
    public func dropLast() -> UInt32? {
        guard let last = self.last else { return nil }
        self.remove(last)
        return last
    }

    ///
    /// (For advanced users.)
    /// Collect statistics about the bitmap, see RoaringStatistics.swift for
    /// a description of RoaringStatistics
    ///
    public func statistics() -> RoaringStatistics {
        var stats = RoaringStatistics()
        croaring.roaring_bitmap_statistics(self.ptr, &stats)
        return stats
    }

    ///
    /// Creates a RoaringBitmapIterator.
    ///
    @inlinable @inline(__always)
    public func makeIterator() -> RoaringBitmapIterator {
        return RoaringBitmapIterator(ptr: self.ptr)
    }

    ///
    /// Structure used to iterate through values in a roaring bitmap
    ///
    @frozen
    public struct RoaringBitmapIterator: IteratorProtocol {
        @usableFromInline
        internal var i: roaring_uint32_iterator_t

        @inlinable @inline(__always)
        init(ptr: UnsafePointer<roaring_bitmap_t>) {
            self.i = roaring_uint32_iterator_t()
            roaring_init_iterator(ptr, &self.i)
        }

        @inlinable @inline(__always)
        public mutating func next() -> UInt32? {
            guard i.has_value else { return nil }
            let val = i.current_value
            croaring.roaring_advance_uint32_iterator(&self.i)
            return val
        }
    }

    ///
    /// Returns a string representation of the bitset
    ///
    public var description: String {
        var ret = prefix(100).map { $0.description }.joined(separator: ", ")
        if self.count >= 100 {
            ret.append(", ...")
        }
        return "{\(ret)}"
    }

    ///
    /// returns a hash value for the bitset, this is expensive and should be buffered
    /// for performance
    ///
    public var hashValue: Int {
        let b: UInt32 = 31
        var hash: UInt32 = 0
        for i in self {
            hash = hash &* b &+ i
        }
        return Int(hash)
    }

    public func hash(into hasher: inout Hasher) {
        let hash = self.hashValue
        hash.hash(into: &hasher)
    }
}

extension RangeReplaceableCollection {
    @inlinable @inline(__always)
    init(capacity: Int) {
        self.init()
        self.reserveCapacity(capacity)
    }
}
