require 'rubygems/comparator/base'

class Gem::Comparator
  class SpecComparator
    include Gem::Comparator::Base

    ##
    # Compares common fields in spec

    def compare(packages, report, options = {})
      info 'Checking spec parameters...'

      spec_params(options[:param]).each do |param|
        values = []
        packages.each do |pkg|
          if pkg.spec.respond_to? :"#{param}"
            values << pkg.spec.send(:"#{param}")
          else
            warn "#{pkg.spec.full_name} does not respond to #{param}, skipping check"
          end
        end

        # Are values the same?
        if values.count(values[0]) == values.size
          report[param] << "[ #{SUCCESS} ] #{param} field is the same" if options[:log_all]
        else
          report[param].set_header "[ #{FAIL} ] #{param} field differs:"
          values.each_with_index do |value, index|
            report[param] << "#{Rainbow(packages[index].spec.version).blue}: #{value}"
          end
        end
      end
      report
    end

    private

      def spec_params(param)
        if param
          if SPEC_PARAMS.include? param
            return [param]
          else
            return []
          end
        end

        SPEC_PARAMS
      end

  end
end
