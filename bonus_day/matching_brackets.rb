require 'pry-byebug'

samples = [
  "({})",
  "{[()]}",
  "{[(])}",
  "{{[[(())]]}}",
  "{{[[(())]]}"
]

@close_open = {
  ']' => '[',
  ')' => '(',
  '}' => '{'
}

def is_opening(c)
  @close_open.values.include?(c)
end

def is_closing(c)
  @close_open.keys.include?(c)
end

sample_arrays = samples.map{|s| s.split("")}

def is_balanced(rest)
  stack = []
  loop do
    n = rest.shift
  
    if n.nil? && stack.length == 0 # end of string no remaining closing needed
      return "balanced"
    elsif n.nil? # end of string but we had a remaining match
      return "unbalanced, expected #{stack}"
    elsif is_opening(n) # new opening 
      stack.unshift(n)
    elsif is_closing(n) && @close_open[n] == stack[0] # matched current opening
      stack.shift
    elsif is_closing(n)
      return "unbalanced, received invalid closing #{n} expecting #{stack}"
    end
  end
end

sample_arrays.each do |s|
  printf "#{s} -> #{is_balanced(s)}\n"
end




