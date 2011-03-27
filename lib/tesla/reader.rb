# -*- coding: utf-8 -*-
require './lib/tesla/input_models.rb'
require './lib/tesla/utils.rb'

module Tesla
  module Reader
    class ExcelReader
      require './lib/poilite/poilite.rb'

      attr_reader :testcases, :steps, :options
      def initialize filename
        POILite::Excel::open(filename) do |book|
          @testcases = Utils::concat(read_range(book, 0)).map{|xs| TestCase.new xs }
          @steps     = Utils::concat(read_range(book, 1).map{|xs| [xs[0], xs[1]] }).map{|xs| StepDefinition.new xs }
          @options   = Hash[*book.sheets[2].used_range.map{|xs| [xs[0], xs[1]] }.flatten]
        end
      end

      def read_range book, index
        book.sheets[index].used_range[1..-1]
      end

    end
  end
end
