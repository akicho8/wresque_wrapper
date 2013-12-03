require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/hash/keys'
require 'active_support/concern'

module WresqueWrapper
  extend ActiveSupport::Concern

  mattr_accessor :default_queue
  self.default_queue = :high

  mattr_accessor :inline
  self.inline = false

  included do
    class_attribute :queue, :default_queue
  end

  module ClassMethods
    def perform(id, method, *args)
      ActiveRecord::Base.clear_active_connections!
      if id
        self.find(id).send(method, *args)
      else
        self.send(method, *args)
      end
    end

    def delay(options = {})
      options = {
        :inline => WresqueWrapper.inline,
      }.merge(options.to_options)

      if options[:inline]
        self
      else
        WresqueWrapper::Proxy.new(self, self, nil, options[:queue], options[:in])
      end
    end
  end

  def delay(options = {})
    options = {
      :inline => WresqueWrapper.inline,
    }.merge(options.to_options)
    if options[:inline]
      self
    else
      WresqueWrapper::Proxy.new(self, self.class, self.id, options[:queue], options[:in])
    end
  end

  class Proxy
    attr_reader :target, :queue

    def initialize(target, klass, target_id, queue, number_of_seconds_from_now = nil)
      @target      = target
      @klass       = klass
      @target_id   = target_id
      @queue       = queue || @klass.default_queue || WresqueWrapper.default_queue
      @klass.queue = @queue
      @number_of_seconds_from_now = number_of_seconds_from_now
    end

    def method_missing(method, *args)
      if @target.respond_to?(method)
        if @number_of_seconds_from_now
          Resque.enqueue_in(@number_of_seconds_from_now, @klass, @target_id, method, *args)
        else
          Resque.enqueue(@klass, @target_id, method, *args)
        end
      else
        @target.send(method, *args)
      end
    end

    def respond_to?(*args)
      super || @target.respond_to?(*args)
    end
  end
end
