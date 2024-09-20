import keras as kr
import numpy as np
import os
import Emotions_Identification as EI
import Speaker_Recognition as SR


Save_Profiles_Path = "/Profiles/Path"
File_Path = "/Files/Path"
Custom_Set = True
Save_Model_Path = "/Saves/Path"
Num_Epochs = 250
Batch_Size = 100


def Save_Model(Full_Path, Test_Pres, Model, Classes_Struct, Custom_Set):
    Save_Full_Path = Full_Path + str(Test_Pres) + ".keras"
    if not(os.path.exists(Save_Full_Path)):
        Model.save(Save_Full_Path)
        Class_Order = ""
        for i in range(0, Classes_Struct.shape[0]):
            Class_Order = Class_Order + str(Classes_Struct[i]) + " "
        with open(Full_Path + "Classes_Order_" + str(Test_Pres) + ".txt", "w") as file:
            if Custom_Set:
                file.write(Class_Order + "\n01 = neutral, 02 = calm, 03 = happy, 04 = sad, 05 = angry, 06 = fearful, 07 = disgust, 08 = surprised")
            else:
                file.write(Class_Order)


def Create_N_Train_Model(F_Path, Test_Share, Custom_Set, N_Epochs, Batch_S, Val_Split, Verbose):
    Train_Set, Train_Answers, Test_Set, Test_Answers, Classes_Struct = EI.Form_Data_Set_Wav(F_Path, Test_Share, Custom_Set=Custom_Set)
    Train_Set = np.nan_to_num(Train_Set)
    Test_Set = np.nan_to_num(Test_Set)
    Idx = np.random.permutation(len(Train_Set))
    Train_Set = Train_Set[Idx]
    Train_Answers = Train_Answers[Idx]
    New_Model = EI.Create_Model_Simple(Train_Set.shape[1:])
    New_Model.fit(Train_Set, Train_Answers, epochs=N_Epochs, batch_size=Batch_S, validation_split=Val_Split, callbacks=None, verbose=Verbose)
    _, test_pres = New_Model.evaluate(Test_Set, Test_Answers)
    weights = New_Model.get_weights()
    New_Model = EI.Create_Model_Simple(Train_Set.shape[1:])
    New_Model.fit(Train_Set[0:10], Train_Answers[0:10], epochs=1, batch_size=1, validation_split=0.5, callbacks=None, verbose=1)
    New_Model.set_weights(weights)
    return test_pres, New_Model, Classes_Struct

#----------Fix_Bad_Files---------------
#EI.Fix_Wav_Files(File_Path)
#--------------------------------------

#----------Train_N_Save_Model------------
#test_pres, New_Model, Classes_Struct = Create_N_Train_Model(File_Path, 0.1, Custom_Set, Num_Epochs, Batch_Size, 0.25, 1)
#Save_Model(Save_Model_Path, test_pres, New_Model,Classes_Struct,Custom_Set)
#----------------------------------------

#------------Enroll_Speakers-------------
#SR.Enroll_Speakers(File_Path, Save_Profiles_Path)
#----------------------------------------

#-------------Use_Model------------------
File_Name = ""
while True:
    File_Name = input("Enter File Path as 'Actor_xx/xxx.wav': ")
    if os.path.exists(File_Path + File_Name):
        break
    else:
        print("Wrong File Name, Be Sure That It's Located at: '" + File_Path + "'")
Profiles_Arr, Possible_Spkrs = SR.Upload_Speakers_Profiles(Save_Profiles_Path)
Speaker_Result = SR.Recognize_Speaker(File_Path + File_Name, Profiles_Arr, Possible_Spkrs)
Emotion_Result = EI.Identify_Emotions(Save_Model_Path, "0.6870229244232178.keras", File_Path + File_Name)
print("Most likely speaker: " + Speaker_Result)
print("His/Her emotion on this record: " + Emotion_Result)
#----------------------------------------

#-----------Test_SR_Precision------------
#Profiles_Arr, Possible_Spkrs = SR.Upload_Speakers_Profiles(Save_Profiles_Path)
#Test_Res = SR.Test_Precision(Profiles_Arr, File_Path, Possible_Spkrs)
#print("Speakers Recognition Precision: " + str(Test_Res))
#----------------------------------------
