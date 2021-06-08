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


file = glob.glob("../../src/repositories2TokenWithComment/all.txt")
print(file)

comments = []
contexts = []
f = open(file[0])
lines = f.readlines()

i=0
for line in lines:
    temp_data = line.replace("\n","")
    temp_context = temp_data.split(' ')[0:20]
    temp_comment = " ".join(temp_data.split(' ')[20:])
    morph = nltk.word_tokenize(temp_comment)
    contexts.append(temp_context)
    comments.append(TaggedDocument(morph,[i]))
    i += 1
f.close()


print(len(comments))
print(len(contexts))

print(contexts[0])
print(comments[0])


model = Doc2Vec(documents=comments, vector_size=15,min_count=5,window=5,epochs=20,dm=0)

print(comments[0])
print(model.docvecs[0])

# 文章IDが0の文章と似た文章とその内積を得ることが出来る。
model.docvecs.most_similar(2)

print(comments[2])
print(comments[39185])
print(comments[39457])


model.save("comment2Vec.model")