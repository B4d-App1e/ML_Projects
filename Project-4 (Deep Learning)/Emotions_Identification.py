from scipy.io import wavfile
from random import randrange
import keras as kr
import librosa
import librosa.feature
import numpy as np
import os
import noisereduce as nr
import wave

def Read_File_And_Clean_Noise(F_Name, First = False):
    Rate, Data = wavfile.read(F_Name)
    if First:
        return Rate, nr.reduce_noise(y=Data, sr=Rate)
    return nr.reduce_noise(y=Data, sr=Rate)


def Read_File_Only(F_Name, First = False):
    Rate, Data = wavfile.read(F_Name)
    if First:
        return Rate, Data
    return Data


def Extract_Features_Old(Audio_Data, Rate):
    Features = librosa.feature.mfcc(y=Audio_Data, sr=Rate, n_mfcc=20, norm='ortho')
    cent = librosa.feature.spectral_centroid(y=Audio_Data, sr=Rate)
    Zero_Cross = librosa.zero_crossings(Audio_Data)
    Num_To_Del = Zero_Cross.shape[0] % Features.shape[1]
    Zero_Cross = Zero_Cross[:-Num_To_Del]
    Sub_Zero_Arr = np.split(Zero_Cross, Features.shape[1])
    Zero_Cross = []
    for Sub_Arr in Sub_Zero_Arr:
        Zero_Cross = np.append(Zero_Cross, sum(Sub_Arr) / Sub_Arr.shape[0])
    Zero_Cross = Zero_Cross.reshape((1, Zero_Cross.shape[0]))
    Spec_Band = librosa.feature.spectral_bandwidth(y=Audio_Data, sr=Rate)
    Features = np.vstack((Features, cent, Zero_Cross, Spec_Band))
    Features = np.transpose(Features)
    return Features


def Extract_Features(Audio_Data, Rate):
    Features = librosa.feature.mfcc(y=Audio_Data, sr=Rate, n_mfcc=20, norm='ortho')
    Features = np.transpose(Features)
    return Features


def Split_Data_Set_Train_Test(Data_Set, Answers_Set, Test_Share):
    Train_Data = Data_Set
    Train_Answers = Answers_Set
    Test_Data = []
    Test_Answers = []
    Counter = 0
    while Counter < Train_Data.shape[0] * Test_Share:
        Item_To_Add_Idx = randrange(Train_Data.shape[0])
        if Counter == 0:
            Test_Data = [Train_Data[Item_To_Add_Idx]]
            Test_Answers = [Train_Answers[Item_To_Add_Idx]]
        else:
            Test_Data = np.append(Test_Data, [Train_Data[Item_To_Add_Idx]], axis=0)
            Test_Answers = np.append(Test_Answers, [Train_Answers[Item_To_Add_Idx]], axis=0)
        Train_Data = np.delete(Train_Data, Item_To_Add_Idx, axis=0)
        Train_Answers = np.delete(Train_Answers, Item_To_Add_Idx, axis=0)
        Counter = Counter + 1
    return Train_Data, Train_Answers, Test_Data, Test_Answers


def Get_Random_Sub_Set(Data_Set, Answers_Set, Num_Elements):
    Base_Set = np.array(Data_Set)
    Base_Ans = np.array(Answers_Set)
    Res_Set = []
    Res_Ans = []
    for i in range(0, Num_Elements):
        Item_To_Add_Idx = randrange(Base_Set.shape[0])
        if i == 0:
            Res_Set = [Base_Set[Item_To_Add_Idx]]
            Res_Ans = [Base_Ans[Item_To_Add_Idx]]
        else:
            Res_Set = np.append(Res_Set, [Base_Set[Item_To_Add_Idx]], axis=0)
            Res_Ans = np.append(Res_Ans, [Base_Ans[Item_To_Add_Idx]], axis=0)
        Base_Set = np.delete(Base_Set, Item_To_Add_Idx, axis=0)
        Base_Ans = np.delete(Base_Ans, Item_To_Add_Idx, axis=0)
    return Res_Set, Res_Ans


def Get_Directory_Items(Directory_Path, Extensions = np.array([])):
    Names = np.array(os.listdir(Directory_Path))
    Names = np.delete(Names, np.where(Names == ".DS_Store"))
    if Extensions.size == 0:
        #option to get folder names
        for i in range(0, Names.shape[0]):
            if "." in str(Names[i]):
                Names = np.delete(Names, i)
        return Names
    else:
        #option to get file names with received extensions
        for i in range(0, Names.shape[0]):
            if i >= Names.shape[0]:
                break
            Right_File_Marker = False
            for j in range(0, Extensions.shape[0]):
                if Extensions[j] in Names[i]:
                    Right_File_Marker = True
            if Right_File_Marker == False:
                Names = np.delete(Names, i)
        return Names


def Zerofy_To_Fit(Array_1, Array_2):
    if Array_1.shape[1] > Array_2.shape[0]:
        Res_Arr = np.array(Array_2)
        while not(Array_1.shape[1] == Res_Arr.shape[0]):
            Res_Arr = np.append(Res_Arr, np.zeros((1, Res_Arr.shape[1]), dtype=np.float32), axis=0)
        return np.append(Array_1, [Res_Arr], axis=0)
    else:
        Res_Arr = np.zeros((Array_1.shape[0], Array_2.shape[0], Array_1.shape[2]),dtype=np.float32)
        for i in range(0, Array_1.shape[0]):
            Buf_Arr = Array_1[i]
            while not(Array_2.shape[0] == Buf_Arr.shape[0]):
                Buf_Arr = np.append(Buf_Arr, np.zeros((1, Buf_Arr.shape[1]), dtype=np.float32), axis=0)
            Res_Arr[i] = Buf_Arr
        return np.append(Res_Arr, [Array_2], axis=0)


def Form_Data_Set_Wav(Directory_Path, Test_Share, Custom_Set = False):
    Data_Set = np.array([[[]]])
    Answers_Set = np.array([[]])
    Directories = Get_Directory_Items(Directory_Path)
    if Directories.size == 0 or "." in str(Directories[0]):
        print("Wrong Directory Path, Try Another One")
        return Data_Set, Answers_Set, Data_Set, Answers_Set
    print(Directories)
    Files_Full_Paths = np.array([])
    Files_Names = np.array([])
    for Value in Directories:
        New_File_Names = Get_Directory_Items(Directory_Path + Value + "/", np.array([".wav"]))
        for Name in New_File_Names:
            Files_Full_Paths = np.append(Files_Full_Paths, Directory_Path + Value + "/" + Name)
            Files_Names = np.append(Files_Names, Name)
    Unique_Classes = np.array([])
    if Custom_Set:
        for i in range(0, Files_Names.shape[0]):
            Buf = str(Files_Names[i])
            Buf = Buf.replace(".wav", "")
            Buf = Buf.replace("n", "")
            Buf_Arr = np.fromstring(Buf, sep="-")
            if not(Buf_Arr[2] in Unique_Classes):
                Unique_Classes = np.append(Unique_Classes, Buf_Arr[2])
    else:
        for i in range(0, Files_Names.shape[0]):
            Buf = str(Files_Names[i])
            Buf = Buf.replace(".wav", "")
            Buf = ''.join([i for i in Buf if not i.isdigit()])
            if not(Buf in Unique_Classes):
                Unique_Classes = np.append(Unique_Classes, Buf)
    print(Unique_Classes)
    for i in range(0, Files_Full_Paths.shape[0]):
        Rate, Data = Read_File_And_Clean_Noise(Files_Full_Paths[i], True)
        F_Features = Extract_Features(np.array(Data).astype(np.float32), Rate)
        Ans = np.zeros(Unique_Classes.shape[0])
        Buf = None
        if Custom_Set:
            Buf = str(Files_Names[i])
            Buf = Buf.replace(".wav", "")
            Buf = Buf.replace("n", "")
            Buf_Arr = np.fromstring(Buf, sep="-")
            Buf = Buf_Arr[2]
        else:
            Buf = str(Files_Names[i])
            Buf = Buf.replace(".wav", "")
            Buf = ''.join([i for i in Buf if not i.isdigit()])
        Ans[np.where(Unique_Classes == Buf)[0][0]] = 1.0
        if i == 0:
            Data_Set = np.array([F_Features])
            Answers_Set = np.array([Ans])
        else:
            Data_Set = Zerofy_To_Fit(Data_Set, F_Features)
            Answers_Set = np.append(Answers_Set, [Ans], axis=0)
    Train_Dt, Train_Ans, Test_Dt, Test_Ans = Split_Data_Set_Train_Test(Data_Set, Answers_Set, Test_Share)
    return Train_Dt, Train_Ans, Test_Dt, Test_Ans, Unique_Classes


def Normalization_2d(Array):
    Res = np.array([])
    First = True
    for Sub_Array in Array:
        Buf_Arr = Sub_Array + np.min(Sub_Array) * -1
        if First:
            Res = [np.divide(Buf_Arr, np.max(Buf_Arr))]
            First = False
        else:
            Res = np.append(Res, [np.divide(Buf_Arr, np.max(Buf_Arr))], axis=0)
    return Res

def Create_Model(Layers_Struct, Neurons_Counts, Learning_Rate = 0.001):
    Model = kr.Sequential()
    if not(Layers_Struct.shape == Neurons_Counts.shape):
        print("Wrong Model Structure Data Received")
        return None
    for i in range(0, Layers_Struct.shape[0]):
        match str(Layers_Struct[i]).lower():
            case "gru":
                if i == 0:
                    Model.add(kr.layers.GRU(int(Neurons_Counts[i]), return_sequences=True))
                else:
                    Model.add(kr.layers.GRU(int(Neurons_Counts[i])))
            case "dropout":
                Model.add(kr.layers.Dropout(np.float32(Neurons_Counts[i])))
            case "dense":
                Model.add(kr.layers.Dense(int(Neurons_Counts[i]), activation=kr.activations.softmax, kernel_regularizer=kr.regularizers.l1_l2))
            case "lstm":
                if i == 0:
                    Model.add(kr.layers.LSTM(int(Neurons_Counts[i]), return_sequences=True))
                else:
                    Model.add(kr.layers.LSTM(int(Neurons_Counts[i])))
            case _:
                continue
    Model.compile(optimizer=kr.optimizers.Adamax(learning_rate=Learning_Rate), loss='binary_crossentropy')
    return Model


def Create_Model_Simple(Inp_Sizes, Learning_Rate = 0.001):
    Model = kr.Sequential()
    Model.add(kr.layers.Input(Inp_Sizes))
    Model.add(kr.layers.Conv1D(filters=60, kernel_size=3, padding="same"))
    Model.add(kr.layers.Dropout(0.2))
    Model.add(kr.layers.BatchNormalization())
    Model.add(kr.layers.ReLU())
    Model.add(kr.layers.Conv1D(filters=60, kernel_size=3, padding="same"))
    Model.add(kr.layers.Dropout(0.2))
    Model.add(kr.layers.BatchNormalization())
    Model.add(kr.layers.ReLU())
    Model.add(kr.layers.Conv1D(filters=60, kernel_size=3, padding="same"))
    Model.add(kr.layers.Dropout(0.2))
    Model.add(kr.layers.BatchNormalization())
    Model.add(kr.layers.ReLU())
    Model.add(kr.layers.GlobalAveragePooling1D())
    Model.add(kr.layers.Dense(8, activation=kr.activations.softmax, kernel_regularizer=kr.regularizers.l1_l2))
    Model.compile(optimizer=kr.optimizers.Adamax(learning_rate=Learning_Rate), loss='binary_crossentropy', metrics=['accuracy'])
    return Model


def Test_Models_Ensemble(Models, Test_set, Test_ans):
    Right_Ans = 0
    for i in range(0, Test_set.shape[0]):
        Ens_Pred = Get_Ensemble_Predict(Models, Test_set[i], Test_ans.shape[1])
        if np.array_equal(Ens_Pred, Test_ans[i]):
            Right_Ans = Right_Ans + 1
    return Right_Ans / Test_set.shape[0]

def Get_Ensemble_Predict(Models, Test_Value, Num_Classes):
    Res = np.zeros((Num_Classes), dtype=np.float32)
    for Model in Models:
        #Pred = Model(np.array([Test_Value]), training=False)
        Pred = Model.predict_on_batch(np.array([Test_Value]))
        #Pred = Model.predict(np.array([Test_Value]))
        Res[np.argmax(Pred)] = Res[np.argmax(Pred)] + 1.0
    Res_idx = np.argmax(Res)
    Res = np.zeros((Num_Classes), dtype=np.float32)
    Res[Res_idx] = 1.0
    return Res


def Crutch_Wav(File_Path, File_Name):
    with wave.open(File_Path + File_Name, 'rb') as wav_file:
        params = wav_file.getparams()
        frames = wav_file.readframes(wav_file.getnframes())
        with wave.open(File_Path + "n" + File_Name, 'wb') as new_wav:
            new_wav.setparams(params)
            new_wav.writeframes(frames)
            new_wav.close()
        wav_file.close()


def Fix_Wav_Files(Directory_Path):
    Directories = Get_Directory_Items(Directory_Path)
    if Directories.size == 0 or "." in str(Directories[0]):
        print("Wrong Directory Path, Try Another One")
    Files_Semi_Full_Paths = np.array([])
    Files_Names = np.array([])
    for Value in Directories:
        New_File_Names = Get_Directory_Items(Directory_Path + Value + "/", np.array([".wav"]))
        for Name in New_File_Names:
            Files_Semi_Full_Paths = np.append(Files_Semi_Full_Paths, Directory_Path + Value + "/")
            Files_Names = np.append(Files_Names, Name)
    for i in range(0, Files_Semi_Full_Paths.shape[0]):
        Crutch_Wav(Files_Semi_Full_Paths[i], Files_Names[i])


def Identify_Emotions(Model_Path, Model_Name, File_Full_Path):
    Rate, Data = Read_File_And_Clean_Noise(File_Full_Path, True)
    F_Features = Extract_Features(np.array(Data).astype(np.float32), Rate)
    Model = kr.models.load_model(Model_Path + Model_Name)
    Classes_Acc = None
    with open(Model_Path + "Classes_Order_" + Model_Name.replace(".keras", ".txt"), 'r') as file:
        Classes_Acc = file.read()
    Class_Sub_Acc = Classes_Acc.split(" \n")
    Nums_Str = Class_Sub_Acc[0].split(" ")
    Nums_Str = [N.replace(".0", "") for N in Nums_Str]
    Nums_Int = np.array(Nums_Str, dtype=np.int16)
    Vars = Class_Sub_Acc[1].split(", ")
    print(Vars)
    for i in range(0, len(Vars)):
        Vars[i] = Vars[i][5:]
    Pred = Model.predict_on_batch(np.array([F_Features]))
    Res_N = Nums_Int[np.argmax(Pred)]
    return Vars[Res_N - 1]

