require 'spec_helper'
require 'wresque_wrapper/wresque_wrapper'
require 'resque'
require 'resque_scheduler'

describe WresqueWrapper do

  before(:all) do
    module ActiveRecord
      class Base; end
    end
  end

  before(:each) do
    class DummyClass
      include WresqueWrapper
      self.default_queue = :dummy_queue
      def id; 1; end
    end

    ActiveRecord::Base.stubs(:verify_active_connections!).returns(true)

    @dummy = DummyClass.new
  end

  describe "Global options" do
    it "default_queue" do
      WresqueWrapper.should respond_to :default_queue
      WresqueWrapper.should respond_to :default_queue=
    end

    it "inline" do
      WresqueWrapper.should respond_to :inline
      WresqueWrapper.should respond_to :inline=
    end
  end

  describe "Class methods" do
    describe ".included" do
      it "should add accessors" do
        DummyClass.should respond_to :queue
        DummyClass.should respond_to :default_queue
      end

      it "should add the instance methods" do
        @dummy.should respond_to :delay
      end
    end

    describe ".default_queue" do
      it "should set the default queue" do
        DummyClass.default_queue = :dummier_queue
        DummyClass.default_queue.should == :dummier_queue
      end
    end

    describe ".perform" do
      it "should send the method to an instance if given an id" do
        test_method = :test_method
        test_args = [1, 2, 3]
        DummyClass.expects(:find).once.returns(@dummy)
        @dummy.expects(:send).with(test_method, *test_args).once.returns(true)
        DummyClass.perform(1, test_method, *test_args)
      end

      it "should send the method to the class if no id is given" do
        test_method = :test_method
        test_args = [1, 2, 3]
        DummyClass.expects(:send).with(test_method, *test_args).once.returns(true)
        DummyClass.perform(nil, test_method, *test_args)
      end
    end

    describe ".delay" do
      it "should return the appropriate proxy object" do
        DummyClass.delay.class.should == WresqueWrapper::Proxy
      end

      it "should not raise an exception if no queue is set" do
        DummyClass.default_queue = nil
        lambda { DummyClass.delay }.should_not raise_error
      end

      it "with inline option" do
        DummyClass.delay.should_not == DummyClass
        DummyClass.delay(:inline => true).should == DummyClass
      end
    end
  end

  describe "Instance methods" do
    describe "#delay" do
      it "should return the appropriate proxy object" do
        @dummy.delay.class.should == WresqueWrapper::Proxy
      end

      it "should not raise an exception if no queue is set" do
        DummyClass.default_queue = nil
        lambda { @dummy.delay }.should_not raise_error
      end

      it "with inline option" do
        @dummy.delay.should_not == @dummy
        @dummy.delay(:inline => true).should == @dummy
      end
    end
  end

  describe WresqueWrapper::Proxy do
    describe "Proxy for Class" do
      before(:each) do
        @class_proxy = WresqueWrapper::Proxy.new(DummyClass, DummyClass, nil, :new_queue)
      end

      describe "#initialize" do
        it "should set the target class's queue" do
          DummyClass.queue.should == :new_queue
        end

        it "should retain the target class" do
          @class_proxy.target.should == DummyClass
        end
      end

      describe "#method_missing" do
      end

      describe "#respond_to?" do
      end
    end

    describe "Proxy for instance" do
      before(:each) do
        @instance_proxy = WresqueWrapper::Proxy.new(@dummy, @dummy.class, @dummy.id, :new_queue)
      end

      describe "#initialize" do
        it "should set the target class's queue" do
          DummyClass.queue.should == :new_queue
        end

        it "should retain the target instance" do
          @instance_proxy.target.should == @dummy
        end
      end

      describe "#method_missing" do
        it "should Resque.enqueue return" do
          @instance_proxy.send(:method_missing, :id).should be_true
        end
      end

      describe "#respond_to?" do
      end
    end

    describe "Proxy for instance with scheduler" do
      before do
        @instance_proxy = WresqueWrapper::Proxy.new(@dummy, @dummy.class, @dummy.id, :new_queue, 60)
      end

      describe "#method_missing" do
        it "should Resque.enqueue_in return" do
          @instance_proxy.send(:method_missing, :id).should be_true
        end
      end
    end

  end
end
