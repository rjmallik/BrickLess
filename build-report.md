# BrickLess build report

- Commit: c5d95887065acf9ae9a3e1e92ec144c6690074fc
- Run: https://github.com/rjmallik/PlayMatch/actions/runs/43569361997
- Date: 2026-11-14T07:09:57Z
- Build: success
- Tests: failure

## Build log (tail)
```
    /Applications/Xcode_26.6.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsnltrainingprocessor --infoplist-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app/Info.plist --temp-dir-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/PlayMatch.build/ssu --bundle-id rjmallik.BrickLess --product-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app --extracted-metadata-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app/Metadata.appintents --metadata-file-list /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/PlayMatch.build/PlayMatch.DependencyMetadataFileList --source-file /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app/Info.plist --archive-ssu-assets
2026-11-14 07:06:57.687 appintentsnltrainingprocessor[7802:29048] Parsing options for appintentsnltrainingprocessor
2026-11-14 07:06:57.687 appintentsnltrainingprocessor[7802:29048] Starting AppIntents SSU YAML Generation
2026-11-14 07:06:57.691 appintentsnltrainingprocessor[7802:29048] No AppShortcuts found - Skipping.

CodeSign /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app/PlayMatch.debug.dylib (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/PlayMatch/PlayMatch
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app/PlayMatch.debug.dylib

CodeSign /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app/__preview.dylib (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/PlayMatch/PlayMatch
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app/__preview.dylib

CodeSign /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/PlayMatch/PlayMatch
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app

RegisterExecutionPolicyException /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/PlayMatch/PlayMatch
    builtin-RegisterExecutionPolicyException /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app

Validate /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/PlayMatch/PlayMatch
    builtin-validationUtility /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app -shallow-bundle -infoplist-subpath Info.plist

Touch /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app (in target 'PlayMatch' from project 'BrickLess')
    cd /Users/runner/work/PlayMatch/PlayMatch
    /usr/bin/touch -c /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Build/Products/Debug-iphonesimulator/PlayMatch.app

** BUILD SUCCEEDED **

```

## Test log (tail)
```
	16  CoreFoundation                      0x000000018041c904 _CFRunLoopRunSpecificWithOptions + 496
	17  XCTestCore                          0x00000001018e9e38 +[XCTWaiter _synchronouslyWaitForTimeInterval:] + 108
	18  XCTestCore                          0x00000001018ea4f8 -[XCTWaiter _performWait:manager:completionHandler:] + 772
	19  XCTestCore                          0x00000001018e8524 -[XCTWaiter _waitForExpectations:timeout:enforceOrder:synchronously:completionHandler:] + 500
	20  XCTestCore                          0x00000001018e82e0 -[XCTWaiter waitForExpectations:timeout:enforceOrder:] + 108
	21  XCTestCore                          0x00000001018e4588 -[XCTFuture _waitForFulfillmentSync:withCompletion:] + 980
	22  XCTestCore                          0x00000001018e5b2c -[XCTFuture value] + 24
	23  XCTestCore                          0x000000010191e154 -[XCTestDriver _runTests] + 172
	24  XCTestCore                          0x00000001019203fc _XCTestMain + 116
	25  libXCTestBundleInject.dylib         0x000000010028d48c __RunTests_block_invoke_2 + 0
	26  CoreFoundation                      0x00000001803e6c50 __CFMachPortPerform + 164
	27  CoreFoundation                      0x0000000180423628 __CFRUNLOOP_IS_CALLING_OUT_TO_A_SOURCE1_PERFORM_FUNCTION__ + 56
	28  CoreFoundation                      0x0000000180422c78 __CFRunLoopDoSource1 + 476
	29  CoreFoundation                      0x0000000180421d44 __CFRunLoopRun + 2100
	30  CoreFoundation                      0x000000018041c904 _CFRunLoopRunSpecificWithOptions + 496
	31  GraphicsServices                    0x00000001933599c0 GSEventRunModal + 116
	32  UIKitCore                           0x00000001864a54cc -[UIApplication _run] + 776
	33  UIKitCore                           0x0000000186b9f910 UIApplicationMain + 120
	34  SwiftUI                             0x00000001d2ecdfa4 $s7SwiftUI17KitRendererCommon33_ACC2C5639A7D76F611E170E831FCA491LLys5NeverOyXlXpFAESpySpys4Int8VGSgGXEfU_ + 164
	35  SwiftUI                             0x00000001d2ecdd18 $s7SwiftUI6runAppys5NeverOxAA0D0RzlF + 180
	36  SwiftUI                             0x00000001d2c5f094 $s7SwiftUI3AppPAAE4mainyyFZ + 148
	37  PlayMatch.debug.dylib               0x0000000103a3db7c $s9PlayMatch0aB3AppV5$mainyyFZ + 40
	38  PlayMatch.debug.dylib               0x0000000103a3dc3c __debug_main_executable_dylib_entry_point + 12
	39  dyld                                0x00000001003b30e4 start_sim + 20
	40  ???                                 0x00000001005ac4e4 0x0 + 4300915940
)
libc++abi: terminating due to uncaught exception of type NSException
2026-11-14 07:09:52.210 xcodebuild[7811:29104] [MT] IDETestOperationsObserverDebug: 126.430 elapsed -- Testing started completed.
2026-11-14 07:09:52.210 xcodebuild[7811:29104] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-11-14 07:09:52.210 xcodebuild[7811:29104] [MT] IDETestOperationsObserverDebug: 126.430 sec, +126.430 sec -- end

Test session results, code coverage, and logs:
	/Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-celrmpaezphlteaxkyazfzkfesbk/Logs/Test/Test-BrickLess-2026.11.14_07-07-03-+0000.xcresult

Testing failed:
	PlayMatch (11516) encountered an error (Early unexpected exit, operation never finished bootstrapping - no restart will be attempted. (Underlying Error: Test crashed with signal abrt while preparing to run tests.))

** TEST FAILED **

Testing started
```

## Build errors
```
```

## Test errors
```
2026-11-14 07:08:51.054872+0000 PlayMatch[11516:42337] [Client] Synchronous remote object proxy returned error: Error Domain=NSCocoaErrorDomain Code=4099 "The connection to service named com.apple.commcenter.coretelephony.xpc was invalidated: Connection init failed at lookup with error 3 - No such process." UserInfo={NSDebugDescription=The connection to service named com.apple.commcenter.coretelephony.xpc was invalidated: Connection init failed at lookup with error 3 - No such process.}
2026-11-14 07:08:51.485483+0000 PlayMatch[11516:42337] [Client] Synchronous remote object proxy returned error: Error Domain=NSCocoaErrorDomain Code=4099 "The connection to service named com.apple.commcenter.coretelephony.xpc was invalidated: Connection init failed at lookup with error 3 - No such process." UserInfo={NSDebugDescription=The connection to service named com.apple.commcenter.coretelephony.xpc was invalidated: Connection init failed at lookup with error 3 - No such process.}
```
