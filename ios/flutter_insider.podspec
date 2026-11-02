Pod::Spec.new do |s|
  s.name             = 'flutter_insider'
  s.version          = '5.5.0+nh'
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
  s.dependency 'InsiderMobile', '16.4.0'
  s.dependency 'InsiderGeofence', '1.3.0'
  s.ios.deployment_target = '12.2'
end
