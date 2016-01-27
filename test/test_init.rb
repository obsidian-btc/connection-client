ENV['CONSOLE_DEVICE'] ||= 'stdout'
ENV['LOG_COLOR'] ||= 'on'
ENV['LOG_LEVEL'] ||= 'trace'
ENV['LOG_OPTIONAL'] ||= 'on'

puts RUBY_DESCRIPTION

require_relative '../init.rb'

require 'test_bench'; TestBench.activate

require 'connection/client/controls'

Telemetry::Logger::AdHoc.activate
