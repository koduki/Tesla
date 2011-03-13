# -*- coding: utf-8 -*-

require './lib/poilite/poilite.rb'
module Tesla
  class Reader
    attr_reader :testcases, :steps, :options
    def initialize filename
      POILite::Excel::open(filename) do |book|
        @testcases = concat(read_range(book, 0)).map{|xs| TestCase.new xs}
        @steps     = concat(read_range(book, 1).map{|xs| [xs[0], xs[1]]}).map{|xs| StepDefinition.new xs}
        @options   = Hash[*book.sheets[2].used_range.map{|xs| [xs[0], xs[1]] }.flatten]
      end
    end

    def read_range book, index
      book.sheets[index].used_range[1..-1]
    end

    def concat cells
      cells.reduce([]) do |r, x|
        if x[0] == ""
          r.last[1] <<  x[1..-1]
          r
        else
          r << [x[0], [x[1..-1]]]
        end
      end
    end

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
