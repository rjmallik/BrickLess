# BrickLess build report

- Commit: 9f07d58bb00d24eb9f5ed3b7ebf7ea897fcd59e9
- Run: https://github.com/rjmallik/BrickLess/actions/runs/43530708846
- Date: 2026-11-14T00:00:33Z
- Build: success
- Tests: failure

## Build log (tail)
```
    /Applications/Xcode_26.6.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/appintentsnltrainingprocessor --infoplist-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app/Info.plist --temp-dir-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/BrickLess.build/ssu --bundle-id rjmallik.BrickLess --product-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app --extracted-metadata-path /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app/Metadata.appintents --metadata-file-list /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Intermediates.noindex/BrickLess.build/Debug-iphonesimulator/BrickLess.build/BrickLess.DependencyMetadataFileList --source-file /Users/runner/Library/Developer/Xcode/DerivedData/BrickLess-flmbbyuxtrgebbbganefizynaavw/Build/Products/Debug-iphonesimulator/BrickLess.app/Info.plist --archive-ssu-assets
2026-11-14 00:00:21.348 appintentsnltrainingprocessor[9946:33020] Parsing options for appintentsnltrainingprocessor
2026-11-14 00:00:21.349 appintentsnltrainingprocessor[9946:33020] Starting AppIntents SSU YAML Generation
2026-11-14 00:00:21.353 appintentsnltrainingprocessor[9946:33020] No AppShortcuts found - Skipping.

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
Command line invocation:
    /Applications/Xcode_26.6.app/Contents/Developer/usr/bin/xcodebuild test -project BrickLess.xcodeproj -scheme BrickLess -destination "platform=iOS Simulator,name=iPhone 17"

Resolve Package Graph


Resolved source packages:
  nanopb: https://github.com/firebase/nanopb.git @ 2.30910.0
  GoogleDataTransport: https://github.com/google/GoogleDataTransport.git @ 9.4.0
  GTMSessionFetcher: https://github.com/google/gtm-session-fetcher.git @ 3.4.1
  Firebase: https://github.com/firebase/firebase-ios-sdk.git @ 10.24.0
  leveldb: https://github.com/firebase/leveldb.git @ 1.22.5
  GoogleAppMeasurement: https://github.com/google/GoogleAppMeasurement.git @ 10.24.0
  AppCheck: https://github.com/google/app-check.git @ 10.19.0
  SwiftProtobuf: https://github.com/apple/swift-protobuf.git @ 1.26.0
  gRPC: https://github.com/google/grpc-binary.git @ 1.62.2
  GoogleUtilities: https://github.com/google/GoogleUtilities.git @ 7.13.1
  Promises: https://github.com/google/promises.git @ 2.4.0
  abseil: https://github.com/google/abseil-cpp-binary.git @ 1.2024011601.1
  InteropForGoogle: https://github.com/google/interop-ios-for-google-sdks.git @ 100.0.0

2026-11-14 00:00:32.827 xcodebuild[10003:33235] Writing error result bundle to /var/folders/h5/t85nd63d71x27_8gl5gw3l_w0000gn/T/ResultBundle_2026-14-11_00-00-0032.xcresult
xcodebuild: error: Scheme BrickLess is not currently configured for the test action.

```
