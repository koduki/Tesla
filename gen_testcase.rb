# -*- coding: utf-8 -*-
require './lib/tesla/reader.rb'
require './lib/tesla/generator.rb'
require './lib/tesla/parser.rb'

include Tesla

filename = ARGV[0]

reader = Reader.new filename
testcases = TestCaseParser::parse_testcases reader.testcases, reader.steps

Generator::Selenium::apply_template testcases, reader.options  
