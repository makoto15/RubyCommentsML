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

vectorSize = 30

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


model = Word2Vec(sentences=[context], size=vectorSize,window=20,iter=60)
model.save("context2Vec.model")
print(model.__dict__)
print(model.most_similar( positive="if"))
model.wv.index2word
print(model.wv["for"])
