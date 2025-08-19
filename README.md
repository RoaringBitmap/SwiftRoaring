# SwiftRoaring
<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/Swift4-compatible-green.svg?style=flat" alt="Swift 4 compatible" /></a>
<a href="https://github.com/apple/swift-package-manager"><img src="https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg"/></a>
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage) ![Ubuntu  CI](https://github.com/RoaringBitmap/SwiftRoaring/workflows/Swift%20on%20Ubuntu%20(latest)/badge.svg)




Swift wrapper for CRoaring (a C/C++ implementation at https://github.com/RoaringBitmap/CRoaring)

Roaring bitmaps are used by several important systems:

*   [Apache Lucene](http://lucene.apache.org/core/) and derivative systems such as Solr and [Elastic](https://www.elastic.co/),
*   Metamarkets' [Druid](http://druid.io/),
*   [Apache Spark](http://spark.apache.org),
*   [Netflix Atlas](https://github.com/Netflix/atlas),
*   [LinkedIn Pinot](https://github.com/linkedin/pinot/wiki),
*   [OpenSearchServer](http://www.opensearchserver.com),
*   [Cloud Torrent](https://github.com/jpillora/cloud-torrent),
*   [Whoosh](https://pypi.python.org/pypi/Whoosh/),
*   [Pilosa](https://www.pilosa.com/),
*   [Microsoft Visual Studio Team Services (VSTS)](https://www.visualstudio.com/team-services/),
*   eBay's [Apache Kylin](http://kylin.io).

Roaring bitmaps are found to work well in many important applications:

> Use Roaring for bitmap compression whenever possible. Do not use other bitmap compression methods ([Wang et al., SIGMOD 2017](http://db.ucsd.edu/wp-content/uploads/2017/03/sidm338-wangA.pdf))


### Dependencies

Swift 4.0 or higher

### Usage using Swift Package Manager

Create a directory where you will create your application:

```bash
mkdir foo
cd foo
swift package init --type executable
```

Then edit ``Package.swift`` so that it reads something like this:


```swift
import PackageDescription

let package = Package(
    name: "foo",
    dependencies: [
   .package(url: "https://github.com/RoaringBitmap/SwiftRoaring",  from: "0.0.1")
    ],
    targets: [
        .target(
            name: "foo",
            dependencies: ["SwiftRoaring"]),
    ]
)
```

Edit ``main.swift`` (in Sources) so that it looks something like this :

```swift
import SwiftRoaring;

....
```

### Example

Here is a simplified but complete example:

```swift
import SwiftRoaring

//Create a new Roaring Bitmap
let bitmap = RoaringBitmap()

//Example: Add Range
bitmap.addRange(min: 0, max: 500)

//Example: copy
let cpy = bitmap.copy()

//Example: Operators
let and = bitmap && cpy

//Example: Iterate
for i in bitmap {
    print(i)
}

//See documentation for more functionalities!

```

### Development

You can build using Swift Package Manager as follows:

```bash
swift build  --configuration release
```
To find where the library is built, type the following
in your shell:
```bash
 echo $(swift build   --configuration release  --show-bin-path)
```

You can run tests using Swift Package Manager as follows:
```bash
swift test
```

### Interactive use

```
$ swift build  --configuration release
$ swift repl -I .build/release -L .build/release -lSwiftRoaringDynamic
  1> import SwiftRoaring
  2> let bitmap = RoaringBitmap()
  3> bitmap.add(1)
  4> for i in bitmap {
       print(i)
     }
```

### Mailing list/discussion group

https://groups.google.com/g/roaring-bitmaps

### Compatibility with Java RoaringBitmap library

You can read bitmaps in Go, Java, C, C++ that have been serialized in Java, C, C++.

### References

-  Daniel Lemire, Owen Kaser, Nathan Kurz, Luca Deri, Chris O'Hara, François Saint-Jacques, Gregory Ssi-Yan-Kai,  Software: Practice and Experience Volume 48, Issue 4 April 2018 Pages 867-895 [arXiv:1709.07821](https://arxiv.org/abs/1709.07821)
-  Samy Chambi, Daniel Lemire, Owen Kaser, Robert Godin,
Better bitmap performance with Roaring bitmaps,
Software: Practice and Experience Volume 46, Issue 5, pages 709–719, May 2016
http://arxiv.org/abs/1402.6407 This paper used data from http://lemire.me/data/realroaring2014.html
- Daniel Lemire, Gregory Ssi-Yan-Kai, Owen Kaser, Consistently faster and smaller compressed bitmaps with Roaring, Software: Practice and Experience Volume 46, Issue 11, pages 1547-1569, November 2016 http://arxiv.org/abs/1603.06549
