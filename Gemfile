source 'https://rubygems.org'

# Declare your gem's dependencies in fun_with_json_api.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

gem 'rake', '< 11.0'

rails_version = ENV.fetch('RAILS_VERSION', '5.2')
if rails_version == 'master'
  gem 'rails', github: 'rails/rails'
else
  gem_version = "~> #{rails_version}.0"
  gem 'rails', gem_version
end

if (ams_version = ENV['AMS_VERSION'])
  gem 'active_model_serializers', "= #{ams_version}"
elsif (ams_branch = ENV.fetch('AMS_BRANCH', 'master'))
  gem 'active_model_serializers', git: 'https://github.com/rails-api/active_model_serializers.git',
                                  branch: ams_branch
end

gem 'pry', group: [:development, :test]
