# コメント文の分散表現をDoc2Vecを用いて作る。(モデルは保存しない)
# 副生産物としてコンテキストの分散表現を得る。

from gensim.models import Word2Vec
from tensorflow import keras
import tensorflow as tf
from keras.models import load_model
import time
import glob
import os
import os.path
import random
import sys
import numpy as np
import nltk
nltk.download('punkt')

from gensim.test.utils import common_texts
from gensim.models.doc2vec import Doc2Vec, TaggedDocument

from keras.models import Sequential
from keras.layers import Dense, Activation, LSTM
from keras.optimizers import RMSprop

sys.path.append('..')
sys.path.append('../..')


file = glob.glob("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing/repositories2TokenWithCommentUpDown20Tokens/all.txt")
print(file)


#トークンのサイズ
tokenSize=20

#コメントのベクトルのサイズ
commentVecSize=100

# コンテキストのベクトルサイズ
contextVecSize = 100

comments = []
contexts = []
f = open(file[0])
lines = f.readlines()

i=0
for line in lines:
    temp_data = line.replace("\n","")
    temp_context = " ".join(temp_data.split(' ')[0:tokenSize])
    temp_comment = " ".join(temp_data.split(' ')[tokenSize:])
    morphComment = nltk.word_tokenize(temp_comment)
    morphContext = nltk.word_tokenize(temp_context)
    contexts.append(TaggedDocument(morphContext,[i]))
    comments.append(TaggedDocument(morphComment,[i]))
    i += 1
f.close()

print(len(comments))
print(len(contexts))

print(contexts[0])
print()
print(comments[0])

# commentModel = Doc2Vec(documents=comments, vector_size=commentVecSize,min_count=3,window=5,epochs=20,dm=0)

contextModel = Doc2Vec(documents=contexts, vector_size=contextVecSize,min_count=3,window=5,epochs=20,dm=0)

# print(comments[0])
# print(commentModel.docvecs[0])

# 文章IDが0の文章と似た文章とその内積を得ることが出来る。
# commentModel.docvecs.most_similar(0)

# print(comments[48893])
# print(comments[6831])
# print(comments[47295])

# # 文章IDが3の文章と似た文章とその内積を得ることが出来る。
# print(comments[3])
# commentModel.docvecs.most_similar(3)

# print(comments[21156])
# print(comments[46428])
# print(comments[8996])
# commentModel.wv.most_similar(positive=['if', 'while'], negative=['for'])

print(contexts[0])
print(contextModel.docvecs[0])

# 文章IDが0の文章と似た文章とその内積を得ることが出来る。
contextModel.docvecs.most_similar(0)

# print(contexts[6584])
# print(contexts[10656])
# print(contexts[45548])

# 文章IDが3の文章と似た文章とその内積を得ることが出来る。
print(contexts[3])
contextModel.docvecs.most_similar(3)

# print(contexts[9055])
# print(contexts[9054])
# print(contexts[11303])

contextModel.save("context2VecUsingDoc2VecUpDown20Tokens100dim.model")

# commentModel.save("comment2VecDoc2Vec.model")

contextModel.wv.most_similar(positive=['if', 'while'], negative=['for'])