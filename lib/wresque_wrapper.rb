# -*- coding: utf-8 -*-
require_relative "wresque_wrapper/version"
require_relative "wresque_wrapper/wresque_wrapper"

if defined?(Rails)
  module WresqueWrapper
    class Railtie < Rails::Railtie
      initializer "wresque_wrapper" do
        ActiveSupport.on_load(:active_record) { include WresqueWrapper }
      end
    end
  end
end
