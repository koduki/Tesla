# -*- coding: utf-8 -*-
require 'lib/poilite.rb'
require 'erb'

filename = ARGV[0]

def create_testblock actions, defines
  testblock = actions.map do |action|
    testcases = defines.find_all{|d| action =~  Regexp.new('^' + d[0] + '$')}[0][1]
    target = action.scan(/「.*」/).
                  map{|x| defines.find_all{|d| x == d[0]}[0] }.
                  map{|x| x[1]} + action.scan(/"(.*?)"/).
                  flatten
    target.reduce(testcases){|testcases, define| testcases.sub('%s', define) } 
  end
  testblock.map{|senario| senario.split(/\n/)}.
            flatten.
            map{|senario| senario.split(",", 3) }.
            map{|senario| (senario.size >= 3) ? senario : (senario << "") } 
end

def concat cells
  cells.reduce([]) do |r, x|
    if x[0] == ""
      r.last[1] += "\n" + x[1]
      r
    else
      r << x
    end
  end
end

def template_case basecase, base_url, ss, senarios
  senarios.map do |test_senario|
    casename = "case%03d" % test_senario[0]
    senario = test_senario[1]

    erb = ERB.new(open(basecase).read)
    [casename, erb.result(binding)] 
  end
end

def template_suite basesuite, suite_title, testcases
  erb = ERB.new(open(basesuite).read)
  erb.result(binding) 
end

POILite::Excel::open(filename) do |book|
  senarios = concat book.sheets[0].used_range[1..-1].map{|xs| [xs[0], xs[2]]}
  defines  = concat book.sheets[1].used_range[1..-1].map{|xs| [xs[0], xs[1]]}
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
  
  testcases = template_case basecase, base_url, ss, senarios.map{|senario| [senario[0], create_testblock(senario[1].split(/\n/), defines)]}  
  testcases.each{|testcase| open(testcase_dir + "#{testcase[0]}.html", "w"){|f| f.puts testcase[1] }}

  testsuite = template_suite basesuite, suite_title, testcases
  open(testcase_dir + "index.html", "w"){|f| f.puts testsuite }
end
