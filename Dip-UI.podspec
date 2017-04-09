Pod::Spec.new do |s|
  s.name             = "Dip-UI"
  s.version          = "1.1"
  s.summary          = "Dip UI extension"

  s.description      = <<-DESC
                        Dip-UI is a simple extension for Dip - Dependency Injection container for Swift.
                        It adds features to support dependency injection for objects
                        created by storyboards or loaded from nib files.

                       DESC

  s.homepage         = "https://github.com/AliSoftware/Dip-UI"
  s.license          = 'MIT'
  s.authors          = { "Ilya Puchka" => "ilya@puchka.me", "Olivier Halligon" => "olivier@halligon.net" }
  s.source           = { :git => "https://github.com/AliSoftware/Dip-UI.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/aligatr'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.requires_arc = true

  s.source_files = 'Sources/**/*.swift'

  s.dependency 'Dip', '~> 5.0'

end
