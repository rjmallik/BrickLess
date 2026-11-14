# BrickLess build report

- Commit: 73a9792b49f8035c22ebab73a911e9cbbff5ad79
- Run: https://github.com/rjmallik/BrickLess/actions/runs/43551005866
- Date: 2026-11-14T03:24:08Z
- Build: success
- Tests: failure

## Build log (tail)
```
    /Applications/Xcode_26.6.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsnltrainingprocessor --infoplist-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/Info.plist --temp-dir-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/PlayMatch.build/ssu --bundle-id rjmallik.BrickLess --product-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app --extracted-metadata-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/Metadata.appintents --metadata-file-list /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/PlayMatch.build/PlayMatch.DependencyMetadataFileList --source-file /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/Info.plist --archive-ssu-assets
2026-11-14 03:23:19.791 appintentsnltrainingprocessor[8479:30985] Parsing options for appintentsnltrainingprocessor
2026-11-14 03:23:19.791 appintentsnltrainingprocessor[8479:30985] Starting AppIntents SSU YAML Generation
2026-11-14 03:23:19.796 appintentsnltrainingprocessor[8479:30985] No AppShortcuts found - Skipping.

CodeSign /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/PlayMatch.debug.dylib (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/PlayMatch.debug.dylib

CodeSign /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/__preview.dylib (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/__preview.dylib

CodeSign /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app

RegisterExecutionPolicyException /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    builtin-RegisterExecutionPolicyException /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app

Validate /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    builtin-validationUtility /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app -shallow-bundle -infoplist-subpath Info.plist

Touch /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    /usr/bin/touch -c /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app

** BUILD SUCCEEDED **

```

## Test log (tail)
```
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/BrickLessTests.build/Objects-normal/arm64/BrickLessTests.swiftdoc /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLessTests.swiftmodule/arm64-apple-ios-simulator.swiftdoc

Copy /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLessTests.swiftmodule/arm64-apple-ios-simulator.abi.json /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/BrickLessTests.build/Objects-normal/arm64/BrickLessTests.abi.json (in target 'BrickLessTests' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/BrickLessTests.build/Objects-normal/arm64/BrickLessTests.abi.json /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLessTests.swiftmodule/arm64-apple-ios-simulator.abi.json

Copy /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLessTests.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/BrickLessTests.build/Objects-normal/arm64/BrickLessTests.swiftsourceinfo (in target 'BrickLessTests' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    builtin-copy -exclude .DS_Store -exclude CVS -exclude .svn -exclude .git -exclude .hg -resolve-src-symlinks -rename /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/BrickLessTests.build/Objects-normal/arm64/BrickLessTests.swiftsourceinfo /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLessTests.swiftmodule/Project/arm64-apple-ios-simulator.swiftsourceinfo

SwiftCompile normal arm64 Compiling\ TestHelpers.swift,\ UserProfileTests.swift /Users/runner/work/BrickLess/BrickLess/BrickLessTests/TestHelpers.swift /Users/runner/work/BrickLess/BrickLess/BrickLessTests/UserProfileTests.swift (in target 'BrickLessTests' from project 'BrickLess')
SwiftCompile normal arm64 /Users/runner/work/BrickLess/BrickLess/BrickLessTests/TestHelpers.swift (in target 'BrickLessTests' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    

SwiftCompile normal arm64 /Users/runner/work/BrickLess/BrickLess/BrickLessTests/UserProfileTests.swift (in target 'BrickLessTests' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    

SwiftDriverJobDiscovery normal arm64 Compiling LocationSetupTests.swift, PlayersFilteringTests.swift, SignupValidationTests.swift (in target 'BrickLessTests' from project 'BrickLess')

SwiftDriverJobDiscovery normal arm64 Compiling BookingTests.swift, ChatTests.swift, CourtTests.swift (in target 'BrickLessTests' from project 'BrickLess')


Test session results, code coverage, and logs:
	/Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Logs/Test/Test-BrickLess-2026.11.14_03-23-26-+0000.xcresult

Testing failed:
	Cannot find type 'Color' in scope
	Cannot infer key path type from context; consider explicitly specifying a root type
	Testing cancelled because the build failed.

** TEST FAILED **


The following build commands failed:
	SwiftCompile normal arm64 Compiling\ SessionLaunchTests.swift,\ SportTabsTests.swift,\ DeleteAccountTests.swift /Users/runner/work/BrickLess/BrickLess/BrickLessTests/SessionLaunchTests.swift /Users/runner/work/BrickLess/BrickLess/BrickLessTests/SportTabsTests.swift /Users/runner/work/BrickLess/BrickLess/BrickLessTests/DeleteAccountTests.swift (in target 'BrickLessTests' from project 'BrickLess')
	SwiftCompile normal arm64 /Users/runner/work/BrickLess/BrickLess/BrickLessTests/SportTabsTests.swift (in target 'BrickLessTests' from project 'BrickLess')
	Testing project BrickLess with scheme BrickLess
(3 failures)
```
