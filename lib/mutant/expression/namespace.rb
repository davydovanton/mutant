module Mutant
  class Expression
    # Abstract base class for expressions matching namespaces
    class Namespace < self
      include AbstractType, Anima.new(:scope_name)
      private(*anima.attribute_names)

      # Recursive namespace expression
      class Recursive < self
        REGEXP = /\A#{SCOPE_NAME_PATTERN}?\*\z/.freeze

        # Initialize object
        #
        # @return [undefined]
        #
        # @api private
        def initialize(*)
          super
          @recursion_pattern = Regexp.union(
            /\A#{scope_name}\z/,
            /\A#{scope_name}::/,
            /\A#{scope_name}[.#]/
          )
        end

        # Return the syntax for this expression
        #
        # @return [String]
        #
        # @api private
        #
        def syntax
          "#{scope_name}*"
        end
        memoize :syntax

        # Return matcher
        #
        # @param [Env::Bootstrap] env
        #
        # @return [Matcher]
        #
        # @api private
        #
        def matcher(env)
          Matcher::Namespace.new(env, self)
        end

        # Return length of match
        #
        # @param [Expression] expression
        #
        # @return [Fixnum]
        #
        # @api private
        #
        def match_length(expression)
          if @recursion_pattern =~ expression.syntax
            scope_name.length
          else
            0
          end
        end

      end # Recursive

      # Exact namespace expression
      class Exact < self

        MATCHER = Matcher::Scope
        private_constant(*constants(false))

        REGEXP  = /\A#{SCOPE_NAME_PATTERN}\z/.freeze

        # Return matcher
        #
        # @param [Env::Bootstrap] env
        #
        # @return [Matcher]
        #
        # @api private
        #
        def matcher(env)
          Matcher::Scope.new(env, Object.const_get(scope_name), self)
        end

        # Return the syntax for this expression
        #
        # @return [String]
        #
        # @api private
        #
        alias_method :syntax, :scope_name
        public :syntax

      end # Exact
    end # Namespace
  end # Namespace
end # Mutant
