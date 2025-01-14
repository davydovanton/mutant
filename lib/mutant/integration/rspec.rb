require 'rspec/core'

module Mutant
  class Integration
    # Rspec integration
    #
    # This looks so complicated, because rspec:
    #
    # * Keeps its state global in RSpec.world and lots of other places
    # * There is no API to "just run a subset of examples", the examples
    #   need to be selected in-place via mutating the `RSpec.filtered_examples`
    #   datastructure
    # * Does not maintain a unique identification for an example,
    #   aside the instances of `RSpec::Core::Example` objects itself.
    #   For that reason identifing examples by:
    #   * full description
    #   * location
    #   Is NOT enough. It would not be uniqe. So we add an "example index"
    #   for unique reference.
    class Rspec < self

      ALL_EXPRESSION       = Expression::Namespace::Recursive.new(scope_name: nil)
      EXPRESSION_CANDIDATE = /\A([^ ]+)(?: )?/.freeze
      LOCATION_DELIMITER   = ':'.freeze
      EXIT_SUCCESS         = 0
      CLI_OPTIONS          = IceNine.deep_freeze(%w[spec --fail-fast])

      private_constant(*constants(false))

      register 'rspec'

      # Initialize rspec integration
      #
      # @return [undefined]
      #
      # @api private
      #
      def initialize(*)
        super
        @output = StringIO.new
        @runner = RSpec::Core::Runner.new(RSpec::Core::ConfigurationOptions.new(CLI_OPTIONS))
        @world  = RSpec.world
      end

      # Setup rspec integration
      #
      # @return [self]
      #
      # @api private
      #
      def setup
        @runner.setup($stderr, @output)
        self
      end
      memoize :setup

      # Return report for test
      #
      # @param [Enumerable<Mutant::Test>] tests
      #
      # @return [Result::Test]
      #
      # @api private
      #
      # rubocop:disable MethodLength
      #
      def call(tests)
        examples = tests.map(&all_tests_index.method(:fetch))
        filter_examples(&examples.method(:include?))
        start = Time.now
        passed = @runner.run_specs(@world.ordered_example_groups).equal?(EXIT_SUCCESS)
        @output.rewind
        Result::Test.new(
          tests:    tests,
          output:   @output.read,
          runtime:  Time.now - start,
          passed:   passed
        )
      end

      # Return all available tests
      #
      # @return [Enumerable<Test>]
      #
      # @api private
      #
      def all_tests
        all_tests_index.keys
      end
      memoize :all_tests

    private

      # Return all tests index
      #
      # @return [Hash<Test, RSpec::Core::Example]
      #
      # @api private
      #
      def all_tests_index
        all_examples.each_with_index.each_with_object({}) do |(example, example_index), index|
          index[parse_example(example, example_index)] = example
        end
      end
      memoize :all_tests_index

      # Parse example into test
      #
      # @param [RSpec::Core::Example] example
      # @param [Fixnum] index
      #
      # @return [Test]
      #
      # @api private
      #
      def parse_example(example, index)
        metadata         = example.metadata
        location         = metadata.fetch(:location)
        full_description = metadata.fetch(:full_description)

        Test.new(
          id:         "rspec:#{index}:#{location}/#{full_description}",
          expression: parse_expression(metadata)
        )
      end

      # Parse metadata into expression
      #
      # @param [RSpec::Core::Example::Medatada] metadata
      #
      # @return [Expression]
      #
      # @api private
      #
      def parse_expression(metadata)
        if metadata.key?(:mutant_expression)
          expression_parser.(metadata.fetch(:mutant_expression))
        else
          match = EXPRESSION_CANDIDATE.match(metadata.fetch(:full_description))
          expression_parser.try_parse(match.captures.first) || ALL_EXPRESSION
        end
      end

      # Return all examples
      #
      # @return [Array<String, RSpec::Core::Example]
      #
      # @api private
      #
      def all_examples
        @world.example_groups.flat_map(&:descendants).flat_map(&:examples).select do |example|
          example.metadata.fetch(:mutant, true)
        end
      end

      # Filter examples
      #
      # @param [#call] predicate
      #
      # @return [undefined]
      #
      # @api private
      #
      def filter_examples(&predicate)
        @world.filtered_examples.each_value do |examples|
          examples.keep_if(&predicate)
        end
      end

    end # Rspec
  end # Integration
end # Mutant
