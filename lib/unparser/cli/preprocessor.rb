# encoding: utf-8

module Unparser
  class CLI

    # CLI Specific preprocessor used for equivalency testing
    class Preprocessor
      include Adamantium::Flat, AbstractType, Concord.new(:node), Procto.call(:result)

      # Return preprocessor result
      #
      # @return [Parser::AST::Node]
      #
      # @api private
      #
      abstract_method :result

      # Run preprocessor for node
      #
      # @param [Parser::AST::Node, nil] node
      #
      # @return [Parser::AST::Node, nil]
      #
      # @api private
      #
      def self.run(node)
        return if node.nil?
        REGISTRY.fetch(node.type, Noop).new(node).result
      end

      REGISTRY = {}

      # Register preprocessor
      #
      # @param [Symbol] type
      #
      # @return [undefined]
      #
      # @api private
      #
      def self.register(type)
        REGISTRY[type] = self
      end
      private_class_method :register

    private

      # Visit node
      #
      # @param [Parser::AST::Node]
      #
      # @api private
      #
      def visit(node)
        self.class.run(node)
      end

      # Return children
      #
      # @return [Array<Parser::AST::Node>]
      #
      # @api private
      #
      def children
        node.children
      end

      # Return mapped children
      #
      # @return [Array<Parser::Ast::Node>]
      #
      # @api private
      #
      def mapped_children
        children.map do |node|
          if node.kind_of?(Parser::AST::Node)
            visit(node)
          else
            node
          end
        end
      end

      # Noop preprocessor that just passes through noode.
      class Noop < self

        # Return preprocessor result
        #
        # @return [Parser::AST::Node]
        #
        # @api private
        #
        def result
          Parser::AST::Node.new(node.type, mapped_children)
        end
      end # Noop

      # Preprocessor for dynamic string nodes. Collapses adjacent string segments into one.
      class Dstr < self

        register :dstr

        # Return preprocessor result
        #
        # @return [Parser::AST::Node]
        #
        # @api private
        #
        def result
          if collapsed_children.all? { |node| node.type == :str }
            Parser::AST::Node.new(:str, [collapsed_children.map(&:children).map(&:first).join])
          else
            node.updated(nil, collapsed_children)
          end
        end

      private

        # Return collapsed children
        #
        # @return [Array<Parser::AST::Node>]
        #
        # @api private
        #
        def collapsed_children
          chunked_children.each_with_object([]) do |(type, nodes), aggregate|
            if type == :str
              aggregate << Parser::AST::Node.new(:str, [nodes.map(&:children).map(&:first).join])
            else
              aggregate.concat(nodes)
            end
          end
        end
        memoize :collapsed_children

        # Return chunked children
        #
        # @return [Array<Parser::AST::Node>]
        #
        # @api private
        #
        def chunked_children
          mapped_children.chunk do |item|
            item.type
          end
        end

      end # Begin

      # Preprocessor for regexp nodes. Normalizes quoting.
      class Regexp < self

        register :regexp

        # Return preprocesso result
        #
        # @return [Parser::AST::Node]
        #
        # @api private
        #
        def result
          location = node.location
          if location && location.begin.source.start_with?('%r')
            Parser::CurrentRuby.parse(Unparser.unparse(node))
          else
            node
          end
        end
      end

      # Preprocessor for begin nodes. Removes begin nodes with one child.
      #
      # These superflownosely currently get generated by unparser.
      #
      class Begin < self

        register :begin

        # Return preprocessor result
        #
        # @return [Parser::AST::Node]
        #
        # @api private
        #
        def result
          if children.one?
            visit(children.first)
          else
            Noop.call(node)
          end
        end

      end # Begin
    end # Preprocessor
  end # CLI
end # Unparser
