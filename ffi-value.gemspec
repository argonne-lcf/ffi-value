Gem::Specification.new do |s|
  s.name = 'ffi-value'
  s.version = "0.1.0"
  s.author = "Brice Videau"
  s.email = "bvideau@anl.gov"
  s.homepage = "https://github.com/alcf-perfengr/ffi-value"
  s.summary = "Allow passing ruby values instead of void* pointers"
  s.description = "Allow passing ruby values instead of void* pointers."
  s.files = Dir[ 'ffi-value.gemspec', 'LICENSE', 'lib/ffi-value.rb' ]
  s.license = 'BSD-3-Clause'
  s.required_ruby_version = '>= 2.3.0'
  s.add_dependency 'ffi', '~> 1.9', '>=1.9.3'
end
