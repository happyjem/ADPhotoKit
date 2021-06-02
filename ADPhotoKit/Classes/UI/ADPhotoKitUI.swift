//
//  ADPhotoKitUI.swift
//  ADPhotoKit
//
//  Created by MAC on 2021/3/20.
//

import Foundation
import UIKit
import Photos

/// Style to display picker.
public enum ADPickerStyle {
    /// The display relationship between the album list and the thumbnail interface is push.
    case normal
    /// The album list is embedded in the navigation of the thumbnail interface, click the drop-down display.
    case embed
}

/// Options to control the asset select condition and ui.
public struct ADAssetSelectOptions: OptionSet {
    public let rawValue: Int
    
    /// Whether photos and videos can be selected together.
    public static let mixSelect = ADAssetSelectOptions(rawValue: 1 << 0)
    /// Allow select Gif, it only controls whether it is displayed in Gif form.
    public static let selectAsGif = ADAssetSelectOptions(rawValue: 1 << 1)
    /// Allow select LivePhoto, it only controls whether it is displayed in LivePhoto form.
    public static let selectAsLivePhoto = ADAssetSelectOptions(rawValue: 1 << 2)
    /// You can slide select photos in album.
    public static let slideSelect = ADAssetSelectOptions(rawValue: 1 << 3)
    /// If `slideSelect` contain, Will auto scroll to top or bottom when your finger at the top or bottom.
    public static let autoScroll = ADAssetSelectOptions(rawValue: 1 << 4)
    /// Allow take photo asset in the album.
    public static let allowTakePhotoAsset = ADAssetSelectOptions(rawValue: 1 << 5)
    /// Allow take video asset in the album.
    public static let allowTakeVideoAsset = ADAssetSelectOptions(rawValue: 1 << 6)
    /// Show the image captured by the camera is displayed on the camera button inside the album.
    public static let captureOnTakeAsset = ADAssetSelectOptions(rawValue: 1 << 7)
    /// If user choose limited Photo mode, a button with '+' will be added. It will call PHPhotoLibrary.shared().presentLimitedLibraryPicker(from:) to add photo.
    @available(iOS 14, *)
    public static let allowAddAsset = ADAssetSelectOptions(rawValue: 1 << 8)
    /// iOS14 limited Photo mode, will show collection footer view in ADThumbnailViewController.
    /// Will go to system setting if clicked.
    @available(iOS 14, *)
    public static let allowAuthTips = ADAssetSelectOptions(rawValue: 1 << 9)
    /// Allow access to the browse large image interface (That is, whether to allow access to the large image interface after clicking the thumbnail image).
    public static let allowBrowser = ADAssetSelectOptions(rawValue: 1 << 10)
    /// Allow toolbar in thumbnail controller
    public static let thumbnailToolBar = ADAssetSelectOptions(rawValue: 1 << 11)
    /// Allow select full image.
    public static let selectOriginal = ADAssetSelectOptions(rawValue: 1 << 12)
        
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let `default`: ADAssetSelectOptions = [.mixSelect,.selectOriginal,.slideSelect,.autoScroll,allowTakePhotoAsset,.thumbnailToolBar,.allowBrowser]
    
}

/// Options to control the asset browser condition and ui.
public struct ADAssetBrowserOptions: OptionSet {
    public let rawValue: Int
    
    /// Allow select full image.
    public static let selectOriginal = ADAssetBrowserOptions(rawValue: 1 << 0)
    /// Display the selected photos at the bottom of the browse large photos interface.
    public static let selectBrowser = ADAssetBrowserOptions(rawValue: 1 << 1)
    /// Display the index of the selected photos at navbar.
    public static let selectIndex = ADAssetBrowserOptions(rawValue: 1 << 2)
    /// Allow framework fetch image when callback.
    public static let fetchImage = ADAssetBrowserOptions(rawValue: 1 << 3)
    
    public static let `default`: ADAssetBrowserOptions = [.selectOriginal, .selectBrowser, .selectIndex, .fetchImage]
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
}

/// Params to control the asset select condition.
public enum ADPhotoSelectParams: Hashable, Equatable {
    /// Limit the max count you can select. Set `nil` means no limit. Default is no limit.
    case maxCount(max: Int?)
    /// Limit the min and max image count you can select. Set `nil` means no limit. Default is no limit.
    case imageCount(min: Int?, max:Int?)
    /// Limit the min and max video count you can select. Set `nil` means no limit. Default is no limit.
    case videoCount(min: Int?, max:Int?)
    /// Limit the min and max video time you can select. Set `nil` means no limit. Default is no limit.
    case videoTime(min: Int?, max: Int?)
    /// Limit the min and max video time you can record. Set `nil` means no limit. Default is no limit.
    case recordTime(min: Int?, max: Int?)
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hashValue)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    public var hashValue: Int {
        var value: Int = 0
        switch self {
        case .maxCount:
            value = 0
        case .imageCount:
            value = 1
        case .videoCount:
            value = 2
        case .videoTime:
            value = 3
        case .recordTime:
            value = 4
        }
        return value
    }
}

/// Main class of ADPhotoKit UI. It provide methods to show asset picker or asset browser.
public class ADPhotoKitUI {
    
    /// Warp of select asset.
    /// - Parameters:
    ///     - asset: Asset select from system.
    ///     - image: Image fetch with asset. It's `nil` if `browserOpts` not contain `.fetchImage` or error occur when fetching.
    ///     - error: Error info when fetch error. It's not `nil` when error occur when fetching.
    /// - Note: If `browserOpts` not contain `.fetchImage`, fetch will not perform and asset will return immediately, `image` and `error` will be `nil`.
    public typealias Asset = (asset: PHAsset, image: UIImage?, error: Error?)
    /// Return select assets and if original or not.
    public typealias AssetSelectHandler = (([Asset],Bool) -> Void)
    /// Return browsable asset array.
    public typealias AssetableSelectHandler = (([ADAssetBrowsable]) -> Void)
    /// Cancel select.
    public typealias AssetCancelHandler = (() -> Void)
    
    /// Show picker to select assets.
    /// - Parameters:
    ///   - on: The controller to show picker.
    ///   - style: Style to display picker.
    ///   - assets: Assets have been selected.
    ///   - albumOpts: Options to limit album type and order. It is `ADAlbumSelectOptions.default` by default.
    ///   - assetOpts: Options to control the asset select condition and ui. It is `ADAssetSelectOptions.default` by default.
    ///   - browserOpts: Options to control browser controller. It is `ADAssetBrowserOptions.default` by default.
    ///   - params: Params to control the asset select condition.
    ///   - selected: Called after selection finish.
    ///   - canceled: Called when cancel select.
    public class func imagePicker(present on: UIViewController,
                                    style: ADPickerStyle = .normal,
                                    assets: [PHAsset] = [],
                                    albumOpts: ADAlbumSelectOptions = .default,
                                    assetOpts: ADAssetSelectOptions = .default,
                                    browserOpts: ADAssetBrowserOptions = .default,
                                    params: Set<ADPhotoSelectParams> = [],
                                    selected: @escaping AssetSelectHandler,
                                    canceled: AssetCancelHandler? = nil) {
        let configuration = ADPhotoKitConfig(albumOpts: albumOpts, assetOpts: assetOpts, browserOpts: browserOpts, params: params, pickerSelect: selected, browserSelect: nil, canceled: canceled)
        if let asset = assets.randomElement() {
            configuration.selectMediaImage = ADAssetModel(asset: asset).type.isImage
        }
        config = configuration
        if style == .normal {
            ADPhotoManager.cameraRollAlbum(options: albumOpts) { (model) in
                let album = ADAlbumListController(config: configuration)
                let nav = ADPhotoNavController(rootViewController: album)
                let thumbnail = ADThumbnailViewController(config: configuration, album: model, style: style, selects: assets)
                nav.modalPresentationStyle = .fullScreen
                nav.pushViewController(thumbnail, animated: false)
                on.present(nav, animated: true, completion: nil)
            }
        }else{
            ADPhotoManager.cameraRollAlbum(options: albumOpts) { (model) in
                let thumbnail = ADThumbnailViewController(config: configuration, album: model, style: style, selects: assets)
                let nav = ADPhotoNavController(rootViewController: thumbnail)
                nav.modalPresentationStyle = .fullScreen
                on.present(nav, animated: true, completion: nil)
            }
        }
    }
    
    /// Show controller to browser and select assets.
    /// - Parameters:
    ///   - on: The controller to show browser.
    ///   - assets: Assets to browser.
    ///   - index: Current browser asset index.
    ///   - selects: Indexs of assets have been selected.
    ///   - options: Options to control browser controller. It is `ADAssetBrowserOptions.default` by default.
    ///   - selected: Called after selection finish.
    ///   - canceled: Called when cancel select.
    public class func assetBrowser(present on: UIViewController,
                                    assets:  [ADAssetBrowsable],
                                    index: Int? = nil,
                                    selects: [Int] = [],
                                    options: ADAssetBrowserOptions = .default,
                                    selected: @escaping AssetableSelectHandler,
                                    canceled: AssetCancelHandler? = nil) {
        if assets.count == 0 {
            fatalError("assets count must>0")
        }
        let configuration = ADPhotoKitConfig(browserOpts: options, pickerSelect: nil, browserSelect: selected, canceled: canceled)
        config = configuration
        let browser = ADAssetBrowserController(config: configuration, assets: assets, index: index, selects: selects)
        let nav = ADPhotoNavController(rootViewController: browser)
        nav.modalPresentationStyle = .fullScreen
        on.present(nav, animated: true, completion: nil)
    }
    
    /// Config pass through.
    public static var config: ADPhotoKitConfig!
}

extension ADPhotoKitUI {
    
    static func springAnimation() -> CAKeyframeAnimation {
        let animate = CAKeyframeAnimation(keyPath: "transform")
        animate.duration = 0.4
        animate.isRemovedOnCompletion = true
        animate.fillMode = .forwards
        
        animate.values = [CATransform3DMakeScale(0.7, 0.7, 1),
                          CATransform3DMakeScale(1.2, 1.2, 1),
                          CATransform3DMakeScale(0.8, 0.8, 1),
                          CATransform3DMakeScale(1, 1, 1)]
        return animate
    }
    
}

/// Parsing the input config to `ADPhotoKitConfig` and pass through the internal methods.
public class ADPhotoKitConfig {

    public let albumOpts: ADAlbumSelectOptions
    public let assetOpts: ADAssetSelectOptions
    public let browserOpts: ADAssetBrowserOptions
    public let params: ADThumbnailParams
    
    let pickerSelect: ADPhotoKitUI.AssetSelectHandler?
    let browserSelect: ADPhotoKitUI.AssetableSelectHandler?
    let canceled: ADPhotoKitUI.AssetCancelHandler?
    
    var selectMediaImage: Bool?
    
    var isOriginal: Bool = false
    
    let fetchImageQueue: OperationQueue = OperationQueue()
    
    init(albumOpts: ADAlbumSelectOptions = .default,
         assetOpts: ADAssetSelectOptions = .default,
         browserOpts: ADAssetBrowserOptions,
         params: Set<ADPhotoSelectParams> = [],
         pickerSelect: ADPhotoKitUI.AssetSelectHandler?,
         browserSelect: ADPhotoKitUI.AssetableSelectHandler?,
         canceled: ADPhotoKitUI.AssetCancelHandler?) {
        self.albumOpts = albumOpts
        self.assetOpts = assetOpts
        self.browserOpts = browserOpts
        self.pickerSelect = pickerSelect
        self.browserSelect = browserSelect
        self.canceled = canceled
        
        var value = ADThumbnailParams()
        for item in params {
            switch item {
            case let .maxCount(max):
                value.maxCount = max
            case let .imageCount(min, max):
                value.minImageCount = min
                value.maxImageCount = max
                if let l = min, let r = max {
                    assert(l <= r, "min count must less than or equal max")
                }
            case let .videoCount(min, max):
                value.minVideoCount = min
                value.maxVideoCount = max
                if let l = min, let r = max {
                    assert(l <= r, "min count must less than or equal max")
                }
            case let .videoTime(min, max):
                value.minVideoTime = min
                value.maxVideoTime = max
                if let l = min, let r = max {
                    assert(l <= r, "min time must less than or equal max")
                }
            case let .recordTime(min, max):
                value.minRecordTime = min
                value.maxRecordTime = max
                if let l = min, let r = max {
                    assert(l <= r, "min time must less than or equal max")
                }
            }
        }
        self.params = value
        
        fetchImageQueue.maxConcurrentOperationCount = 3
    }
}

extension ADAssetListDataSource {
    
    func fetchSelectImages(original: Bool, asGif: Bool, completion: @escaping (()->Void)) {
        var hud = ADPhotoUIConfigurable.progressHUD()
        
        var timeout: Bool = false
        hud.timeoutBlock = {
            timeout = true
            ADPhotoKitUI.config.fetchImageQueue.cancelAllOperations()
        }
        
        hud.show(timeout: ADPhotoKitConfiguration.default.fetchTimeout)
        
        var result: [ADPhotoKitUI.Asset?] = Array(repeating: nil, count: selects.count)
        var operations: [Operation] = []
        for (i,item) in selects.enumerated() {
            let op = ADAssetOperation(model: item.asset, isOriginal: original, selectAsGif: asGif, progress: nil) { (asset) in
                result[i] = asset
            }
            operations.append(op)
        }
        
        DispatchQueue.main.async {
            ADPhotoKitUI.config.fetchImageQueue.addOperations(operations, waitUntilFinished: true)
            hud.hide()
            if !timeout {
                ADPhotoKitUI.config.pickerSelect?(result.compactMap { $0 }, original)
                completion()
            }
        }
    }
    
}
