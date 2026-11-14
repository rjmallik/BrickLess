# BrickLess build report

- Commit: 2173e20b1409ddce1e2137e43b32f330b8f56751
- Run: https://github.com/rjmallik/BrickLess/actions/runs/43546478575
- Date: 2026-11-14T02:39:49Z
- Build: success
- Tests: failure

## Build log (tail)
```
    /Applications/Xcode_26.6.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsnltrainingprocessor --infoplist-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/Info.plist --temp-dir-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/PlayMatch.build/ssu --bundle-id rjmallik.BrickLess --product-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app --extracted-metadata-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/Metadata.appintents --metadata-file-list /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/PlayMatch.build/PlayMatch.DependencyMetadataFileList --source-file /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/Info.plist --archive-ssu-assets
2026-11-14 02:33:09.326 appintentsnltrainingprocessor[16206:50251] Parsing options for appintentsnltrainingprocessor
2026-11-14 02:33:09.327 appintentsnltrainingprocessor[16206:50251] Starting AppIntents SSU YAML Generation
2026-11-14 02:33:09.332 appintentsnltrainingprocessor[16206:50251] No AppShortcuts found - Skipping.

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
	15  CoreFoundation                      0x000000018041c904 _CFRunLoopRunSpecificWithOptions + 496
	16  XCTestCore                          0x00000001058a9e38 +[XCTWaiter _synchronouslyWaitForTimeInterval:] + 108
	17  XCTestCore                          0x00000001058aa4f8 -[XCTWaiter _performWait:manager:completionHandler:] + 772
	18  XCTestCore                          0x00000001058a8524 -[XCTWaiter _waitForExpectations:timeout:enforceOrder:synchronously:completionHandler:] + 500
	19  XCTestCore                          0x00000001058a82e0 -[XCTWaiter waitForExpectations:timeout:enforceOrder:] + 108
	20  XCTestCore                          0x00000001058a4588 -[XCTFuture _waitForFulfillmentSync:withCompletion:] + 980
	21  XCTestCore                          0x00000001058a5b2c -[XCTFuture value] + 24
	22  XCTestCore                          0x00000001058de32c -[XCTestDriver _runTests] + 644
	23  XCTestCore                          0x00000001058e03fc _XCTestMain + 116
	24  libXCTestBundleInject.dylib         0x00000001042d948c __RunTests_block_invoke_2 + 0
	25  CoreFoundation                      0x00000001803e6c50 __CFMachPortPerform + 164
	26  CoreFoundation                      0x0000000180423628 __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__ + 56
	27  CoreFoundation                      0x0000000180422c78 __CFRunLoopDoSource1 + 476
	28  CoreFoundation                      0x0000000180421d44 __CFRunLoopRun + 2100
	29  CoreFoundation                      0x000000018041c904 _CFRunLoopRunSpecificWithOptions + 496
	30  GraphicsServices                    0x00000001933599c0 GSEventRunModal + 116
	31  UIKitCore                           0x00000001864a54cc -[UIApplication _run] + 776
	32  UIKitCore                           0x0000000186b9f910 UIApplicationMain + 120
	33  SwiftUI                             0x00000001d2ecdfa4 $s7SwiftUI17KitRendererCommon33_ACC2C5639A7D76F611E170E831FCA491LLys5NeverOyXlXpFAESpySpys4Int8VGSgGXEfU_ + 164
	34  SwiftUI                             0x00000001d2ecdd18 $s7SwiftUI6runAppys5NeverOxAA0D0RzlF + 180
	35  SwiftUI                             0x00000001d2c5f094 $s7SwiftUI3AppPAAE4mainyyFZ + 148
	36  PlayMatch.debug.dylib               0x00000001077f198c $s9PlayMatch0aB3AppV5$mainyyFZ + 40
	37  PlayMatch.debug.dylib               0x00000001077f1a4c __debug_main_executable_dylib_entry_point + 12
	38  dyld                                0x00000001043ff0e4 start_sim + 20
	39  ???                                 0x00000001044ec4e4 0x0 + 4367238372
)
libc++abi: terminating due to uncaught exception of type NSException
2026-11-14 02:39:39.509 xcodebuild[16279:50529] [MT] IDETestOperationsObserverDebug: 289.293 elapsed -- Testing started completed.
2026-11-14 02:39:39.509 xcodebuild[16279:50529] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-11-14 02:39:39.509 xcodebuild[16279:50529] [MT] IDETestOperationsObserverDebug: 289.294 sec, +289.294 sec -- end

Test session results, code coverage, and logs:
	/Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Logs/Test/Test-BrickLess-2026.11.14_02-33-21-+0000.xcresult

Testing failed:
	PlayMatch (22577) encountered an error (Early unexpected exit, operation never finished bootstrapping - no restart will be attempted. (Underlying Error: Test crashed with signal abrt while preparing to run tests.))

** TEST FAILED **

Testing started
```
