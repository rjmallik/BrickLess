# BrickLess build report

- Commit: 93b2dbb4dd0334312fa6ea00b4462096f1ab4b1a
- Run: https://github.com/rjmallik/BrickLess/actions/runs/43535554875
- Date: 2026-11-14T00:47:42Z
- Build: success
- Tests: failure

## Build log (tail)
```
    /Applications/Xcode_26.6.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsnltrainingprocessor --infoplist-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app/Info.plist --temp-dir-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/BrickLess.build/ssu --bundle-id rjmallik.BrickLess --product-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app --extracted-metadata-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app/Metadata.appintents --metadata-file-list /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/BrickLess.build/BrickLess.DependencyMetadataFileList --source-file /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app/Info.plist --archive-ssu-assets
2026-11-14 00:42:51.758 appintentsnltrainingprocessor[10511:35434] Parsing options for appintentsnltrainingprocessor
2026-11-14 00:42:51.758 appintentsnltrainingprocessor[10511:35434] Starting AppIntents SSU YAML Generation
2026-11-14 00:42:51.764 appintentsnltrainingprocessor[10511:35434] No AppShortcuts found - Skipping.

CodeSign /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app/BrickLess.debug.dylib (in target 'BrickLess' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app/BrickLess.debug.dylib

CodeSign /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app/__preview.dylib (in target 'BrickLess' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app/__preview.dylib

CodeSign /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app (in target 'BrickLess' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    
    Signing Identity:     "Sign to Run Locally"
    
    /usr/bin/codesign --force --sign - --timestamp\=none --generate-entitlement-der /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app

RegisterExecutionPolicyException /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app (in target 'BrickLess' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    builtin-RegisterExecutionPolicyException /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app

Validate /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app (in target 'BrickLess' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    builtin-validationUtility /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app -shallow-bundle -infoplist-subpath Info.plist

Touch /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app (in target 'BrickLess' from project 'BrickLess')
    cd /Users/runner/work/BrickLess/BrickLess
    /usr/bin/touch -c /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app

** BUILD SUCCEEDED **

```

## Test log (tail)
```
	16  XCTestCore                          0x0000000106359e38 +[XCTWaiter _synchronouslyWaitForTimeInterval:] + 108
	17  XCTestCore                          0x000000010635a4f8 -[XCTWaiter _performWait:manager:completionHandler:] + 772
	18  XCTestCore                          0x0000000106358524 -[XCTWaiter _waitForExpectations:timeout:enforceOrder:synchronously:completionHandler:] + 500
	19  XCTestCore                          0x00000001063582e0 -[XCTWaiter waitForExpectations:timeout:enforceOrder:] + 108
	20  XCTestCore                          0x0000000106354588 -[XCTFuture _waitForFulfillmentSync:withCompletion:] + 980
	21  XCTestCore                          0x0000000106355b2c -[XCTFuture value] + 24
	22  XCTestCore                          0x000000010638d558 -[XCTestDriver _prepareTestConfigurationAndIDESession] + 312
	23  XCTestCore                          0x000000010638d3ec -[XCTestDriver run] + 20
	24  XCTestCore                          0x00000001063903fc _XCTestMain + 116
	25  libXCTestBundleInject.dylib         0x0000000104e2548c __RunTests_block_invoke_2 + 0
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
	37  BrickLess.debug.dylib               0x0000000108221eac $s9BrickLess0aB3AppV5$mainyyFZ + 40
	38  BrickLess.debug.dylib               0x0000000108221f6c __debug_main_executable_dylib_entry_point + 12
	39  dyld                                0x0000000104d4b0e4 start_sim + 20
	40  ???                                 0x0000000104e5c4e4 0x0 + 4377134308
)
libc++abi: terminating due to uncaught exception of type NSException
2026-11-14 00:47:35.510 xcodebuild[10609:35716] [MT] IDETestOperationsObserverDebug: 200.896 elapsed -- Testing started completed.
2026-11-14 00:47:35.510 xcodebuild[10609:35716] [MT] IDETestOperationsObserverDebug: 0.000 sec, +0.000 sec -- start
2026-11-14 00:47:35.510 xcodebuild[10609:35716] [MT] IDETestOperationsObserverDebug: 200.896 sec, +200.896 sec -- end

Test session results, code coverage, and logs:
	/Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Logs/Test/Test-BrickLess-2026.11.14_00-43-01-+0000.xcresult

Testing failed:
	BrickLess (16677) encountered an error (Early unexpected exit, operation never finished bootstrapping - no restart will be attempted. (Underlying Error: Test crashed with signal abrt before establishing connection.))

** TEST FAILED **

Testing started
```
