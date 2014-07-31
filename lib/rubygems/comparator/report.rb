require 'rubygems/comparator/report/entry'

class Gem::Comparator

  ##
  # Gem::Comparator::Report can nest sections and print only those that
  # contain some messages.
  #
  # Usage:
  #   report = Gem::Comparator::Report.new
  #   report['section1'] << "Message 1"
  #   report['section1']['subsection1'].set_header 'Message 2 Header'
  #   report['section1']['subsection1'] << "Message 2" if false
  #   report['section1'].section
  #     nest('subsection2').section
  #       puts "Message 3"
  #     end
  #   end
  #   report.print
  #
  # This won't print Message 2 nor its header saving a lot of if/else.

  class Report

    module Signs
      def same
        Rainbow('SAME').green.bright
      end

      def different
        Rainbow('DIFFERENT').red.bright
      end
    end

    def self.new(name = 'main')
      Gem::Comparator::Report::NestedSection.new(name)
    end

    class NestedSection
      include Report::Signs
      include Gem::UserInteraction

      DEFAULT_INDENT = '  '

      attr_reader :header, :messages, :parent_section, :level
      attr_accessor :name, :sections

      def initialize(name, parent_section = nil)
        @name = name
        @header = Entry.new
        @messages = []
        @sections = []
        @level = 0

        set_parent parent_section if parent_section
      end

      def section(&block)
        instance_eval &block
      end

      def set_header(message)
        @header = Entry.new(message)
      end

      def puts(message)
        case message
        when String, Array
          @messages << Entry.new(message) unless message.empty?
        else
          @messages << Entry.new(message) unless message
        end
      end
      alias_method :<<, :puts

      def nest(name)
        @sections.each do |s|
          return s if s.name == name
        end
        NestedSection.new(name, self)
      end
      alias_method :[], :nest

      def print
        all_messages.each { |m| m.print }
      end

      def all_messages
        indent = DEFAULT_INDENT*@level

        if @header.empty?
          @messages.map do |m|
            m.set_indent!(indent)
          end + nested_messages
        else
          nested = @messages.map do |m|
            m.set_indent!(indent * 2)
          end + nested_messages
          return [] if nested.empty?

          @header.set_indent!(indent)
          nested.unshift(@header)
        end
      end

      def lines(line_num)
        all_messages[line_num].data
      end

      def nested_messages
        nested_messages = []
        @sections.each do |section|
          section.all_messages.each do |m|
            nested_messages << m
          end
        end
        nested_messages
      end

      private

        def set_parent(parent)
          parent.sections << self
          @level = parent.level + 1
          parent_section = parent
        end

    end
  end
end
