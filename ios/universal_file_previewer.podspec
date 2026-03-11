#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint universal_file_previewer.podspec` to validate before submitting.
#
Pod::Spec.new do |s|
  s.name             = 'universal_file_previewer'
  s.version          = '0.3.0'
  s.summary          = 'Preview 50+ file formats with zero heavy dependencies.'
  s.description      = <<-DESC
A new Flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/Naimish-Kumar/universal_file_previewer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Naimish Kumar' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
