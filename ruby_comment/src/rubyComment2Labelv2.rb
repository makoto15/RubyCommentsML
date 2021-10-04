#Rubyのリポジトリのうちコメントがあるものだけを取り出して、txtファイルに出力するコード
# コメントの取り方は同じ行のものはその直前の行だけを取り出す、
# 最終行にある場合は前のトークンから取り出す
# その他の場合は直下にあるブロックを取り出す。
# 出力するコメントの末尾にはファイル名を記載する。


require 'ripper'
require 'pp'


root_folder_name = "repositories2TokenWithCommentv2"
minAppear2UNK = 3
sizeOfContext = 30

#上のソースコードを考慮し出す、コメントの最後から数えがした時の行数
minLastLine = 2


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
        (l[1] != :on_sp) && (l[1] != :on_nl)
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
        (l[1] != :on_sp) && (l[1] != :on_nl)
      end
      tokensWithComment = []

      # ソースコードの最終行を記録
      lastLine = -1
      if lex.size > 0
        lastLine = lex[-1][0][0]
      end
      index = 0
      comment_token = []

      while index < lex.size
        temp_token = []
        # もしコメントが行の途中からあったとしたら
        if (lex[index][1] == :on_comment) && (index > 0) && (lex[index-1][1] != :on_comment) &&(lex[index][0][0] == lex[index-1][0][0])
          temp_num = index
          #temp_numに行頭のindexを保管させる
          while (temp_num > 0) && (lex[temp_num-1][0][0] == lex[index][0][0]) && (lex[temp_num-1][1] != :on_comment)
            temp_num -= 1
          end

          flag = true
          while flag
            #行頭からコメントまでのソースコードを記録
            if lex[temp_num][1] == :on_ident || lex[temp_num][1] == :on_const
              temp_tok = lex[temp_num][1].to_s + "----" + lex[temp_num][2].to_s.downcase.split(' ').join('')
              if token_appear[temp_tok] <= minAppear2UNK
                temp_token << temp_tok.split('----')[0]
              else
                temp_token << temp_tok
              end
            elsif lex[temp_num][1] == :on_kw
              temp_tok = lex[temp_num][1].to_s + "----" + lex[temp_num][2].to_s.downcase
              if token_appear[temp_tok] <= minAppear2UNK
                temp_token << temp_tok.split('----')[0]
              else
                temp_token << temp_tok
                temp_token.flatten!
              end
            else
              if token_appear[lex[temp_num][1].to_s.downcase] <= minAppear2UNK
                temp_token << "UNK"
              else
                temp_token << lex[temp_num][1].to_s.downcase
              end
            end
            temp_num += 1
            if temp_num >= index
              flag = false
            end
          end

          #temp_tokenのサイズをsizeOfContextに調整する
          if temp_token.size < sizeOfContext
            while temp_token.size < sizeOfContext
              temp_token << "EMP"
            end
          elsif temp_token.size > sizeOfContext
            while temp_token.size > sizeOfContext
              temp_token.pop
            end
          end

          #
          comment_token << lex[index][2].split(' ')
          comment_token.flatten!
          temp_token << comment_token
          temp_token.flatten!
          fileNameAndLine = file + lex[index][0][0].to_s
          temp_token << fileNameAndLine
          comment_token = []
          tokensWithComment << temp_token
          temp_token = []


        elsif (lex[index][1] == :on_comment) && (lastLine != -1) && (lastLine-minLastLine < lex[index][0][0]) && ((index+1) < lex.size) && (lex[index+1][1] != :on_comment)
        #コメントが最後の行からminLastLine行以内にいる時

          #どこから読み出すかを決める
          temp_num = index
          #sizeOfContextになるまで読み込む
          numForSizeOfContext = 0
          #temp_numに行頭のindexを保管させる
          while (temp_num > 0) && (numForSizeOfContext < sizeOfContext)
            if (lex[temp_num-1][1] != :on_comment) && (lex[temp_num-1][1] != :on_ignored_nl)
              numForSizeOfContext += 1
            end
            temp_num -= 1
          end

          flag = true
          while flag
            if (lex[temp_num][1] != :on_ignored_nl)
              if lex[temp_num][1] == :on_ident || lex[temp_num][1] == :on_const
                temp_tok = lex[temp_num][1].to_s + "----" + lex[temp_num][2].to_s.downcase.split(' ').join('')
                if token_appear[temp_tok] <= minAppear2UNK
                  temp_token << temp_tok.split('----')[0]
                else
                  temp_token << temp_tok
                end
              elsif lex[temp_num][1] == :on_kw
                temp_tok = lex[temp_num][1].to_s + "----" + lex[temp_num][2].to_s.downcase
                if token_appear[temp_tok] <= minAppear2UNK
                  temp_token << temp_tok.split('----')[0]
                else
                  temp_token << temp_tok
                  temp_token.flatten!
                end
              elsif lex[temp_num][1] != :on_comment
                if token_appear[lex[temp_num][1].to_s.downcase] <= minAppear2UNK
                  temp_token << "UNK"
                else
                  temp_token << lex[temp_num][1].to_s.downcase
                end
              end
              temp_num += 1
              if temp_num >= index
                flag = false
              end
            else
              temp_num += 1
              if temp_num >= index
                flag = false
              end
            end
          end

          #temp_tokenのサイズをsizeOfContextに調整する
          if temp_token.size < sizeOfContext
            while temp_token.size < sizeOfContext
              temp_token << "EMP"
            end
          elsif temp_token.size > sizeOfContext
            while temp_token.size > sizeOfContext
              temp_token.pop
            end
          end

          comment_token << lex[index][2].split(' ')
          comment_token.flatten!
          temp_token << comment_token
          temp_token.flatten!
          fileNameAndLine = file + lex[index][0][0].to_s
          temp_token << fileNameAndLine
          comment_token = []
          tokensWithComment << temp_token
          temp_token = []

        elsif (lex[index][1] == :on_comment) && ((index+1) < lex.size) && (lex[index+1][1] != :on_comment)
          #もしコメントが複数行で続いていなかったとしたら

          #コメントが始まる行
          startComment = index
          #コメントが前の行にもあるか
          startCommentFlg = true

          while startCommentFlg
            if (startComment > 0) && lex[startComment-1][1] == :on_comment
              startComment -= 1
            else
              startCommentFlg = false
            end
          end

          if (lex[startComment][0][0] == 0) || (lex[startComment][0][0] == 1) ||((lex[startComment][0][0] > 1) && lex[startComment-1][1] == :on_ignored_nl && lex[startComment-1][0][0] != lex[startComment-2][0][0])
            # もし前の行が空行であったとしたら

            #どこから読み出すかを決める
            temp_num = index+1
            flag = true
            while flag
              #行頭からコメントまでのソースコードを記録

              if (temp_num < lex.size)
                if lex[temp_num][1] == :on_ident || lex[temp_num][1] == :on_const
                  temp_tok = lex[temp_num][1].to_s + "----" + lex[temp_num][2].to_s.downcase.split(' ').join('')
                  if token_appear[temp_tok] <= minAppear2UNK
                    temp_token << temp_tok.split('----')[0]
                  else
                    temp_token << temp_tok
                  end
                elsif lex[temp_num][1] == :on_kw
                  temp_tok = lex[temp_num][1].to_s + "----" + lex[temp_num][2].to_s.downcase
                  if token_appear[temp_tok] <= minAppear2UNK
                    temp_token << temp_tok.split('----')[0]
                  else
                    temp_token << temp_tok
                    temp_token.flatten!
                  end
                elsif lex[temp_num][1] != :on_comment
                  if token_appear[lex[temp_num][1].to_s.downcase] <= minAppear2UNK
                    temp_token << "UNK"
                  else
                    temp_token << lex[temp_num][1].to_s.downcase
                  end
                end
                temp_num += 1
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

          elsif (lex[startComment-1][1] != :on_ignored_nl ||(lex[startComment-1][1] == :on_ignored_nl && lex[startComment-1][0][0] == lex[startComment-2][0][0]))
          #もしコメントの前の行が空行でないとしたら

            temp_num = startComment
            #temp_numに前の行の行頭番号を保管する
            while (temp_num > 0) && (lex[temp_num-1][0][0] == lex[startComment-1][0][0])
              temp_num -= 1
            end

            while temp_num < startComment
              #行頭からコメントまでのソースコードを記録
              if lex[temp_num][1] == :on_ident || lex[temp_num][1] == :on_const
                temp_tok = lex[temp_num][1].to_s + "----" + lex[temp_num][2].to_s.downcase.split(' ').join('')
                if token_appear[temp_tok] <= minAppear2UNK
                  temp_token << temp_tok.split('----')[0]
                else
                  temp_token << temp_tok
                end
              elsif lex[temp_num][1] == :on_kw
                temp_tok = lex[temp_num][1].to_s + "----" + lex[temp_num][2].to_s.downcase
                if token_appear[temp_tok] <= minAppear2UNK
                  temp_token << temp_tok.split('----')[0]
                else
                  temp_token << temp_tok
                  temp_token.flatten!
                end
              elsif lex[temp_num][1] != :on_comment
                if token_appear[lex[temp_num][1].to_s.downcase] <= minAppear2UNK
                  temp_token << "UNK"
                else
                  temp_token << lex[temp_num][1].to_s.downcase
                end
              end
              temp_num += 1
            end
            if temp_token.size > sizeOfContext
              while temp_token.size > sizeOfContext
                temp_token.pop
              end
            end

            #どこから読み出すかを決める
            temp_num = index+1
            flag = true
            while flag
              #行頭からコメントまでのソースコードを記録
              if (temp_num < lex.size)
                if lex[temp_num][1] == :on_ident || lex[temp_num][1] == :on_const
                  temp_tok = lex[temp_num][1].to_s + "----" + lex[temp_num][2].to_s.downcase.split(' ').join('')
                  if token_appear[temp_tok] <= minAppear2UNK
                    temp_token << temp_tok.split('----')[0]
                  else
                    temp_token << temp_tok
                  end
                elsif lex[temp_num][1] == :on_kw
                  temp_tok = lex[temp_num][1].to_s + "----" + lex[temp_num][2].to_s.downcase
                  if token_appear[temp_tok] <= minAppear2UNK
                    temp_token << temp_tok.split('----')[0]
                  else
                    temp_token << temp_tok
                    temp_token.flatten!
                  end
                elsif lex[temp_num][1] != :on_comment
                  if token_appear[lex[temp_num][1].to_s.downcase] <= minAppear2UNK
                    temp_token << "UNK"
                  else
                    temp_token << lex[temp_num][1].to_s.downcase
                  end
                end
                temp_num += 1
              else
                if temp_token.size < sizeOfContext
                  while temp_token.size < sizeOfContext
                    temp_token << "EMP"
                  end
                end
              end
              if temp_token.size >= sizeOfContext
                flag = false
              end
            end
            if temp_token.size > sizeOfContext
              while temp_token.size > sizeOfContext
                temp_token.pop
              end
            end
  

          end

          #
          comment_token << lex[index][2].split(' ')
          comment_token.flatten!
          temp_token << comment_token
          temp_token.flatten!
          fileNameAndLine = file + lex[index][0][0].to_s
          temp_token << fileNameAndLine
          comment_token = []
          tokensWithComment << temp_token
          temp_token = []

        elsif (lex[index][1] == :on_comment) && ((index+1) < lex.size) && (lex[index+1][1] == :on_comment)
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
















































#       while index < lex.size
#         temp_token = []
#         # もしコメントが複数行で続いていなかったとしたら
#         if (lex[index][1] == :on_comment) && ((index+1) < lex.size) && (lex[index+1][1] != :on_comment)
#           flag = true
#           count_num = index+1
#           while flag
#             #コメントの後のコードの内コメントが含まれないトークンを記録
#             #もしcount_numがlexのサイズより小さい場合
#             if (count_num < lex.size)
#               if (lex[count_num][1] != :on_comment)
#                 if lex[count_num][1] == :on_ident || lex[count_num][1] == :on_const
#                   temp_tok = lex[count_num][1].to_s + "----" + lex[count_num][2].to_s.downcase.split(' ').join('')
#                   if token_appear[temp_tok] <= minAppear2UNK
#                     temp_token << temp_tok.split('----')[0]
#                   else
#                     temp_token << temp_tok
#                   end
#                 elsif lex[count_num][1] == :on_kw
#                   temp_tok = lex[count_num][1].to_s + "----" + lex[count_num][2].to_s.downcase
#                   if token_appear[temp_tok] <= minAppear2UNK
#                     temp_token << temp_tok.split('----')[0]
#                   else
#                     temp_token << temp_tok
#                     temp_token.flatten!
#                   end
#                 else
#                   if token_appear[lex[count_num][1].to_s.downcase] <= minAppear2UNK
#                     temp_token << "UNK"
#                   else
#                     temp_token << lex[count_num][1].to_s.downcase
#                   end
#                 end
#               end
#               count_num += 1
#             else
#               if temp_token.size < sizeOfContext
#                 while temp_token.size < sizeOfContext
#                   temp_token << "EMP"
#                 end
#               end
#             end
#             if temp_token.size == sizeOfContext
#               flag = false
#             end
#           end
#           comment_token << lex[index][2].split(' ')
#           comment_token.flatten!
#           temp_token << comment_token
#           temp_token.flatten!
#           comment_token = []
#           tokensWithComment << temp_token
#           temp_token = []
#         elsif (lex[index][1] == :on_comment) && ((index+1) < lex.size) && (lex[index+1][1] == :on_comment)
#           p lex[index][2]
#           comment_token << lex[index][2].split(' ')
#           comment_token.flatten!
#         end
#         index += 1
#       end

#       File.open("../repositories_cleansing/#{root_folder_name}/#{folder_name}/#{rep}.txt",mode="a"){ |f|
#         tokensWithComment.each do |file|
#           f.puts file.join(" ")
#         end
#       }
#       File.open("../repositories_cleansing/#{root_folder_name}/all.txt",mode="a"){ |f|
#       tokensWithComment.each do |file|
#         f.puts file.join(" ")
#       end
#       }
#     end
#   end

# end
