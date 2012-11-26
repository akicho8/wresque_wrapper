# -*- coding: utf-8 -*-

require "active_record"
require_relative "../lib/wresque_wrapper"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define do
  create_table :users do |t|
  end
end

class User < ActiveRecord::Base
  def foo
    "ok"
  end
end

user = User.create!

p User.delay.foo
