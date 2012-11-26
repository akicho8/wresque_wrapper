require_relative "wresque_wrapper/wresque_wrapper"

ActiveRecord::Base.extend(WresqueWrapper)
