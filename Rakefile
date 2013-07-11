# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugin :seattlerb

Hoe.spec 'omnifocus-github' do
  developer 'Ryan Davis', 'ryand-ruby@zenspider.com'

  dependency "omnifocus", "~> 2.0"
  dependency "octokit",   "~> 1.24"
  dependency "system-timer" "~> 1.2" # bug in octokit's deps

  self.rubyforge_name = 'seattlerb'
end

# vim: syntax=ruby
