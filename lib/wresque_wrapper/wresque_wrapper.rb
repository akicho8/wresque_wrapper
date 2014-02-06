# -*- coding: utf-8 -*-
require 'active_support/core_ext/module/attribute_accessors'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/hash/keys'
require 'active_support/concern'

module WresqueWrapper
  extend ActiveSupport::Concern

  mattr_accessor :default_queue
  self.default_queue = :high

  mattr_accessor :inline
  self.inline = defined?(Rails) ? Rails.env.test? : false

  included do
    class_attribute :queue, :default_queue
  end

  module ClassMethods
    # 自分自身が Worker になっている
    def perform(id, method, *args)
      ActiveRecord::Base.clear_active_connections!
      if id
        self.unscoped.find(id).send(method, *args)
      else
        self.send(method, *args)
      end
    end

    def delay(options = {})
      options = {
        :inline => WresqueWrapper.inline,
      }.merge(options.to_options)

      if options.delete(:inline)
        self
      else
        WresqueWrapper::Proxy.new(self, self, nil, options)
      end
    end
  end

  def delay(options = {})
    options = {
      :inline => WresqueWrapper.inline,
    }.merge(options.to_options)

    if options.delete(:inline)
      self
    else
      WresqueWrapper::Proxy.new(self, self.class, id, options)
    end
  end

  class Proxy
    attr_reader :klass_or_instance, :klass, :record_id, :queue, :options

    def initialize(klass_or_instance, klass, record_id, options = {})
      options.assert_valid_keys(:inline, :queue, :from_now, :at)

      @klass_or_instance = klass_or_instance
      @klass             = klass
      @record_id         = record_id
      @options           = options

      @queue = @options[:queue] || @klass.default_queue || WresqueWrapper.default_queue

      # ここは要注意。クラス変数を共有しているため、同じクラスでさまざまなキューを指定してしまうと指定通りのキューに行かない可能性がある。
      # この副作用問題になるなら、いちいちクラスを作って Worker を作らないといけないので、
      # 気軽に delay できるこのライブラリのメリットがなくなってしまう。
      @klass.queue = @queue
    end

    def method_missing(method, *args)
      if @klass_or_instance.respond_to?(method)
        if @options[:at]
          Resque.enqueue_at(@options[:at], @klass, @record_id, method, *args)
        elsif @options[:from_now]
          Resque.enqueue_in(@options[:from_now], @klass, @record_id, method, *args)
        else
          Resque.enqueue(@klass, @record_id, method, *args)
        end
      else
        @klass_or_instance.send(method, *args)
      end
    end

    def respond_to?(*args)
      super || @klass_or_instance.respond_to?(*args)
    end
  end
end
