#Rubyのリポジトリを全部Tokenに変えてtxtファイルに出力するコード

require 'ripper'
require 'pp'

root_folder_name = "repositories2TokenDownOnly50Tokens"
minAppear2UNK = 5
sizeOfContext = 50

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
  Dir.mkdir("../repositories_cleansing/#{root_folder_name}/#{folder_name}")

  #各ファイルのループ
  Dir.glob("#{i}/**/*.rb") do |file|
    if File.file?(file)
      token_appear = {}
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
        if l[1] == :on_ident || l[1] == :on_const
          temp = l[2].to_s.downcase
          tokens << temp.split(' ')
          tokens.flatten!
        elsif l[1] == :on_kw
          tokens << l[2].to_s.downcase
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
