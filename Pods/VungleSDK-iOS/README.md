# Vungle's iOS-SDK
[![Version](https://img.shields.io/cocoapods/v/VungleSDK-iOS.svg?style=flat)](http://cocoapods.org/pods/VungleSDK-iOS)
[![License](https://img.shields.io/cocoapods/l/VungleSDK-iOS.svg?style=flat)](http://cocoapods.org/pods/VungleSDK-iOS)
[![Platform](https://img.shields.io/cocoapods/p/VungleSDK-iOS.svg?style=flat)](http://cocoapods.org/pods/VungleSDK-iOS)

## Getting Started
To get up and running with Vungle, you'll need to [Create an Account With Vungle](https://v.vungle.com/dashboard) and [Add an Application to the Vungle Dashboard](https://support.vungle.com/hc/en-us/articles/210468678)

Once you've created an account you can follow our [Getting Started for iOS Guide](https://support.vungle.com/hc/en-us/articles/204430550-Getting-Started-with-Vungle-iOS-SDK) to complete the integration. Remember to get the Vungle App ID from the Vungle dashboard.

The Vungle iOS SDK can also be installed via [CocoaPods](https://cocoapods.org/).  To install the Vungle iOS-SDK via CocoaPods add the following line to your Podfile and re-run the `pod install` command:

```ruby
pod "VungleSDK-iOS"
```

The latest information around our CocoaPods support can be found at the [VungleSDK-iOS CocoaPods Page](https://cocoapods.org/pods/VungleSDK-iOS)

### Version Info
The Vungle iOS SDK only supports iOS 7+, iOS 10 with limited tracking, and supports both 32bit and 64bit apps.  

Our newest iOS SDK (4.0.6) was released on September 29th, 2016 in support of the newest XCode 7+. Please ensure you are using XCode 7.0 or higher to ensure smooth integration.

## Release Notes
### 4.0.6
* Add cache early check to initial operation chain 
* Prefix 3rd party zip/unzip lib functions 
* Track and use the didDownload state for legacy ads

### 4.0.5
* Bug fixes
* Performance improvement

### 4.0.4
* iOS 10 OS performance optimizations
* CloudUX functionality support
* Vungle unique id implementation to maintain publisher frequency capping
* Fix click area around CTA button


## License
The Vungle iOS-SDK is available under a commercial license. See the LICENSE file for more info.
