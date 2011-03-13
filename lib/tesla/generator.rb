# -*- coding: utf-8 -*-

require "erb"
require "fileutils"

module Tesla
  module Generator
    module Selenium

      def self.apply_template_case basecase, base_url, ss, testcases
        testcases.map do |testcase|
          case_name = "case%03d" % testcase.id

          erb = ERB.new(open(basecase).read)
          {:name => case_name, :body => erb.result(binding)} 
        end
      end

      def self.apply_template_suite basesuite, suite_title, testcase_names
        erb = ERB.new(open(basesuite).read)
        erb.result(binding) 
      end

      def self.apply_template testcases, options
        base_url = options["Base URL"]
        basecase = options["TestCase Template"]
        basesuite = options["TestSuite Template"]
        suite_title = options["Index Title"]

        testcase_dir = options["TestCase Output Directory"].sub(/\/$/,'').sub(/$/, '/')
        ss = {
            :output_dir => Dir::pwd + "/" +  options["ScreenShot Output Direcotry"].sub(/\/$/,'').sub(/$/, '/'),
            :bgcolor => options["ScreenShot BG Color"],
        }

        FileUtils.mkdir_p(testcase_dir) unless File::exists? testcase_dir 
        FileUtils.mkdir_p(ss[:output_dir]) unless File::exists? ss[:output_dir]

        selenium_testcases = apply_template_case basecase, base_url, ss, testcases
        selenium_testcases.each{|testcase| open(testcase_dir + "#{testcase[:name]}.html", "w"){|f| f.puts testcase[:body] }}

        selenium_testsuite = apply_template_suite basesuite, suite_title, selenium_testcases.map{|t| t[:name] }
        open(testcase_dir + "index.html", "w"){|f| f.puts selenium_testsuite }
      end
    end 
  end
end
