#Rubyのリポジトリを全部Tokenに変えてtxtファイルに出力するコード
#identifierもそのまま出力する。

require 'ripper'
require 'pp'

root_folder_name = "repositories2TokenRawDataWithIdent"
minAppear2UNK = 5
sizeOfContext = 150

if !File.directory?('../repositories_cleansing')
  Dir.mkdir('../repositories_cleansing')
end
if !File.directory?("../repositories_cleansing/#{root_folder_name}")
  Dir.mkdir("../repositories_cleansing/#{root_folder_name}")
end


#各リポジトリのループ
Dir.glob("../repositories/*") do |i|
  folder_name = i.split('/')[-1]

  #プロジェクト名と名前が一致するフォルダを作成
  if !File.directory?("../repositories_cleansing/#{root_folder_name}/#{folder_name}")
    Dir.mkdir("../repositories_cleansing/#{root_folder_name}/#{folder_name}")
  end
  allToken = []
  token_appear = {}

  #各ファイルのループ
  Dir.glob("#{i}/**/*.rb") do |file|
    if File.file?(file)
      #ファイル名をrep変数に格納
      rep = file.split('/')[3..-1].join('_')
      puts file

      contents = File.read(file)
      lex = Ripper.lex(contents)
      lex = lex.select do |l|
        (l[1] != :on_sp) && (l[1] != :on_ignored_nl) && (l[1] != :on_nl)
      end
      tokens = []
      #ここからUNKに置き換えるトークンを計算
      lex.each do |l|
        #コードの中にある適当な文字列
        if (l[1] == :on_tstring_content) || (l[1] == :on_int)
          tokens << l[1]
        elsif l[1] != :on_comment
          temp = l[2].to_s.downcase
          tokens << temp.split(' ')
          tokens.flatten!
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
      p token_appear.keys.size

      #ここまで
    end
  end
  #各ファイルのループ
  Dir.glob("#{i}/**/*.rb") do |file|
    if File.file?(file)
      #ファイル名をrep変数に格納
      rep = file.split('/')[3..-1].join('_')
      puts file

      contents = File.read(file)
      lex = Ripper.lex(contents)
      lex = lex.select do |l|
        (l[1] != :on_sp) && (l[1] != :on_ignored_nl) && (l[1] != :on_nl)
      end
      tokens = []
      lex.each do |l|
        #コードの中にある適当な文字列
        if (l[1] == :on_tstring_content) || (l[1] == :on_int)
          tokens << l[1]
        elsif l[1] != :on_comment
          temp = l[2].to_s.downcase
          tokens << temp.split(' ')
          tokens.flatten!
        end
      end
      tokens.size.times do |i|
        if token_appear[tokens[i]] <= minAppear2UNK
          tokens[i] = "UNK"
        end
      end
      
      File.open("../repositories_cleansing/#{root_folder_name}/#{folder_name}/all.txt",mode="a"){ |f|
        f.puts tokens.join(" ")
      }

      File.open("../repositories_cleansing/#{root_folder_name}/all.txt",mode="a"){ |f|
        f.puts tokens.join(" ")
      }

      File.open("../repositories_cleansing/#{root_folder_name}/#{folder_name}/all.txt",mode="a"){ |f|
        f.puts (["EMP"]*sizeOfContext).join(' ')
      }
    end 
  end
end

File.open("../repositories_cleansing/#{root_folder_name}/all.txt",mode="a"){ |f|
  f.puts (["EMP"]*sizeOfContext).join(' ')
}

