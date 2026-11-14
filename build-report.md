# BrickLess build report

- Commit: 492fd05b69a1798fd3ef6ec5733c3730a22bb7a8
- Run: https://github.com/rjmallik/BrickLess/actions/runs/43545944897
- Date: 2026-11-14T02:27:35Z
- Build: success
- Tests: success

## Build log (tail)
```
    /Applications/Xcode_26.6.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsnltrainingprocessor --infoplist-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/Info.plist --temp-dir-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/PlayMatch.build/ssu --bundle-id rjmallik.BrickLess --product-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app --extracted-metadata-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/Metadata.appintents --metadata-file-list /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/PlayMatch.build/PlayMatch.DependencyMetadataFileList --source-file /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/PlayMatch.app/Info.plist --archive-ssu-assets
2026-11-14 02:26:00.144 appintentsnltrainingprocessor[12590:42353] Parsing options for appintentsnltrainingprocessor
2026-11-14 02:26:00.144 appintentsnltrainingprocessor[12590:42353] Starting AppIntents SSU YAML Generation
2026-11-14 02:26:00.148 appintentsnltrainingprocessor[12590:42353] No AppShortcuts found - Skipping.

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
	14  CoreFoundation                      0x0000000180422a94 __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__ + 12
	15  CoreFoundation                      0x0000000180421c6c __CFRunLoopRun + 1884
	16  CoreFoundation                      0x000000018041c904 _CFRunLoopRunSpecificWithOptions + 496
	17  XCTestCore                          0x0000000106469e38 +[XCTWaiter _synchronouslyWaitForTimeInterval:] + 108
	18  XCTestCore                          0x000000010646a4f8 -[XCTWaiter _performWait:manager:completionHandler:] + 772
	19  XCTestCore                          0x0000000106468524 -[XCTWaiter _waitForExpectations:timeout:enforceOrder:synchronously:completionHandler:] + 500
	20  XCTestCore                          0x00000001064682e0 -[XCTWaiter waitForExpectations:timeout:enforceOrder:] + 108
	21  XCTestCore                          0x0000000106464588 -[XCTFuture _waitForFulfillmentSync:withCompletion:] + 980
	22  XCTestCore                          0x0000000106465b2c -[XCTFuture value] + 24
	23  XCTestCore                          0x000000010649ecb0 -[XCTestDriver _reportFinishedExecutingTests] + 208
	24  XCTestCore                          0x000000010649e620 -[XCTestDriver _runTests] + 1400
	25  XCTestCore                          0x00000001064a03fc _XCTestMain + 116
	26  libXCTestBundleInject.dylib         0x0000000104e6948c __RunTests_block_invoke_2 + 0
	27  CoreFoundation                      0x00000001803e6c50 __CFMachPortPerform + 164
	28  CoreFoundation                      0x0000000180423628 __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__ + 56
	29  CoreFoundation                      0x0000000180422c78 __CFRunLoopDoSource1 + 476
	30  CoreFoundation                      0x0000000180421d44 __CFRunLoopRun + 2100
	31  CoreFoundation                      0x000000018041c904 _CFRunLoopRunSpecificWithOptions + 496
	32  GraphicsServices                    0x00000001933599c0 GSEventRunModal + 116
	33  UIKitCore                           0x00000001864a54cc -[UIApplication _run] + 776
	34  UIKitCore                           0x0000000186b9f910 UIApplicationMain + 120
	35  SwiftUI                             0x00000001d2ecdfa4 $s7SwiftUI17KitRendererCommon33_ACC2C5639A7D76F611E170E831FCA491LLys5NeverOyXlXpFAESpySpys4Int8VGSgGXEfU_ + 164
	36  SwiftUI                             0x00000001d2ecdd18 $s7SwiftUI6runAppys5NeverOxAA0D0RzlF + 180
	37  SwiftUI                             0x00000001d2c5f094 $s7SwiftUI3AppPAAE4mainyyFZ + 148
	38  PlayMatch.debug.dylib               0x000000010840598c $s9PlayMatch0aB3AppV5$mainyyFZ + 40
	39  PlayMatch.debug.dylib               0x0000000108405a4c __debug_main_executable_dylib_entry_point + 12
	40  dyld                                0x00000001051870e4 start_sim + 20
	41  ???                                 0x0000000104f004e4 0x0 + 4377806052
)
libc++abi: terminating due to uncaught exception of type NSException
2026-11-14 02:27:30.469 xcodebuild[12602:42448] [MT] IDETestOperationsObserverDebug: 49.136 elapsed -- Testing started completed.
2026-11-14 02:27:30.469 xcodebuild[12602:42448] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-11-14 02:27:30.469 xcodebuild[12602:42448] [MT] IDETestOperationsObserverDebug: 49.136 sec, +49.136 sec -- end

Test session results, code coverage, and logs:
	/Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Logs/Test/Test-BrickLess-2026.11.14_02-26-05-+0000.xcresult

** TEST SUCCEEDED **

Testing started
```
