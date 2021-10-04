#Rubyのリポジトリのうちコメントがあるものだけを取り出して、txtファイルに出力するコード


require 'ripper'
require 'pp'


root_folder_name = "repositories2TokenWithComment"
minAppear2UNK = 3
sizeOfContext = 30


if !File.directory?("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing")
  Dir.mkdir("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing")
end

if !File.directory?("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing/#{root_folder_name}")
  Dir.mkdir("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing/#{root_folder_name}")
end


Dir.glob("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories/*") do |i|
  folder_name = i.split('/')[-1]

  # プロジェクト名と名前が一致するフォルダを作成
  Dir.mkdir("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing/#{root_folder_name}/#{folder_name}")

  #ここから先はできたtokenのハッシュを使ってファイルに出力
  token_appear = {}

  Dir.glob("#{i}/**/*.rb") do |file|
  tokens = []
    if File.file?(file)

      #ファイル名をrep変数に格納
      rep = file.split('/')[3..-1].join("_")
      p file
      contents = File.read(file)
      lex = Ripper.lex(contents)
      lex = lex.select do |l|
        (l[1] != :on_sp) && (l[1] != :on_ignored_nl) && (l[1] != :on_nl)
      end

      #ここからUNKに置き換えるトークンを計算
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

  #ここまで

  Dir.glob("#{i}/**/*.rb") do |file|
  tokens = []
    if File.file?(file)

      #ファイル名をrep変数に格納
      rep = file.split('/')[3..-1].join("_")
      p file
      contents = File.read(file)
      lex = Ripper.lex(contents)
      lex = lex.select do |l|
        (l[1] != :on_sp) && (l[1] != :on_ignored_nl) && (l[1] != :on_nl)
      end
      tokensWithComment = []

      index = 0
      comment_token = []
      while index < lex.size
        temp_token = []
        # もしコメントが複数行で続いていなかったとしたら
        if (lex[index][1] == :on_comment) && ((index+1) < lex.size) && (lex[index+1][1] != :on_comment)
          flag = true
          count_num = index+1
          while flag
            #コメントの後のコードの内コメントが含まれないトークンを記録
            #もしcount_numがlexのサイズより小さい場合
            if (count_num < lex.size)
              if (lex[count_num][1] != :on_comment)
                if lex[count_num][1] == :on_ident || lex[count_num][1] == :on_const
                  temp_tok = lex[count_num][1].to_s + "----" + lex[count_num][2].to_s.downcase.split(' ').join('')
                  if token_appear[temp_tok] <= minAppear2UNK
                    temp_token << temp_tok.split('----')[0]
                  else
                    temp_token << temp_tok
                  end
                elsif lex[count_num][1] == :on_kw
                  temp_tok = lex[count_num][1].to_s + "----" + lex[count_num][2].to_s.downcase
                  if token_appear[temp_tok] <= minAppear2UNK
                    temp_token << temp_tok.split('----')[0]
                  else
                    temp_token << temp_tok
                    temp_token.flatten!
                  end
                else
                  if token_appear[lex[count_num][1].to_s.downcase] <= minAppear2UNK
                    temp_token << "UNK"
                  else
                    temp_token << lex[count_num][1].to_s.downcase
                  end
                end
              end
              count_num += 1
            else
              if temp_token.size < sizeOfContext
                while temp_token.size < sizeOfContext
                  temp_token << "EMP"
                end
              end
            end
            if temp_token.size == sizeOfContext
              flag = false
            end
          end
          comment_token << lex[index][2].split(' ')
          comment_token.flatten!
          temp_token << comment_token
          temp_token.flatten!
          comment_token = []
          tokensWithComment << temp_token
          temp_token = []
        elsif (lex[index][1] == :on_comment) && ((index+1) < lex.size) && (lex[index+1][1] == :on_comment)
          p lex[index][2]
          comment_token << lex[index][2].split(' ')
          comment_token.flatten!
        end
        index += 1
      end

      File.open("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing/#{root_folder_name}/#{folder_name}/#{rep}.txt",mode="a"){ |f|
        tokensWithComment.each do |file|
          f.puts file.join(" ")
        end
      }
      File.open("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing/#{root_folder_name}/all.txt",mode="a"){ |f|
      tokensWithComment.each do |file|
        f.puts file.join(" ")
      end
      }
    end
  end

end
