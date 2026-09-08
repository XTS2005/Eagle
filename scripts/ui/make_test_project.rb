require 'xcodeproj'
require 'fileutils'

output = File.expand_path(ARGV.fetch(0))
FileUtils.mkdir_p(output)
project = Xcodeproj::Project.new(File.join(output, 'GalleryQA.xcodeproj'))
target = project.new_target(:ui_test_bundle, 'GalleryInteractionTests', :ios, '16.0')
target.add_file_references([project.main_group.new_file(File.join(__dir__, 'GalleryInteractionTests.swift'))])
target.build_configurations.each do |configuration|
  configuration.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'local.eagle.gallery-interaction-tests'
  configuration.build_settings['SWIFT_VERSION'] = '5.0'
  configuration.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  configuration.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
end
scheme = Xcodeproj::XCScheme.new
scheme.add_build_target(target)
scheme.add_test_target(target)
scheme.save_as(project.path, 'GalleryInteractionTests', true)
project.save
