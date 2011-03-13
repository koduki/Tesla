# -*- coding: utf-8 -*-

module Tesla
  module Reader
    class TestCase
      attr_reader :id, :scenarios
      def initialize testcase
        @id = testcase[0].to_i
        @scenarios = concat_scenario(testcase[1].map{|xs| [xs[1], [xs[2]]]}).
                                    find_all{|item| not item[0].empty? }.
                                    map{|item| TestScenario.new item }
      end

      def concat_scenario cells
        cells.reduce([]) do |r, x|
          if x[1] == ""
            r.last[1] +=  x[1]
            r
          else
            r << x
          end
        end
      end
    end

    class TestScenario
      attr_reader :action, :validations  
      def initialize item
        @action = item[0]
        @validations = item[1]
      end
    end

    class StepDefinition
      attr_reader :pattern, :defines  
      def initialize item
        @pattern = item[0]
        @defines = item[1]
      end
    end

  end
end 
