#
# Be sure to run `pod lib lint AdParticipesCumCepis.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |m|
  m.name             = 'AdParticipesCumCepis'
  m.version          = '0.1.0'
  m.summary          = 'A short description of AdParticipesCumCepis.'

  m.description      = <<-DESC
    Library to create an app which can share data on the device with others via
    a transient onion service.
                       DESC

  m.homepage         = 'https://github.com/tladesignz/AdParticipesCumCepis'
  m.license          = { :type => 'MIT', :file => 'LICENSE' }
  m.author           = { 'Benjamin Erhart' => 'berhart@netzarchitekten.com' }
  m.source           = { :git => 'https://github.com/tladesignz/AdParticipesCumCepis.git', :tag => m.version.to_s }
  m.social_media_url = 'https://twitter.com/tladesignz'

  m.swift_version = '5.0'

  m.ios.deployment_target = '15.0'

  m.static_framework = true

  m.subspec 'Shared' do |s|
    s.source_files = 'AdParticipesCumCepis/Shared/**/*'
  end

  m.subspec 'App' do |s|
    s.source_files = 'AdParticipesCumCepis/App/**/*.swift'

    s.dependency 'AdParticipesCumCepis/Shared'
    s.dependency 'TLPhotoPicker', '~> 2.1'
    s.dependency 'Tor', '~> 406.10'
    s.dependency 'GCDWebServer', '~> 3.5'
    s.dependency 'ZIPFoundation', '~> 0.9'
    s.dependency 'IPtProxyUI', '~> 1.7'

    s.resource_bundles = {
      'AdParticipesCumCepis' => ['AdParticipesCumCepis/App/Assets/**/*']
    }
  end

  m.subspec 'Extension' do |s|
    s.source_files = 'AdParticipesCumCepis/Extension/**/*'

    s.dependency 'AdParticipesCumCepis/Shared'
    s.dependency 'MBProgressHUD', '~> 1.2'
  end

  m.default_subspecs = 'App'
end
