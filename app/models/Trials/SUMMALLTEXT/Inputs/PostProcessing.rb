require 'csv'

def euclidean_distance(a,b,start,finish)
  a1 = a[start,finish]
  b1 = b[start,finish]
  
  sum = 0
  a1.length.times do |i|
    diff = a1[i].to_i - b1[i].to_i
    sum += diff**2
  end
  
  return Math.sqrt(sum)
end

def main_function()
  all_rows = Array.new
  CSV.foreach("BarackObama_PostWordVector1.csv",{:quote_char => '"'}) do |row|
    all_rows << row#[0,286]
  end
  all_rows.delete_at(0)

  all_rows.length.times do |i|
    score = 0
    for b in all_rows
      score += euclidean_distance(all_rows[i],b,2,286)
    end
    #puts "#{i} #{score} #{all_rows[i].length}"
    all_rows[i] << score
  end

  all_rows.sort!{|a,b| a[287] <=> b[287]}
  summary_list = Array.new
  summary_list << all_rows[0]
  all_rows.delete_at(0)


  count = 0
  while count <  9
    max = 0 
    candidate = nil
    for r1 in all_rows
      score = 0
      for s1 in summary_list
        score += euclidean_distance(r1,s1,2,286)
      end
      if score > max
        max = score
        candidate = r1
      end
    end
    summary_list << candidate
    all_rows.delete(candidate)
    count += 1
  end

  for s1 in summary_list
    puts "#{s1[1]} #{s1[287]}"
  end

end
main_function()
