3.1.2# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version
ruby "3.1.2" (windows installer from https://rubyinstaller.org/)
gem "rails", "~> 8.0.2"  (gem install rails)
bundle install

* System dependencies

* Configuration

* Database creation

* Database initialization
Init data (should be safe to repeat)
rails db:seed
Rebuilt inferred values, stats and alike (currntly also ranks of translation so need to run before first launch)
rails runner lib/rebuild_counters.rb

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
