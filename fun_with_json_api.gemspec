$LOAD_PATH.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'fun_with_json_api/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'fun_with_json_api'
  s.version     = FunWithJsonApi::VERSION
  s.authors     = ['Ben Morrall']
  s.email       = ['bemo56@hotmail.com']
  s.homepage    = 'https://github.com/bmorrall/fun_with_json_api'
  s.summary     = 'Provides JSON API-compliant Controller integration'
  s.description = 'Adds various modules and libraries for handing' \
                  ' the tricky parts of a JSON API implementation.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['spec/**/*']

  s.add_dependency 'rails', '>= 5.1'
  s.add_dependency 'active_model_serializers', '>= 0.10.0'

  s.add_development_dependency 'sqlite3', '~> 1.4'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'rubocop', '~> 0.38.0'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'simplecov'
end
