require 'parallel'
require 'pp'
require_relative 'sof/version'
require_relative 'sof/check'
require_relative 'sof/server'
require_relative 'sof/checks'
require_relative 'sof/runner'
require_relative 'sof/options'

module Sof
  FAILURE_EXIT_CODE = 127
end
