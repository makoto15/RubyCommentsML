import pickle
import nltk
from nltk import bleu_score
import unittest
import numpy as np
import math
from collections import Counter
from tensorflow.keras.models import Model
from tensorflow.keras.layers import Input, LSTM, Dense
 
import scipy
import numpy as np

import tensorflow as tf
from tensorflow import keras
import gensim

from gensim.models import Word2Vec
import time
import glob
import os
import os.path
import random
import sys
import numpy as np
sys.path.append('..')
sys.path.append('../..')

print('scipy version :', scipy.__version__)
print('numpy version :', np.__version__)
print('tensorflow version : ', tf.__version__)
print('keras version : ', keras.__version__)
print('gensim version : ', gensim.__version__)

nltk.download('punkt')
nltk.download('averaged_perceptron_tagger')

codeID = []
commentID = []
vectorID = []
numberOfTestData = 12
results = {}

#　テストデータとして扱うリポジトリの配列番号
testRepositoryNum = 0

# 各ソースコードのトークン数
lenOfToken = 30
# トークンのベクトル化の次元数
vecSize = 100


with open('/home/u00545/comments/RubyCommentsML/ruby_comment/pickle/code/30dim/codeIDPracticalIdentKubetu.binaryfile', 'rb') as web:
    codeID = pickle.load(web)

with open('/home/u00545/comments/RubyCommentsML/ruby_comment/pickle/code/30dim/commentIDPracticalIdentKubetu.binaryfile', 'rb') as web:
    commentID = pickle.load(web)

with open('/home/u00545/comments/RubyCommentsML/ruby_comment/pickle/code/30dim/vectorIDPracticalIdentKubetu.binaryfile', 'rb') as web:
    vectorID = pickle.load(web)


# Word2Vecのロード
context2VecModel = Word2Vec.load("/home/u00545/comments/RubyCommentsML/ruby_comment/models/code/30dim/context2Vec100dimPractical_IdentKubetu.model")

# encoderのロード
token2EncoderModel = tf.keras.models.load_model("/home/u00545/comments/RubyCommentsML/ruby_comment/models/code/30dim/seq2Encoder30dimPractical_IdentKubetu.model")


    
print(type(codeID))
print(type(commentID))
print(type(vectorID))

print(codeID[1])
print(commentID[1])
print(vectorID[1])


#学習データのファイル群を取得
file = glob.glob("/home/u00545/comments/RubyCommentsML/ruby_comment/repositories_cleansing/repositories2TokenWithCommentDefSyntaxPractical/test/*")

print(file)

#全ソースコードを順に配列に格納したもの
allContexts = []
#全コメントを順に配列に格納したもの
allComments = []

fileSelected =  glob.glob(file[testRepositoryNum] + "/all.txt")

f = open(fileSelected[0])
lines = f.readlines()
random.shuffle(lines)
random.shuffle(lines)
for line in lines:
    if '# frozen_string_literal: true' in line:
        a = []
    else:
        temp_data = line.replace('\n','')
        temp_data = temp_data.split(' ')
        allContexts.append(temp_data[0:lenOfToken])
        allComments.append(temp_data[lenOfToken:])
f.close()

if len(allComments) < numberOfTestData:
    numberOfTestData = len(allComments)

# IdentSameの時はコメント外す

#for context in range(len(allContexts)):
#    for word in range(len(allContexts[context])):
#        if "on_ident" in allContexts[context][word]:
#            allContexts[context][word] = "on_ident"
#        elif "on_const" in allContexts[context][word]:
#            allContexts[context][word] = "on_const"
    
# ここまで

# IdentKubetuの時はコメント外す

for context in range(len(allContexts)):
    for word in range(len(allContexts[context])):
        if "on_ident" in allContexts[context][word]:
            if allContexts[context][word] not in context2VecModel.wv: 
                allContexts[context][word] = "on_ident"
        elif "on_const" in allContexts[context][word]:
            if allContexts[context][word] not in context2VecModel.wv: 
                allContexts[context][word] = "on_const"
    
# ここまで

#データ全部使用
num_samples = len(allContexts)  # Number of samples to train on.
print(num_samples)

# Vectorize the data.
input_texts = []
target_texts = []



for line in allContexts[: num_samples]:
    target_text = line.copy()
    # We use "tab" as the "start sequence" character
    # for the targets, and "\n" as "end sequence" character.
    target_text.append('\n')
    target_text.insert(0,'\t')
    input_texts.append(line)
    target_texts.append(target_text)
    
#エンコーダ、デコーダのベクトルの次元数(word2Vecの次元数と一致)
num_encoder_tokens = vecSize
num_decoder_tokens = vecSize
max_encoder_seq_length = max([len(txt) for txt in input_texts])
max_decoder_seq_length = max([len(txt) for txt in target_texts])
 
print('Number of samples:', len(input_texts))
print('Number of unique input tokens:', num_encoder_tokens)
print('Number of unique output tokens:', num_decoder_tokens)
print('Max sequence length for inputs:', max_encoder_seq_length)
print('Max sequence length for outputs:', max_decoder_seq_length)
print()
print(input_texts[1])
print(target_texts[1])

testDatasRaw = allContexts
testCommentsRaw = allComments
testDatasEncode = np.zeros((len(input_texts), max_encoder_seq_length, num_encoder_tokens))

# for i, (input_text) in enumerate(allContexts[num_samples:-1]):
for i, (input_text) in enumerate(testDatasRaw):
    for t, char in enumerate(input_text):
        testDatasEncode[i, t] = context2VecModel.wv[char]


testCodes = []
testComments = []
predictCodes = []
predictComments = []
mostSimilarCodes = []
mostSimilarComments = []
RepositoryMatch4Predict = []
RepositoryMatch4MostSimilar = []
mostSimilarCommentsIndex = []


# Define sampling models
# encoder_model = Model(encoder_inputs, encoder_states)

 
def sequence_states(input_seq):
    # Encode the input as state vectors.
    states_value = token2EncoderModel.predict(input_seq)
    # Update states
    # states_value = [h, c]
    return states_value

weights_1 = (1./1.,)
weights_2 = (1./2., 1./2.)
weights_3 = (1./3., 1./3., 1./3.)
weights_4 = (1./4., 1./4., 1./4., 1./4.)

weights = [weights_1,weights_2,weights_3,weights_4]

print("=======================================================")
print("RawでBLEUScoreを測る。")

codeIDCopyPre = codeID.copy()
vectorIDCopyPre = vectorID.copy()
commentIDCopyPre = commentID.copy()
indexNum = len(codeID)

for commentLine in range(len(allComments)):
    
    codeIDCopyPre[indexNum] = testDatasRaw[commentLine]
    commentIDCopyPre[indexNum] = testCommentsRaw[commentLine]
    vectorTest_h,c = sequence_states(testDatasEncode[commentLine:commentLine+1]) 
    vectorIDCopyPre[indexNum] = vectorTest_h
    indexNum += 1

indexNum = len(codeID)

for i in range(numberOfTestData):

    deleteIndexNum = i + indexNum
    codeIDCopy = {k: v for k, v in codeIDCopyPre.items() if k != deleteIndexNum}
    commentIDCopy = {k: v for k, v in commentIDCopyPre.items() if k != deleteIndexNum}
    vectorIDCopy = {k: v for k, v in vectorIDCopyPre.items() if k != deleteIndexNum}        
            
    print(testDatasRaw[i])
    vectorTest_h,c = sequence_states(testDatasEncode[i:i+1]) 
    ans = -1
    difference = [] # element [codes embedded distance, CommentBleuScore, IndexNum]
    sampledIndices = random.sample(list(range(len(vectorIDCopy))), 10000)
    for j in sampledIndices:
        if j != deleteIndexNum:
            diff = np.linalg.norm(vectorIDCopy[j]-vectorTest_h)

            #RawでBleuScoreを計算
            scores = []
            for weight in range(len(weights)):
                commentJoin = " ".join(commentIDCopy[j][0:-1])
                commentTokenize = nltk.word_tokenize(commentJoin)
                testCommentsRawJoin = " ".join(testCommentsRaw[i][0:-1])
                testCommentsRawTokenize = nltk.word_tokenize(testCommentsRawJoin)

                scores.append(bleu_score.sentence_bleu([commentTokenize],testCommentsRawTokenize ,weights[weight]))

            avgScore = sum(scores)/len(scores)

            difference.append([diff,avgScore,j])

    sort4SimilarCodes = sorted(difference, key=lambda x: x[0])
    sort4SimilarComments = sorted(difference, key=lambda x: x[1])
    sort4SimilarComments.reverse()
    
    print("The most similar comment number is...")
    m = sort4SimilarCodes[0][2]
    print(m)
    print()
    print("the code is")
    print(codeIDCopy[m])
    print()
    print("The comment is")
    commentJoin = " ".join(commentIDCopy[m])
    commentTokenize = nltk.word_tokenize(commentJoin)
    print(commentTokenize)
    print()
    print("Answer comment is")
    testCommentsRawJoin = " ".join(testCommentsRaw[i])
    testCommentsRawTokenize = nltk.word_tokenize(testCommentsRawJoin)
    print(testCommentsRawTokenize)
    print()
    
    # repositoryMatch を検証(コードが最も類似するものに対して)
    predictRepositoryPath = commentIDCopy[m][-1]
    predictRepositoryPath = predictRepositoryPath.split('/')
    if 'repositories' in predictRepositoryPath:
        predictRepositoryIndex = predictRepositoryPath.index('repositories')
        if len(predictRepositoryPath) > predictRepositoryIndex:
            predictRepository = predictRepositoryPath[predictRepositoryIndex+1]
        else:
            predictRepository = "no existance"
    else:
        predictRepository = "no existance"
    
    answerRepositoryPath = testCommentsRaw[i][-1]
    answerRepositoryPath = answerRepositoryPath.split('/')
    if 'repositories' in answerRepositoryPath:
        answerRepositoryIndex = answerRepositoryPath.index('repositories')
        if len(answerRepositoryPath) > answerRepositoryIndex:
            answerRepository = answerRepositoryPath[predictRepositoryIndex+1]
        else:
            answerRepository = "no existance2"
    else:
        answerRepository = "no existance2"
    
    if predictRepository == answerRepository:
        RepositoryMatch4Predict.append(1)
    else:
         RepositoryMatch4Predict.append(0)
            
            
            
    # repositoryMatch を検証(コーパスの中にある最も類似するコメントに対して)
    predictRepositoryPath = commentIDCopy[sort4SimilarComments[0][2]][-1]
    predictRepositoryPath = predictRepositoryPath.split('/')
    if 'repositories' in predictRepositoryPath:
        predictRepositoryIndex = predictRepositoryPath.index('repositories')
        if len(predictRepositoryPath) > predictRepositoryIndex:
            predictRepository = predictRepositoryPath[predictRepositoryIndex+1]
        else:
            predictRepository = "no existance"
    else:
        predictRepository = "no existance"
    
    answerRepositoryPath = testCommentsRaw[i][-1]
    answerRepositoryPath = answerRepositoryPath.split('/')
    if 'repositories' in answerRepositoryPath:
        answerRepositoryIndex = answerRepositoryPath.index('repositories')
        if len(answerRepositoryPath) > answerRepositoryIndex:
            answerRepository = answerRepositoryPath[predictRepositoryIndex+1]
        else:
            answerRepository = "no existance2"
    else:
        answerRepository = "no existance2"
    
    if predictRepository == answerRepository:
        RepositoryMatch4MostSimilar.append(1)
    else:
         RepositoryMatch4MostSimilar.append(0)
            
            
    
    testCodes.append(testDatasRaw[i])
    testComments.append(testCommentsRaw[i])
    predictCodes.append(codeIDCopy[m])
    predictComments.append(commentIDCopy[m])
    mostSimilarCodes.append(codeIDCopy[sort4SimilarComments[0][2]])
    mostSimilarComments.append(commentIDCopy[sort4SimilarComments[0][2]])
    
    
    for j in range(len(sort4SimilarCodes)):
        if sort4SimilarComments[0][2] == sort4SimilarCodes[j][2]:
            mostSimilarCommentsIndex.append(j)
            break
            
    
    
        
        
        
    
    # ここまで
    
    print("====================================")
    print()


results["RawData"] = {}

results["RawData"]["testCodes"] = testCodes
results["RawData"]["testComments"] = testComments
results["RawData"]["predictCodes"] = predictCodes
results["RawData"]["predictComments"] = predictComments
results["RawData"]["mostSimilarCodes"] = mostSimilarCodes
results["RawData"]["mostSimilarComments"] = mostSimilarComments
results["RawData"]["RepositoryMatch4Predict"] = RepositoryMatch4Predict
results["RawData"]["RepositoryMatch4MostSimilar"] = RepositoryMatch4MostSimilar
results["RawData"]["mostSimilarCommentsIndex"] = mostSimilarCommentsIndex


print(results["RawData"]["testCodes"][0])
print(results["RawData"]["testComments"][0])
print(results["RawData"]["predictCodes"][0])
print(results["RawData"]["predictComments"][0])
print(results["RawData"]["mostSimilarCodes"][0])
print(results["RawData"]["mostSimilarComments"][0])
print(results["RawData"]["RepositoryMatch4Predict"][0])
print(results["RawData"]["RepositoryMatch4MostSimilar"][0])
print(results["RawData"]["mostSimilarCommentsIndex"][0])


testCodes = []
testComments = []
predictCodes = []
predictComments = []
mostSimilarCodes = []
mostSimilarComments = []
RepositoryMatch4Predict = []
RepositoryMatch4MostSimilar = []
mostSimilarCommentsIndex = []


print("=======================================================")
print("CommentをNLTKに変換してBLEUScoreを測る。")

codeIDCopyPre = codeID.copy()
vectorIDCopyPre = vectorID.copy()
commentIDCopyPre = commentID.copy()
indexNum = len(codeID)

for commentLine in range(len(allComments)):
    if i != commentLine:
        codeIDCopyPre[indexNum] = testDatasRaw[commentLine]
        commentIDCopyPre[indexNum] = testCommentsRaw[commentLine]
        vectorTest_h,c = sequence_states(testDatasEncode[commentLine:commentLine+1]) 
        vectorIDCopyPre[indexNum] = vectorTest_h
        indexNum += 1

indexNum = len(codeID)


for i in range(numberOfTestData):
    deleteIndexNum = i + indexNum
    codeIDCopy = {k: v for k, v in codeIDCopyPre.items() if k != deleteIndexNum}
    commentIDCopy = {k: v for k, v in commentIDCopyPre.items() if k != deleteIndexNum}
    vectorIDCopy = {k: v for k, v in vectorIDCopyPre.items() if k != deleteIndexNum}            
            
    print(testDatasRaw[i])
    vectorTest_h,c = sequence_states(testDatasEncode[i:i+1]) 
    ans = -1
    difference = [] # element [codes embedded distance, CommentBleuScore, IndexNum]

    for j in range(len(vectorIDCopy)):
        if j != deleteIndexNum:
            diff = np.linalg.norm(vectorIDCopy[j]-vectorTest_h)


            #RawでBleuScoreを計算
            scores = []
            for weight in range(len(weights)):
                commentJoin = " ".join(commentIDCopy[j][0:-1])
                commentTokenize = nltk.word_tokenize(commentJoin)
                predictComment = commentTokenize

                predictCommentWithoutHash = [k for k in predictComment if k != '#']

                testCommentsRawJoin = " ".join(testCommentsRaw[i][0:-1])
                testCommentsRawTokenize = nltk.word_tokenize(testCommentsRawJoin)
                ansComment = testCommentsRawTokenize
                ansCommentWithoutHash = [k for k in ansComment if k != '#']

                predictSentence = ' '.join(predictCommentWithoutHash)
                ansSentence = ' '.join(ansCommentWithoutHash)

                predictWords = nltk.word_tokenize(predictSentence)
                ansWords = nltk.word_tokenize(ansSentence)

                predictTokenize = nltk.pos_tag(predictWords)
                ansTokenize = nltk.pos_tag(ansWords)

                predictTokenizeList = [k[1] for k in predictTokenize]
                ansTokenizeList = [k[1] for k in ansTokenize]

                scores.append(bleu_score.sentence_bleu([commentTokenize],testCommentsRawTokenize ,weights[weight]))


            avgScore = sum(scores)/len(scores)

            difference.append([diff,avgScore,j])

    sort4SimilarCodes = sorted(difference, key=lambda x: x[0])
    sort4SimilarComments = sorted(difference, key=lambda x: x[1])
    sort4SimilarComments.reverse()
    
    print("The most similar comment number is...")
    m = sort4SimilarCodes[0][2]
    print(m)
    print()
    print("the code is")
    print(codeIDCopy[m])
    print()
    print("The comment is")
    commentJoin = " ".join(commentIDCopy[m])
    commentTokenize = nltk.word_tokenize(commentJoin)
    print(commentTokenize)
    print()
    print("Answer comment is")
    testCommentsRawJoin = " ".join(testCommentsRaw[i])
    testCommentsRawTokenize = nltk.word_tokenize(testCommentsRawJoin)
    print(testCommentsRawTokenize)
    print()
    
    # repositoryMatch を検証(コードが最も類似するものに対して)
    predictRepositoryPath = commentIDCopy[m][-1]
    predictRepositoryPath = predictRepositoryPath.split('/')
    if 'repositories' in predictRepositoryPath:
        predictRepositoryIndex = predictRepositoryPath.index('repositories')
        if len(predictRepositoryPath) > predictRepositoryIndex:
            predictRepository = predictRepositoryPath[predictRepositoryIndex+1]
        else:
            predictRepository = "no existance"
    else:
        predictRepository = "no existance"
    
    answerRepositoryPath = testCommentsRaw[i][-1]
    answerRepositoryPath = answerRepositoryPath.split('/')
    if 'repositories' in answerRepositoryPath:
        answerRepositoryIndex = answerRepositoryPath.index('repositories')
        if len(answerRepositoryPath) > answerRepositoryIndex:
            answerRepository = answerRepositoryPath[predictRepositoryIndex+1]
        else:
            answerRepository = "no existance2"
    else:
        answerRepository = "no existance2"

    
    if predictRepository == answerRepository:
        RepositoryMatch4Predict.append(1)
    else:
         RepositoryMatch4Predict.append(0)
            
            
            
    # repositoryMatch を検証(コーパスの中にある最も類似するコメントに対して)
    predictRepositoryPath = commentIDCopy[sort4SimilarComments[0][2]][-1]
    predictRepositoryPath = predictRepositoryPath.split('/')
    if 'repositories' in predictRepositoryPath:
        predictRepositoryIndex = predictRepositoryPath.index('repositories')
        if len(predictRepositoryPath) > predictRepositoryIndex:
            predictRepository = predictRepositoryPath[predictRepositoryIndex+1]
        else:
            predictRepository = "no existance"
    else:
        predictRepository = "no existance"
    
    answerRepositoryPath = testCommentsRaw[i][-1]
    answerRepositoryPath = answerRepositoryPath.split('/')
    if 'repositories' in answerRepositoryPath:
        answerRepositoryIndex = answerRepositoryPath.index('repositories')
        if len(answerRepositoryPath) > answerRepositoryIndex:
            answerRepository = answerRepositoryPath[predictRepositoryIndex+1]
        else:
            answerRepository = "no existance2"
    else:
        answerRepository = "no existance2"
    
    if predictRepository == answerRepository:
        RepositoryMatch4MostSimilar.append(1)
    else:
         RepositoryMatch4MostSimilar.append(0)
            
            
    
    testCodes.append(testDatasRaw[i])
    testComments.append(testCommentsRaw[i])
    predictCodes.append(codeIDCopy[m])
    predictComments.append(commentIDCopy[m])
    mostSimilarCodes.append(codeIDCopy[sort4SimilarComments[0][2]])
    mostSimilarComments.append(commentIDCopy[sort4SimilarComments[0][2]])
    
    
    for j in range(len(sort4SimilarCodes)):
        if sort4SimilarComments[0][2] == sort4SimilarCodes[j][2]:
            mostSimilarCommentsIndex.append(j)
            break
            
    
    
        
        
        
    
    # ここまで
    
    print("====================================")
    print()



results["nltkComment"] = {}

results["nltkComment"]["testCodes"] = testCodes
results["nltkComment"]["testComments"] = testComments
results["nltkComment"]["predictCodes"] = predictCodes
results["nltkComment"]["predictComments"] = predictComments
results["nltkComment"]["mostSimilarCodes"] = mostSimilarCodes
results["nltkComment"]["mostSimilarComments"] = mostSimilarComments
results["nltkComment"]["RepositoryMatch4Predict"] = RepositoryMatch4Predict
results["nltkComment"]["RepositoryMatch4MostSimilar"] = RepositoryMatch4MostSimilar
results["nltkComment"]["mostSimilarCommentsIndex"] = mostSimilarCommentsIndex


with open('/home/u00545/comments/RubyCommentsML/ruby_comment/pickle/code/30dim/BleuScorePracticalResultsOnlyMostSimilarComment_TrainIdentKubetu_TestIdentKubetuRespository0.binaryfile', 'wb') as web:
    pickle.dump(results , web)

