# Build status — WeaveGlass 0.3.0 Alpha

| Check | Result |
|---|---|
| Bundle / version / Theos file references | Statically checked |
| Unit-style static source assertions | See `test-results.txt` (24 tests) |
| Original handoff archives retained | No: private original archives excluded from public repository |
| Apple iOS SDK Objective-C type compilation | **Not run; Xcode/iOS SDK unavailable** |
| Theos / Logos compile & link | **Not run; Theos unavailable** |
| Package `.deb` | **Not produced** |
| iOS 26 WeChat launch, UIKit hierarchy and controls | **Not tested** |

Static tests cannot prove a dylib will compile or load. First test with an iOS 26+ capable injection device and a fixed WeChat version. `docs/03-module-coverage.md` contains exact acceptance checks.
