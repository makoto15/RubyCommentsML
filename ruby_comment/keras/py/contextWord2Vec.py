from gensim.models import Word2Vec
from tensorflow import keras
import time
import glob
import os
import os.path
import random
import sys
import numpy as np
sys.path.append('..')
sys.path.append('../..')

#学習データのファイル群を取得
file = glob.glob("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing/repositories2Token/all.txt")
print(file)

#単語の分散表現のベクトルの次元数
vecSize = 700
minCount = 3
windowSize = 20

context = []
f = open(file[0])
lines = f.readlines()
for line in lines:
    temp_data = line.replace('\n','')
    temp_data = line.split(' ')
    for data in temp_data:
        context.append(data)
f.close()
print(len(context))

print(context[0:10])

#文字の数を出力
chars = sorted(list(set(context)))
print(len(chars))
print(context[0:1000])


model = Word2Vec(sentences=[context], size=vecSize,window=20,iter=60, min_count=minCount)
model.save("/home/u00545/comments/RubyCommentsML/ruby_comment/models/context2Vec700dim.model")
print(model.__dict__)
print("list of words detected")
print(model.wv.index2word)

print("number of words")
print(len(model.wv.index2word))

print("most similar word for if")
print(model.most_similar( positive="if"))
print()
print("most similar word for else")
print(model.most_similar( positive="else"))
print()
print("most similar word for while")
print(model.most_similar( positive="while"))
print()
print("most similar word for def")
print(model.most_similar( positive="end"))
print(model.wv["for"])

print("vector of  if")
print(model.wv["if"])
print()
print("vector of  else")
print(model.wv["else"])
print()
print("vector of  while")
print(model.wv["while"])
print()
print("vector of  end")
print(model.wv["end"])
