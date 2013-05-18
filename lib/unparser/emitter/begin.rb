module Unparser
  class Emitter

    # Emitter for rescue nodes
    class Rescue < self

      handle :rescue

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        k_begin
        indented { visit(first_child) }
        children[1..-2].each do |child|
          visit(child)
        end
        k_end
      end
    end # Rescue

    # Emitter for enusre nodes
    class Ensure < self

      handle :ensure

      K_ENSURE = 'ensure'.freeze

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        k_begin
        emit_body
        write(K_ENSURE)
        emit_ensure_body
        k_end
      end

      # Emit body
      #
      # @return [undefined]
      #
      # @api private
      #
      def emit_body
        indented { visit(first_child) }
      end

      # Emit ensure body
      #
      # @return [undefined]
      #
      # @api private
      #
      def emit_ensure_body
        indented { visit(children[1]) }
      end

    end # Ensure

    # Emitter for rescue body nodes
    class Resbody < self

      handle :resbody

      RESCUE = 'rescue'.freeze

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        write(RESCUE)
        emit_exception
        emit_assignment
        indented { visit(children[2]) }
      end

      # Emit exception
      #
      # @return [undefined]
      #
      # @api private
      #
      def emit_exception
        exception = first_child
        return unless exception
        ws
        delimited(exception.children)
      end

      ASSIGN_OP = ' => '.freeze

      # Emit assignment
      #
      # @return [undefined]
      #
      # @api private
      #
      def emit_assignment
        assignment = children[1]
        return unless assignment
        write(ASSIGN_OP)
        visit(assignment)
      end

    end # Resbody

    # Emitter for begin nodes
    class Begin < self

      handle :begin

    private

      # Perform dispatch
      #
      # @return [undefined]
      #
      # @api private
      #
      def dispatch
        if flat?
          visit(first_child)
          return
        end
        k_begin
        indented { emit_inner }
        k_end
      end

      SINGLE_NODES = [:rescue, :ensure].freeze

      # Test for flat emit
      #
      # @return [true]
      #   if flat emit is possible
      #
      # @return [false]
      #   otherwise
      #
      # @api private
      #
      def flat?
        children.one? && SINGLE_NODES.include?(first_child.type)
      end

      # Emit inner nodes
      #
      # @return [undefined]
      #
      # @api private
      #
      def emit_inner
        childs = children
        max = childs.length - 1
        childs.each_with_index do |child, index|
          visit(child)
          nl if index < max
        end
      end

    end # Body
  end # Emitter
end # Unparser