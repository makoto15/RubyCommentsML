#Rubyのリポジトリを全部Tokenに変えてtxtファイルに出力するコード

# 変数名はそのまま(型名を事前につける)
# リテラルは型名に変換
# 空白文字や改行は削除
# 各リポジトリででもし3回以下しか出現しなかったら変数名、定数名だったらその型名に変えるか、違ったら"UNK"に変える

require 'ripper'
require 'pp'

root_folder_name = "repositories2Token"
minAppear2UNK = 3
sizeOfContext = 150

if !File.directory?('../repositories_cleansing/')
  Dir.mkdir('../repositories_cleansing/')
end
if !File.directory?("../repositories_cleansing/#{root_folder_name}")
  Dir.mkdir("../repositories_cleansing/#{root_folder_name}")
end



# #すぐ消す
# if !File.directory?('../test_repositories')
#   Dir.mkdir('../test_repositories')
# end
# if !File.directory?("../test_repositories/#{root_folder_name}")
#   Dir.mkdir("../test_repositories/#{root_folder_name}")
# end

#各リポジトリのループ
unkToken = []
Dir.glob("../repositories/*") do |i|
  folder_name = i.split('/')[-1]

  #プロジェクト名と名前が一致するフォルダを作成
  Dir.mkdir("../repositories_cleansing/#{root_folder_name}/#{folder_name}")
  token_appear = {}

  #各ファイルのループ
  Dir.glob("#{i}/**/*.rb") do |file|
  tokens = []
    if File.file?(file)
      #ファイル名をrep変数に格納
      rep = file.split('/')[3..-1].join('_')
      puts file

      contents = File.read(file)
      lex = Ripper.lex(contents)
      lex = lex.select do |l|
        (l[1] != :on_sp) && (l[1] != :on_ignored_nl) && (l[1] != :on_nl)
      end

      lex.each do |l|
        if l[1] == :on_ident || l[1] == :on_const
          temp = l[2].to_s.downcase
          temp = l[1].to_s + "----" + temp.split(' ').join('')
          tokens << temp
          tokens.flatten!
        elsif l[1] == :on_kw
          tokens << l[1].to_s + "----" + l[2].to_s.downcase
        elsif l[1] != :on_comment
          tokens << l[1].to_s.downcase
        end
      end

      tokens.each do |token|
        temp_tok = token
        if token_appear[temp_tok] == nil
          token_appear[temp_tok] = 1
        else
          token_appear[temp_tok] += 1
        end
      end
    end
  end

  Dir.glob("#{i}/**/*.rb") do |file|
  tokens = []
    if File.file?(file)
      contents = File.read(file)
      lex = Ripper.lex(contents)
      lex = lex.select do |l|
        (l[1] != :on_sp) && (l[1] != :on_ignored_nl) && (l[1] != :on_nl)
      end

      lex.each do |l|
        if l[1] == :on_ident || l[1] == :on_const
          temp = l[2].to_s.downcase
          temp = l[1].to_s + "----" + temp.split(' ').join('')
          tokens << temp
          tokens.flatten!
        elsif l[1] == :on_kw
          tokens << l[1].to_s + "----" + l[2].to_s.downcase
        elsif l[1] != :on_comment
          tokens << l[1].to_s.downcase
        end
      end

      tokens.size.times do |n|
        if token_appear[tokens[n]] <= minAppear2UNK
          if tokens[n].include?("----")
            tokens[n] = tokens[n].split('---')[0]
          else
            unkToken << tokens[n] + i
            tokens[n] = "UNK"
          end
        end
      end

      File.open("../repositories_cleansing/#{root_folder_name}/#{folder_name}/all.txt",mode="a"){ |f|
        f.puts tokens.join(" ")
      }
      File.open("../repositories_cleansing/#{root_folder_name}/all.txt",mode="a"){ |f|
        f.puts tokens.join(" ")
      }

      # File.open("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing/#{root_folder_name}/#{folder_name}/all.txt",mode="a"){ |f|
      #   f.puts (["EMP"]*sizeOfContext).join(' ')
      # }
    end
  end
end

File.open("../repositories_cleansing/#{root_folder_name}/all.txt",mode="a"){ |f|
  f.puts (["EMP"]*sizeOfContext).join(' ')
}

p unkToken
