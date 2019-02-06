Pod::Spec.new do |s|
  s.name             = "FrigKit"
  s.summary          = "The Swift army knife"
  s.version          = "1.0.0"
  s.homepage         = "https://github.com/afrigon/FrigKit"
  s.license          = 'MIT'
  s.author           = { "Alexandre Frigon" => "alexandre.frigon.1@gmail.com" }
  s.source           = { :git => "https://github.com/afrigon/FrigKit.git", :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_version = '4.2'

  s.source_files = 'Sources/**/*.swift'
end
