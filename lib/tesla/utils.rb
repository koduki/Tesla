module Tesla
  module Utils
    def self.concat cells
      cells.reduce([]) do |r, x|
        if x[0] == ""
          r.last[1] <<  x[1..-1]
          r
        else
          r << [x[0], [x[1..-1]]]
        end
      end
    end
    
  end
end
