import Foundation
import croaring

///
/// This class contains different values about a given RoaringBitmap
///
public typealias RoaringStatistics = roaring_statistics_t

///
/// Swift wrapper for CRoaring (a C/C++ implementation at https://github.com/RoaringBitmap/CRoaring)
///
/// Every function of CRoaring's public 32-bit API is reachable from this type,
/// except for five that have no Swift meaning:
/// `roaring_bitmap_init_with_capacity` and `roaring_bitmap_init_cleared`
/// initialize a `roaring_bitmap_t` the caller allocated, which `init()` and
/// `init(capacity:)` do here; `roaring_iterator_create`,
/// `roaring_uint32_iterator_copy` and `roaring_uint32_iterator_free` are the
/// heap-allocated iterator, replaced by the allocation-free
/// `RoaringBitmapIterator` value type. The variadic `roaring_bitmap_from` macro
/// corresponds to `init(values:)` and to array literals.
///
public final class RoaringBitmap: Sequence, Equatable, CustomStringConvertible,
                                  Hashable, ExpressibleByArrayLiteral, SetAlgebra, Codable {

    @usableFromInline
    let ptr: UnsafeMutablePointer<roaring_bitmap_t>

    ///
    /// When this bitmap is a *frozen view* created by `frozenView(bytes:)`, this
    /// holds the aligned buffer the view reads from. It is deallocated, after the
    /// bitmap itself, by `deinit`. It is `nil` for every ordinary bitmap.
    ///
    @usableFromInline
    let frozenBacking: UnsafeMutableRawPointer?

    public typealias Element = UInt32

    /////////////////////////////////////////////////////////////////////////////
    ///                             CONSTRUCTORS                              ///
    /////////////////////////////////////////////////////////////////////////////
    ///
    /// Creates a new bitmap (initially empty)
    ///
    required public convenience init() {
        self.init(ptr: croaring.roaring_bitmap_create()!)
    }

    ///
    /// Creates a new bitmap using a given ptr
    ///
    required public init(ptr: UnsafeMutablePointer<roaring_bitmap_t>) {
        self.ptr = ptr
        self.frozenBacking = nil
    }

    private init(ptr: UnsafeMutablePointer<roaring_bitmap_t>, frozenBacking: UnsafeMutableRawPointer) {
        self.ptr = ptr
        self.frozenBacking = frozenBacking
    }

    ///
    /// Add all the values between min (included) and max (excluded) that are at a
    /// distance k*step from min.
    ///
    public convenience init(min: UInt64, max: UInt64, step: UInt32) {
        self.init(ptr: croaring.roaring_bitmap_from_range(min, max, step)!)
    }

    public convenience init(range: Range<UInt64>, step: UInt32) {
        self.init(ptr: croaring.roaring_bitmap_from_range(
            range.lowerBound,
            range.upperBound,
            step
        )!)
    }

    ///
    /// Creates a new bitmap (initially empty) with a provided
    /// container-storage capacity (it is a performance hint).
    ///
    public convenience init(capacity: UInt32) {
        self.init(ptr: croaring.roaring_bitmap_create_with_capacity(capacity)!)
    }

    ///
    /// Creates a new bitmap from a pointer of `uint32_t` integers
    ///
    public convenience init(values: [UInt32]) {
        self.init(ptr: croaring.roaring_bitmap_of_ptr(values.count, values)!)
    }

    public required convenience init(arrayLiteral: Element...) {
        self.init(ptr: croaring.roaring_bitmap_create()!)
        for i in arrayLiteral { add(i) }

    }

    deinit {
        self.free()
        self.frozenBacking?.deallocate()
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
    /// Replaces the content of this bitmap with a copy of `other`.
    ///
    /// It might be preferable and simpler to call `copy()`, except that
    /// `overwrite(with:)` can save on memory allocations. Returns false if the
    /// copy could not be made.
    ///
    @inlinable @inline(__always)
    @discardableResult
    public func overwrite(with other: RoaringBitmap) -> Bool {
        return croaring.roaring_bitmap_overwrite(self.ptr, other.ptr)
    }

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
    /// Remove value x, and return it if it was there.
    ///
    @inlinable @inline(__always)
    @discardableResult
    public func remove(_ value: UInt32) -> UInt32? {
        guard self.removeCheck(value) else { return nil }
        return value
    }

    ///
    /// Remove value x, without reporting whether it was there. Slightly faster
    /// than `remove(_:)`.
    ///
    @inlinable @inline(__always)
    public func discard(_ value: UInt32) {
        croaring.roaring_bitmap_remove(self.ptr, value)
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

    ///
    /// Remove multiple values, faster than repeatedly calling `remove(_:)`.
    ///
    @inlinable @inline(__always)
    public func removeMany(values: [UInt32]) {
        croaring.roaring_bitmap_remove_many(self.ptr, values.count, values)
    }

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

    ///
    /// Convert a slice of the bitmap to an array: at most `limit` values, starting
    /// at the `offset`-th smallest one. Useful to page through a large bitmap.
    /// Returns nil in case of failure.
    ///
    public func toArray(offset: size_t, limit: size_t) -> [UInt32]? {
        let cardinality = size_t(self.count)
        let count = offset >= cardinality ? 0 : Swift.min(limit, cardinality - offset)
        var array = [UInt32](repeating: 0, count: count)
        guard croaring.roaring_bitmap_range_uint32_array(self.ptr, offset, limit, &array) else {
            return nil
        }
        return array
    }

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
    /// use with `roaring_bitmap_serialize`
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
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        let count = self.sizeInBytes()
        var data = Data(count: count)

        data.withUnsafeMutableBytes { (buffer: UnsafeMutableRawBufferPointer) in
            let ptr = buffer.baseAddress!.assumingMemoryBound(to: Int8.self)
            _ = croaring.roaring_bitmap_serialize(self.ptr, ptr)
        }
        try container.encode(data.base64EncodedString())
    }

    ///
    /// Decodable conformance
    ///
    public convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        let buffer = try container.decode(String.self)
        let ptr = Data(base64Encoded: buffer).flatMap { data in
            data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
                bytes.baseAddress.flatMap {
                    croaring.roaring_bitmap_deserialize_safe($0, bytes.count)
                }
            }
        }
        guard let ptr = ptr else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "not a serialized bitmap")
        }
        self.init(ptr: ptr)
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
    /// Serializes the bitmap in the portable format and returns the bytes.
    ///
    @inlinable
    public func portableSerialize() -> [UInt8] {
        return [UInt8](unsafeUninitializedCapacity: self.portableSizeInBytes()) { buffer, count in
            count = croaring.roaring_bitmap_portable_serialize(
                self.ptr, UnsafeMutableRawPointer(buffer.baseAddress!).assumingMemoryBound(to: CChar.self))
        }
    }

    ///
    /// Returns the element having the designated rank, where the smallest element
    /// has rank 0. Returns nil if the bitmap holds `rank` elements or fewer.
    ///
    @inlinable @inline(__always)
    public func select(rank: UInt32) -> UInt32? {
        var value: UInt32 = 0
        guard croaring.roaring_bitmap_select(self.ptr, rank, &value) else { return nil }
        return value
    }

    @available(*, deprecated, message: "the result was discarded; use select(rank:) -> UInt32? instead")
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
    public func popFirst() -> UInt32? {
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
    public func popLast() -> UInt32? {
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
    /// Creates a RoaringBitmapIterator positioned on the smallest value.
    ///
    @inlinable @inline(__always)
    public func makeIterator() -> RoaringBitmapIterator {
        return RoaringBitmapIterator(bitmap: self)
    }

    ///
    /// Creates a RoaringBitmapIterator positioned on the largest value, to be
    /// walked backward with `previous()`.
    ///
    @inlinable @inline(__always)
    public func makeLastIterator() -> RoaringBitmapIterator {
        return RoaringBitmapIterator(bitmap: self, atLast: true)
    }

    ///
    /// Structure used to iterate through values in a roaring bitmap.
    ///
    /// The iterator is a value type holding the C iterator inline, so no
    /// allocation takes place and copying it copies its position (the role
    /// `roaring_uint32_iterator_copy` plays in C).
    ///
    @frozen
    public struct RoaringBitmapIterator: IteratorProtocol {
        @usableFromInline
        internal var i: roaring_uint32_iterator_t

        @usableFromInline
        internal let bitmap: RoaringBitmap

        @inlinable @inline(__always)
        init(bitmap: RoaringBitmap) {
            self.i = roaring_uint32_iterator_t()
            roaring_iterator_init(bitmap.ptr, &self.i)
            self.bitmap = bitmap
        }

        @inlinable @inline(__always)
        init(bitmap: RoaringBitmap, atLast: Bool) {
            self.i = roaring_uint32_iterator_t()
            if atLast {
                roaring_iterator_init_last(bitmap.ptr, &self.i)
            } else {
                roaring_iterator_init(bitmap.ptr, &self.i)
            }
            self.bitmap = bitmap
        }

        ///
        /// Whether the iterator currently points at a value.
        ///
        @inlinable @inline(__always)
        public var hasValue: Bool {
            return i.has_value
        }

        ///
        /// The value the iterator points at, undefined when `hasValue` is false.
        ///
        @inlinable @inline(__always)
        public var currentValue: UInt32 {
            return i.current_value
        }

        ///
        /// The value the iterator points at, or nil if it is exhausted.
        ///
        @inlinable @inline(__always)
        public var value: UInt32? {
            return i.has_value ? i.current_value : nil
        }

        @inlinable @inline(__always)
        public mutating func next() -> UInt32? {
            guard i.has_value else { return nil }
            let val = i.current_value
            croaring.roaring_uint32_iterator_advance(&self.i)
            return val
        }

        ///
        /// Moves the iterator to the next value. Returns true if it still points
        /// at a value afterward.
        ///
        @inlinable @inline(__always)
        @discardableResult
        public mutating func advance() -> Bool {
            return croaring.roaring_uint32_iterator_advance(&self.i)
        }

        ///
        /// Moves the iterator to the previous value. Returns true if it still
        /// points at a value afterward.
        ///
        @inlinable @inline(__always)
        @discardableResult
        public mutating func previous() -> Bool {
            return croaring.roaring_uint32_iterator_previous(&self.i)
        }

        ///
        /// Returns the previous value, walking the bitmap backward, or nil once
        /// the iterator is exhausted. Pair with `makeLastIterator()`.
        ///
        @inlinable @inline(__always)
        public mutating func nextBackward() -> UInt32? {
            guard i.has_value else { return nil }
            let val = i.current_value
            croaring.roaring_uint32_iterator_previous(&self.i)
            return val
        }

        ///
        /// Moves the iterator to the smallest value that is greater than or equal
        /// to `value`. Returns true if such a value exists.
        ///
        @inlinable @inline(__always)
        @discardableResult
        public mutating func moveEqualOrLarger(_ value: UInt32) -> Bool {
            return croaring.roaring_uint32_iterator_move_equalorlarger(&self.i, value)
        }

        ///
        /// Reads up to `count` values into an array, advancing the iterator past
        /// them. The array is shorter than `count` when the bitmap runs out.
        ///
        public mutating func read(count: UInt32) -> [UInt32] {
            var buffer = [UInt32](repeating: 0, count: Int(count))
            let read = buffer.withUnsafeMutableBufferPointer { buf in
                croaring.roaring_uint32_iterator_read(&self.i, buf.baseAddress, count)
            }
            buffer.removeLast(Int(count) - Int(read))
            return buffer
        }

        ///
        /// Reads up to `count` values in decreasing order into an array, moving
        /// the iterator backward past them. Pair with `makeLastIterator()`.
        ///
        public mutating func readBackward(count: UInt32) -> [UInt32] {
            var buffer = [UInt32](repeating: 0, count: Int(count))
            let read = buffer.withUnsafeMutableBufferPointer { buf in
                croaring.roaring_uint32_iterator_read_backward(&self.i, buf.baseAddress, count)
            }
            buffer.removeLast(Int(count) - Int(read))
            return buffer
        }

        ///
        /// Reads up to `count` maximal runs of consecutive values, advancing the
        /// iterator past them. `{1, 2, 3, 5, 6}` reads as `[1...3, 5...6]`.
        ///
        public mutating func readRanges(count: Int) -> [ClosedRange<UInt32>] {
            var buffer = [roaring_uint32_range_closed_t](
                repeating: roaring_uint32_range_closed_t(), count: count
            )
            let read = buffer.withUnsafeMutableBufferPointer { buf in
                croaring.roaring_uint32_iterator_read_ranges(&self.i, buf.baseAddress, count)
            }
            return buffer.prefix(read).map { $0.min...$0.max }
        }

        ///
        /// Reads up to `count` maximal runs of consecutive values in decreasing
        /// order, moving the iterator backward past them.
        ///
        public mutating func readPreviousRanges(count: Int) -> [ClosedRange<UInt32>] {
            var buffer = [roaring_uint32_range_closed_t](
                repeating: roaring_uint32_range_closed_t(), count: count
            )
            let read = buffer.withUnsafeMutableBufferPointer { buf in
                croaring.roaring_uint32_iterator_read_prev_ranges(&self.i, buf.baseAddress, count)
            }
            return buffer.prefix(read).map { $0.min...$0.max }
        }

        ///
        /// Advances the iterator past `count` values without reading them.
        /// Returns how many were actually skipped.
        ///
        @inlinable @inline(__always)
        @discardableResult
        public mutating func skip(_ count: UInt32) -> UInt32 {
            return croaring.roaring_uint32_iterator_skip(&self.i, count)
        }

        ///
        /// Moves the iterator backward past `count` values without reading them.
        /// Returns how many were actually skipped.
        ///
        @inlinable @inline(__always)
        @discardableResult
        public mutating func skipBackward(_ count: UInt32) -> UInt32 {
            return croaring.roaring_uint32_iterator_skip_backward(&self.i, count)
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
        return "RoaringBitmap(\(ret))"
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

/////////////////////////////////////////////////////////////////////////////
///                        BULK (CONTEXT) OPERATIONS                      ///
/////////////////////////////////////////////////////////////////////////////

extension RoaringBitmap {
    ///
    /// A bit of context usable with the `*Bulk` operations.
    ///
    /// Reusing a context across calls whose values are in increasing order lets
    /// CRoaring skip the container lookup. A context may only be used with a
    /// single bitmap, and any modification of that bitmap that does not go
    /// through a `*Bulk` call taking the same context invalidates it.
    ///
    @frozen
    public struct BulkContext {
        @usableFromInline
        internal var context: roaring_bulk_context_t

        @inlinable @inline(__always)
        public init() {
            self.context = roaring_bulk_context_t()
        }

        ///
        /// Forgets the cached container, making the context usable again after
        /// the bitmap was modified out of band (or with another bitmap).
        ///
        @inlinable @inline(__always)
        public mutating func reset() {
            self.context = roaring_bulk_context_t()
        }
    }

    ///
    /// Add value x, using context from a previous insert for speed optimization.
    ///
    @inlinable @inline(__always)
    public func addBulk(_ value: UInt32, context: inout BulkContext) {
        croaring.roaring_bitmap_add_bulk(self.ptr, &context.context, value)
    }

    ///
    /// Check if value x is present, using context from a previous lookup for
    /// speed optimization.
    ///
    @inlinable @inline(__always)
    public func containsBulk(_ value: UInt32, context: inout BulkContext) -> Bool {
        return croaring.roaring_bitmap_contains_bulk(self.ptr, &context.context, value)
    }
}

/////////////////////////////////////////////////////////////////////////////
///                         RANGES AND OFFSETS                            ///
/////////////////////////////////////////////////////////////////////////////

extension RoaringBitmap {
    ///
    /// Remove all values in range [min, max]
    ///
    @inlinable @inline(__always)
    public func remove(_ range: ClosedRange<UInt32>) {
        croaring.roaring_bitmap_remove_range_closed(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// Remove all values in range [min, max)
    ///
    @inlinable @inline(__always)
    public func remove(_ range: Range<UInt64>) {
        croaring.roaring_bitmap_remove_range(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// Check whether all the values from `min` to `max` (both included) are present.
    ///
    @inlinable @inline(__always)
    public func containsRangeClosed(min: UInt32, max: UInt32) -> Bool {
        return croaring.roaring_bitmap_contains_range_closed(self.ptr, min, max)
    }

    @inlinable @inline(__always)
    public func contains(_ range: ClosedRange<UInt32>) -> Bool {
        return croaring.roaring_bitmap_contains_range_closed(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// Returns the number of elements in range [min, max].
    ///
    @inlinable @inline(__always)
    public func rangeCardinalityClosed(min: UInt32, max: UInt32) -> UInt64 {
        return croaring.roaring_bitmap_range_cardinality_closed(self.ptr, min, max)
    }

    @inlinable @inline(__always)
    public func cardinality(in range: Range<UInt64>) -> UInt64 {
        return croaring.roaring_bitmap_range_cardinality(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    @inlinable @inline(__always)
    public func cardinality(in range: ClosedRange<UInt32>) -> UInt64 {
        return croaring.roaring_bitmap_range_cardinality_closed(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// Check whether the bitmap has any value in the range [x, y).
    ///
    @inlinable @inline(__always)
    public func intersectWithRange(min: UInt64, max: UInt64) -> Bool {
        return croaring.roaring_bitmap_intersect_with_range(self.ptr, min, max)
    }

    @inlinable @inline(__always)
    public func intersects(_ range: Range<UInt64>) -> Bool {
        return croaring.roaring_bitmap_intersect_with_range(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// compute the negation of the roaring bitmap within a specified closed
    /// interval: [rangeStart, rangeEnd].
    /// Areas outside the range are passed through unchanged.
    ///
    @inlinable @inline(__always)
    public func flipClosed(rangeStart: UInt32, rangeEnd: UInt32) -> Self {
        return Self(ptr: croaring.roaring_bitmap_flip_closed(self.ptr, rangeStart, rangeEnd))
    }

    @inlinable @inline(__always)
    public func flip(_ range: ClosedRange<UInt32>) -> Self {
        return Self(ptr: croaring.roaring_bitmap_flip_closed(
            self.ptr,
            range.lowerBound,
            range.upperBound
        ))
    }

    ///
    /// compute (in place) the negation of the roaring bitmap within a specified
    /// closed interval: [rangeStart, rangeEnd].
    /// Areas outside the range are passed through unchanged.
    ///
    @inlinable @inline(__always)
    public func flipInplaceClosed(rangeStart: UInt32, rangeEnd: UInt32) {
        croaring.roaring_bitmap_flip_inplace_closed(self.ptr, rangeStart, rangeEnd)
    }

    @inlinable @inline(__always)
    public func flipInPlace(_ range: ClosedRange<UInt32>) {
        croaring.roaring_bitmap_flip_inplace_closed(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// Returns a new bitmap containing every value of this one shifted by
    /// `offset`. Values that would fall outside `UInt32` are dropped.
    ///
    @inlinable @inline(__always)
    public func addOffset(_ offset: Int64) -> Self {
        return Self(ptr: croaring.roaring_bitmap_add_offset(self.ptr, offset))
    }
}

/////////////////////////////////////////////////////////////////////////////
///                              RANK/SELECT                              ///
/////////////////////////////////////////////////////////////////////////////

extension RoaringBitmap {
    ///
    /// Returns the number of integers that are smaller or equal to each of
    /// `values`, in one pass. `values` must be sorted in ascending order.
    ///
    public func rankMany(_ values: [UInt32]) -> [UInt64] {
        var answers = [UInt64](repeating: 0, count: values.count)
        guard !values.isEmpty else { return answers }
        values.withUnsafeBufferPointer { input in
            answers.withUnsafeMutableBufferPointer { output in
                croaring.roaring_bitmap_rank_many(
                    self.ptr,
                    input.baseAddress,
                    input.baseAddress! + input.count,
                    output.baseAddress
                )
            }
        }
        return answers
    }

    ///
    /// Returns the index of `value` in the sorted set, or nil when `value` is
    /// not present. It is equivalent to, but faster than, `rank(value:) - 1`.
    ///
    @inlinable @inline(__always)
    public func index(of value: UInt32) -> UInt64? {
        let index = croaring.roaring_bitmap_get_index(self.ptr, value)
        return index < 0 ? nil : UInt64(index)
    }
}

/////////////////////////////////////////////////////////////////////////////
///                            COPY-ON-WRITE                              ///
/////////////////////////////////////////////////////////////////////////////

extension RoaringBitmap {
    ///
    /// Whether copy-on-write is enabled. With copy-on-write, `copy()` and the
    /// binary operations may share containers instead of duplicating them,
    /// which is faster and more compact but makes the bitmaps unsafe to use
    /// from several threads at once.
    ///
    /// Turning it off unshares every container that is currently shared.
    ///
    @inlinable @inline(__always)
    public var copyOnWrite: Bool {
        get { return croaring.roaring_bitmap_get_copy_on_write(self.ptr) }
        set { croaring.roaring_bitmap_set_copy_on_write(self.ptr, newValue) }
    }

    ///
    /// Whether the bitmap holds at least one container shared with another
    /// bitmap, which can only happen when copy-on-write is in use.
    ///
    @inlinable @inline(__always)
    public var containsShared: Bool {
        return croaring.roaring_contains_shared(self.ptr)
    }

    ///
    /// Gives the bitmap its own copy of every shared container. Returns false
    /// if the allocation failed, in which case the bitmap is unchanged.
    ///
    @inlinable @inline(__always)
    @discardableResult
    public func unshareAll() -> Bool {
        return croaring.roaring_unshare_all(self.ptr)
    }
}

/////////////////////////////////////////////////////////////////////////////
///                          CLOSURE ITERATION                            ///
/////////////////////////////////////////////////////////////////////////////

extension RoaringBitmap {
    ///
    /// Calls `body` once for every value of the bitmap, in increasing order,
    /// stopping early as soon as `body` returns false. Returns true if the
    /// whole bitmap was visited.
    ///
    /// This is faster than the `Sequence` conformance, at the cost of not being
    /// able to interleave the iteration with other work.
    ///
    @discardableResult
    public func iterate(_ body: (UInt32) -> Bool) -> Bool {
        return withoutActuallyEscaping(body) { body in
            var body = body
            return withUnsafeMutablePointer(to: &body) { context in
                croaring.roaring_iterate(self.ptr, { value, context in
                    let body = context!.assumingMemoryBound(to: ((UInt32) -> Bool).self)
                    return body.pointee(value)
                }, UnsafeMutableRawPointer(context))
            }
        }
    }

    ///
    /// Same as `iterate(_:)`, but each value is widened to 64 bits and combined
    /// with `highBits`, which is useful when the bitmap stands for one slice of
    /// a larger 64-bit set.
    ///
    @discardableResult
    public func iterate64(highBits: UInt64, _ body: (UInt64) -> Bool) -> Bool {
        return withoutActuallyEscaping(body) { body in
            var body = body
            return withUnsafeMutablePointer(to: &body) { context in
                croaring.roaring_iterate64(self.ptr, { value, context in
                    let body = context!.assumingMemoryBound(to: ((UInt64) -> Bool).self)
                    return body.pointee(value)
                }, highBits, UnsafeMutableRawPointer(context))
            }
        }
    }
}

/////////////////////////////////////////////////////////////////////////////
///                             CONVERSIONS                               ///
/////////////////////////////////////////////////////////////////////////////

extension RoaringBitmap {
    ///
    /// Converts the bitmap to a plain uncompressed bitset, returned as its
    /// 64-bit words: value `v` is present when bit `v % 64` of word `v / 64` is
    /// set. Returns nil if the allocation failed.
    ///
    /// Beware that this needs about `maximum() / 8` bytes.
    ///
    public func toBitsetWords() -> [UInt64]? {
        guard let bitset = croaring.bitset_create() else { return nil }
        defer { croaring.bitset_free(bitset) }
        guard croaring.roaring_bitmap_to_bitset(self.ptr, bitset) else { return nil }
        guard let words = bitset.pointee.array else { return [] }
        return [UInt64](UnsafeBufferPointer(start: words, count: bitset.pointee.arraysize))
    }

    ///
    /// Returns `count` words of the bitset, starting at word `firstWord`: value
    /// `64 * (firstWord + k) + i` is present when bit `i` of word `k` is set.
    /// The cost is proportional to `count` plus the number of values and runs
    /// in the range, not to the size of the bitmap.
    ///
    /// `firstWord + count` must be at most 2^26 (that is, 2^32 / 64).
    ///
    public func toBitsetWords(firstWord: UInt32, count: UInt32) -> [UInt64] {
        precondition(UInt64(firstWord) + UInt64(count) <= 1 << 26,
                     "the words must lie within the 32-bit range")
        if count == 0 { return [] }
        return [UInt64](unsafeUninitializedCapacity: Int(count)) { buffer, initialized in
            croaring.roaring_bitmap_word_range_to_bitset(self.ptr, firstWord, count, buffer.baseAddress)
            initialized = Int(count)
        }
    }
}

/////////////////////////////////////////////////////////////////////////////
///                        SERIALIZATION (EXTRAS)                         ///
/////////////////////////////////////////////////////////////////////////////

extension RoaringBitmap {
    ///
    /// Read a bitmap written by `serialize(buffer:)`, reading no more than
    /// `maxbytes` bytes. Returns nil if the buffer does not hold a valid bitmap.
    ///
    public static func deserializeSafe(buffer: [Int8], maxbytes: size_t) -> Self? {
        guard let ptr = croaring.roaring_bitmap_deserialize_safe(buffer, maxbytes) else {
            return nil
        }
        return Self(ptr: ptr)
    }

    ///
    /// How many bytes `frozenSerialize()` needs.
    ///
    @inlinable @inline(__always)
    public func frozenSizeInBytes() -> size_t {
        return croaring.roaring_bitmap_frozen_size_in_bytes(self.ptr)
    }

    ///
    /// Serializes the bitmap in the "frozen" format, which mirrors the in-memory
    /// layout so that `frozenView(bytes:)` can read it back without parsing.
    ///
    /// The format is neither portable across architectures nor stable across
    /// releases of CRoaring; use `portableSerialize(buffer:)` for storage.
    ///
    public func frozenSerialize() -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: self.frozenSizeInBytes())
        guard !buffer.isEmpty else { return buffer }
        buffer.withUnsafeMutableBytes {
            croaring.roaring_bitmap_frozen_serialize(
                self.ptr,
                $0.baseAddress!.assumingMemoryBound(to: CChar.self)
            )
        }
        return buffer
    }

    ///
    /// Creates a read-only bitmap out of bytes produced by `frozenSerialize()`.
    /// Returns nil if the bytes do not hold a valid frozen bitmap.
    ///
    /// The bytes are copied into a suitably aligned buffer owned by the returned
    /// bitmap. The result must only be read, never modified.
    ///
    public static func frozenView(bytes: [UInt8]) -> Self? {
        return withOwnedAlignedCopy(of: bytes, alignment: 32) { buffer in
            croaring.roaring_bitmap_frozen_view(
                buffer.assumingMemoryBound(to: CChar.self),
                bytes.count
            ).map { UnsafeMutablePointer(mutating: $0) }
        }
    }

    ///
    /// Reads a bitmap serialized by `portableSerialize(buffer:)` without copying
    /// the containers out of the buffer, which is faster than
    /// `portableDeserialize(buffer:)` but yields a read-only bitmap.
    ///
    /// The bytes are copied into a buffer owned by the returned bitmap. This is
    /// unsafe in the same ways the underlying C function is: it trusts the bytes
    /// to hold a valid serialized bitmap.
    ///
    public static func portableDeserializeFrozen(bytes: [UInt8]) -> Self? {
        return withOwnedAlignedCopy(of: bytes, alignment: 32) { buffer in
            croaring.roaring_bitmap_portable_deserialize_frozen(
                buffer.assumingMemoryBound(to: CChar.self)
            )
        }
    }

    ///
    /// Copies `bytes` into an aligned buffer, hands it to `makeBitmap`, and ties
    /// the buffer's lifetime to the resulting bitmap.
    ///
    private static func withOwnedAlignedCopy(
        of bytes: [UInt8],
        alignment: Int,
        _ makeBitmap: (UnsafeMutableRawPointer) -> UnsafeMutablePointer<roaring_bitmap_t>?
    ) -> Self? {
        let buffer = UnsafeMutableRawPointer.allocate(
            byteCount: Swift.max(bytes.count, 1),
            alignment: alignment
        )
        bytes.withUnsafeBytes { source in
            if let base = source.baseAddress {
                buffer.copyMemory(from: base, byteCount: bytes.count)
            }
        }
        guard let ptr = makeBitmap(buffer) else {
            buffer.deallocate()
            return nil
        }
        return Self(ptr: ptr, frozenBacking: buffer)
    }
}

/////////////////////////////////////////////////////////////////////////////
///                              VALIDATION                               ///
/////////////////////////////////////////////////////////////////////////////

extension RoaringBitmap {
    ///
    /// (For advanced users.)
    /// Checks the internal invariants of the bitmap, which is mostly useful on
    /// bitmaps that came from an untrusted source. Returns nil when the bitmap
    /// is well formed, and the reason it is not otherwise.
    ///
    public func internalValidate() -> String? {
        var reason: UnsafePointer<CChar>?
        guard !croaring.roaring_bitmap_internal_validate(self.ptr, &reason) else {
            return nil
        }
        return reason.map { String(cString: $0) } ?? "unknown reason"
    }
}

#if compiler(>=6.2)

/////////////////////////////////////////////////////////////////////////////
///                       PORTABLE FORMAT IN PLACE                        ///
/////////////////////////////////////////////////////////////////////////////

@available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0, *)
extension RoaringBitmap {
    ///
    /// Reads a bitmap in the portable format from `bytes`, without copying them
    /// first. Returns nil if `bytes` do not hold a valid bitmap. Reading no more
    /// than `bytes`, the call itself is safe, but a bitmap recovered from
    /// arbitrary bytes may still be malformed: check `internalValidate()` before
    /// using one that came from an untrusted source.
    ///
    @inlinable
    public convenience init?(portableBytes bytes: RawSpan) {
        let ptr = bytes.withUnsafeBytes { bytes in
            bytes.baseAddress.flatMap {
                croaring.roaring_bitmap_portable_deserialize_safe($0.assumingMemoryBound(to: CChar.self), bytes.count)
            }
        }
        guard let ptr = ptr else { return nil }
        self.init(ptr: ptr)
    }

    ///
    /// Appends the bitmap in the portable format to `buffer`, which must have
    /// at least `portableSizeInBytes()` bytes of free capacity.
    ///
    @inlinable
    public func portableSerialize(into buffer: inout OutputRawSpan) {
        precondition(buffer.freeCapacity >= self.portableSizeInBytes(), "buffer has less free capacity than portableSizeInBytes()")
        buffer.withUnsafeMutableBytes { bytes, initializedCount in
            initializedCount += croaring.roaring_bitmap_portable_serialize(
                self.ptr, (bytes.baseAddress! + initializedCount).assumingMemoryBound(to: CChar.self))
        }
    }

    ///
    /// Calls `body` with a read-only view of the portable bitmap in `bytes`, read
    /// in place, and returns its result, or nil if `bytes` do not hold exactly one
    /// valid bitmap or on big-endian machines. Only the layout is checked, not the values: for bytes from
    /// an untrusted source, use `init?(portableBytes:)` and `internalValidate()`.
    ///
    @inlinable
    public static func withPortableView<Result: ~Copyable, Failure: Error>(
        of bytes: RawSpan,
        _ body: (borrowing View) throws(Failure) -> Result
    ) throws(Failure) -> Result? {
        return try bytes.withUnsafeBytes { (bytes) throws(Failure) -> Result? in
            guard let base = bytes.baseAddress?.assumingMemoryBound(to: CChar.self), !bytes.isEmpty,
                  croaring.roaring_bitmap_portable_deserialize_size(base, bytes.count) == bytes.count,
                  portableBytesAreFrozenSafe(bytes),
                  let ptr = croaring.roaring_bitmap_portable_deserialize_frozen(base) else {
                return nil
            }
            defer { croaring.roaring_bitmap_free(ptr) }
            return try body(View(ptr: ptr))
        }
    }

    // roaring_bitmap_portable_deserialize_frozen follows the offset headers, which
    // roaring_bitmap_portable_deserialize_size skips, and sizes run containers by
    // their header cardinality; call only after deserialize_size accepted `bytes`.
    @usableFromInline
    static func portableBytesAreFrozenSafe(_ bytes: UnsafeRawBufferPointer) -> Bool {
        func u16(_ offset: Int) -> Int {
            return Int(UInt16(littleEndian: bytes.loadUnaligned(fromByteOffset: offset, as: UInt16.self)))
        }
        func u32(_ offset: Int) -> Int {
            return Int(UInt32(littleEndian: bytes.loadUnaligned(fromByteOffset: offset, as: UInt32.self)))
        }
        let hasRun = u32(0) & 0xFFFF == Int(SERIAL_COOKIE)
        let count = hasRun ? u32(0) >> 16 + 1 : u32(4)
        let hasOffsets = !hasRun || count >= NO_OFFSET_THRESHOLD
        let headers = hasRun ? 4 + (count + 7) / 8 : 8
        let offsets = headers + 4 * count
        var position = hasOffsets ? offsets + 4 * count : offsets
        for i in 0..<count {
            guard !hasOffsets || u32(offsets + 4 * i) == position else { return false }
            let cardinality = u16(headers + 4 * i + 2) + 1
            if hasRun && bytes[4 + i / 8] & (1 << (i % 8)) != 0 {
                let runs = u16(position)
                guard runs <= cardinality else { return false }
                position += 2 + 4 * runs
            } else if cardinality > DEFAULT_MAX_SIZE {
                position += 8192
            } else {
                position += 2 * cardinality
            }
        }
        return true
    }

    ///
    /// A read-only bitmap reading serialized bytes in place, lent to the body of
    /// `withPortableView(of:_:)`. Being noncopyable and borrowed, it cannot
    /// outlive that call.
    ///
    public struct View: ~Copyable {
        @usableFromInline
        let ptr: UnsafePointer<roaring_bitmap_t>

        @inlinable
        init(ptr: UnsafePointer<roaring_bitmap_t>) {
            self.ptr = ptr
        }

        @inlinable
        public var count: UInt64 {
            return croaring.roaring_bitmap_get_cardinality(self.ptr)
        }

        @inlinable
        public var isEmpty: Bool {
            return croaring.roaring_bitmap_is_empty(self.ptr)
        }

        @inlinable
        public func contains(_ value: UInt32) -> Bool {
            return croaring.roaring_bitmap_contains(self.ptr, value)
        }

        @inlinable
        public func min() -> UInt32? {
            return self.isEmpty ? nil : croaring.roaring_bitmap_minimum(self.ptr)
        }

        @inlinable
        public func max() -> UInt32? {
            return self.isEmpty ? nil : croaring.roaring_bitmap_maximum(self.ptr)
        }

        /// The number of values smaller than or equal to `value`.
        @inlinable
        public func rank(value: UInt32) -> UInt64 {
            return croaring.roaring_bitmap_rank(self.ptr, value)
        }

        /// The value of rank `rank`, the smallest having rank 0.
        @inlinable
        public func select(rank: UInt32) -> UInt32? {
            var value: UInt32 = 0
            return croaring.roaring_bitmap_select(self.ptr, rank, &value) ? value : nil
        }

        /// A mutable copy, for anything a view does not offer.
        public func copy() -> RoaringBitmap {
            return RoaringBitmap(ptr: croaring.roaring_bitmap_copy(self.ptr)!)
        }
    }
}

#endif
