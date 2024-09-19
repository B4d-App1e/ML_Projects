//
//  Random_Forest.swift
//  S_Stocks
//
//  Created by Alex Glukhov on 02.12.2023.
//

import Foundation
extension Collection where Self.Iterator.Element: RandomAccessCollection {
    func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        guard let firstRow = self.first else { return [] }
        return firstRow.indices.map { index in
            self.map{ $0[index] }
        }
    }
}
extension String{
    struct NumFormatter {
        static let instance = NumberFormatter()
    }
    func index(from: Int) -> Index {
            return self.index(startIndex, offsetBy: from)
        }

        func substring(from: Int) -> String {
            let fromIndex = index(from: from)
            return String(self[fromIndex...])
        }

        func substring(to: Int) -> String {
            let toIndex = index(from: to)
            return String(self[..<toIndex])
        }

        func substring(with r: Range<Int>) -> String {
            let startIndex = index(from: r.lowerBound)
            let endIndex = index(from: r.upperBound)
            return String(self[startIndex..<endIndex])
        }
    
    func numberOfOccurrencesOf(string: String) -> Int {
            return self.components(separatedBy:string).count - 1
        }
    var doubleValue: Double? {
        return NumFormatter.instance.number(from: self)?.doubleValue
    }
    var integerValue: Int? {
        return NumFormatter.instance.number(from: self)?.intValue
    }
    var boolValue: Bool?{
        return NumFormatter.instance.number(from: self)?.boolValue
    }
}
func equals(x : Any, y : Any) -> Bool {
    guard x is AnyHashable else { return false }
    guard y is AnyHashable else { return false }
    return (x as! AnyHashable) == (y as! AnyHashable)
}
struct Tree : Codable{
    var Valid : Bool
    var Hash : Int
    var Value : [Double]
    var Data_Type : String
    var Children : [Tree]?
    var Res_Type : String
    var Res : [Double]
    var Res_Probs : [Double]
    init(Input_Array: [[Any]]? = nil, Key_Creteria: Int? = nil, Defined_Keys: [Int]? = nil, Added_Criteries: [Int]? = nil, Branching_Limit: Int? = nil){
        self.Valid = false
        self.Hash = -1
        self.Value = []
        self.Data_Type = "nil"
        self.Children = nil
        self.Res = []
        self.Res_Probs = []
        self.Res_Type = "nil"
    }
    func Get_Res_Fast(Entry: [Any])->[[Any]?]{
        if self.Hash < Entry.count{
            for i in 0..<self.Value.count{
                if  Value[i] >= Entry[self.Hash] as? Double ?? Double.greatestFiniteMagnitude || Value[i] >= Double(Entry[self.Hash] as? Int ?? Int.max){
                    if self.Hash != -1 && self.Children != nil && self.Children!.count > i && self.Children![i].Valid{
                        return self.Children![i].Get_Res_Fast(Entry: Entry)
                    }
                    else{
                        if equals(x: Res, y: []) && self.Res_Probs == []{
                            return [[self.Res_Type], nil, nil]
                        }
                        else if equals(x: Res, y: []){
                            return [[self.Res_Type], nil, self.Res_Probs]
                        }
                        else if self.Res_Probs == []{
                            return [[self.Res_Type], self.Res, nil]
                        }
                        else{
                            return [[self.Res_Type], self.Res, self.Res_Probs]
                        }
                    }
                }
            }
            if self.Hash != -1 && self.Children != nil && self.Children!.count == self.Value.count && self.Children![self.Value.count - 1].Valid{
                return self.Children![self.Value.count - 1].Get_Res_Fast(Entry: Entry)
            }
            else{
                if equals(x: Res, y: []) && self.Res_Probs == []{
                    return [[self.Res_Type], nil, nil]
                }
                else if equals(x: Res, y: []){
                    return [[self.Res_Type], nil, self.Res_Probs]
                }
                else if self.Res_Probs == []{
                    return [[self.Res_Type], self.Res, nil]
                }
                else{
                    return [[self.Res_Type], self.Res, self.Res_Probs]
                }
            }
        }
        else{
            print("Dimensions of Train set and Given Example are different, Full Res Part")
            return [nil, nil, nil]
        }
    }
    func Calc_Entries_Probs(Values: [Int])-> [Double]{
        var Sum : Double = Double.zero
        var Res : [Double] = []
        for Val in Values{
            Sum += Double(Val)
            Res.append(Double(Val))
        }
        return Res.map {$0 / Sum}
    }
    func Remove_Entries_Groups(Base: [[Any]], Sec_Key: Int, Prev_Val: Double? = nil, Curr_Val: Double)->[[Any]]{
        var Res : [[Any]] = []
        for Val in Base{
            if Prev_Val != nil{
                if Double(String(describing: Val[Sec_Key]))! > Prev_Val! && Double(String(describing: Val[Sec_Key]))! <= Curr_Val{
                    Res.append(Val)
                }
            }
            else{
                if Double(String(describing: Val[Sec_Key]))! <= Curr_Val{
                    Res.append(Val)
                }
            }
        }
        return Res
    }
    func Remove_Entries(Base: [[Any]], Sec_Key: Int, Val: Any)->[[Any]]{
        var Res : [[Any]] = []
        for Vals in Base{
            if equals(x: Vals[Sec_Key], y: Val){
                Res.append(Vals)
            }
        }
        return Res
    }
    func Get_Unique(Vals : [Any])->[[Any]]{
        var Ret_Type = "String"
        var Entr_Res : [Int] = []
        var Res_Bool : [Bool] = []
        var Res_Int : [Int] = []
        var Res_Double : [Double] = []
        var Res_Str : [String] = []
        for Val in Vals {
            let buf = String(describing: Val)
            if let I_Val = Int(buf){
                if Ret_Type != "Int"{
                    Ret_Type = "Int"
                }
                if let Idx = Res_Int.firstIndex(of: I_Val){
                    Entr_Res[Idx] += 1
                }
                else{
                    Res_Int.append(I_Val)
                    Entr_Res.append(1)
                }
            }
            else if let D_Val = Double(buf){
                if Ret_Type != "Double"{
                    Ret_Type = "Double"
                }
                if let Idx = Res_Double.firstIndex(of: D_Val){
                    Entr_Res[Idx] += 1
                }
                else{
                    Res_Double.append(D_Val)
                    Entr_Res.append(1)
                }
            }
            else if let B_Val = Bool(buf){
                if Ret_Type != "Bool"{
                    Ret_Type = "Bool"
                }
                if let Idx = Res_Bool.firstIndex(of: B_Val){
                    Entr_Res[Idx] += 1
                }
                else{
                    Res_Bool.append(B_Val)
                    Entr_Res.append(1)
                }
            }
            else{
                if let Idx = Res_Str.firstIndex(of: buf){
                    Entr_Res[Idx] += 1
                }
                else{
                    Res_Str.append(buf)
                    Entr_Res.append(1)
                }
            }
        }
        switch Ret_Type{
        case "Bool":
            return [[Ret_Type], Res_Bool, Entr_Res]
        case "Int":
            return [[Ret_Type], Res_Int, Entr_Res]
        case "Double":
            return [[Ret_Type], Res_Double, Entr_Res]
        default:
            return[[Ret_Type], Res_Str, Entr_Res]
        }
    }
    func Key_Parm_Vals(Val:Any, Base:[[Any]], Unique_Criteria: [Any], Mast_Key: Int,  Sec_Key: Int)->[Int]{
        var Res : [Int] = .init(repeating: Int.zero, count: Unique_Criteria.count)
        for Vals in Base{
            if equals(x: Val, y: Vals[Sec_Key]){
                if let Idx = Unique_Criteria.firstIndex(where: {equals(x: $0, y: Vals[Mast_Key])}){
                    Res[Idx] += 1
                }
            }
        }
        return Res
    }
    func Entropy(Values: [Int], Count: Int)-> Double{
        guard Count > 0 else {return Double.zero}
        guard Values.count > 1 else {return Double.zero}
        var Res : Double = Double.zero
        if Values.count == 2{
            for Val in Values{
                if Val != Int.zero{
                    Res -= Double(Val)/Double(Count) * log2(Double(Val)/Double(Count))
                }
            }
        }
        else{
            var Counter = 0.0
            for i in 0..<Values.count-1{
                for j in i+1..<Values.count{
                    let Count_ij = Values[i] + Values[j]
                    Res += Entropy(Values: [Values[i], Values[j]], Count: Count_ij)
                    Counter += 1.0
                }
            }
            Res /= Counter
        }
        return Res
    }
    func Gain(Entropy_Base: Double, Unique_Vals_Entrns: [[Any]], Base : [[Any]], Unique_Criteria: [Any], Mast_Key: Int, Sec_Key: Int, Groups_Of: Int? = nil, Type: String? = nil) -> Double{
        var Res : Double = Entropy_Base
        let Val_Names = Unique_Vals_Entrns[1]
        var Vals_Counts : [Int] = Unique_Vals_Entrns[2] as! [Int]
        var Names : [Double] = []
        var Step : Double = Double.zero
        var Steps_Count : Int = 0
        var Names_Normalizer : Double = Double.zero
        var Groups : [[Int]] = .init(repeating: .init(repeating: Int.zero, count: Unique_Criteria.count), count: Groups_Of ?? 0)
        var Groups_Counts : [Int] = .init(repeating: Int.zero, count: Groups_Of ?? 0)
        if Groups_Of != nil && Type != nil{
            Names = Type! == "Double" ? Val_Names as! [Double] : (Val_Names as! [Int]).map {Double($0)}
            let Vals_Sorted = Fast_Sort(Vals_Names: Names, Vals_Counts: Vals_Counts)
            Names = Vals_Sorted[0]
            Names_Normalizer = -1 * Names[0] + 1.0
            if Names_Normalizer > 0{
                Names = Names.map {$0 + Names_Normalizer}
            }
            Vals_Counts = Vals_Sorted[1].map {Int($0)}
            Step = (Names[0] + Names[Names.count-1])/Double(Groups_Of!)
        }
        for i in 0..<Val_Names.count {
            if Groups_Of == nil || Type == nil{
                let Val_Name = Val_Names[i]
                let Entrances = Key_Parm_Vals(Val: Val_Name, Base: Base, Unique_Criteria: Unique_Criteria, Mast_Key: Mast_Key, Sec_Key: Sec_Key) //V
                let Global_Count = Base.count
                let Parm_Count = Vals_Counts[i]
                Res -= Double(Parm_Count)/Double(Global_Count) * Entropy(Values: Entrances, Count: Parm_Count)
            }
            else{
                var Entrances : [Int] = []
                if Names_Normalizer <= 0{
                    Entrances = Key_Parm_Vals(Val: Type! == "Double" ? Names[i] : Int(Names[i]), Base: Base, Unique_Criteria: Unique_Criteria, Mast_Key: Mast_Key, Sec_Key: Sec_Key) //V with Int X with defined Groups
                }
                else{
                    Entrances = Key_Parm_Vals(Val: Type! == "Double" ? Names[i] - Names_Normalizer : Int(Names[i] - Names_Normalizer), Base: Base, Unique_Criteria: Unique_Criteria, Mast_Key: Mast_Key, Sec_Key: Sec_Key) //V with Int
                }
                if Step * Double(Steps_Count + 1) < Names[i]{
                    Steps_Count += 1
                }
                Groups[Steps_Count] = Per_Element_Sum(Arr_1: Groups[Steps_Count], Arr_2: Entrances)
                Groups_Counts[Steps_Count] += Vals_Counts[i]
            }
        }
        if Groups_Of != nil && Type != nil{
            for i in 0..<Groups_Of!{
                Res -= Double(Groups_Counts[i])/Double(Base.count) * Entropy(Values: Groups[i], Count: Groups_Counts[i])
            }
        }
        return Res
    }
    func Per_Element_Sum(Arr_1: [Int], Arr_2: [Int])->[Int]{
        guard Arr_1.count == Arr_2.count else {return Arr_1}
        var Res : [Int] = .init(repeating: Int.zero, count: Arr_1.count)
        for i in 0..<Arr_1.count{
            Res[i] = Arr_1[i] + Arr_2[i]
        }
        return Res
    }
    func Fast_Sort(Vals_Names: [Double], Vals_Counts: [Int], Desc : Bool = true) -> [[Double]]{
        guard Vals_Names.count > 1 else {return [Vals_Names, Vals_Counts.map {Double($0)}]}
        let pivot = Vals_Names[Vals_Names.count/2]
        var less : [Double] = []
        var less_shadow : [Int] = []
        var equal : [Double] = []
        var equal_shadow : [Int] = []
        var greater : [Double] = []
        var greater_shadow : [Int] = []
        for Val in 0..<Vals_Names.count{
            if Desc{
                if Vals_Names[Val] < pivot{
                    less.append(Vals_Names[Val])
                    less_shadow.append(Vals_Counts[Val])
                }
                else if(Vals_Names[Val] > pivot){
                    greater.append(Vals_Names[Val])
                    greater_shadow.append(Vals_Counts[Val])
                }
                else{
                    equal.append(Vals_Names[Val])
                    equal_shadow.append(Vals_Counts[Val])
                }
            }
            else{
                if Vals_Names[Val] > pivot{
                    less.append(Vals_Names[Val])
                    less_shadow.append(Vals_Counts[Val])
                }
                else if(Vals_Names[Val] < pivot){
                    greater.append(Vals_Names[Val])
                    greater_shadow.append(Vals_Counts[Val])
                }
                else{
                    equal.append(Vals_Names[Val])
                    equal_shadow.append(Vals_Counts[Val])
                }
            }
        }
        let Sorted_less = Fast_Sort(Vals_Names: less, Vals_Counts: less_shadow, Desc: Desc)
        let Sorted_Greater = Fast_Sort(Vals_Names: greater, Vals_Counts: greater_shadow, Desc: Desc)
        
        return [Sorted_less[0] + equal + Sorted_Greater[0], Sorted_less[1] + equal_shadow.map {Double($0)} + Sorted_Greater[1]]
    }
}
class Random_Forest : Codable{
    private var Working : Bool
    private var Best_Forest : [Tree] = []
    private var Classifier : Bool
    public init(f_Name: String){
        let Dec = JSONDecoder()
        let Url = URL(fileURLWithPath: f_Name)
        guard let data = try? Data.init(contentsOf: Url) else{
            print("Error During Reading Process(Random Forest)")
            self.Working = false
            self.Classifier = true
            return
        }
        guard let Decd = try? Dec.decode(Random_Forest.self, from: data) else{
            print("Error During Decoding Process(Random Forest)")
            self.Working = false
            self.Classifier = true
            return
        }
        self.Best_Forest = Decd.Best_Forest
        self.Working = Decd.Working
        self.Classifier = Decd.Classifier
    }
    public func Save_Model(f_Name: String){
        let Enc = JSONEncoder()
        guard let Encd = try? Enc.encode(self) else{
            print("Error During Encoding Process(Random Forest)")
            return
        }
        let Url = URL(fileURLWithPath: f_Name)
        do{
            try Encd.write(to: Url)
        }
        catch{
            print("Error During Writing Process(Random Forest)")
        }
    }
    init(Is_It_Classifier: Bool = true){
        self.Working = false
        self.Classifier = Is_It_Classifier
    }
    public func Build_Forest(Train_Set: [[Any]], Key_Creteria: Int, Epochs: Int, Batch_Size: Int, Train_Test_Ratio: Double? = nil, Creterion_Limit: Int? = nil, Branching_Limit: Int? = nil, Forest_Num : Int? = nil){
        if !self.Classifier && Int(String(describing: Train_Set[0][Key_Creteria])) == nil && Double(String(describing: Train_Set[0][Key_Creteria])) == nil{
            print("Given Train Set Can't Be Used For Regression Building, 'Cause it's Key Criterion is not an Number, Try Again with Different Key Value or 'Is_It_Classifier' setting")
        }
        else if Train_Set.count != 0 && Key_Creteria >= 0 && Key_Creteria < Train_Set[0].count && Epochs > 0 && Batch_Size > 0{
            var T_T_Ratio : Double = 0.9
            var C_Limit : Int = Int(sqrt(Double(Train_Set[0].count)))
            if Train_Test_Ratio != nil && Train_Test_Ratio! >= Double.zero && Train_Test_Ratio! <= 1.0{
                T_T_Ratio = Train_Test_Ratio!
            }
            if Creterion_Limit != nil && Creterion_Limit! > Int.zero && Creterion_Limit! < Train_Set[0].count{
                C_Limit = Creterion_Limit!
            }
            let Set = Train_Set.shuffled()
            let Training_Set = Set.prefix(upTo: Int(T_T_Ratio * Double(Set.count)))
            let Test_Set = Set.suffix(from: Int(T_T_Ratio * Double(Set.count)))
            for Epoch in 1 ... Epochs{
                var Trees_Ep : [Tree] = []
                var Shuffled_Train = Training_Set.shuffled()
                var Shuffled_Test = Test_Set.shuffled()
                var Trees_Counter = 1
                while !Shuffled_Train.isEmpty{
                    let Batch = Array(Shuffled_Train.prefix(Batch_Size))
                    var Def_Creterions : [Int] = []
                    while Def_Creterions.count != C_Limit{
                        let Rand_Val = Int.random(in: 0..<Shuffled_Train[0].count)
                        if Rand_Val == Key_Creteria || Def_Creterions.firstIndex(of: Rand_Val) != nil{
                            continue
                        }
                        Def_Creterions.append(Rand_Val)
                    }
                    let New_Tree : Tree = .init(Input_Array: Batch, Key_Creteria: Key_Creteria, Defined_Keys: Def_Creterions, Branching_Limit: Branching_Limit)
                    if New_Tree.Valid{
                        Trees_Ep += [New_Tree]
                        print("Tree Number " + String(Trees_Counter) + " on Epoch " + String(Epoch) + " created")
                        Trees_Counter += 1
                        let Obj_To_Del = min(Shuffled_Train.count, Batch_Size)
                        for _ in 1...Obj_To_Del{
                            Shuffled_Train.remove(at: Int.random(in: 0..<Shuffled_Train.count))
                        }
                    }
                }
                var Err : Double = Double.zero
                print("Calc Answer For Epoch " + String(Epoch))
                //Single Forest Variant
                if Forest_Num == nil || Forest_Num == 1{
                    for i in 0..<Shuffled_Test.count{
                        let Right_Ans = Shuffled_Test[i][Key_Creteria]
                        Shuffled_Test[i].remove(at: Key_Creteria)
                        if self.Classifier{
                            Err += equals(x: Get_Predict_Short(Input: Shuffled_Test[i], Unique_Forest: Trees_Ep), y: Right_Ans) ? Double.zero : 1.0
                        }
                        else{
                            let Ans = String(describing: Get_Predict_Short(Input: Shuffled_Test[i], Unique_Forest: Trees_Ep))
                            let Ans_Str = String(describing: Right_Ans)
                            Err += pow(Double(Ans)! - Double(Ans_Str)!, 2)/2
                        }
                    }
                }
                else{
                    var Exp_Trees : [[Tree]] = []
                    let SynqQueu = DispatchQueue(label: "...")
                    if !self.Best_Forest.isEmpty{
                        Exp_Trees.append(self.Best_Forest)
                    }
                    else{
                        let Rnd = Int.random(in: 0 ..< Trees_Ep.count)
                        Exp_Trees.append([Trees_Ep[Rnd]])
                        Trees_Ep.remove(at: Rnd)
                    }
                    DispatchQueue.concurrentPerform(iterations: Trees_Ep.count, execute: {r in
                        var Errs_Arr = Get_Errs_Mltp_Forests(Forests_Arr: Exp_Trees, Key_Creteria: Key_Creteria, Test_Set: Shuffled_Test)
                        var Trees_Too = Exp_Trees
                        for i in 0 ..< Trees_Too.count{
                            Trees_Too[i].append(Trees_Ep[r])
                        }
                        let Errs_Arr_New = Get_Errs_Mltp_Forests(Forests_Arr: Trees_Too, Key_Creteria: Key_Creteria, Test_Set: Shuffled_Test)
                        for i in 0 ..< Errs_Arr.count{
                            Errs_Arr[i] -= Errs_Arr_New[i]
                        }
                        if let Mx = Errs_Arr.max(){
                            if Mx > Double.zero{
                                let Best_Add_To = Int(Errs_Arr.firstIndex(of: Mx)!)
                                SynqQueu.sync {
                                    Exp_Trees[Best_Add_To].append(Trees_Ep[r])
                                }
                            }
                            else if Exp_Trees.count < Forest_Num!{
                                SynqQueu.sync {
                                    Exp_Trees.append([Trees_Ep[r]])
                                }
                            }
                        }
                    })
                    let Errs_Arr = Get_Errs_Mltp_Forests(Forests_Arr:  Exp_Trees, Key_Creteria: Key_Creteria, Test_Set: Shuffled_Test)
                    let Best_Trees = Int(Errs_Arr.firstIndex(of: Errs_Arr.min()!)!)
                    self.Best_Forest = Exp_Trees[Best_Trees]
                    Err = Errs_Arr[Best_Trees]
                }
                //Multiple Forests Variant
                print("Error on Epoch Number " + String(Epoch) + " is " + String(Err) + " (total), " + String(Err / Double(Shuffled_Test.count)) + " (average)")
                if Forest_Num == nil || Forest_Num == 1{
                    self.Best_Forest += Trees_Ep
                }
            }
        }
        self.Working = true
    }
    private func Get_Errs_Mltp_Forests(Forests_Arr : [[Tree]], Key_Creteria: Int, Test_Set: [[Any]]) -> [Double]{
        var Res : [Double] = .init(repeating: Double.zero, count: Forests_Arr.count)
        DispatchQueue.concurrentPerform(iterations: Forests_Arr.count, execute: {Frs in
            for i in 0 ..< Test_Set.count{
                let Right_Ans = Test_Set[i][Key_Creteria]
                var Buf_Test = Test_Set[i]
                Buf_Test.remove(at: Key_Creteria)
                if self.Classifier{
                    Res[Frs] += equals(x: Get_Predict_Short(Input: Buf_Test, Unique_Forest: Forests_Arr[Frs]), y: Right_Ans) ? Double.zero : 1.0
                }
                else{
                    let Ans = String(describing: Get_Predict_Short(Input: Buf_Test, Unique_Forest: Forests_Arr[Frs]))
                    let Ans_Str = String(describing: Right_Ans)
                    let Buf = pow(Double(Ans)! - Double(Ans_Str)!, 2) / 2
                    Res[Frs] += Buf.isNaN ? Double.zero : Buf
                }
            }
        })
        return Res
    }
    public func Get_Predict_Short(Input: [Any], Unique_Forest: [Tree] = [])->Any{
        let Ans_Unique = Get_Trees_Answers(Input: Input, Forest: Unique_Forest.isEmpty ? self.Best_Forest : Unique_Forest)
        if self.Classifier{
            let Ans_Counts = Ans_Unique[1] as! [Double]
            return Ans_Unique[0][Ans_Counts.firstIndex(of: Ans_Counts.max()!)!]
        }
        else{
            var Res : Double = Double.zero
            let Ans_Probs = Ans_Unique[1] as! [Double]
            for i in 0..<Ans_Unique[0].count{
                let buf = String(describing: Ans_Unique[0][i])
                Res += Double(buf)! * Ans_Probs[i]
            }
            return Res / Double(Ans_Probs.count)
        }
    }
    private func Get_Trees_Answers(Input: [Any], Forest : [Tree])->[[Any]]{
        var Res_Names : [Any] = []
        var Res : [Double] = []
        for Tr in Forest{
            let Buf_Res = Tr.Get_Res_Fast(Entry: Input)
            if Buf_Res.firstIndex(where: {$0 == nil}) == nil{
                if Classifier{
                    let Buf_Probs = Buf_Res[2]! as! [Double]
                    let Max_Prob = Buf_Probs.firstIndex(of: Buf_Probs.max()!)!
                    Res_Names += [Buf_Res[1]![Max_Prob]]
                    Res += [Buf_Probs[Max_Prob]]
                }
                else{
                    Res_Names += Buf_Res[1]!
                    Res += Buf_Res[2]! as! [Double]
                }
                
            }
        }
        return Count_Uniques(Names: Res_Names, Probs: Res)
    }
    private func Count_Uniques(Names: [Any], Probs: [Double])->[[Any]]{
        var Unique_Names : [Any] = []
        var Counts : [Double] = []
        var Counter_Each : [Double] = []
        for i in 0..<Names.count{
            if let Idx = Unique_Names.firstIndex(where: {equals(x: $0, y: Names[i])}){
                Counts[Idx] += Probs[i]
                Counter_Each[Idx] += 1.0
            }
            else{
                Unique_Names += [Names[i]]
                Counts.append(Probs[i])
                Counter_Each.append(1.0)
            }
        }
        if self.Classifier{
            return [Unique_Names, Counter_Each]
        }
        else{
            for i in 0..<Counts.count{
                Counts[i] /= Counter_Each[i]
            }
            return [Unique_Names, Counts]
        }
    }
}
