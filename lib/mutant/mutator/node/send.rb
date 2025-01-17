module Mutant
  class Mutator
    class Node

      # Namespace for send mutators
      class Send < self
        include AST::Types

        handle(:send)

        children :receiver, :selector

        SELECTOR_REPLACEMENTS = IceNine.deep_freeze(
          reverse_map:   %i[map each],
          kind_of?:      %i[instance_of?],
          is_a?:         %i[instance_of?],
          reverse_each:  %i[each],
          reverse_merge: %i[merge],
          map:           %i[each],
          send:          %i[public_send __send__],
          __send__:      %i[public_send],
          gsub:          %i[sub],
          eql?:          %i[equal?],
          to_s:          %i[to_str],
          to_i:          %i[to_int],
          to_a:          %i[to_ary],
          at:            %i[fetch],
          :[] =>         %i[at fetch],
          :== =>         %i[eql? equal?],
          :>= =>         %i[> == eql? equal?],
          :<= =>         %i[< == eql? equal?],
          :> =>          %i[== >= eql? equal?],
          :< =>          %i[== <= eql? equal?]
        )

      private

        # Perform dispatch
        #
        # @return [undefined]
        #
        # @api private
        #
        def dispatch
          emit_singletons
          if meta.index_assignment?
            run(Index::Assign)
          else
            non_index_dispatch
          end
        end

        # Perform non index dispatch
        #
        # @return [undefined]
        #
        # @api private
        #
        def non_index_dispatch
          if meta.binary_method_operator?
            run(Binary)
          elsif meta.attribute_assignment?
            run(AttributeAssignment)
          else
            normal_dispatch
          end
        end

        # Return AST metadata for node
        #
        # @return [AST::Meta::Send]
        def meta
          AST::Meta::Send.new(node)
        end
        memoize :meta

        # Return arguments
        #
        # @return [Enumerable<Parser::AST::Node>]
        #
        # @api private
        #
        alias_method :arguments, :remaining_children

        # Perform normal, non special case dispatch
        #
        # @return [undefined]
        #
        # @api private
        #
        def normal_dispatch
          emit_naked_receiver
          emit_selector_replacement
          emit_argument_propagation
          mutate_receiver
          mutate_arguments
        end

        # Emit selector replacement
        #
        # @return [undefined]
        #
        # @api private
        #
        def emit_selector_replacement
          SELECTOR_REPLACEMENTS.fetch(selector, EMPTY_ARRAY).each do |replacement|
            emit_selector(replacement)
          end
        end

        # Emit naked receiver mutation
        #
        # @return [undefined]
        #
        # @api private
        #
        def emit_naked_receiver
          emit(receiver) if receiver && !NOT_ASSIGNABLE.include?(receiver.type)
        end

        # Mutate arguments
        #
        # @return [undefined]
        #
        # @api private
        #
        def mutate_arguments
          emit_type(receiver, selector)
          remaining_children_with_index.each do |_node, index|
            mutate_child(index)
            delete_child(index)
          end
        end

        # Emit argument propagation
        #
        # @return [undefined]
        #
        # @api private
        #
        def emit_argument_propagation
          node = arguments.first
          emit(node) if arguments.one? && !NOT_STANDALONE.include?(node.type)
        end

        # Emit receiver mutations
        #
        # @return [undefined]
        #
        # @api private
        #
        def mutate_receiver
          return unless receiver
          emit_implicit_self
          emit_receiver_mutations do |node|
            !n_nil?(node)
          end
        end

        # Emit implicit self mutation
        #
        # @return [undefined]
        #
        # @api private
        #
        def emit_implicit_self
          emit_receiver(nil) if n_self?(receiver) && !(
            KEYWORDS.include?(selector)         ||
            METHOD_OPERATORS.include?(selector) ||
            OP_ASSIGN.include?(parent_type)     ||
            meta.attribute_assignment?
          )
        end

      end # Send
    end # Node
  end # Mutator

end # Mutant
