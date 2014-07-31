class Gem::Comparator
  class Report
    class Entry
      include Gem::UserInteraction

      attr_accessor :data, :indent

      def initialize(data = '', indent = '')
        @data = data
        @indent = indent
      end

      def set_indent!(indent)
        @indent = indent
        self
      end

      def empty?
        case @data
        when String, Array
          @data.empty?
        end
      end

      def print
        printed = case @data
                  when String
                    "#{@indent}#{@data}"
                  when Array
                    @indent + @data.join("\n#{@indent}")
                  else
                    "#{@indent}#{@data}"
                  end
        say printed
      end
    end
  end
end
