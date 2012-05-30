require 'rubygems'
require "bundler"
Bundler.setup
ENV['RAILS_ENV'] ||= 'test'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'pg_csv'

require File.dirname(__FILE__) + '/spec_support.rb'
