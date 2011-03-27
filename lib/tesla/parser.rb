# -*- coding: utf-8 -*-

module Tesla
  module TestCaseParser
    def self.parse_testcases testcases, steps
      testcases.map do |testcase|
        SeleniumCase.new testcase, steps
      end
    end

    class SeleniumCase
      attr_reader :id, :scenarios
      def initialize testcase, steps
        @id = testcase.id
        @scenarios = testcase.scenarios.map{|scenario| SeleniumScenario.new scenario, steps  }
      end
    end
    
    class SeleniumScenario
      attr_reader :commands
      def initialize scenario, steps
        @commands = []
        @commands += matching_scenario2define(scenario, steps).map{|cmd| SeleniumCommand.new cmd, true }
        @commands += matching_validations2define(scenario, steps).map{|cmd| SeleniumCommand.new cmd, false }
      end 

      def matching_validations2define scenario, steps
        scenario.validations.find_all{|validation| not validation.empty? }.map do |action|
          words = (action.scan(/「.*」/).
                        map{|word| steps.find_all{|step| word == step.pattern }.first.defines } + 
                  action.scan(/'(.*?)'/)).
                  flatten
          defines = steps.find_all{|step| action =~  Regexp.new('^' + step.pattern + '$')}.first.defines.flatten.join("\n")
          words.reduce(defines){|defines, word| defines.sub('%s', word) }.split("\n").
              map{|xs| xs.split(",")}.map{|xs| (xs.size == 2) ? xs << "" : xs}.flatten
        end
      end
 
      def matching_scenario2define scenario, steps
        action = scenario.action
        words = (action.scan(/「.*」/).
                        map{|word| steps.find_all{|step| word == step.pattern }.first.defines } + 
                action.scan(/'(.*?)'/)).
                flatten
        defines = steps.find_all{|step| action =~  Regexp.new('^' + step.pattern + '$')}.first.defines.flatten.join("\n")

        words.reduce(defines){|defines, word| defines.sub('%s', word) }.split("\n").
              map{|xs| xs.split(",")}.map{|xs| (xs.size == 2) ? xs << "" : xs}
      end
    end
    
    class SeleniumCommand
      attr_reader :name, :target, :value
      def initialize items, capturble
        @name, @target, @value = items
        @capturble = capturble
      end

      def capturble?
        @capturble
      end
    end

  end

end
