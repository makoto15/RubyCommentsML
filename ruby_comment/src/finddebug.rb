#Rubyのリポジトリのうちコメントがあるものだけを取り出して、txtファイルに出力するコード


require 'ripper'
require 'pp'


root_folder_name = "finddebug"

Dir.glob("../repositories/*") do |i|
  folder_name = i.split('/')[-1]
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
        if (l[1] == :on_tstring_content) || (l[1] == :on_int)
          tokens << l[1]
        elsif l[1] != :on_comment
          p l
          p file
          temp = l[2].to_s.downcase
          tokens << temp.split(' ')
          tokens.flatten!
        end
      end
    end
  end
end
