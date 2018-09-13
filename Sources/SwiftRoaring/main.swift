import croaring

final class RoaringBitmap {
    let ptr: UnsafeMutablePointer<roaring_bitmap_t>
    
    /**
    * Creates a new bitmap (initially empty)
    */
    init() {
        self.ptr = croaring.roaring_bitmap_create()!
    }

    /**
    * Add value x
    *
    */
    func add(x:UInt32) {
        croaring.roaring_bitmap_add(self.ptr, x)
    }


    /**
    * Remove value x
    *
    */
    func remove(x:UInt32) {
        croaring.roaring_bitmap_remove(self.ptr, x)
    }

    /**
    * Frees the memory.
    */
    func free() {
        croaring.roaring_bitmap_free(self.ptr)
    }

    /**
    * Print the content of the bitmap.
    */
    func print() {
        croaring.roaring_bitmap_printf(self.ptr)
    }

    /**
    * Check if value x is present
    */
    func contains(x: UInt32) -> Bool {
        return croaring.roaring_bitmap_contains(self.ptr, x)
    }   
    
}

// let bitmap = RoaringBitmap()
// bitmap.add(x: 35)
// print(bitmap.contains(x: 35))