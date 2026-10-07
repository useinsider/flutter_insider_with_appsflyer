Pod::Spec.new do |s|
  s.name             = 'flutter_insider'
  s.version          = '5.3.0+nh'
  s.summary          = 'Flutter Plugin For Insider SDK'
  s.description      = <<-DESC
  Flutter Plugin For Insider SDK
                       DESC
  s.homepage         = 'https://insiderone.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Insider' => 'mobile@useinsider.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_insider/Sources/flutter_insider/**/*.{h,m}'
  s.public_header_files = 'flutter_insider/Sources/flutter_insider/include/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'InsiderMobile', '16.2.0'
  s.dependency 'InsiderGeofence', '1.2.4'
  s.dependency 'InsiderHybrid', '1.8.0'
  s.ios.deployment_target = '12.2'
end
