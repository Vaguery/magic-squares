def basic_square(edge_size)
  core = (1..edge_size*edge_size).each_slice(edge_size).to_a
  cols = core.transpose
  result = {}
  core.each_with_index do |row,idx|
    result[("r#{idx+1}").intern] = row
  end
  cols.each_with_index do |col,idx|
    result[("c#{idx+1}").intern] = col
  end
  result[:d1] = core.collect.with_index {|c,i| c[i]}
  result[:d2] = core.collect.with_index {|c,i| c[edge_size-i-1]}
  return result
end

def pandiagonal_square(edge_size)
  core = (1..edge_size*edge_size).each_slice(edge_size).to_a
  result = basic_square(edge_size)
  # replace and add new diagonals
  (0...edge_size).each do |i|
    result["d#{i+1}".intern] =
      (0...edge_size).collect {|r| core[r][(r+i) - edge_size]}
  end
  (0...edge_size).each do |i|
    result["d#{edge_size+i+1}".intern] =
      (0...edge_size).collect {|r| core[r][(edge_size - (r+i) - 1)]}
  end
  return result
end

def pretty_matrix(assignment)
  rows = assignment.values.each_slice(Math.sqrt(assignment.length)).to_a
  width = rows.flatten.max.to_s.size+3
  rows.map { |a| a.map { |i| i.to_s.rjust(width) }.join }
end


@basic_3x3_square = basic_square(3)

@pandiagonal_3x3_square = pandiagonal_square(3)


@basic_4x4_square = basic_square(4)

@pandiagonal_4x4_square =
  {r1: [1,2,3,4], r2: [5,6,7,8], r3: [9,10,11,12], r4: [13,14,15,16],
   c1: [1,5,9,13], c2: [2,6,10,14], c3: [3,7,11,15], c4: [4,8,12,16],
   d1: [1,6,11,16], d2: [2,7,12,13], d3: [3,8,9,14], d4: [4,6,11,15],
   d5: [4,7,10,13], d6: [3,6,9,16], d7: [2,5,12,15], d8: [1,8,11,14]}

@slipped_3x3_nonsquare =
  {l1: [1,2,3], l2: [4,5,6], l3: [11,7,8,9],
   l4: [1,4,10,11,12,13], l5: [12,2,5,8], l6: [13,3,6,9],
   l7: [1,5,9], l8: [10,7,5,3]}


def random_keys(size)
  h = {}
  (0...size).each do |i|
    h[i+1] = rand()
  end
  return h
end


def assignment(genome)
  c = genome.length
  sorted = genome.sort_by {|k,v| v}
  ordering = sorted.collect {|pr| pr[0]}
  h = {}
  ordering.each_with_index do |ord,idx|
    h[idx+1] = ord
  end
  return h
end

def random_direct_assignment(size,range)
  h = {}
  (0...size).each do |i|
    h[i+1] = rand(2*range)-range
  end
  return h
end

def mutate(keys, prob)
  mutant = {}
  keys.each do |k,v|
    mutant[k] = (rand() <= prob ? rand() : v)
  end
  return mutant
end

def tweak_direct_assignment(a,prob)
  mutant = {}
  a.each do |k,v|
    mutant[k] = (rand() <= prob) ? v + rand(3) - 1 : v
  end
  return mutant
end

def crossover(p1,p2)
  child = {}
  p1.keys.each {|k| child[k] = (rand() < 0.5 ? p1[k] : p2[k])}
  return child
end

def swap3(a)
  which = a.keys.sample(3)
  into = which.rotate
  mutant = a.dup
  (0...3).each do |i|
    mutant[into[i]] = a[which[i]]
  end
  return mutant
end


def sums(hypergraph,assignment)
  allsums = {}
  hypergraph.each do |line,items|
    allsums[line]=items.reduce(0) {|sum,i| sum + assignment[i]}
  end
  allsums[:total] = allsums.values.reduce(:+)
  return allsums
end


def products(hypergraph,assignment)
  allproducts = {}
  hypergraph.each do |line,items|
    allproducts[line]=items.reduce(1) {|prod,i| prod * assignment[i]}
  end
  allproducts[:total] = allproducts.values.reduce(:+)
  return allproducts
end


def total_sum_error(sums)
  c = sums.count
  target = sums[:total].to_f/(c-1)
  sums.reduce(0) {|tot,(k,v)| k == :total ? tot : (tot + (v-target).abs) }
end

def total_product_error(products)
  c = products.count
  target = products[:total].to_f/(c-1)
  products.reduce(0) {|tot,(k,v)| k == :total ? tot : (tot + (v-target).abs) }
end



testing = pandiagonal_square(9)
population = {}

done = false
mu = 0.1
max_pop = 500
numeric_range = 5
vertex_count = testing.values.flatten.max

20000.times do |i|
  unless done
    population = (population.to_a.sort_by {|kv| kv[1]})[0,max_pop].to_h
    (max_pop).times do
      k = random_direct_assignment(vertex_count,vertex_count*numeric_range)
      population[k] = total_sum_error(sums(testing,k))
    end
    # puts population.inspect
    min_error = population.values.min
    median_error = population.values.sort[population.length/2]
    max_error = population.values.max
    if min_error == 0.0
      done = true
      winners = population.select {|k,v| v == 0.0}
      puts "winners:"
      winners.each do |k,v|
        puts pretty_matrix(k)
        puts
      end
    end
    variants = (0..max_pop).collect do
      p1 = population.keys.sample(1)
      rand() < 0.5 ?
        tweak_direct_assignment(p1[0],mu) :
        swap3(p1[0])
    end
    variants.each do |k|
      k_error = total_sum_error(sums(testing,k))
      population[k] = k_error unless (k.values.uniq.count < k.count) || (k_error > median_error)
    end
    puts "#{i},#{min_error},#{median_error},#{max_error},#{population.length}"
  end
end
