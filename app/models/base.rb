# frozen_string_literal: true

require 'sequel'

DB = Sequel.connect('sqlite://db/test.db')

require_relative '../../lib/helpers/result'
require_relative './operation'
require_relative './product'
require_relative './template'
require_relative './user'
