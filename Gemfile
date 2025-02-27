# frozen_string_literal: true

# rubocop:disable Metrics/LineLength
source ENV["GEM_SERVER_URL"] || "https://rubygems.org"

# State machine
gem "aasm", "4.11.0"
gem "activerecord-import"
gem "acts_as_tree"
# BGS
gem "bgs", git: "https://github.com/department-of-veterans-affairs/ruby-bgs.git", ref: "dfe3035db0ebe957066f24ac93706d14fd0e7a8b"
# Bootsnap speeds up app boot (and started to be a default gem in 5.2).
gem "bootsnap", require: false
gem "business_time", "~> 0.9.3"
gem "caseflow", git: "https://github.com/department-of-veterans-affairs/caseflow-commons", ref: "ffb77dd0395cbd5b7c1a5729f7f8275b5ec681fa"
gem "connect_vbms", git: "https://github.com/department-of-veterans-affairs/connect_vbms.git", ref: "0e39b66ff1224f27419f8f2838e4c5a72e6c7233"
gem "dogstatsd-ruby"
gem "fast_jsonapi"
gem "holidays", "~> 6.4"
gem "kaminari"
# active_model_serializers has a default dependency on loofah 2.2.2 which has a security vuln (CVE-2018-16468)
gem "loofah", ">= 2.2.3"
gem "moment_timezone-rails"
gem "newrelic_rpm"
# nokogiri versions before 1.10.3 are affected by CVE-2019-11068. Explicitly define nokogiri version here to avoid that.
# https://github.com/sparklemotion/nokogiri/issues/1892
gem "nokogiri", "1.10.3"
gem "paper_trail", "8.1.2"
# Used to speed up reporting
gem "parallel"
# soft delete gem
gem "paranoia", "~> 2.2"
# PDF Tools
gem "pdf-forms"
gem "pdfjs_viewer-rails", git: "https://github.com/senny/pdfjs_viewer-rails.git", ref: "a4249eacbf70175db63b57e9f364d0a9a79e2b43"
gem "pg", platforms: :ruby
gem "prometheus-client", "~> 0.7.1"
# Application server: Puma
# Puma was chosen because it handles load of 40+ concurrent users better than Unicorn and Passenger
# Discussion: https://github.com/18F/college-choice/issues/597#issuecomment-139034834
gem "puma", "~> 3.12.0"
# rack versions before 2.0.6 are affected by CVE-2018-16470 and CVE-2018-16471.
# Explicitly define rack version here to avoid that.
gem "rack", "~> 2.0.6"
gem "rails", "5.1.6.2"
# Used to colorize output for rake tasks
gem "rainbow"
# React
gem "react_on_rails", "8.0.6"
gem "redis-namespace"
gem "redis-rails", "~> 5.0.2"
gem "request_store"
gem "roo", "~> 2.7"
# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
# Error reporting to Sentry
gem "sentry-raven"
gem "shoryuken", "3.1.11"
gem "stringex", require: false
# catch problematic migrations at development/test time
gem "strong_migrations"
# execjs runtime
gem "therubyracer", platforms: :ruby
# print trees
gem "tty-tree"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"

group :production, :staging, :ssh_forwarding, :development, :test do
  # Oracle DB
  gem "activerecord-oracle_enhanced-adapter"
  gem "ruby-oci8", "~> 2.2"
end

group :test, :development, :demo do
  # Security scanners
  gem "brakeman"
  gem "bullet"
  gem "bundler-audit"
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: :ruby
  # Testing tools
  gem "capybara"
  gem "capybara-screenshot"
  gem "danger", "~> 5.10"
  gem "database_cleaner"
  gem "factory_bot_rails", "~> 4.8"
  gem "faker"
  gem "guard-rspec"
  # Linters
  gem "jshint", platforms: :ruby
  gem "pry"
  gem "pry-byebug"
  gem "rb-readline"
  gem "rspec"
  gem "rspec-rails"
  # For CircleCI test metadata analysis
  gem "rspec_junit_formatter"
  gem "rubocop", "~> 0.52", require: false
  gem "rubocop-performance"
  gem "scss_lint", require: false
  gem "simplecov", git: "https://github.com/colszowka/simplecov.git", require: false
  gem "sniffybara", git: "https://github.com/department-of-veterans-affairs/sniffybara.git", branch: "mb-update-capybara-click"
  gem "timecop"
  gem "webdrivers"
end

group :development do
  gem "bummr", require: false
  gem "derailed_benchmarks"
  gem "dotenv-rails"
  gem "fasterer", require: false
  gem "foreman"
  gem "meta_request"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  # gem 'spring', platforms: :ruby
  # Include the IANA Time Zone Database on Windows, where Windows doesn't ship with a timezone database.
  # POSIX systems should have this already, so we're not going to bring it in on other platforms
  gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
end
# rubocop:enable Metrics/LineLength
