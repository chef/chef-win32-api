# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  enable_coverage :branch
  minimum_coverage 80
end

require "test/unit"
