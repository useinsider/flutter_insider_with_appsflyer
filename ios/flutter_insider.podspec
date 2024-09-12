Pod::Spec.new do |s|
  s.name             = 'flutter_insider'
  s.version          = '3.12.0'
  s.summary          = 'Flutter Plugin For Insider SDK'
  s.description      = <<-DESC
  Flutter Plugin For Insider SDK
                       DESC
  s.homepage         = 'https://useinsider.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Insider' => 'mobile@useinsider.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'InsiderMobile', '13.6.2'
  s.dependency 'InsiderGeofence', '1.2.0'
  s.dependency 'InsiderHybrid', '1.4.0'
  s.ios.deployment_target = '12.0'
end
