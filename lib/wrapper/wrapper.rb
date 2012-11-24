require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/class/attribute'
require 'active_support/concern'

module WresqueWrapper
  extend ActiveSupport::Concern

  mattr_accessor :default_queue
  self.default_queue = :high

  included do
    class_attribute :queue, :default_queue
  end

  module ClassMethods
    def perform(id, method, *args)
      ActiveRecord::Base.verify_active_connections!
      if id
        self.find(id).send(method, *args)
      else
        self.send(method, *args)
      end
    end

    def delay(options = {})
      WresqueWrapper::WrapperProxies::Proxy.new(self, self, nil, options[:queue])
    end
  end

  def delay(options = {})
    WresqueWrapper::WrapperProxies::Proxy.new(self, self.class, self.id, options[:queue])
  end

  module WrapperProxies
    class Proxy
      attr_reader :target

      def initialize(target, klass, target_id, queue)
        @target      = target
        @klass       = klass
        @target_id   = target_id
        @klass.queue = queue || @klass.default_queue || WresqueWrapper.default_queue
      end

      def method_missing(method, *args)
        if @target.respond_to?(method)
          Resque.enqueue(@klass, @target_id, method, *args)
        else
          @target.send(method, *args)
        end
      end

      def respond_to?(*args)
        super || @target.respond_to?(*args)
      end
    end
  end
end
