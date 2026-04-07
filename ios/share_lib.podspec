Pod::Spec.new do |s|
  s.name             = 'share_lib'
  s.version          = '1.0.1'
  s.summary          = 'Share lib — native Sign in with Apple button (iOS)'
  s.description      = <<-DESC
  Embeds ASAuthorizationAppleIDButton per Apple HIG.
                       DESC
  s.homepage         = 'https://github.com/smartcompany/flutter_share_lib'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'smartcompany' => 'https://github.com/smartcompany/flutter_share_lib' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform         = :ios, '13.0'
  s.swift_version    = '5.0'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
end
