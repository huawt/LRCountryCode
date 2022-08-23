
Pod::Spec.new do |s|
  s.name             = 'LRCountryCode'
  s.version          = '0.1.0'
  s.summary          = 'A short description of LRCountryCode.'
  s.homepage         = 'https://github.com/huawt/LRCountryCode'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'huawt' => 'ghost263sky@163.com' }
  s.source           = { :git => 'https://github.com/huawt/LRCountryCode.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'LRCountryCode/Classes/**/*'
  s.resource = 'LRCountryCode/LRCountryCode.bundle'
end
