Pod::Spec.new do |s|
  s.name           = 'ExpoLiveActivities'
  s.version        = '0.1.0'
  s.summary        = 'Generic Expo module for iOS Live Activities and Dynamic Island'
  s.description    = 'A customizable Expo module that enables iOS Live Activities and Dynamic Island support with any activity type'
  s.author         = ''
  s.homepage       = 'https://github.com/yourusername/react-native-ios-activitykit'
  s.platform       = :ios, '16.1'
  s.source         = { git: '' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.4',
    'DEFINES_MODULE' => 'YES'
  }

  s.source_files = "**/*.{h,m,swift}"
end
