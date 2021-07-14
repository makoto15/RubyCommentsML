#Rubyのリポジトリのうちコメントがあるものだけを取り出して、txtファイルに出力するコード


require 'ripper'
require 'pp'


root_folder_name = "repositories2TokenWithCommentDownOnly20Tokens"
minAppear2UNK = 3
sizeOfContext = 20


if !File.directory?("../repositories_cleansing/")
  Dir.mkdir("../repositories_cleansing")
end

if !File.directory?("../repositories_cleansing/#{root_folder_name}")
  Dir.mkdir("../repositories_cleansing/#{root_folder_name}")
end


Dir.glob("../repositories/*") do |i|
  folder_name = i.split('/')[-1]

  # プロジェクト名と名前が一致するフォルダを作成
  Dir.mkdir("../repositories_cleansing/#{root_folder_name}/#{folder_name}")

  #ここから先はできたtokenのハッシュを使ってファイルに出力

  Dir.glob("#{i}/**/*.rb") do |file|
    if File.file?(file)
  
      token_appear = {}

      #ファイル名をrep変数に格納
      rep = file.split('/')[3..-1].join("_")
      p file
      contents = File.read(file)
      lex = Ripper.lex(contents)
      lex = lex.select do |l|
        (l[1] != :on_sp) && (l[1] != :on_ignored_nl) && (l[1] != :on_nl)
      end
      tokens = []
      tokensWithComment = []

      #ここからUNKに置き換えるトークンを計算
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

      #ここまで


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
              if (lex[count_num][1] != :on_comment) && (lex[count_num][1] != :on_sp) && (lex[count_num][1] != :on_ignored_nl) && (lex[count_num][1] != :on_nl)
                if lex[count_num][1] == :on_ident || lex[count_num][1] == :on_const
                  temp_ary = lex[count_num][2].to_s.downcase.split(' ')
                  temp_ary.each do |temp|
                    if token_appear[temp] <= minAppear2UNK
                      temp_token << "UNK"
                    else
                      temp_token << temp
                    end
                  end
                elsif lex[count_num][1] == :on_kw
                  if token_appear[lex[count_num][2].to_s.downcase] <= minAppear2UNK
                    temp_token << "UNK"
                  else
                    temp_token << lex[count_num][2].to_s.downcase.split(' ')
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

      File.open("../repositories_cleansing/#{root_folder_name}/#{folder_name}/#{rep}.txt",mode="a"){ |f|
        tokensWithComment.each do |file|
          f.puts file.join(" ")
        end
      }
      File.open("../repositories_cleansing/#{root_folder_name}/all.txt",mode="a"){ |f|
      tokensWithComment.each do |file|
        f.puts file.join(" ")
      end
      }
    end
  end

end
