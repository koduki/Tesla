# -*- coding: utf-8 -*-
require 'lib/poilite.rb'
require 'erb'

filename = ARGV[0]

def parse_testcases testcases, steps
  testcases.map do |testcase|
    SeleniumCase.new testcase, steps
  end
end

def apply_template_case basecase, base_url, ss, testcases
  testcases.map do |testcase|
    case_name = "case%03d" % testcase.id

    erb = ERB.new(open(basecase).read)
    {:name => case_name, :body => erb.result(binding)} 
  end
end

def apply_template_suite basesuite, suite_title, testcase_names
  erb = ERB.new(open(basesuite).read)
  erb.result(binding) 
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
    @commands = matching_scenario2define(scenario, steps).map{|cmd| SeleniumCommand.new cmd }
  end 

  def matching_scenario2define scenario, steps
    action = scenario.action
#    p action
#    print action
#puts
    
    words = (action.scan(/「.*」/).
                  map{|word| steps.find_all{|step| word == step.pattern }.first.defines } + 
            action.scan(/"(.*?)"/)).
            flatten
    steps.find_all{|step| action =~  Regexp.new('^' + step.pattern + '$')}.first
    defines = steps.find_all{|step| action =~  Regexp.new('^' + step.pattern + '$')}.first.defines.flatten.join("\n")

    words.reduce(defines){|defines, word| defines.sub('%s', word) }.split("\n").
          map{|xs| xs.split(",")}.map{|xs| (xs.size == 2) ? xs << "" : xs}
  end
end
class SeleniumCommand
  attr_reader :name, :target, :value
  def initialize items
    @name, @target, @value = items
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

POILite::Excel::open(filename) do |book|
  testcases = concat(book.sheets[0].used_range[1..-1]).map{|xs| TestCase.new xs}
  steps = concat(book.sheets[1].used_range[1..-1].map{|xs| [xs[0], xs[1]]}).map{|xs| StepDefinition.new xs}

  options  = Hash[*book.sheets[2].used_range.map{|xs| [xs[0], xs[1]] }.flatten]

  base_url = options["Base URL"]
  basecase = options["TestCase Template"]
  basesuite = options["TestSuite Template"]
  suite_title = options["Index Title"]
  testcase_dir = options["TestCase Output Directory"]
  ss = {
        :output_dir => options["ScreenShot Output Direcotry"],
        :bgcolor => options["ScreenShot BG Color"],
      }

  testcase_dir = testcase_dir.sub(/\/$/,'').sub(/$/, '/')
  Dir::mkdir(testcase_dir) unless File::exists? testcase_dir 

  ss[:output_dir] = Dir::pwd + "/" + ss[:output_dir].sub(/\/$/,'').sub(/$/, '/')
  Dir::mkdir(ss[:output_dir]) unless File::exists? ss[:output_dir]

  selenium_testcases = parse_testcases testcases, steps
  
  testcases = apply_template_case basecase, base_url, ss, selenium_testcases
  testcases.each{|testcase| open(testcase_dir + "#{testcase[:name]}.html", "w"){|f| f.puts testcase[:body] }}

  testsuite = apply_template_suite basesuite, suite_title, testcases.map{|t| t[:name] }
  open(testcase_dir + "index.html", "w"){|f| f.puts testsuite }
end
