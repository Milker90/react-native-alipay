require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))

Pod::Spec.new do |s|
  s.name         = "react-native-alipay"
  version        = package["version"]
  s.version      = version
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.authors      = package["author"]

  s.platforms    = { :ios => "10.0" }
  s.source       = { :git => "https://github.com/Milker90/react-native-alipay.git", :tag => "#{s.version}" }

  
  s.source_files = "ios/**/*.{h,m,mm,swift}"
  s.header_mappings_dir = "ios"
  
  s.dependency "React-Core"
  s.dependency "AlipaySDK-iOS", "15.8.11"

#  s.pod_target_xcconfig = {
#      'HEADER_SEARCH_PATHS' => '$SRCROOT'
#    }
end
