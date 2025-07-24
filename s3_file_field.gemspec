# encoding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 's3_file_field/version'

Gem::Specification.new do |gem|
  gem.authors       = ["Adam Stankiewicz", "Jade Ornelas"]
  gem.email         = ["sheerun@sher.pl", "jade@zoobean.com"]
  gem.description   = %q{jQuery File Upload extension for direct uploading to Amazon S3 using CORS with AWS Signature Version 4}
  gem.summary       = %q{jQuery File Upload extension for direct uploading to Amazon S3 using CORS with AWS Signature Version 4}
  gem.homepage      = "https://github.com/zoobean/s3_file_field"

  gem.files         = Dir["{lib,app}/**/*"] + ["README.md"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "s3_file_field"
  gem.require_paths = ["lib"]
  gem.version       = S3FileField::VERSION
  gem.license       = 'MIT'

  gem.add_dependency 'rails', '>= 3.2'
  gem.add_dependency 'coffee-rails', '>= 3.2.1'
  gem.add_dependency 'sass-rails', '>= 3.2.5'
  gem.add_dependency 'jquery-fileupload-rails', '~> 0.4.1'

  gem.add_development_dependency 'bundler', '~> 2.0'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'pry'
end
