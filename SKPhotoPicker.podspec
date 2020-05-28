
Pod::Spec.new do |s|

  s.name         = "SKPhotoPicker"
  s.version      = "1.0.1"
  s.summary      = "Easy to use photo album by PhotoKit."
  s.homepage     = "https://github.com/Xcoder1011/SKPhotoPicker"
  s.license      = "MIT"
  s.author             = { "Xcoder1011" => "shangkunwu@msn.com" }
  s.social_media_url   = "https://github.com/Xcoder1011"
  s.source       = { :git => "https://github.com/Xcoder1011/SKPhotoPicker.git", :tag => s.version }
  
  s.ios.deployment_target = "9.1"
  s.requires_arc = true
  s.dependency "SDWebImage", "~> 4.0"
  s.dependency "Masonry"
  
  # s.source_files = 'SKPhotoPicker/**/*'
  s.resources = 'SKPhotoPicker/Assets/*.bundle'
  s.frameworks = 'UIKit','Foundation'
  
end
