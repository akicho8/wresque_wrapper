require_relative "wresque_wrapper/wresque_wrapper"

ActiveRecord::Base.send(:include, WresqueWrapper)
