Pod::Spec.new do |spec|
  spec.name = "EventTracker"
  spec.version = "1.0.0"
  spec.summary = "Framework to log events"
  spec.homepage = "https://github.com/birwin93/EventTracker"
  spec.license = { type: 'MIT', file: 'LICENSE' }
  spec.authors = { "Billy Irwin" => 'birwin93@gmail.com' }
  spec.social_media_url = "http://twitter.com/billy_the_kid"

  spec.platform = :ios, "9.0"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/birwin93/EventTracker.git", tag: "v#{spec.version}", submodules: true }
  spec.source_files = "EventTracker/**/*.{h,swift}"
end
