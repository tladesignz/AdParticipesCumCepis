#
# Be sure to run `pod lib lint AdParticipesCumCepis.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'AdParticipesCumCepis'
  s.version          = '0.1.0'
  s.summary          = 'A short description of AdParticipesCumCepis.'

  s.description      = <<-DESC
    Library to create an app which can share data on the device with others via
    a transient onion service.
                       DESC

  s.homepage         = 'https://github.com/tladesignz/AdParticipesCumCepis'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Benjamin Erhart' => 'berhart@netzarchitekten.com' }
  s.source           = { :git => 'https://github.com/tladesignz/AdParticipesCumCepis.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/tladesignz'

  s.swift_version = '5.0'

  s.ios.deployment_target = '15.0'

  s.static_framework = true

  s.source_files = 'AdParticipesCumCepis/Classes/**/*'

   s.resource_bundles = {
     'AdParticipesCumCepis' => ['AdParticipesCumCepis/Assets/**/*']
   }

  s.dependency 'TLPhotoPicker', '~> 2.1'
  s.dependency 'Tor', '~> 406.10'
  s.dependency 'GCDWebServer', '~> 3.5'
  s.dependency 'ZIPFoundation', '~> 0.9'
  s.dependency 'IPtProxyUI', '~> 1.7'

end
