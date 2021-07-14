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

from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Activation, LSTM
from tensorflow.keras.optimizers import RMSprop

sys.path.append('..')
sys.path.append('../..')

#単語の分散表現のベクトルの次元数
vecSize = 100
tokenSize = 20

#コンテキストのサイズ
contextSize = 20

model = Word2Vec.load("/home/u00545/comments/RubyCommentsML/ruby_comment/models/context2Vec.model")
file = glob.glob("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing/repositories2TokenWithCommentUpDown20Tokens/all.txt")

print(len(model.wv.vocab))

print(model.wv.vocab['require'].__dict__)

print(model.wv.vocab)


context = []
f = open(file[0])
lines = f.readlines()
for line in lines:
    temp_data = line.replace('\n','')
    temp_data = temp_data.split(' ')[0:contextSize]
    context.append(temp_data)
f.close()
print(len(context))

print(context[1])
print(len(context[0]))
print(context[0][0])

#テキストのベクトル化
#context2Vec tokenSizeトークンに区切った配列を格納している。
context2Vec = []

for i in range(len(context)):
    temp_ary = []
    for j in range(len(context[i])):
        temp_ary.append(np.array(model.wv[context[i][j]]))
    temp_ary = np.array(temp_ary)
    context2Vec.append(temp_ary)
print(context2Vec[0][0])


print(len(context2Vec))

maxLen = tokenSize-1

sentences = []
next_chars = []


for i in range(len(context2Vec)):
    sentences.append(context2Vec[i][0:maxLen])
    next_chars.append(context2Vec[i][-1])

print(len(sentences[0][0]))

print("The length of sentences and next_chars is")
print(len(sentences))
print(len(next_chars))

sentences = np.array(sentences)
next_chars = np.array(next_chars)

# モデルを定義する

models = Sequential()
models.add(LSTM(128,batch_input_shape=(None,maxLen,vecSize)))

models.add(Dense(vecSize))


models.add(Activation('softmax'))

optimizer = RMSprop(learning_rate=0.01)

#損失関数は平均２条誤差を使用

models.compile(loss='mean_squared_error', optimizer=optimizer)

def sample(preds):
    return model.most_similar( [ np.array(preds) ], [], 5)[0][0]

for iteration in range(1,30):
    print()
    print('-'*50)
    print('繰り返し回数: ', iteration)
    models.fit(np.array(sentences),np.array(next_chars),epochs=2)

    start_index = random.randint(0, len(sentences)-1)
    while model.most_similar([sentences[start_index][0] ],[],1)[0][0] == "UNK":
        start_index = random.randint(0, len(sentences))

    generated = ''
    #ベクトル表現から単語を得ている。
    #初期値となる単語を得ている。
    sentence = model.most_similar([sentences[start_index][0] ],[],1)[0][0]
    generated += sentence
    print('-----Seedを生成しました"' + sentence + '"')

    sys.stdout.write(generated)

    x = sentences[start_index]
    for i in range(400):
        input_x = x[-maxLen:]
        input_x = np.array(input_x)
        #形を(1,maxLen,textSize)にするため
        input_x = input_x.reshape(1,input_x.shape[0],input_x.shape[1])
        #次の単語の分散表現を得ている。
        preds = models.predict(input_x,verbose=2)[0]
        
        next_char = sample(preds)
        generated += next_char
        generated += " "
        x = np.append(x, np.array([model.wv[next_char]]),axis=0)
    print()
    print(generated)
    print()
    
    
models.save("../../models/context2SeqUpDown20Tokens.model")

#ここからはmodelをloadしてきて遊んでみる

models = keras.models.load_model("../../models/context2SeqUpDown20Tokens.model")
print(np.array([context2Vec[0][:maxLen]]).shape)

preds = models.predict(np.array([context2Vec[1][:maxLen]]),verbose=2)
print(preds[0])






