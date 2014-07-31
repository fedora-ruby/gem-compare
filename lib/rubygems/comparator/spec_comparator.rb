require 'rubygems/comparator/base'

class Gem::Comparator

  ##
  # Gem::Comparator::SpecComparator can
  # compare values from the gem verions specs

  class SpecComparator < Gem::Comparator::Base

    ##
    # Compare common fields in spec

    def compare(specs, report, options = {})
      info 'Checking spec parameters...'
      p = options[:param]
      b = options[:brief]

      filter_params(SPEC_PARAMS, p, b).each do |param|
        values = values_from_specs(param, specs)

        if same_values?(values) && options[:log_all]
          v = value(values[0])
          report[param].section do
            set_header "#{self.same} #{param}:"
	    puts v
          end
        elsif !same_values?(values)
          report[param].set_header "#{different} #{param}:"
          values.each_with_index do |value, index|
            report[param] << \
              "#{Rainbow(specs[index].version).blue}: #{value}"
          end
        end
      end
      report
    end

    private

      def value(value)
        case value
        when Gem::Requirement
          unless value.requirements.empty?
            r = value.requirements[0]
            "#{r[0]} #{r[1].version} "
          else
            '[]'
          end
        when Gem::Platform
          value.to_s
        when String
          return value unless value.empty?
          ''
        else
          value.inspect
        end
      end

      def same_values?(values)
        values.count(values[0]) == values.size
      end
  end
end
