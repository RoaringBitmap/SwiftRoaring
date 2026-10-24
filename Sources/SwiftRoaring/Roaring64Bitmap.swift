import Foundation
import croaring

///
/// This structure contains different values about a given Roaring64Bitmap
///
public typealias Roaring64Statistics = roaring64_statistics_t

///
/// Swift wrapper for the 64-bit bitmaps of CRoaring (a C/C++ implementation at
/// https://github.com/RoaringBitmap/CRoaring)
///
/// A `Roaring64Bitmap` stores `UInt64` values by partitioning the value space on
/// the high 48 bits and using ordinary Roaring containers for the low 16 bits.
/// The API mirrors `RoaringBitmap`, minus the operations CRoaring only offers in
/// 32 bits (the lazy operations, the many-way unions, and the non-portable
/// serialization format).
///
/// Every function of CRoaring's public 64-bit API is reachable from this type:
/// `roaring64_bitmap_add_offset_signed` through the `addOffset(_:)` and
/// `subtractOffset(_:)` pair, and the variadic `roaring64_bitmap_from` macro
/// through `init(values:)` and array literals.
///
public final class Roaring64Bitmap: Sequence, Equatable, CustomStringConvertible,
                                    Hashable, ExpressibleByArrayLiteral, SetAlgebra, Codable {

    @usableFromInline
    let ptr: OpaquePointer

    ///
    /// When this bitmap is a *frozen view* created by `frozenView(bytes:)`, this
    /// holds the aligned buffer the view reads from. It is deallocated, after the
    /// bitmap itself, by `deinit`. It is `nil` for every ordinary bitmap.
    ///
    @usableFromInline
    let frozenBacking: UnsafeMutableRawPointer?

    public typealias Element = UInt64

    /////////////////////////////////////////////////////////////////////////////
    ///                             CONSTRUCTORS                              ///
    /////////////////////////////////////////////////////////////////////////////

    ///
    /// Creates a new bitmap (initially empty)
    ///
    required public convenience init() {
        self.init(ptr: croaring.roaring64_bitmap_create()!)
    }

    ///
    /// Creates a new bitmap using a given ptr
    ///
    required public init(ptr: OpaquePointer) {
        self.ptr = ptr
        self.frozenBacking = nil
    }

    private init(ptr: OpaquePointer, frozenBacking: UnsafeMutableRawPointer) {
        self.ptr = ptr
        self.frozenBacking = frozenBacking
    }

    ///
    /// Add all the values between min (included) and max (excluded) that are at a
    /// distance k*step from min.
    ///
    public convenience init(min: UInt64, max: UInt64, step: UInt64) {
        self.init(ptr: croaring.roaring64_bitmap_from_range(min, max, step)
            ?? croaring.roaring64_bitmap_create()!)
    }

    public convenience init(range: Range<UInt64>, step: UInt64) {
        self.init(min: range.lowerBound, max: range.upperBound, step: step)
    }

    ///
    /// Creates a new bitmap from an array of `uint64_t` integers
    ///
    public convenience init(values: [UInt64]) {
        self.init(ptr: croaring.roaring64_bitmap_of_ptr(values.count, values)!)
    }

    ///
    /// Creates a new 64-bit bitmap holding the values of a 32-bit one, by moving
    /// its containers over. This is cheaper than copying them, but it leaves
    /// `bitmap` empty.
    ///
    public convenience init(moving bitmap: RoaringBitmap) {
        self.init(ptr: croaring.roaring64_bitmap_move_from_roaring32(bitmap.ptr)!)
    }

    ///
    /// Creates a new 64-bit bitmap holding the values of a 32-bit one, which is
    /// left unchanged.
    ///
    public convenience init(_ bitmap: RoaringBitmap) {
        self.init(moving: bitmap.copy())
    }

    public required convenience init(arrayLiteral: Element...) {
        self.init(ptr: croaring.roaring64_bitmap_of_ptr(arrayLiteral.count, arrayLiteral)!)
    }

    deinit {
        croaring.roaring64_bitmap_free(self.ptr)
        self.frozenBacking?.deallocate()
    }

    /////////////////////////////////////////////////////////////////////////////
    ///                             OPERATORS                                 ///
    /////////////////////////////////////////////////////////////////////////////

    ///
    /// Computes the intersection between two bitmaps and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public func intersection(_ other: Roaring64Bitmap) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_and(self.ptr, other.ptr))
    }
    ///
    /// Computes the intersection between two bitmaps and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public static func &(lhs: Roaring64Bitmap, rhs: Roaring64Bitmap) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_and(lhs.ptr, rhs.ptr))
    }

    ///
    /// Inplace version modifies x1, x1 == x2 is allowed
    ///
    @inlinable @inline(__always)
    public func formIntersection(_ other: Roaring64Bitmap) {
        croaring.roaring64_bitmap_and_inplace(self.ptr, other.ptr)
    }
    ///
    /// Inplace version modifies x1, x1 == x2 is allowed
    ///
    @inlinable @inline(__always)
    public static func &=(lhs: Roaring64Bitmap, rhs: Roaring64Bitmap) {
        lhs.formIntersection(rhs)
    }

    ///
    /// Computes the size of the intersection between two bitmaps.
    ///
    @inlinable @inline(__always)
    public func intersectionCount(_ other: Roaring64Bitmap) -> UInt64 {
        return croaring.roaring64_bitmap_and_cardinality(self.ptr, other.ptr)
    }

    ///
    /// Check whether two bitmaps intersect.
    ///
    @inlinable @inline(__always)
    public func intersect(_ other: Roaring64Bitmap) -> Bool {
        return croaring.roaring64_bitmap_intersect(self.ptr, other.ptr)
    }

    ///
    /// Check whether the bitmap has any value in the range [min, max).
    ///
    @inlinable @inline(__always)
    public func intersectWithRange(min: UInt64, max: UInt64) -> Bool {
        return croaring.roaring64_bitmap_intersect_with_range(self.ptr, min, max)
    }

    @inlinable @inline(__always)
    public func intersects(_ range: Range<UInt64>) -> Bool {
        return croaring.roaring64_bitmap_intersect_with_range(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// Computes the Jaccard index between two bitmaps. (Also known as the Tanimoto
    /// distance, or the Jaccard similarity coefficient).
    ///
    /// The Jaccard index is undefined if both bitmaps are empty.
    ///
    @inlinable @inline(__always)
    public func jaccardIndex(_ other: Roaring64Bitmap) -> Double {
        return croaring.roaring64_bitmap_jaccard_index(self.ptr, other.ptr)
    }

    ///
    /// Computes the size of the union between two bitmaps.
    ///
    @inlinable @inline(__always)
    public func unionCount(_ other: Roaring64Bitmap) -> UInt64 {
        return croaring.roaring64_bitmap_or_cardinality(self.ptr, other.ptr)
    }

    ///
    /// Computes the size of the difference (andnot) between two bitmaps.
    ///
    @inlinable @inline(__always)
    public func subtractingCount(_ other: Roaring64Bitmap) -> UInt64 {
        return croaring.roaring64_bitmap_andnot_cardinality(self.ptr, other.ptr)
    }

    ///
    /// Computes the size of the symmetric difference (xor) between two bitmaps.
    ///
    @inlinable @inline(__always)
    public func symmetricDifferenceCount(_ other: Roaring64Bitmap) -> UInt64 {
        return croaring.roaring64_bitmap_xor_cardinality(self.ptr, other.ptr)
    }

    ///
    /// Returns the number of elements in range [min, max).
    ///
    @inlinable @inline(__always)
    public func rangeCardinality(min: UInt64, max: UInt64) -> UInt64 {
        return croaring.roaring64_bitmap_range_cardinality(self.ptr, min, max)
    }

    ///
    /// Returns the number of elements in range [min, max].
    ///
    @inlinable @inline(__always)
    public func rangeCardinalityClosed(min: UInt64, max: UInt64) -> UInt64 {
        return croaring.roaring64_bitmap_range_closed_cardinality(self.ptr, min, max)
    }

    @inlinable @inline(__always)
    public func cardinality(in range: Range<UInt64>) -> UInt64 {
        return croaring.roaring64_bitmap_range_cardinality(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    @inlinable @inline(__always)
    public func cardinality(in range: ClosedRange<UInt64>) -> UInt64 {
        return croaring.roaring64_bitmap_range_closed_cardinality(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// Computes the union between two bitmaps and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public func union(_ other: Roaring64Bitmap) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_or(self.ptr, other.ptr))
    }
    ///
    /// Computes the union between two bitmaps and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public static func |(lhs: Roaring64Bitmap, rhs: Roaring64Bitmap) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_or(lhs.ptr, rhs.ptr))
    }

    ///
    /// Inplace version of `roaring64_bitmap_or`, modifies x1.
    ///
    @inlinable @inline(__always)
    public func formUnion(_ other: Roaring64Bitmap) {
        croaring.roaring64_bitmap_or_inplace(self.ptr, other.ptr)
    }
    ///
    /// Inplace version of `roaring64_bitmap_or`, modifies x1.
    ///
    @inlinable @inline(__always)
    public static func |=(lhs: Roaring64Bitmap, rhs: Roaring64Bitmap) {
        lhs.formUnion(rhs)
    }

    ///
    /// Computes the symmetric difference (xor) between two bitmaps
    /// and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public func symmetricDifference(_ other: Roaring64Bitmap) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_xor(self.ptr, other.ptr))
    }
    ///
    /// Computes the symmetric difference (xor) between two bitmaps
    /// and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public static func ^(lhs: Roaring64Bitmap, rhs: Roaring64Bitmap) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_xor(lhs.ptr, rhs.ptr))
    }

    ///
    /// Inplace version of `roaring64_bitmap_xor`, modifies x1. x1 != x2.
    ///
    @inlinable @inline(__always)
    public func formSymmetricDifference(_ other: Roaring64Bitmap) {
        croaring.roaring64_bitmap_xor_inplace(self.ptr, other.ptr)
    }
    ///
    /// Inplace version of `roaring64_bitmap_xor`, modifies x1. x1 != x2.
    ///
    @inlinable @inline(__always)
    public static func ^=(lhs: Roaring64Bitmap, rhs: Roaring64Bitmap) {
        lhs.formSymmetricDifference(rhs)
    }

    ///
    /// Computes the difference (andnot) between two bitmaps and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public func subtracting(_ other: Roaring64Bitmap) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_andnot(self.ptr, other.ptr))
    }
    ///
    /// Computes the difference (andnot) between two bitmaps and returns new bitmap.
    ///
    @inlinable @inline(__always)
    public static func -(lhs: Roaring64Bitmap, rhs: Roaring64Bitmap) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_andnot(lhs.ptr, rhs.ptr))
    }

    ///
    /// Inplace version of `roaring64_bitmap_andnot`, modifies x1. x1 != x2.
    ///
    @inlinable @inline(__always)
    public func subtract(_ other: Roaring64Bitmap) {
        croaring.roaring64_bitmap_andnot_inplace(self.ptr, other.ptr)
    }
    ///
    /// Inplace version of `roaring64_bitmap_andnot`, modifies x1. x1 != x2.
    ///
    @inlinable @inline(__always)
    public static func -=(lhs: Roaring64Bitmap, rhs: Roaring64Bitmap) {
        lhs.subtract(rhs)
    }

    ///
    /// Return true if the two bitmaps contain the same elements.
    ///
    @inlinable @inline(__always)
    public static func ==(lhs: Roaring64Bitmap, rhs: Roaring64Bitmap) -> Bool {
        return croaring.roaring64_bitmap_equals(lhs.ptr, rhs.ptr)
    }

    ///
    /// Return true if all the elements of ra1 are also in ra2.
    ///
    @inlinable @inline(__always)
    public func isSubset(of other: Roaring64Bitmap) -> Bool {
        return croaring.roaring64_bitmap_is_subset(self.ptr, other.ptr)
    }

    ///
    /// Return true if all the elements of ra1 are also in ra2 and ra2 is strictly
    /// greater than ra1.
    ///
    @inlinable @inline(__always)
    public func isStrictSubset(of other: Roaring64Bitmap) -> Bool {
        return croaring.roaring64_bitmap_is_strict_subset(self.ptr, other.ptr)
    }

    ///
    /// Return true if ra1 and ra2 have no elements in common.
    ///
    @inlinable @inline(__always)
    public func isDisjoint(with other: Roaring64Bitmap) -> Bool {
        return !croaring.roaring64_bitmap_intersect(self.ptr, other.ptr)
    }

    ///
    /// compute the negation of the roaring bitmap within a specified
    /// interval: [rangeStart, rangeEnd). The number of negated values is
    /// rangeEnd - rangeStart.
    /// Areas outside the range are passed through unchanged.
    ///
    @inlinable @inline(__always)
    public func flip(rangeStart: UInt64, rangeEnd: UInt64) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_flip(self.ptr, rangeStart, rangeEnd))
    }

    @inlinable @inline(__always)
    public func flip(_ range: Range<UInt64>) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_flip(
            self.ptr,
            range.lowerBound,
            range.upperBound
        ))
    }

    ///
    /// compute the negation of the roaring bitmap within a specified closed
    /// interval: [rangeStart, rangeEnd].
    /// Areas outside the range are passed through unchanged.
    ///
    @inlinable @inline(__always)
    public func flipClosed(rangeStart: UInt64, rangeEnd: UInt64) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_flip_closed(self.ptr, rangeStart, rangeEnd))
    }

    @inlinable @inline(__always)
    public func flip(_ range: ClosedRange<UInt64>) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_flip_closed(
            self.ptr,
            range.lowerBound,
            range.upperBound
        ))
    }

    ///
    /// compute (in place) the negation of the roaring bitmap within a specified
    /// interval: [rangeStart, rangeEnd).
    /// Areas outside the range are passed through unchanged.
    ///
    @inlinable @inline(__always)
    public func flipInplace(rangeStart: UInt64, rangeEnd: UInt64) {
        croaring.roaring64_bitmap_flip_inplace(self.ptr, rangeStart, rangeEnd)
    }

    @inlinable @inline(__always)
    public func flipInPlace(_ range: Range<UInt64>) {
        croaring.roaring64_bitmap_flip_inplace(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// compute (in place) the negation of the roaring bitmap within a specified
    /// closed interval: [rangeStart, rangeEnd].
    /// Areas outside the range are passed through unchanged.
    ///
    @inlinable @inline(__always)
    public func flipInplaceClosed(rangeStart: UInt64, rangeEnd: UInt64) {
        croaring.roaring64_bitmap_flip_closed_inplace(self.ptr, rangeStart, rangeEnd)
    }

    @inlinable @inline(__always)
    public func flipInPlace(_ range: ClosedRange<UInt64>) {
        croaring.roaring64_bitmap_flip_closed_inplace(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// Returns a new bitmap containing every value of this one shifted up by
    /// `offset`. Values that would overflow are dropped.
    ///
    @inlinable @inline(__always)
    public func addOffset(_ offset: UInt64) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_add_offset(self.ptr, offset))
    }

    ///
    /// Returns a new bitmap containing every value of this one shifted down by
    /// `offset`. Values that would underflow are dropped.
    ///
    @inlinable @inline(__always)
    public func subtractOffset(_ offset: UInt64) -> Self {
        return Self(ptr: croaring.roaring64_bitmap_sub_offset(self.ptr, offset))
    }

    /////////////////////////////////////////////////////////////////////////////
    ///                        MODIFYING AND QUERYING                         ///
    /////////////////////////////////////////////////////////////////////////////

    ///
    /// Copies a bitmap. This does memory allocation.
    ///
    @inlinable @inline(__always)
    public func copy() -> Self {
        return Self(ptr: croaring.roaring64_bitmap_copy(self.ptr))
    }

    ///
    /// Replaces the content of this bitmap with a copy of `other`.
    ///
    /// It might be preferable and simpler to call `copy()`, except that
    /// `overwrite(with:)` can save on memory allocations.
    ///
    @inlinable @inline(__always)
    public func overwrite(with other: Roaring64Bitmap) {
        croaring.roaring64_bitmap_overwrite(self.ptr, other.ptr)
    }

    ///
    /// Add value x
    ///
    @inlinable @inline(__always)
    public func add(_ value: UInt64) {
        croaring.roaring64_bitmap_add(self.ptr, value)
    }

    ///
    /// Add all the values of `values`, faster than repeatedly calling `add(_:)`
    ///
    @inlinable @inline(__always)
    public func addMany(values: [UInt64]) {
        croaring.roaring64_bitmap_add_many(self.ptr, values.count, values)
    }

    ///
    /// Add value x
    /// Returns true if a new value was added, false if the value was already existing.
    ///
    @inlinable @inline(__always)
    public func addCheck(_ value: UInt64) -> Bool {
        return croaring.roaring64_bitmap_add_checked(self.ptr, value)
    }

    ///
    /// Add all values in range [min, max]
    ///
    @inlinable @inline(__always)
    public func addRangeClosed(min: UInt64, max: UInt64) {
        croaring.roaring64_bitmap_add_range_closed(self.ptr, min, max)
    }

    @inlinable @inline(__always)
    public func add(_ range: ClosedRange<UInt64>) {
        croaring.roaring64_bitmap_add_range_closed(
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
        croaring.roaring64_bitmap_add_range(self.ptr, min, max)
    }

    @inlinable @inline(__always)
    public func add(_ range: Range<UInt64>) {
        croaring.roaring64_bitmap_add_range(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    @inlinable @inline(__always)
    @discardableResult
    public func insert(_ newMember: UInt64) -> (inserted: Bool, memberAfterInsert: UInt64) {
        let inserted = self.addCheck(newMember)
        return (inserted, newMember)
    }

    @inlinable @inline(__always)
    @discardableResult
    public func update(with newMember: UInt64) -> UInt64? {
        guard self.addCheck(newMember) else { return newMember }
        return nil
    }

    ///
    /// Remove value x, and return it if it was there.
    ///
    @inlinable @inline(__always)
    @discardableResult
    public func remove(_ value: UInt64) -> UInt64? {
        guard self.removeCheck(value) else { return nil }
        return value
    }

    ///
    /// Remove value x, without reporting whether it was there. Slightly faster
    /// than `remove(_:)`.
    ///
    @inlinable @inline(__always)
    public func discard(_ value: UInt64) {
        croaring.roaring64_bitmap_remove(self.ptr, value)
    }

    ///
    /// Remove value x
    /// Returns true if a value was removed, false if the value was not existing.
    ///
    @inlinable @inline(__always)
    public func removeCheck(_ value: UInt64) -> Bool {
        return croaring.roaring64_bitmap_remove_checked(self.ptr, value)
    }

    ///
    /// Remove multiple values, faster than repeatedly calling `remove(_:)`
    ///
    @inlinable @inline(__always)
    public func removeMany(values: [UInt64]) {
        croaring.roaring64_bitmap_remove_many(self.ptr, values.count, values)
    }

    ///
    /// Remove all values in range [min, max]
    ///
    @inlinable @inline(__always)
    public func removeRangeClosed(min: UInt64, max: UInt64) {
        croaring.roaring64_bitmap_remove_range_closed(self.ptr, min, max)
    }

    @inlinable @inline(__always)
    public func remove(_ range: ClosedRange<UInt64>) {
        croaring.roaring64_bitmap_remove_range_closed(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// Remove all values in range [min, max)
    ///
    @inlinable @inline(__always)
    public func removeRange(min: UInt64, max: UInt64) {
        croaring.roaring64_bitmap_remove_range(self.ptr, min, max)
    }

    @inlinable @inline(__always)
    public func remove(_ range: Range<UInt64>) {
        croaring.roaring64_bitmap_remove_range(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// Empties the bitmap.
    ///
    @inlinable @inline(__always)
    public func clear() {
        croaring.roaring64_bitmap_clear(self.ptr)
    }

    @inlinable @inline(__always)
    public func removeAll() {
        self.clear()
    }

    @inlinable @inline(__always)
    public func removeAll(where shouldBeRemoved: (UInt64) -> Bool) {
        for i in self where shouldBeRemoved(i) {
            self.remove(i)
        }
    }

    ///
    /// Get the cardinality of the bitmap (number of elements).
    ///
    @inlinable @inline(__always)
    public var count: UInt64 {
        return croaring.roaring64_bitmap_get_cardinality(self.ptr)
    }

    ///
    /// Check if value x is present
    ///
    @inlinable @inline(__always)
    public func contains(_ value: UInt64) -> Bool {
        return croaring.roaring64_bitmap_contains(self.ptr, value)
    }

    ///
    /// Check whether all the values from `start` (included) to `end` (excluded)
    /// are present.
    ///
    @inlinable @inline(__always)
    public func containsRange(start: UInt64, end: UInt64) -> Bool {
        return croaring.roaring64_bitmap_contains_range(self.ptr, start, end)
    }

    @inlinable @inline(__always)
    public func contains(_ range: Range<UInt64>) -> Bool {
        return croaring.roaring64_bitmap_contains_range(
            self.ptr,
            range.lowerBound,
            range.upperBound
        )
    }

    ///
    /// Check whether all the values from `min` to `max` (both included) are present.
    ///
    @inlinable @inline(__always)
    public func containsRangeClosed(min: UInt64, max: UInt64) -> Bool {
        return croaring.roaring64_bitmap_contains_range_closed(self.ptr, min, max)
    }

    @inlinable @inline(__always)
    public func contains(_ range: ClosedRange<UInt64>) -> Bool {
        return croaring.roaring64_bitmap_contains_range_closed(
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
        return croaring.roaring64_bitmap_is_empty(self.ptr)
    }

    ///
    /// Returns the element having the designated rank, where the smallest element
    /// has rank 0. Returns nil if the bitmap holds `rank` elements or fewer.
    ///
    @inlinable @inline(__always)
    public func select(rank: UInt64) -> UInt64? {
        var value: UInt64 = 0
        guard croaring.roaring64_bitmap_select(self.ptr, rank, &value) else { return nil }
        return value
    }

    ///
    /// Returns the number of integers that are smaller or equal to x.
    ///
    @inlinable @inline(__always)
    public func rank(value: UInt64) -> UInt64 {
        return croaring.roaring64_bitmap_rank(self.ptr, value)
    }

    ///
    /// Returns the index of `value` in the sorted set, or nil when `value` is
    /// not present. It is equivalent to, but faster than, `rank(value:) - 1`.
    ///
    @inlinable @inline(__always)
    public func index(of value: UInt64) -> UInt64? {
        var index: UInt64 = 0
        guard croaring.roaring64_bitmap_get_index(self.ptr, value, &index) else { return nil }
        return index
    }

    ///
    /// Returns the smallest value in the set.
    /// Returns nil if the set is empty.
    ///
    @inlinable @inline(__always)
    public func min() -> UInt64? {
        guard !self.isEmpty else { return nil }
        return croaring.roaring64_bitmap_minimum(self.ptr)
    }

    @inlinable @inline(__always)
    public var first: UInt64? {
        return self.min()
    }

    @inlinable @inline(__always)
    public func popFirst() -> UInt64? {
        guard let first = self.first else { return nil }
        self.remove(first)
        return first
    }

    ///
    /// Returns the greatest value in the set.
    /// Returns nil if the set is empty.
    ///
    @inlinable @inline(__always)
    public func max() -> UInt64? {
        guard !self.isEmpty else { return nil }
        return croaring.roaring64_bitmap_maximum(self.ptr)
    }

    @inlinable @inline(__always)
    public var last: UInt64? {
        return self.max()
    }

    @inlinable @inline(__always)
    public func popLast() -> UInt64? {
        guard let last = self.last else { return nil }
        self.remove(last)
        return last
    }

    /////////////////////////////////////////////////////////////////////////////
    ///                             OPTIMIZATION                              ///
    /////////////////////////////////////////////////////////////////////////////

    ///
    /// Remove run-length encoding even when it is more space efficient.
    /// Returns whether a change was applied.
    ///
    @inlinable @inline(__always)
    public func removeRunCompression() -> Bool {
        return croaring.roaring64_bitmap_remove_run_compression(self.ptr)
    }

    ///
    /// convert array and bitmap containers to run containers when it is more
    /// efficient; also convert from run containers when more space efficient.
    /// Returns true if the result has at least one run container.
    /// Additional savings might be possible by calling shrink().
    ///
    @inlinable @inline(__always)
    public func runOptimize() -> Bool {
        return croaring.roaring64_bitmap_run_optimize(self.ptr)
    }

    ///
    /// If needed, reallocate memory to shrink the memory usage. Returns
    /// the number of bytes saved.
    ///
    @inlinable @inline(__always)
    public func shrink() -> size_t {
        return croaring.roaring64_bitmap_shrink_to_fit(self.ptr)
    }

    ///
    /// (For advanced users.)
    /// Collect statistics about the bitmap.
    ///
    public func statistics() -> Roaring64Statistics {
        var stats = Roaring64Statistics()
        croaring.roaring64_bitmap_statistics(self.ptr, &stats)
        return stats
    }

    ///
    /// (For advanced users.)
    /// Checks the internal invariants of the bitmap, which is mostly useful on
    /// bitmaps that came from an untrusted source. Returns nil when the bitmap
    /// is well formed, and the reason it is not otherwise.
    ///
    public func internalValidate() -> String? {
        var reason: UnsafePointer<CChar>?
        guard !croaring.roaring64_bitmap_internal_validate(self.ptr, &reason) else {
            return nil
        }
        return reason.map { String(cString: $0) } ?? "unknown reason"
    }

    /////////////////////////////////////////////////////////////////////////////
    ///                              CONVERSION                               ///
    /////////////////////////////////////////////////////////////////////////////

    ///
    /// Convert the bitmap to an array.
    ///
    public func toArray() -> [UInt64] {
        var array = [UInt64](repeating: 0, count: Int(self.count))
        array.withUnsafeMutableBufferPointer {
            croaring.roaring64_bitmap_to_uint64_array(self.ptr, $0.baseAddress)
        }
        return array
    }

    ///
    /// Calls `body` once for every value of the bitmap, in increasing order,
    /// stopping early as soon as `body` returns false. Returns true if the
    /// whole bitmap was visited.
    ///
    /// This is faster than the `Sequence` conformance, at the cost of not being
    /// able to interleave the iteration with other work.
    ///
    @discardableResult
    public func iterate(_ body: (UInt64) -> Bool) -> Bool {
        return withoutActuallyEscaping(body) { body in
            var body = body
            return withUnsafeMutablePointer(to: &body) { context in
                croaring.roaring64_bitmap_iterate(self.ptr, { value, context in
                    let body = context!.assumingMemoryBound(to: ((UInt64) -> Bool).self)
                    return body.pointee(value)
                }, UnsafeMutableRawPointer(context))
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////////
    ///                              ITERATION                                ///
    /////////////////////////////////////////////////////////////////////////////

    ///
    /// Creates a Roaring64BitmapIterator positioned on the smallest value.
    ///
    @inlinable @inline(__always)
    public func makeIterator() -> Roaring64BitmapIterator {
        return Roaring64BitmapIterator(bitmap: self)
    }

    ///
    /// Creates a Roaring64BitmapIterator positioned on the largest value, to be
    /// walked backward with `previous()` or `nextBackward()`.
    ///
    @inlinable @inline(__always)
    public func makeLastIterator() -> Roaring64BitmapIterator {
        return Roaring64BitmapIterator(bitmap: self, atLast: true)
    }

    ///
    /// Used to iterate through values in a 64-bit roaring bitmap.
    ///
    /// Unlike its 32-bit counterpart this is a reference type, because CRoaring
    /// only hands out heap-allocated 64-bit iterators; use `copy()` to fork one.
    ///
    public final class Roaring64BitmapIterator: IteratorProtocol {
        @usableFromInline
        internal var it: OpaquePointer

        ///
        /// Keeps the bitmap the iterator reads from alive.
        ///
        @usableFromInline
        internal let bitmap: Roaring64Bitmap

        @inlinable @inline(__always)
        internal init(bitmap: Roaring64Bitmap) {
            self.it = croaring.roaring64_iterator_create(bitmap.ptr)!
            self.bitmap = bitmap
        }

        @inlinable @inline(__always)
        internal init(bitmap: Roaring64Bitmap, atLast: Bool) {
            self.it = atLast
                ? croaring.roaring64_iterator_create_last(bitmap.ptr)!
                : croaring.roaring64_iterator_create(bitmap.ptr)!
            self.bitmap = bitmap
        }

        @inlinable @inline(__always)
        internal init(
            it: OpaquePointer,
            bitmap: Roaring64Bitmap
        ) {
            self.it = it
            self.bitmap = bitmap
        }

        deinit {
            croaring.roaring64_iterator_free(self.it)
        }

        ///
        /// Returns an independent iterator at the same position.
        ///
        @inlinable @inline(__always)
        public func copy() -> Roaring64BitmapIterator {
            return Roaring64BitmapIterator(
                it: croaring.roaring64_iterator_copy(self.it)!,
                bitmap: self.bitmap
            )
        }

        ///
        /// Rewinds the iterator to the smallest value of `bitmap`.
        ///
        @inlinable @inline(__always)
        public func reinit() {
            croaring.roaring64_iterator_reinit(self.bitmap.ptr, self.it)
        }

        ///
        /// Moves the iterator to the largest value of `bitmap`.
        ///
        @inlinable @inline(__always)
        public func reinitLast() {
            croaring.roaring64_iterator_reinit_last(self.bitmap.ptr, self.it)
        }

        ///
        /// Whether the iterator currently points at a value.
        ///
        @inlinable @inline(__always)
        public var hasValue: Bool {
            return croaring.roaring64_iterator_has_value(self.it)
        }

        ///
        /// The value the iterator points at, undefined when `hasValue` is false.
        ///
        @inlinable @inline(__always)
        public var currentValue: UInt64 {
            return croaring.roaring64_iterator_value(self.it)
        }

        ///
        /// The value the iterator points at, or nil if it is exhausted.
        ///
        @inlinable @inline(__always)
        public var value: UInt64? {
            return self.hasValue ? self.currentValue : nil
        }

        @inlinable @inline(__always)
        public func next() -> UInt64? {
            guard croaring.roaring64_iterator_has_value(self.it) else { return nil }
            let value = croaring.roaring64_iterator_value(self.it)
            croaring.roaring64_iterator_advance(self.it)
            return value
        }

        ///
        /// Moves the iterator to the next value. Returns true if it still points
        /// at a value afterward.
        ///
        @inlinable @inline(__always)
        @discardableResult
        public func advance() -> Bool {
            return croaring.roaring64_iterator_advance(self.it)
        }

        ///
        /// Moves the iterator to the previous value. Returns true if it still
        /// points at a value afterward.
        ///
        @inlinable @inline(__always)
        @discardableResult
        public func previous() -> Bool {
            return croaring.roaring64_iterator_previous(self.it)
        }

        ///
        /// Returns the previous value, walking the bitmap backward, or nil once
        /// the iterator is exhausted. Pair with `makeLastIterator()`.
        ///
        @inlinable @inline(__always)
        public func nextBackward() -> UInt64? {
            guard croaring.roaring64_iterator_has_value(self.it) else { return nil }
            let value = croaring.roaring64_iterator_value(self.it)
            croaring.roaring64_iterator_previous(self.it)
            return value
        }

        ///
        /// Moves the iterator to the smallest value that is greater than or equal
        /// to `value`. Returns true if such a value exists.
        ///
        @inlinable @inline(__always)
        @discardableResult
        public func moveEqualOrLarger(_ value: UInt64) -> Bool {
            return croaring.roaring64_iterator_move_equalorlarger(self.it, value)
        }

        ///
        /// Reads up to `count` values into an array, advancing the iterator past
        /// them. The array is shorter than `count` when the bitmap runs out.
        ///
        public func read(count: UInt64) -> [UInt64] {
            var buffer = [UInt64](repeating: 0, count: Int(count))
            let read = buffer.withUnsafeMutableBufferPointer { buf in
                croaring.roaring64_iterator_read(self.it, buf.baseAddress, count)
            }
            buffer.removeLast(Int(count) - Int(read))
            return buffer
        }

        ///
        /// Reads up to `count` values in decreasing order into an array, moving
        /// the iterator backward past them. Pair with `makeLastIterator()`.
        ///
        public func readBackward(count: UInt64) -> [UInt64] {
            var buffer = [UInt64](repeating: 0, count: Int(count))
            let read = buffer.withUnsafeMutableBufferPointer { buf in
                croaring.roaring64_iterator_read_backward(self.it, buf.baseAddress, count)
            }
            buffer.removeLast(Int(count) - Int(read))
            return buffer
        }

        ///
        /// Reads up to `count` maximal runs of consecutive values, advancing the
        /// iterator past them. `{1, 2, 3, 5, 6}` reads as `[1...3, 5...6]`.
        ///
        public func readRanges(count: Int) -> [ClosedRange<UInt64>] {
            var buffer = [roaring64_range_closed_t](
                repeating: roaring64_range_closed_t(), count: count
            )
            let read = buffer.withUnsafeMutableBufferPointer { buf in
                croaring.roaring64_iterator_read_ranges(self.it, buf.baseAddress, count)
            }
            return buffer.prefix(read).map { $0.min...$0.max }
        }

        ///
        /// Reads up to `count` maximal runs of consecutive values in decreasing
        /// order, moving the iterator backward past them.
        ///
        public func readPreviousRanges(count: Int) -> [ClosedRange<UInt64>] {
            var buffer = [roaring64_range_closed_t](
                repeating: roaring64_range_closed_t(), count: count
            )
            let read = buffer.withUnsafeMutableBufferPointer { buf in
                croaring.roaring64_iterator_read_prev_ranges(self.it, buf.baseAddress, count)
            }
            return buffer.prefix(read).map { $0.min...$0.max }
        }
    }

    /////////////////////////////////////////////////////////////////////////////
    ///                            DESCRIPTION                                ///
    /////////////////////////////////////////////////////////////////////////////

    ///
    /// Returns a string representation of the bitset
    ///
    public var description: String {
        var ret = prefix(100).map { $0.description }.joined(separator: ", ")
        if self.count >= 100 {
            ret.append(", ...")
        }
        return "Roaring64Bitmap(\(ret))"
    }

    ///
    /// Returns a hash value for the bitset. This is expensive and should be
    /// buffered for performance.
    ///
    public func hash(into hasher: inout Hasher) {
        let b: UInt64 = 31
        var hash: UInt64 = 0
        for i in self {
            hash = hash &* b &+ i
        }
        hasher.combine(hash)
    }
}

/////////////////////////////////////////////////////////////////////////////
///                        BULK (CONTEXT) OPERATIONS                      ///
/////////////////////////////////////////////////////////////////////////////

extension Roaring64Bitmap {
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
        internal var context: roaring64_bulk_context_t

        @inlinable @inline(__always)
        public init() {
            self.context = roaring64_bulk_context_t()
        }

        ///
        /// Forgets the cached container, making the context usable again after
        /// the bitmap was modified out of band (or with another bitmap).
        ///
        @inlinable @inline(__always)
        public mutating func reset() {
            self.context = roaring64_bulk_context_t()
        }
    }

    ///
    /// Add value x, using context from a previous insert for speed optimization.
    ///
    @inlinable @inline(__always)
    public func addBulk(_ value: UInt64, context: inout BulkContext) {
        croaring.roaring64_bitmap_add_bulk(self.ptr, &context.context, value)
    }

    ///
    /// Remove value x, using context from a previous removal for speed optimization.
    ///
    @inlinable @inline(__always)
    public func removeBulk(_ value: UInt64, context: inout BulkContext) {
        croaring.roaring64_bitmap_remove_bulk(self.ptr, &context.context, value)
    }

    ///
    /// Check if value x is present, using context from a previous lookup for
    /// speed optimization.
    ///
    @inlinable @inline(__always)
    public func containsBulk(_ value: UInt64, context: inout BulkContext) -> Bool {
        return croaring.roaring64_bitmap_contains_bulk(self.ptr, &context.context, value)
    }
}

/////////////////////////////////////////////////////////////////////////////
///                            SERIALIZATION                              ///
/////////////////////////////////////////////////////////////////////////////

extension Roaring64Bitmap {
    ///
    /// How many bytes are required to serialize this bitmap in the portable
    /// format, which is compatible with the Java and Go versions. See the format
    /// specification at https://github.com/RoaringBitmap/RoaringFormatSpec
    ///
    @inlinable @inline(__always)
    public func portableSizeInBytes() -> size_t {
        return croaring.roaring64_bitmap_portable_size_in_bytes(self.ptr)
    }

    ///
    /// write a bitmap to a char buffer. The output buffer should refer to at least
    /// `portableSizeInBytes()` bytes of allocated memory. Returns how many bytes
    /// were written.
    ///
    @inlinable @inline(__always)
    public func portableSerialize(buffer: inout [Int8]) -> size_t {
        return croaring.roaring64_bitmap_portable_serialize(self.ptr, &buffer)
    }

    ///
    /// Serializes the bitmap in the portable format and returns the bytes.
    ///
    public func portableSerialize() -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: self.portableSizeInBytes())
        guard !buffer.isEmpty else { return buffer }
        buffer.withUnsafeMutableBytes {
            _ = croaring.roaring64_bitmap_portable_serialize(
                self.ptr,
                $0.baseAddress!.assumingMemoryBound(to: CChar.self)
            )
        }
        return buffer
    }

    ///
    /// read a bitmap from a serialized version in a safe manner (reading up to
    /// `maxbytes`). Returns nil if the buffer does not hold a valid bitmap.
    ///
    public static func portableDeserializeSafe(buffer: [Int8], maxbytes: size_t) -> Self? {
        guard let ptr = croaring.roaring64_bitmap_portable_deserialize_safe(buffer, maxbytes) else {
            return nil
        }
        return Self(ptr: ptr)
    }

    ///
    /// read a bitmap from bytes written by `portableSerialize()`. Returns nil if
    /// the bytes do not hold a valid bitmap.
    ///
    public static func portableDeserializeSafe(bytes: [UInt8]) -> Self? {
        let ptr: OpaquePointer? = bytes.withUnsafeBytes {
            croaring.roaring64_bitmap_portable_deserialize_safe(
                $0.baseAddress?.assumingMemoryBound(to: CChar.self),
                bytes.count
            )
        }
        return ptr.map { Self(ptr: $0) }
    }

    ///
    /// Check how many bytes would be read (up to `maxbytes`) at this pointer if
    /// there is a bitmap, returns zero if there is no valid bitmap.
    ///
    @inlinable @inline(__always)
    public static func portableDeserializeSize(buffer: [Int8], maxbytes: size_t) -> size_t {
        return croaring.roaring64_bitmap_portable_deserialize_size(buffer, maxbytes)
    }

    ///
    /// How many bytes `frozenSerialize()` needs. Call `shrink()` first.
    ///
    @inlinable @inline(__always)
    public func frozenSizeInBytes() -> size_t {
        return croaring.roaring64_bitmap_frozen_size_in_bytes(self.ptr)
    }

    ///
    /// Serializes the bitmap in the "frozen" format, which mirrors the in-memory
    /// layout so that `frozenView(bytes:)` can read it back without parsing.
    /// `shrink()` must be called first.
    ///
    /// The format is neither portable across architectures nor stable across
    /// releases of CRoaring; use `portableSerialize()` for storage.
    ///
    public func frozenSerialize() -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: self.frozenSizeInBytes())
        guard !buffer.isEmpty else { return buffer }
        buffer.withUnsafeMutableBytes {
            _ = croaring.roaring64_bitmap_frozen_serialize(
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
        return withOwnedAlignedCopy(of: bytes) { buffer in
            croaring.roaring64_bitmap_frozen_view(
                buffer.assumingMemoryBound(to: CChar.self),
                bytes.count
            )
        }
    }

    ///
    /// Reads a bitmap serialized by `portableSerialize()` without copying the
    /// container payloads out of the buffer, which is faster than
    /// `portableDeserializeSafe(bytes:)` but yields a read-only bitmap. Returns
    /// nil if the bytes do not hold a valid bitmap, and on big-endian machines,
    /// where the payloads cannot be used where they sit.
    ///
    /// The bytes are copied into a buffer owned by the returned bitmap. The
    /// result must only be read, never modified. Reading no more than
    /// `bytes.count`, the call itself is safe, but a bitmap recovered from
    /// arbitrary bytes may still be malformed: check `internalValidate()` before
    /// using one that came from an untrusted source.
    ///
    public static func portableDeserializeFrozen(bytes: [UInt8]) -> Self? {
        return withOwnedAlignedCopy(of: bytes) { buffer in
            croaring.roaring64_bitmap_portable_deserialize_frozen(
                buffer.assumingMemoryBound(to: CChar.self),
                bytes.count
            )
        }
    }

    ///
    /// Copies `bytes` into an aligned buffer, hands it to `makeBitmap`, and ties
    /// the buffer's lifetime to the resulting bitmap.
    ///
    private static func withOwnedAlignedCopy(
        of bytes: [UInt8],
        _ makeBitmap: (UnsafeMutableRawPointer) -> OpaquePointer?
    ) -> Self? {
        let buffer = UnsafeMutableRawPointer.allocate(
            byteCount: Swift.max(bytes.count, 1),
            alignment: 64
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

    ///
    /// Encodable conformance, using the portable format.
    ///
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Data(self.portableSerialize()).base64EncodedString())
    }

    ///
    /// Decodable conformance, using the portable format.
    ///
    public convenience init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let encoded = try container.decode(String.self)
        guard let data = Data(base64Encoded: encoded) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "not valid base64"
            )
        }
        let ptr: OpaquePointer? = data.withUnsafeBytes {
            croaring.roaring64_bitmap_portable_deserialize_safe(
                $0.baseAddress?.assumingMemoryBound(to: CChar.self),
                data.count
            )
        }
        guard let ptr = ptr else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "not a valid serialized Roaring64Bitmap"
            )
        }
        self.init(ptr: ptr)
    }
}

#if compiler(>=6.2)

/////////////////////////////////////////////////////////////////////////////
///                       PORTABLE FORMAT IN PLACE                        ///
/////////////////////////////////////////////////////////////////////////////

@available(macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2, visionOS 1.0, *)
extension Roaring64Bitmap {
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
                croaring.roaring64_bitmap_portable_deserialize_safe($0.assumingMemoryBound(to: CChar.self), bytes.count)
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
            initializedCount += croaring.roaring64_bitmap_portable_serialize(
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
                  croaring.roaring64_bitmap_portable_deserialize_size(base, bytes.count) == bytes.count,
                  let ptr = croaring.roaring64_bitmap_portable_deserialize_frozen(base, bytes.count) else {
                return nil
            }
            defer { croaring.roaring64_bitmap_free(ptr) }
            return try body(View(ptr: ptr))
        }
    }

    ///
    /// A read-only bitmap reading serialized bytes in place, lent to the body of
    /// `withPortableView(of:_:)`. Being noncopyable and borrowed, it cannot
    /// outlive that call.
    ///
    public struct View: ~Copyable {
        @usableFromInline
        let ptr: OpaquePointer

        @inlinable
        init(ptr: OpaquePointer) {
            self.ptr = ptr
        }

        @inlinable
        public var count: UInt64 {
            return croaring.roaring64_bitmap_get_cardinality(self.ptr)
        }

        @inlinable
        public var isEmpty: Bool {
            return croaring.roaring64_bitmap_is_empty(self.ptr)
        }

        @inlinable
        public func contains(_ value: UInt64) -> Bool {
            return croaring.roaring64_bitmap_contains(self.ptr, value)
        }

        @inlinable
        public func min() -> UInt64? {
            return self.isEmpty ? nil : croaring.roaring64_bitmap_minimum(self.ptr)
        }

        @inlinable
        public func max() -> UInt64? {
            return self.isEmpty ? nil : croaring.roaring64_bitmap_maximum(self.ptr)
        }

        /// The number of values smaller than or equal to `value`.
        @inlinable
        public func rank(value: UInt64) -> UInt64 {
            return croaring.roaring64_bitmap_rank(self.ptr, value)
        }

        /// The value of rank `rank`, the smallest having rank 0.
        @inlinable
        public func select(rank: UInt64) -> UInt64? {
            var value: UInt64 = 0
            return croaring.roaring64_bitmap_select(self.ptr, rank, &value) ? value : nil
        }

        /// A mutable copy, for anything a view does not offer.
        public func copy() -> Roaring64Bitmap {
            return Roaring64Bitmap(ptr: croaring.roaring64_bitmap_copy(self.ptr)!)
        }
    }
}

#endif
