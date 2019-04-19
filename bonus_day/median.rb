input = [12, 4, 5, 3, 8, 7]

q = []

while n = input.shift do
  q << n
  q.sort!
  if q.length % 2 == 1
    m = q.length / 2
    puts q[m]
  else
    m = q.length / 2
    puts (q[m] + q[m-1])/2.0
  end
end
