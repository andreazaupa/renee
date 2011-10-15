$: << File.expand_path('../../../renee-core/lib', __FILE__)
$: << File.expand_path('../../lib', __FILE__)
require 'renee-core'
require 'renee-render'

# TODO better registration method (?)
Renee::Core::Application.send(:include, Renee::Render)

# Load shared test helpers
require File.expand_path('../../../lib/test_helper', __FILE__)
