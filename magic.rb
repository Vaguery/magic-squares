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

@slipped_3x3_nonsquare_rotated_center =
  {l1: [1,2,3,4], l2: [6,7,8], l3: [10,11,12,13],
   l4: [2,5,6,10], l5: [3,7,11], l6: [4,8,9,12],
   l7: [1,5,7,9,13], l8:[4,7,10]}

@rect_3x4_no_diags =
  {r1: [1,2,3,4], r2: [5,6,7,8], r3: [9,10,11,12],
   c1: [1,5,9], c2: [2,6,10], c3: [3,7,11], c4: [4,8,12]}

@rect_3x4_4x_diags =
  {r1: [1,2,3,4], r2: [5,6,7,8], r3: [9,10,11,12],
   c1: [1,5,9], c2: [2,6,10], c3: [3,7,11], c4: [4,8,12],
   d1: [1,6,11], d2: [2,7,12], d3: [3,6,9], d4: [4,7,10]}

@rect_4x5_4x_diags =
  {r1: [1,2,3,4,5], r2: [6,7,8,9,10], r3: [11,12,13,14,15], r4: [16,17,18,19,20],
   c1: [1,6,11,16], c2: [2,7,12,17], c3: [3,8,13,18], c4: [4,9,14,19], c5: [5,10,15,20],
   d1: [1,7,13,19], d2: [2,8,14,20], d3: [4,8,12,16], d4: [5,9,13,17]}


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


def tweak_direct_assignment(a,scale,prob)
  mutant = {}
  a.each do |k,v|
    mutant[k] = (rand() <= prob) ? v + rand(2*scale) - scale : v
  end
  return mutant
end

def crossover(p1,p2)
  child = {}
  p1.keys.each {|k| child[k] = (rand() < 0.5 ? p1[k] : p2[k])}
  return child
end

def swapN(a,n)
  which = a.keys.sample(n)
  into = which.rotate
  mutant = a.dup
  (0...n).each do |i|
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


def total_error_hash(hypergraph,answer)
  sums = sums(hypergraph,answer)
  c = sums.count
  target_error = sums[:total].to_f/(c-1)
  error_hash = sums.reduce({}) do |errs,(k,v)|
    errs[k] = (k == :total ? 0.0 : (v-target_error).to_f.abs)
    errs
  end
  error_hash[:total] = error_hash.values.reduce(:+)
  return error_hash
end


def rough_lexicase_selection(pop,target_size)
  until pop.length <= target_size
    which_key = pop.keys.first.keys.sample
    worst_score = pop.keys.collect {|k| k[which_key]}.max
    pop = pop.select {|k,v| k[which_key] < worst_score}
  end
  return pop
end



testing = @rect_4x5_4x_diags
population = {}

done = false
max_pop = 300
numeric_range = 3
vertex_count = testing.values.flatten.max
mu = 3.0/vertex_count



100000.times do |i|
  unless done
    (2).times do
      v = random_direct_assignment(vertex_count,vertex_count*numeric_range)
      population[total_error_hash(testing,v)] = v
    end
    population = rough_lexicase_selection(population,max_pop)
    # puts population.inspect
    totals = population.keys.collect {|e| e[:total]}
    min_error = totals.min
    median_error = totals.sort[population.length/2]
    max_error = totals.max
    if min_error == 0.0
      done = true
      winners = population.select {|k,v| k[:total] == 0.0}
      puts "winners:"
      winners.each do |k,v|
        puts pretty_matrix(v)
        puts k.inspect
        puts
      end
    end
    variants = population.collect do |k,v|
      rand() < 0.5 ?
        tweak_direct_assignment(v, v.length, mu) :
        swapN(v,rand(vertex_count/2)+2)
    end
    variants.each do |k|
      k_error = total_error_hash(testing,k)
      population[k_error] = k unless
        (k.values.uniq.count < k.count) #|| (k_error[:total] > median_error)
    end
    puts "#{i},#{min_error},#{median_error},#{max_error},#{population.length},#{population.select {|k,v| k[:total] == min_error}.to_a[0][1].values.join(",")}" if (i%10 == 0)
  end
end
