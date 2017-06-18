use_frameworks!

def shared_pods
    pod 'Realm'
end

target 'Chronic' do
    platform :ios, '10.0'

    # Core
    shared_pods

    # Settings
    pod 'LaunchKit'
    pod 'SwiftyJSON'
    pod 'ReachabilitySwift'
    pod 'SDVersion'
    pod 'PureLayout'    

    # UI
    pod 'DZNEmptyDataSet'
    pod 'Charts'
    pod 'AMPopTip'
    pod 'Whisper'
    
    # Transitions / Segues
    pod 'BubbleTransition'
    pod 'AMWaveTransition'
    pod 'MZFormSheetPresentationController'

    # Parse
    pod 'Parse'
    pod 'ParseFacebookUtilsV4'
    pod 'ParseTwitterUtils'
    pod 'ParseUI'

    # Fabric
    pod 'Crashlytics'
    pod 'mopub-ios-sdk'
    
    # Ad Networks
    pod 'Google-Mobile-Ads-SDK'
    pod 'FBAudienceNetwork'
    pod 'ChartboostSDK'
    pod 'Flurry-iOS-SDK/FlurrySDK'
    pod 'VungleSDK-iOS'
    
    # Deprecated Frameworks
    #pod 'GreystripeSDK' // installed manually cocoapods not up-to-date
    #pod 'CNPPopupController'
    #pod 'PermissionScope'
    #pod 'Spring'
    #pod 'ChameleonFramework/Swift'
    #pod 'Rollout'
    #pod 'Appsee'
    #pod ‘AdColony’
end

target 'Chronic WatchKit Extension' do
    platform :watchos, '3.0'
    
    # Core
    shared_pods
end
