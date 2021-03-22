//
//  Bundle+ADExtension.swift
//  ADPhotoKit
//
//  Created by MAC on 2021/3/22.
//

import Foundation

extension Bundle {
    
    static var photoKitUIBundle: Bundle? {
        return moduleUI
    }
    
    class func resetLocaleUIBundle() {
        locale_UIbundle = nil
    }
    
    private static var locale_UIbundle: Bundle? = nil
    
    private static var moduleUI: Bundle? = {
        let bundleName = "ADPhotoKitUI"

        var candidates = [
            // Bundle should be present here when the package is linked into an App.
            Bundle.main.resourceURL,

            // Bundle should be present here when the package is linked into a framework.
            Bundle(for: ADPhotoKitUI.self).resourceURL,

            // For command-line tools.
            Bundle.main.bundleURL,
        ]
        
        #if SWIFT_PACKAGE
        // For SWIFT_PACKAGE.
        candidates.append(Bundle.module.bundleURL)
        #endif

        for candidate in candidates {
            let bundlePath = candidate?.appendingPathComponent(bundleName + ".bundle")
            if let bundle = bundlePath.flatMap(Bundle.init(url:)) {
                return bundle
            }
        }
        
        return nil
    }()
    
}
