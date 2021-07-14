#Rubyのリポジトリのうちコメントがあるものの上下のトークンだけを取り出して、txtファイルに出力するコード


require 'ripper'
require 'pp'


root_folder_name = "repositories2TokenWithCommentUpDownRawData50Tokens"
minAppear2UNK = 5
sizeOfContext = 50

if !File.directory?('../repositories_cleansing')
  Dir.mkdir('../repositories_cleansing')
end

if !File.directory?("../repositories_cleansing/#{root_folder_name}")
  Dir.mkdir("../repositories_cleansing/#{root_folder_name}")
end

Dir.glob("../repositories/*") do |i|
  folder_name = i.split('/')[-1]

  # プロジェクト名と名前が一致するフォルダを作成
  if !File.directory?("../repositories_cleansing/#{root_folder_name}/#{folder_name}")
    Dir.mkdir("../repositories_cleansing/#{root_folder_name}/#{folder_name}")
  end

  token_appear = {}

    #minAppear2UNKの作成
    Dir.glob("#{i}/**/*.rb") do |file|
    if File.file?(file)
      contents = File.read(file)
      lex = Ripper.lex(contents)
      lex = lex.select do |l|
        (l[1] != :on_sp) && (l[1] != :on_ignored_nl) && (l[1] != :on_nl)
      end
      tokens = []

      #ここからUNKに置き換えるトークンを計算
      lex.each do |l|
        #コードの中にある適当な文字列
        if (l[1] == :on_tstring_content) || (l[1] == :on_int) || (l[1] == :on_ident)
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

  p "done making token_appear"

  #ここから先は出てきたtokenのハッシュを使ってファイルに出力

  Dir.glob("#{i}/**/*.rb") do |file|
    if File.file?(file)
  

      #ファイル名をrep変数に格納
      rep = file.split('/')[3..-1].join("_")
      p file
      contents = File.read(file)
      lex = Ripper.lex(contents)
      lex = lex.select do |l|
        #スペース,改行を除いてる
        (l[1] != :on_sp) && (l[1] != :on_ignored_nl) && (l[1] != :on_nl)
      end
      tokensWithComment = []

      index = 0
      comment_token = []
      stack = []

      while index < lex.size
        temp_token = []
        #ここからはコメントの上の部分にあるトークンをtemp_tokenに格納する
        # もしコメントが複数行で続いていなかったとしたら
        if (lex[index][1] == :on_comment) && ((index+1) < lex.size) && (lex[index+1][1] != :on_comment)
          #もしコメントの直前にTokenがなかったとしたら
          if stack.size == 0
            sizeOfContext.times do
              temp_token << "EMP" 
            end
          #もしStackの中にあるトークンの数がsizeOfContextの数値よりも少なかったら
          elsif stack.size < sizeOfContext
            numOfEmp = sizeOfContext - stack.size
            numOfEmp.times do 
              temp_token << "EMP"
            end
            stack.size.times do |i|
              if (stack[i][1] != :on_tstring_content) && (stack[i][1] != :on_int) && (stack[i][1] != :on_ident)
                temp_ary = stack[i][2].to_s.downcase.split(' ')
                temp_ary.each do |temp|
                  if token_appear[temp] <= minAppear2UNK
                    temp_token << "UNK"
                  else
                    temp_token << temp
                  end
                end
              else
                if token_appear[stack[i][1]] <= minAppear2UNK
                  temp_token << "UNK"
                else
                  temp_token << stack[i][1]
                end
              end
            end
          else
            temp_stack = stack[-sizeOfContext..-1]
            temp_stack.size.times do |i|
              if (temp_stack[i][1] != :on_tstring_content) && (temp_stack[i][1] != :on_int) && (temp_stack[i][1] != :on_ident)
                temp_ary = temp_stack[i][2].to_s.downcase.split(' ')
                temp_ary.each do |temp|
                  if token_appear[temp] <= minAppear2UNK
                    temp_token << "UNK"
                  else
                    temp_token << temp
                  end
                end
              else
                if token_appear[temp_stack[i][1]] <= minAppear2UNK
                  temp_token << "UNK"
                else
                  temp_token << temp_stack[i][1]
                end
              end
            end
          end


          #次はコメントの後のトークンをtemp_tokenに格納していく。
          flag = true
          count_num = index+1
          while flag
            #コメントの後のコードの内コメントが含まれないトークンを記録
            #もしcount_numがlexのサイズより小さい場合かつtemp_tokenのサイズがsizeOfContextよりも小さい場合
            if (count_num < lex.size) && (temp_token.size < 2*sizeOfContext)
              if (lex[count_num][1] != :on_comment) && (lex[count_num][1] != :on_sp) && (lex[count_num][1] != :on_ignored_nl) && (lex[count_num][1] != :on_nl)
                if (lex[count_num][1] != :on_tstring_content) && (lex[count_num][1] != :on_int) && (lex[count_num][1] != :on_ident)
                  temp_ary = lex[count_num][2].to_s.downcase.split(' ')
                  temp_ary.each do |temp|
                    if token_appear[temp] <= minAppear2UNK
                      temp_token << "UNK"
                    else
                      temp_token << temp
                    end
                  end
                else
                  if token_appear[lex[count_num][1]] <= minAppear2UNK
                    temp_token << "UNK"
                  else
                    temp_token << lex[count_num][1]
                  end
                end
              end
              count_num += 1
            else
              if temp_token.size < 2*sizeOfContext
                while temp_token.size < 2*sizeOfContext
                  temp_token << "EMP"
                end
              elsif temp_token.size > 2*sizeOfContext
                while temp_token.size > 2*sizeOfContext
                  temp_token.pop
                end
              end
            end
            if temp_token.size == 2*sizeOfContext
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
        elsif (lex[index][1] != :on_comment) && (lex[index][1] != :on_sp) && (lex[index][1] != :on_ignored_nl) && (lex[index][1] != :on_nl)
          stack << lex[index]
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
