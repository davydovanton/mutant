module Mutant
  class Env
    # Boostrap environment
    class Bootstrap
      include Adamantium::Flat, Concord::Public.new(:config, :cache), Procto.call(:env)

      SEMANTICS_MESSAGE =
        "Fix your lib to follow normal ruby semantics!\n" \
        '{Module,Class}#name should return resolvable constant name as String or nil'.freeze

      # Return scopes that are eligible for mnatching
      #
      # @return [Enumerable<Matcher::Scope>]
      #
      # @api private
      #
      attr_reader :matchable_scopes

      # Return new bootstrap env
      #
      # @return [Env]
      #
      # @api private
      #
      def self.new(_config, _cache = Cache.new)
        super
      end

      # Initialize object
      #
      # @return [Object]
      #
      # @api private
      #
      def initialize(*)
        super
        infect
        initialize_matchable_scopes
      end

      # Print warning message
      #
      # @param [String]
      #
      # @return [self]
      #
      # @api private
      #
      def warn(message)
        config.reporter.warn(message)
        self
      end

      # Return environment after bootstraping
      #
      # @return [Env]
      #
      # @api private
      #
      # rubocop:disable MethodLength
      #
      def env
        subjects = matched_subjects
        Env.new(
          actor_env:        Actor::Env.new(Thread),
          config:           config,
          cache:            cache,
          subjects:         subjects,
          matchable_scopes: matchable_scopes,
          integration:      @integration,
          selector:         Selector::Expression.new(@integration),
          mutations:        subjects.flat_map(&:mutations)
        )
      end

    private

      # Return scope name
      #
      # @param [Class, Module] scope
      #
      # @return [String]
      #   if scope has a name and does not raise exceptions obtaining it
      #
      # @return [nil]
      #   otherwise
      #
      # @api private
      #
      def scope_name(scope)
        scope.name
      rescue => exception
        warn("#{scope.class}#name from: #{scope.inspect} raised an error: #{exception.inspect}. #{SEMANTICS_MESSAGE}")
        nil
      end

      # Infect environment
      #
      # @return [undefined]
      #
      # @api private
      #
      def infect
        config.includes.each(&$LOAD_PATH.method(:<<))
        config.requires.each(&method(:require))
        @integration = config.integration.new(config).setup
      end

      # Return matched subjects
      #
      # @return [Enumerable<Subject>]
      #
      # @api private
      #
      def matched_subjects
        Matcher::Compiler.call(self, config.matcher).to_a
      end

      # Initialize matchable scopes
      #
      # @return [undefined]
      #
      # @api private
      #
      def initialize_matchable_scopes
        scopes = ObjectSpace.each_object(Module).each_with_object([]) do |scope, aggregate|
          expression = expression(scope)
          aggregate << Matcher::Scope.new(self, scope, expression) if expression
        end

        @matchable_scopes = scopes.sort_by { |scope| scope.expression.syntax }
      end

      # Try to turn scope into expression
      #
      # @param [Class, Module] scope
      #
      # @return [Expression]
      #   if scope can be represented in an expression
      #
      # @return [nil]
      #   otherwise
      #
      # @api private
      #
      def expression(scope)
        name = scope_name(scope) or return

        unless name.instance_of?(String)
          warn("#{scope.class}#name from: #{scope.inspect} returned #{name.inspect}. #{SEMANTICS_MESSAGE}")
          return
        end

        config.expression_parser.try_parse(name)
      end
    end # Boostrap
  end # Env
end # Mutant
