module Unparser
  class Emitter
    class Literal
      # Emitter for execute strings (xstr) nodes
      class ExecuteString < self

        OPEN = CLOSE = '`'.freeze

        handle :xstr

      private

        # Perform dispatch
        #
        # @return [undefined]
        #
        # @api private
        #
        def dispatch
          parentheses(OPEN, CLOSE) do
            visit(dynamic_body)
          end
        end

        # Return dynamic body
        #
        # @return [Parser::AST::Node]
        #
        # @api private
        #
        def dynamic_body
          Parser::AST::Node.new(:dyn_xstr_body, children)
        end

      end # ExecuteString
    end # Literal
  end # Emitter
end # Unparser
