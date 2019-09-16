#!/usr/bin/env ruby

cache = {}

$stdin.each_line do |line|
  line.split(" ").each do |a|
    c = cache.fetch(a, 0)
    cache[a] = c + 1
  end
end

p cache.sort_by(&:last)
