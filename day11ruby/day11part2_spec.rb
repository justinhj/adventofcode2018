require 'rspec'
require_relative 'day11part2'

describe "Finding the correct grid using summed area table" do

  let(:grid) {
    grid_array_to_hash([
      [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
      [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
      [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
      [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
      [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
      [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1],
      [-1,-1,-1,10,10,10,-1,-1,-1,-1],
      [-1,-1,-1,10,10,10,-1,-1,-1,-1],
      [-1,-1,-1,10,10,10,-1,-1,-1,-1],
      [-1,-1,-1,-1,-1,-1,-1,-1,-1,-1]
                       ])
  }
  
  let(:grid_sat) { summed_area_table(grid, 10) }

  subject { find_best(grid_sat, 10) }

  specify { expect(subject).to eql([4,7,3]) }

end

describe "Create sat from wikipedia entry" do

  let(:provided_grid) {
    grid = {
      [1,1] => 31, [2,1] => 2, [3,1] => 4, [4,1] => 33, [5,1] => 5, [6,1] => 36,
      [1,2] => 12, [2,2] => 26, [3,2] => 9, [4,2] => 10, [5,2] => 29, [6,2] => 25,
      [1,3] => 13, [2,3] => 17, [3,3] => 21, [4,3] => 22, [5,3] => 20, [6,3] => 18,
      [1,4] => 24, [2,4] => 23, [3,4] => 15, [4,4] => 16, [5,4] => 14, [6,4] => 19,
      [1,5] => 30, [2,5] => 8, [3,5] => 28, [4,5] => 27, [5,5] => 11, [6,5] => 7,
      [1,6] => 1, [2,6] => 35, [3,6] => 34, [4,6] => 3, [5,6] => 32, [6,6] => 6 }
    
    grid.default = 0
    grid
  }
  
  let(:provided_sat) {
    grid_array_to_hash([
                         [31,33,37,70,75,111],
                         [43,71,84,127,161,222],
                         [56,101,135,200,254,333],
                         [80,148,197,278,346,444],
                         [110,186,263,371,450,555],
                         [111,222,333,444,555,666]
                       ])
  }

  subject { summed_area_table(provided_grid, 6)  }

  specify { expect(subject).to eql(provided_sat) }
  
end

describe "Sat Is correct with uniform array" do

  let(:grid) {
    grid_array_to_hash([
      [1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1],
      [1,1,1,1,1,1,1,1,1,1]
                       ])
  }
  
  let(:grid_sat) { summed_area_table(grid, 10) }

  subject { find_best(grid_sat, 10) }

  # TODO should be 1,1,10 but is 1,1,8
  
  #  specify { expect(subject).to eql([4,7,3]) }
  specify { draw_sat(grid_sat, 10) }

  specify { pp subject }

end


