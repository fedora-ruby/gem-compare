require 'rubygems/comparator/base'

class Gem::Comparator
  class SpecComparator
    include Gem::Comparator::Base

    ##
    # Compares common fields in spec

    def compare(specs, report, options = {})
      info 'Checking spec parameters...'

      filter_params(SPEC_PARAMS, options[:param]).each do |param|
        values = values_from_specs(param, specs)

        # Are values the same?
        if same_values? values
          report[param] << "#{SUCCESS} #{param}" if options[:log_all]
        else
          report[param].set_header "#{FAIL} #{param}:"
          values.each_with_index do |value, index|
            report[param] << \
              "#{Rainbow(specs[index].version).blue}: #{value}"
          end
        end
      end
      report
    end

    private

      def values_from_specs(param, specs)
	values = []
        specs.each do |s|
          if s.respond_to? :"#{param}"
            values << s.send(:"#{param}")
          else
            warn "#{s.full_name} does not respond to " +
		 "#{param}, skipping check"
          end
        end
	values
      end

      def same_values?(values)
        values.count(values[0]) == values.size
      end
  end
end
