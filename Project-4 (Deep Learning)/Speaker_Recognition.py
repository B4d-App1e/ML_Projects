import numpy as np
import pveagle
import wave
import Emotions_Identification as EI

Access_Key = "keyforpveagle"


def Read_Wav_T_Arr(Full_Path, Min_Frames):
    Frames_Res = None
    with wave.open(Full_Path, 'rb') as wav_file:
        frames = wav_file.readframes(wav_file.getnframes())
        Frames_Res = np.frombuffer(frames, dtype=np.int16)
        wav_file.close()
    El_to_Del = Frames_Res.shape[0] % Min_Frames
    Frames_Res = np.delete(Frames_Res, range(Frames_Res.size - El_to_Del, Frames_Res.size))
    return np.split(Frames_Res, int(Frames_Res.size / Min_Frames))


def Read_All_Speaker_Data(Dir_Path, Min_Frames):
    Res = np.array([])
    First = True
    Files_Names = EI.Get_Directory_Items(Dir_Path, np.array([".wav"]))
    for Name in Files_Names:
        if First:
            Res = Read_Wav_T_Arr(Dir_Path + Name, Min_Frames)
            First = False
        else:
            Res = np.append(Res, Read_Wav_T_Arr(Dir_Path + Name, Min_Frames), axis=0)
    return Res


def Enroll_Speakers(Files_Path, Save_Path):
    Dir_Items_Names = EI.Get_Directory_Items(Files_Path)
    Speakers_Profiles = []
    Black_List = ["Actor_09"]
    for Name in Dir_Items_Names:
        if Name in Black_List:
            continue
        Profiler = None
        try:
            Profiler = pveagle.create_profiler(access_key=Access_Key)
        except pveagle.EagleError as e:
            print("Impossible to Use Profiler, Try Again Later")
            return
            pass
        Speaker_Data = Read_All_Speaker_Data(Files_Path + Name + "/", Profiler.min_enroll_samples * 2)
        Counter = 0
        enroll_percentage = 0.0
        print(Name + " Processing At the Moment")
        while enroll_percentage < 100.0 and Counter < Speaker_Data.shape[0]:
            enroll_percentage, feedback = Profiler.enroll(Speaker_Data[Counter].tolist())
            print("Current Quality: " + str(enroll_percentage))
            Counter = Counter + 1
        Profile = Profiler.export()
        Speakers_Profiles.append(Profile)
        Profiler.delete()
        with open(Save_Path + Name + "_Profile.txt", 'wb') as file:
            file.write(Profile.to_bytes())
            print("Profile for '" + Name + "' Saved")
            file.close()
    return Speakers_Profiles


def Upload_Speakers_Profiles(Profiles_Path):
    Speakers_Profiles = []
    Classes_Acc = []
    Files_Names = EI.Get_Directory_Items(Profiles_Path, np.array([".txt"]))
    Counter = 0
    for Name in Files_Names:
        with open(Profiles_Path + Name, 'rb') as file:
            Bytes_Data = file.read()
            Speakers_Profiles.append(pveagle.EagleProfile.from_bytes(Bytes_Data))
            file.close()
        Classes_Acc.append(Name.replace("_Profile.txt", ""))
        Counter = Counter + 1
    return Speakers_Profiles, Classes_Acc


def Recognize_Speaker(File_Full_Path, Speakers_Profiles, Possible_Speakers):
    Res_Raw = np.array([])
    try:
        Recognizer = pveagle.create_recognizer(access_key=Access_Key, speaker_profiles=Speakers_Profiles)
    except pveagle.EagleError as e:
        print("Impossible to Use Recognizer, Try Again Later")
        return
        pass
    First = True
    File_Frames = Read_Wav_T_Arr(File_Full_Path, Recognizer.frame_length)
    for Frames_Piece in File_Frames:
        scores = Recognizer.process(Frames_Piece.tolist())
        if First:
            Res_Raw = np.array([scores])
            First = False
        else:
            Res_Raw = np.append(Res_Raw, np.array([scores]), axis=0)
    return Possible_Speakers[Process_Result(Res_Raw)]


def Process_Result(Raw_Res):
    Res_F = np.zeros((Raw_Res.shape[1]), dtype=np.int16)
    for Sub_Res in Raw_Res:
        Res_idx = np.where(Sub_Res == Sub_Res.max())
        Res_F[Res_idx] = Res_F[Res_idx] + 1
    print(Res_F)
    return np.argmax(Res_F)

def Test_Precision(Speakers_Profiles, Directory_Path, Possible_Speakers):
    Right_Counter = 0
    Directories = EI.Get_Directory_Items(Directory_Path)
    Files_Full_Paths = np.array([])
    Files_Names = np.array([])
    Forbidden_Names = ["Actor_09", "Actor_03", "Actor_19", "Actor_21", "Actor_08"]
    for Value in Directories:
        if Value in Forbidden_Names:
            continue
        New_File_Names = EI.Get_Directory_Items(Directory_Path + Value + "/", np.array([".wav"]))
        for Name in New_File_Names:
            Files_Full_Paths = np.append(Files_Full_Paths, Directory_Path + Value + "/" + Name)
            Files_Names = np.append(Files_Names, Name)
    for i in range(0, Files_Full_Paths.shape[0]):
        print("Calculating Result For " + str(i) + " File")
        File_Data = Read_Wav_T_Arr(Files_Full_Paths[i], 20480)
        Buf = str(Files_Names[i])
        Buf = Buf.replace(".wav", "")
        Buf = Buf.replace("n", "")
        Buf_Arr = np.fromstring(Buf, sep="-")
        Actor_num = str(Buf_Arr[Buf_Arr.shape[0] - 1])[:-2]
        if len(Actor_num) == 1:
            Actor_num = "0" + Actor_num
        Right_Ans = "Actor_" + Actor_num
        Ans = Recognize_Speaker(Files_Full_Paths[i], Speakers_Profiles, Possible_Speakers)
        print(Right_Ans)
        print(Ans)
        if Right_Ans == Ans:
            Right_Counter = Right_Counter + 1
    return Right_Counter / Files_Names.shape[0]