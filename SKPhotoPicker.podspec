
Pod::Spec.new do |s|

  s.name         = "SKPhotoPicker"
  s.version      = "1.0.1"
  s.summary      = "Easy to use photo album by PhotoKit."
  s.homepage     = "https://github.com/Xcoder1011/SKPhotoPicker"
  s.license      = "MIT"
  s.author             = { "Xcoder1011" => "shangkunwu@msn.com" }
  s.social_media_url   = "https://github.com/Xcoder1011"
  s.source       = { :git => "https://github.com/Xcoder1011/SKPhotoPicker.git", :tag => s.version }
  
  s.ios.deployment_target = "9.0"
  s.requires_arc = true
  s.dependency "SDWebImage", "~> 4.0"
  s.dependency "Masonry"
  
  s.source_files = 'SKPhotoPicker/Classes/Models/SKPhotoHeader.h'
  s.resources = 'SKPhotoPicker/Assets/*.bundle'
  s.frameworks = 'UIKit'
  
  s.subspec 'Controllers' do |ss|
    ss.source_files = 'SKPhotoPicker/Classes/Controllers/*.{h.m}'
  end

  s.subspec 'Models' do |ss|
    ss.source_files = 'SKPhotoPicker/Classes/Models/*.{h.m}'
  end
  
  s.subspec 'Views' do |ss|
    ss.source_files = 'SKPhotoPicker/Classes/Views/*.{h.m}'
  end

end
