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

from keras.models import Sequential
from keras.layers import Dense, Activation, LSTM
from keras.optimizers import RMSprop

sys.path.append('..')
sys.path.append('../..')

#単語の分散表現のベクトルの次元数
vecSize = 15

model = Word2Vec.load("context2Vec.model")

#学習データのファイル群を取得
file = glob.glob("../../src/repositories2TokenWithComment/all.txt")
print(file)

context = []
f = open(file[0])
lines = f.readlines()
for line in lines:
    temp_data = line.replace('\n','')
    temp_data = temp_data.split(' ')[0:20]
    context.append(temp_data)
f.close()
print(len(context))

print(context[0])
print(context[0][0])


#テキストのベクトル化
#context2Vec 20トークンに区切った配列を格納している。
context2Vec = []

for i in range(len(context)):
    temp_ary = []
    for j in range(len(context[i])):
        temp_ary.append(np.array(model.wv[context[i][j]]))
    temp_ary = np.array(temp_ary)
    context2Vec.append(temp_ary)
print(context2Vec[0][0])

print(len(context2Vec))

maxLen = 19

sentences = []
next_chars = []

for i in range(len(context2Vec)):
    sentences.append(context2Vec[i][0:maxLen])
    next_chars.append(context2Vec[i][-1])


print(len(sentences[0][0]))

# モデルを定義する

models = Sequential()
models.add(LSTM(128,input_shape=(maxLen,vecSize)))

models.add(Dense(vecSize))
models.add(Activation('softmax'))
optimizer = RMSprop(lr=0.01)

#損失関数は平均２条誤差を使用

models.compile(loss='mean_squared_error', optimizer=optimizer)

def sample(preds):
    return model.most_similar( [ np.array(preds) ], [], 5)[0][0]


for iteration in range(1,30):
    print()
    print('-'*50)
    print('繰り返し回数: ', iteration)
    models.fit([sentences],[next_chars],batch_size=128,epochs=2)

    start_index = random.randint(0, len(context)-maxLen-1)

    generated = ''
    sentence = model.most_similar([sentences[start_index][0] ],[],1)[0][0]
    generated += sentence
    print('-----Seedを生成しました"' + sentence + '"')

    sys.stdout.write(generated)

    x = sentences[start_index]
    print(x)
    for i in range(400):
        input_x = x[-maxLen:]
        input_x = np.array(input_x)
        input_x = np.array([input_x])
        preds = models.predict([input_x],verbose=2)[0]
        next_char = sample(preds)
        generated += next_char
        generated += " "
        sentence = sentence[1:] + next_char
        x = np.append(x, np.array([model.wv[next_char]]),axis=0)

        sys.stdout.write(next_char)
        sys.stdout.write(" ")
        sys.stdout.flush()
    print()
    

models.save("context2Seq.model")

#ここからはmodelをloadしてきて遊んでみる
models = keras.models.load_model("context2Seq.model")
print(np.array([context2Vec[0][:19]]).shape)
preds = models.predict(np.array([context2Vec[1][:19]]),verbose=2)
preds[0]