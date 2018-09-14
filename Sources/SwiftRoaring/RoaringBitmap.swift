import croaring

public class RoaringBitmap {
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
    public init(n_args: size_t, vals: [UInt32]) {
        let ptr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: vals)
        self.ptr = croaring.roaring_bitmap_of_ptr(n_args, ptr)!
    }

    // TODO: FIX THIS CONSTRUCTOR
    // /**
    // * Creates a new bitmap from a list of uint32_t integers
    // */
    // public init(list: [UInt32]) {
    //     self.ptr = croaring.roaring_bitmap_of(list.count, list)!
    // }

    /////////////////////////////////////////////////////////////////////////////
    ///                             OPERATORS                                 ///
    /////////////////////////////////////////////////////////////////////////////

    /**
    * Computes the intersection between two bitmaps and returns new bitmap. The
    * caller is
    * responsible for memory management.
    *
    */
    public func and(x: RoaringBitmap) -> RoaringBitmap {
        let x2 = RoaringBitmap()
        x2.ptr = croaring.roaring_bitmap_and(self.ptr, x.ptr)
        return x2

    }

    /**
    * Computes the size of the intersection between two bitmaps.
    *
    */
    public func andCardinality(x: RoaringBitmap) -> UInt64 {
        return croaring.roaring_bitmap_and_cardinality(self.ptr, x.ptr)

    }

    /**
    * Check whether two bitmaps intersect.
    *
    */
    public func intersect(x: RoaringBitmap) -> Bool {
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
    public func jaccardIndex(x: RoaringBitmap) -> Double {
        return croaring.roaring_bitmap_jaccard_index(self.ptr, x.ptr)

    }

    /**
    * Computes the size of the union between two bitmaps.
    *
    */
    public func orCardinality(x: RoaringBitmap) -> UInt64 {
        return croaring.roaring_bitmap_or_cardinality(self.ptr, x.ptr)

    }

    /**
    * Computes the size of the difference (andnot) between two bitmaps.
    *
    */
    public func andNotCardinality(x: RoaringBitmap) -> UInt64 {
        return croaring.roaring_bitmap_andnot_cardinality(self.ptr, x.ptr)

    }

    /**
    * Computes the size of the symmetric difference (andnot) between two bitmaps.
    *
    */
    public func xorCardinality(x: RoaringBitmap) -> UInt64 {
        return croaring.roaring_bitmap_xor_cardinality(self.ptr, x.ptr)

    }

    /**
    * Inplace version modifies x1, x1 == x2 is allowed
    */
    public func inplace(x: RoaringBitmap) {
        croaring.roaring_bitmap_and_inplace(self.ptr, x.ptr)

    }

    /**
    * Computes the union between two bitmaps and returns new bitmap. The caller is
    * responsible for memory management.
    */
    public func or(x: RoaringBitmap) -> RoaringBitmap {
        let x2 = RoaringBitmap()
        x2.ptr = croaring.roaring_bitmap_or(self.ptr, x.ptr)
        return x2

    }

    /**
    * Inplace version of roaring_bitmap_or, modifies x1. TDOO: decide whether x1 ==
    *x2 ok
    *
    */
    public func orInplace(x: RoaringBitmap) {
        croaring.roaring_bitmap_or_inplace(self.ptr, x.ptr)

    }

    /**
    * Compute the union of 'number' bitmaps. See also roaring_bitmap_or_many_heap.
    * Caller is responsible for freeing the
    * result.
    *
    */
    public func orMany(xs: [RoaringBitmap]) -> RoaringBitmap {
        let x2 = RoaringBitmap()
        var ptrArray: [UnsafePointer<roaring_bitmap_t>?] = []
        for x in xs {
            ptrArray.append(x.ptr)
        }
        ptrArray.append(self.ptr)
        let ptrArrayPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: ptrArray)
        x2.ptr = croaring.roaring_bitmap_or_many(ptrArray.count, ptrArrayPtr)
        return x2

    }

    /**
    * Compute the union of 'number' bitmaps using a heap. This can
    * sometimes be faster than roaring_bitmap_or_many which uses
    * a naive algorithm. Caller is responsible for freeing the
    * result.
    *
    */
    public func orManyHeap(xs: [RoaringBitmap]) -> RoaringBitmap {
        let x2 = RoaringBitmap()
        var ptrArray: [UnsafePointer<roaring_bitmap_t>?] = []
        for x in xs {
            ptrArray.append(x.ptr)
        }
        ptrArray.append(self.ptr)
        let ptrArrayPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: ptrArray)
        x2.ptr = croaring.roaring_bitmap_or_many_heap(UInt32(ptrArray.count), ptrArrayPtr)
        return x2

    }

    /**
    * Computes the symmetric difference (xor) between two bitmaps
    * and returns new bitmap. The caller is responsible for memory management.
    */
    public func xor(x: RoaringBitmap) -> RoaringBitmap {
        let x2 = RoaringBitmap()
        x2.ptr = croaring.roaring_bitmap_xor(self.ptr, x.ptr)
        return x2

    }

    /**
    * Inplace version of roaring_bitmap_xor, modifies x1. x1 != x2.
    *
    */
    public func xorInplace(x: RoaringBitmap) {
        croaring.roaring_bitmap_xor_inplace(self.ptr, x.ptr)

    }

    /**
    * Compute the xor of 'number' bitmaps.
    * Caller is responsible for freeing the
    * result.
    *
    */
    public func xorMany(xs: [RoaringBitmap]) -> RoaringBitmap {
        let x2 = RoaringBitmap()
        var ptrArray: [UnsafePointer<roaring_bitmap_t>?] = []
        for x in xs {
            ptrArray.append(x.ptr)
        }
        ptrArray.append(self.ptr)
        let ptrArrayPtr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: ptrArray)
        x2.ptr = croaring.roaring_bitmap_xor_many(ptrArray.count, ptrArrayPtr)
        return x2

    }


    /**
    * Computes the  difference (andnot) between two bitmaps
    * and returns new bitmap. The caller is responsible for memory management.
    */
    public func andNot(x: RoaringBitmap) -> RoaringBitmap {
        let x2 = RoaringBitmap()
        x2.ptr = croaring.roaring_bitmap_andnot(self.ptr, x.ptr)
        return x2

    }

    /**
    * Inplace version of roaring_bitmap_andnot, modifies x1. x1 != x2.
    *
    */
    public func andNotInplace(x: RoaringBitmap) {
        croaring.roaring_bitmap_andnot_inplace(self.ptr, x.ptr)

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
        let cpy = RoaringBitmap()
        cpy.ptr = croaring.roaring_bitmap_copy(self.ptr)
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
    public func add(x:UInt32) {
        croaring.roaring_bitmap_add(self.ptr, x)
    }

    /**
    * Add value n_args from pointer vals, faster than repeatedly calling
    * roaring_bitmap_add
    *
    */
    public func addMany(n_args: size_t, vals: [UInt32]) {
        let ptr: UnsafeMutablePointer = UnsafeMutablePointer(mutating: vals)
        croaring.roaring_bitmap_add_many(self.ptr, n_args, ptr)
    }

    /**
    * Add value x
    * Returns true if a new value was added, false if the value was already existing.
    */
    public func addCheck(x:UInt32) -> Bool {
        return croaring.roaring_bitmap_add_checked(self.ptr, x)
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
    public func remove(x:UInt32) {
        croaring.roaring_bitmap_remove(self.ptr, x)
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
    public func removeCheck(x:UInt32) -> Bool {
        return croaring.roaring_bitmap_remove_checked(self.ptr, x)
    }

    /**
    * Frees the memory.
    */
    public func free() {
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
    public func count(x: UInt32) -> UInt64 {
        return croaring.roaring_bitmap_get_cardinality(self.ptr)
    }

    /**
    * Check if value x is present
    */
    public func contains(x: UInt32) -> Bool {
        return croaring.roaring_bitmap_contains(self.ptr, x)
    }

    /**
    * Check whether a range of values from range_start (included) to range_end (excluded) is present
    */
    public func containsRange(start: UInt64, end: UInt64) -> Bool {
        return croaring.roaring_bitmap_contains_range(self.ptr, start, end)
    }
    
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
    
}