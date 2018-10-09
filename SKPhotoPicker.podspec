
Pod::Spec.new do |s|

  s.name         = "SKPhotoPicker"
  s.version      = "0.0.1"
  s.summary      = "Easy to use photo album by PhotoKit."
  s.homepage     = "https://github.com/Xcoder1011/SKPhotoPicker"
  s.license      = "MIT"
  s.author             = { "Xcoder1011" => "shangkunwu@msn.com" }
  s.social_media_url   = "https://github.com/Xcoder1011"
  s.platform     = :ios, "9.0"
  s.ios.deployment_target = "9.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/Xcoder1011/SKPhotoPicker.git", :tag => s.version }
  s.requires_arc = true
  s.dependency "SDWebImage", "~> 4.0"

end
