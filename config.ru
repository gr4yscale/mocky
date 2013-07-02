require 'rubygems'
require 'sinatra'
require 'rack'

root_dir = File.dirname(__FILE__)
require File.join(root_dir,'mock_server.rb')

set :environment, :production
disable :run, :reload

run MockySync
