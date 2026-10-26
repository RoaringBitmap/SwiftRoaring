// libFuzzer target for the APIs that read untrusted portable bytes.

import SwiftRoaring

/// Input layout: [selector] [8-byte probe value] [portable bitmap bytes...]; selector bit 0 picks 32 or 64-bit.
@_cdecl("LLVMFuzzerTestOneInput")
public func fuzzTest(_ start: UnsafeRawPointer, _ count: Int) -> CInt {
    guard count >= 9 else { return 0 }
    let probe = start.loadUnaligned(fromByteOffset: 1, as: UInt64.self)
    let span = RawSpan(_unsafeBytes: UnsafeRawBufferPointer(start: start + 9, count: count - 9))
    if start.load(as: UInt8.self) & 1 == 0 {
        fuzz32(span, UInt32(truncatingIfNeeded: probe))
    } else {
        fuzz64(span, probe)
    }
    return 0
}

private func fuzz32(_ span: RawSpan, _ x: UInt32) {
    _ = RoaringBitmap.withPortableView(of: span) { view in
        // The view checks layout, not values: invalid values must not fault (ASan), but answers may differ.
        let copy = view.copy()
        guard copy.internalValidate() == nil else { return }
        precondition(view.count == copy.count && view.isEmpty == copy.isEmpty)
        precondition(view.contains(x) == copy.contains(x) && view.contains(x & 0xFFFF) == copy.contains(x & 0xFFFF))
        precondition(view.min() == copy.min() && view.max() == copy.max())
        precondition(view.rank(value: x) == copy.rank(value: x))
        precondition(view.select(rank: x & 0xFFF) == copy.select(rank: x & 0xFFF))
    }
    // CRoaring requires internal_validate before using a bitmap parsed from untrusted bytes.
    if let bitmap = RoaringBitmap(portableBytes: span), bitmap.internalValidate() == nil {
        bitmap.portableSerialize().withUnsafeBytes { raw in
            precondition(RoaringBitmap(portableBytes: RawSpan(_unsafeBytes: raw)) == bitmap, "round trip changed the bitmap")
        }
    }
}

private func fuzz64(_ span: RawSpan, _ x: UInt64) {
    _ = Roaring64Bitmap.withPortableView(of: span) { view in
        let copy = view.copy()
        guard copy.internalValidate() == nil else { return }
        precondition(view.count == copy.count && view.isEmpty == copy.isEmpty)
        precondition(view.contains(x) == copy.contains(x) && view.contains(x & 0xFFFF) == copy.contains(x & 0xFFFF))
        precondition(view.min() == copy.min() && view.max() == copy.max())
        precondition(view.rank(value: x) == copy.rank(value: x))
        precondition(view.select(rank: x & 0xFFF) == copy.select(rank: x & 0xFFF))
    }
    if let bitmap = Roaring64Bitmap(portableBytes: span), bitmap.internalValidate() == nil {
        bitmap.portableSerialize().withUnsafeBytes { raw in
            precondition(Roaring64Bitmap(portableBytes: RawSpan(_unsafeBytes: raw)) == bitmap, "round trip changed the bitmap")
        }
    }
}
