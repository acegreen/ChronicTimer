source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

target "Chronic" do
    pod 'CNPPopupController'
    pod 'DZNEmptyDataSet'
    pod 'SDVersion'
    pod 'Parse'
    pod 'ParseFacebookUtilsV4'
    pod 'ParseTwitterUtils'
    pod 'ParseUI'
    pod 'AMPopTip'
    pod 'AMWaveTransition'
    pod 'LaunchKit'
    pod 'SwiftyJSON', :git => 'https://github.com/SwiftyJSON/SwiftyJSON.git', :branch => 'swift3'
    pod 'BubbleTransition'
    pod 'Rollout.io'
    pod 'Charts', :git => 'https://github.com/danielgindi/Charts.git', :branch => 'Swift-3.0'
    pod 'PureLayout'
    pod 'Google-Mobile-Ads-SDK'

    #pod 'Spring', :git => 'https://github.com/MengTo/Spring.git', :branch => 'swift2'
    #pod 'ChameleonFramework/Swift'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
        end
    end
end
