#リポジトリにある総行数とそれに対するコメントの割合を出力するもの


require 'ripper'
require 'pp'
allFile = 0
goodFile = 0

Dir.glob("../repositories_ssh/*") do |i|
  allFile += 1
  loc = 0
  cl = 0
  sloc = 0
  Dir.glob("#{i}/**/*.rb") do |file|
    if File.file?(file)

      p file
      contents = File.read(file)
      lex = Ripper.lex(contents)
      n = 1
      lex.each do |l|
        if l[0][0] == n
          n += 1
          if l[1] == :on_comment
            cl += 1
          else
            loc += 1
            sloc += 1
          end
        end
      end
    end
  end

  puts "ファイル名"
  puts i
  puts "割合"
  puts (cl/loc.to_f)
  if (cl/loc.to_f) <= 0.126
    goodFile += 1
  end
end

puts "全リポジトリの内コメントの割合が12.6%以下だったものは"
puts allFile
puts goodFile