# SwiftRoaring benchmarks

Benchmarks of the SwiftRoaring API, copying CRoaring v5.1.0 [benchmarks/benchmark.cpp](https://github.com/RoaringBitmap/CRoaring/blob/v5.1.0/benchmarks/benchmark.cpp) by name and input. Built on [package-benchmark](https://github.com/ordo-one/benchmark).

## Run

```bash
./fetch-datasets.sh        # census1881, weather_sept_85, wikileaks-noquotes; `all` for all nine
swift package benchmark
swift package benchmark --filter '.*/census1881'
```

## Compare a change

Swap only the library sources, so both runs use the same benchmarks:

```bash
git checkout master -- ../Sources
swift package --allow-writing-to-package-directory benchmark baseline update master
git checkout HEAD -- ../Sources
swift package benchmark baseline compare master
```

## Compare with C

Swift times one pass; C reports the fastest window per operation. Divide the Swift p0 by:

- `microbench/IterateAll`, `frozen/portable_deserialize`, `frozen/portable_deserialize_frozen`: bitmaps (200).
- `microbench/RandomAccess`: 3 x bitmaps.
- `microbench/SuccessiveIntersection`: bitmaps - 1.
- `iteration/previous`: union cardinality.
- `roaring_bitmap/add/*`, `roaring_bitmap/remove/*`: 200,000.

package-benchmark's malloc interposer adds a few nanoseconds per allocation, so allocation-heavy benchmarks run slower than C's own binary.
