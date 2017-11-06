# frozen_string_literal: true

require 'helix_runtime'
require 'hypothesis-ruby-core/native'

module Hypothesis
  class Engine
    attr_reader :current_source

    def initialize(max_examples: 200, seed: nil)
      @max_examples = max_examples
      if seed.nil?
        seed = Random.rand(2**64 - 1)
      end
      @core_engine = HypothesisCoreEngine.new(seed)
    end

    def run
      count = 0
      total_count = 0
      while (count < @max_examples) && (total_count < @max_examples * 10)
        @current_source = Source.new(@core_engine, @core_engine.new_source)
        count += 1
        total_count += 1
        begin
          yield(@current_source)
        rescue UnsatisfiedAssumption
          count -= 1
        end
      end
      raise Unsatisfiable if count.zero?
    end
  end

  class Source
    def initialize(core_engine, core_id)
      @core_engine = core_engine
      @core_id = core_id
    end

    def bits(n)
      @core_engine.bits(@core_id, n)
    end

    def given(provider = nil, &block)
      provider ||= block
      provider.call(self)
    end

    def assume(condition)
      raise UnsatisfiedAssumption unless condition
    end
  end
end
