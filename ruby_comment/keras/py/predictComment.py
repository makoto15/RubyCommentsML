

import tensorflow as tf
from gensim.models import Word2Vec
from tensorflow import keras
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
# import matplotlib.pyplot as plt

from gensim.test.utils import common_texts
from gensim.models.doc2vec import Doc2Vec, TaggedDocument

from keras.models import Sequential
from keras.layers import Dense, Activation, LSTM
from keras.optimizers import RMSprop

sys.path.append('..')
sys.path.append('../..')

maxLen=49
vectorSize = 30

context2VecModel = Word2Vec.load("/home/u00545/comments/RubyCommentsML/ruby_comment/models/context2Vec.model")
# comment2VecModel = Doc2Vec.load("/home/u00545/comments/RubyCommentsML/ruby_comment/models/comment2VecUpDown50Tokens.model")
context2SeqModel = keras.models.load_model("/home/u00545/comments/RubyCommentsML/ruby_comment/models/context2SeqUpDown50Tokens.model")

#学習データのファイル群を取得
file = glob.glob("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing/repositories2TokenWithCommentUpDown50Tokens/all.txt")
print(file)

contexts = []
comments = []
f = open(file[0])
lines = f.readlines()
i=0
for line in lines:
    temp_data = line.replace('\n','')
    temp_context = temp_data.split(' ')[0:maxLen]
    temp_comment = " ".join(temp_data.split(' ')[(maxLen+1):])
    morph = nltk.word_tokenize(temp_comment)
    contexts.append(temp_context)
    comments.append(TaggedDocument(morph,[i]))
    i += 1
f.close()
print(len(contexts))

print(contexts[0])
print(contexts[0][0])


print(len(comments))
print(len(contexts))

print(contexts[0])



#全部の分散表現を得る

def distributedRepresentation(AllContexts,AllComments):
    contexts2Vec=[]
    comments2Vec=[]
    seq2Vec = []
    
    #ここでコンテキストの各単語の分散表現を得ている
    for i in range(len(AllContexts)):
        temp_ary = []
        for j in range(len(AllContexts[i])):
            temp_ary.append(np.array(context2VecModel.wv[AllContexts[i][j]]))
        temp_ary = np.array(temp_ary)
        contexts2Vec.append(temp_ary)
    print(len(contexts2Vec))
    
    #ここで各単語の分散表現を用いて文の分散表現を得ている
    for i in range(len(contexts2Vec)):
        print(i)
        seqVec = context2SeqModel.predict(np.array([contexts2Vec[i][:maxLen]]),verbose=2)[0]
        seq2Vec.append(np.array(seqVec))
        
    #ここでコメントの分散表現を得る
    comment2VecModel = Doc2Vec(documents=AllComments, vector_size=vectorSize,min_count=5,window=5,epochs=20,dm=0)
    for i in range(len(seq2Vec)):
        comments2Vec.append(comment2VecModel.docvecs[i])
    
    #ここでpredictionするモデルをする
    
    return seq2Vec, comments2Vec, comment2VecModel
    



print(len(contexts))
print(len(comments))

#80%を学習データに20%をテストデータに

trainNum = int((len(contexts)*8/10))
testNum = len(contexts)-trainNum
testData = contexts[trainNum:]
testDataAns = comments[trainNum:]

    
seq2Vec, comments2Vec, comment2VecModel = distributedRepresentation(contexts[0:trainNum],comments[0:trainNum])


#モデルの作成
predictionModel = Sequential()

#モデルにレイヤーを積み上げていく
predictionModel.add(Dense(128, input_dim=vectorSize))
predictionModel.add(Activation('relu'))
predictionModel.add(Dense(units=vectorSize))
optimizer = RMSprop(learning_rate=0.01)

#損失関数は平均２条誤差を使用
predictionModel.compile(loss='mean_squared_error',optimizer=optimizer)



print(np.array(seq2Vec).shape)
print(np.array(comments2Vec).shape)
epochs = 100

predictionModel.fit(np.array(seq2Vec), np.array(comments2Vec), epochs=100,batch_size=32)



print(predictionModel.history)
print(predictionModel.history.params)


# plt.plot(range(1,epochs+1),predictionModel.history['accuracy'],label="training")
# plt.plot(range(1,epochs+1),predictionModel.history['val_accuracy'],label="validation")
# plt.xlabel('Epochs')
# plt.ylabel('Accuracy')
# plt.legend()
# plt.show()

predictionModel.save("seq2CommentPredictionUpDown50Tokens.model")



print(len(testData))
print(len(testDataAns))
print(np.array(testData).shape)
print(np.array(testDataAns).shape)


seq2VecAns, comments2VecAns, comment2VecModelAns = distributedRepresentation(testData,testDataAns)


print(np.array(seq2VecAns).shape)
print(np.array(comments2VecAns).shape)

predictions = predictionModel.predict(np.array(seq2VecAns),batch_size=128)

print(len(predictions))
print(predictions[0])

print(comment2VecModel.docvecs[0])
comment2VecModel.docvecs.most_similar(0)

print("this is comment2VecModel.docvecs attributes")
print(comment2VecModel.docvecs.__dict__)
prediction_index = 1000

def cosine_norm(model,ary,limit=10):
    temp_ary = []
    i = 0
    for v in model.docvecs.vectors_docs:
        distance = np.dot(v,ary)/(np.linalg.norm(v) * np.linalg.norm(ary))
        temp_ary.append([distance,i])
        i+=1
    temp_ary = sorted(temp_ary)
    temp_ary.reverse()
    return temp_ary[0:limit]

results = cosine_norm(comment2VecModel,predictions[prediction_index],10)


print(results)


results_index = []
for result in results:
    results_index.append(result[1])
print(results_index)

print(seq2VecAns[prediction_index])

print(testDataAns[prediction_index])

print(len(contexts))
print(len(comments))

for index in results_index:
    print()
    print('=======================')
    print(contexts[index])
    print(comments[index])
    print()
