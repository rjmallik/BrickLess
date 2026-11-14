# BrickLess build report

- Commit: 9ed7eee83e45fc0ef1fbaa5d3836e5bd4b247462
- Run: https://github.com/rjmallik/BrickLess/actions/runs/43555130063
- Date: 2026-11-14T04:16:48Z
- Build: failure
- Tests: skipped

## Build log (tail)
```
    

SwiftCompile normal x86_64 /Users/runner/work/BrickLess/BrickLess/BrickLess/LoadingScreenUI.swift (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    

SwiftCompile normal x86_64 /Users/runner/work/BrickLess/BrickLess/BrickLess/UserProfile.swift (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    

SwiftCompile normal x86_64 /Users/runner/work/BrickLess/BrickLess/BrickLess/ProfileSetupView.swift (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    

SwiftCompile normal x86_64 /Users/runner/work/BrickLess/BrickLess/BrickLess/ProfileView.swift (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    

CreateUniversalBinary /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/FirebaseAnalyticsSwift.o normal arm64\ x86_64 (in target 'FirebaseAnalyticsSwift' from project 'Firebase')
    cd /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/SourcePackages/checkouts/firebase-ios-sdk
    /Applications/Xcode_26.6.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/lipo -create /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/Firebase.build/Debug-iphonesimulator/FirebaseAnalyticsSwift.build/Objects-normal/arm64/Binary/FirebaseAnalyticsSwift.o /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/Firebase.build/Debug-iphonesimulator/FirebaseAnalyticsSwift.build/Objects-normal/x86_64/Binary/FirebaseAnalyticsSwift.o -output /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/FirebaseAnalyticsSwift.o

SwiftExplicitDependencyGeneratePcm arm64 /Users/runner/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/SwiftUI-21HO5GXGWMPI9BSAIULZAIM08.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules/FirebaseFirestoreInternal-EVX3YTC8ZLOVG6LOZ7C9LF4TS.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules/GTMSessionFetcherCore-4Y6Z53Z3YZ0ZHGXNNYFGJMYVY.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/SwiftExplicitPrecompiledModules/FirebaseAnalytics-BZZNILR5B1M1URNZLI946IUOY.pcm

SwiftExplicitDependencyGeneratePcm arm64 /Users/runner/Library/Developer/Xcode/DerivedData/ModuleCache.noindex/PhotosUI-CUXW3PBA1A7NL8V4FSUB5GXBV.pcm

** BUILD FAILED **


The following build commands failed:
	EmitSwiftModule normal x86_64 (in target 'PlayMatch' from project 'BrickLess')
	SwiftEmitModule normal x86_64 Emitting\ module\ for\ PlayMatch (in target 'PlayMatch' from project 'BrickLess')
	Building project BrickLess with scheme BrickLess
(3 failures)
```

## Test log (tail)
```
(no test log)
```
