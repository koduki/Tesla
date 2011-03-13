module POILite
  libdir =  File.expand_path('../',  __FILE__)

  require 'java'
  require libdir + '/jarlib/poi-3.7-20101029.jar'
  require libdir + '/jarlib/poi-ooxml-3.7-20101029.jar'
  require libdir + '/jarlib/poi-scratchpad-3.7-20101029.jar'
  
  module Excel
    include_class 'org.apache.poi.ss.usermodel.Cell'
    include_class 'org.apache.poi.ss.usermodel.Sheet'
    include_class 'org.apache.poi.ss.usermodel.Workbook'
    include_class 'org.apache.poi.ss.usermodel.WorkbookFactory'
    include_class 'org.apache.poi.ss.usermodel.DateUtil'
  
    class WorkBook
      attr_reader :sheets
      def initialize poibook
        @poibook = poibook
        @sheets = @poibook.sheets.map{|sheet| WorkSheet.new sheet }
      end
    end
  
    class WorkSheet
      attr_reader :rows
  
      def initialize poisheet
        @poisheet = poisheet 
        @rows = Rows.new @poisheet
      end
  
      def cells row_index, column_index
        Util::value @poisheet.getRow(row_index).getCell(column_index)  
      end
  
      def first_row_num 
        @poisheet.getFirstRowNum
      end
      def first_row
        @rows[first_row_num]
      end
  
      def last_row_num
        @poisheet.getLastRowNum
      end
      def last_row
        @rows[last_row_num]
      end
  
      def used_range
        used_rows = (first_row_num..last_row_num).map{ |i| @rows[i] }
        min_cell_num = used_rows.map{|r| r.first_cell_num }.min
        max_cell_num = used_rows.map{|r| r.last_cell_num }.max
  
        used_range = used_rows.map do |row|
          (min_cell_num..max_cell_num).map do |i|
            row.cells[i]
          end
        end
      end
    end
  
    class Rows
      def initialize poisheet
        @poisheet = poisheet
      end
  
      def [](index)
        Row.new @poisheet.getRow(index)
      end
    end
  
    class Row
      attr_reader :cells
  
      def initialize poirow
        @poirow = poirow
        @cells = Cells.new @poirow
      end
  
      def first_cell_num 
        (@poirow == nil) ? 0 : @poirow.getFirstCellNum
      end
      def first_cell
        (@poirow == nil) ? nil : @cells[first_cell_num]
      end
  
      def last_cell_num
        (@poirow == nil) ? 0 : @poirow.getLastCellNum
      end
      def last_cell
        (@poirow == nil) ? nil : @cells[last_cell_num]
      end
    end
  
    class Cells
      def initialize poirow
        @poirow = poirow
      end
  
      def [](index)
        if @poirow == nil
          ""
        else
          Util::value @poirow.getCell(index)
        end
      end
    end
  
    module Util
      def self.value cell
        if (cell == nil) 
          ""
        else 
          case cell.getCellType 
          when Cell.CELL_TYPE_BLANK
            ""
          when Cell.CELL_TYPE_STRING
            cell.getStringCellValue
          when Cell.CELL_TYPE_NUMERIC
            if DateUtil.isCellDateFormatted(cell) 
              Time.at(cell.getDateCellValue.getTime / 1000)
            else 
              cell.getNumericCellValue
            end
          when Cell.CELL_TYPE_FORMULA
            cell.getNumericCellValue
          when Cell.CELL_TYPE_ERROR
            cell.getErrorCellValue
          when Cell.CELL_TYPE_BOOLEAN 
            cell.getBooleanCellValue
          else 
            cell.to_s
          end
        end
      end  
  
    end
  
    def Excel.open filename, &block
      include_class 'java.io.FileInputStream'
  
      input = FileInputStream.new filename
      poibook = WorkbookFactory.create(input)
  
      if block != nil
        begin
          block.call POILite::Excel::WorkBook.new poibook
        ensure
          input.close
        end
      else
        POILite::Excel::WorkBook.new poibook
      end
    end
  end
end  
