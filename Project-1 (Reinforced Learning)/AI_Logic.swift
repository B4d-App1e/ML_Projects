//
//  AI_Logic.swift
//  Multi_Agent_1
//
//  Created by Alex Glukhov on 18.02.2024.
//

import Foundation

class Policy_Tables : Codable{
    var rawValue : Int?
    var Table: [[Float]]
    var Rate: Float
    var Gamma: Float
    var Curr_State: Int
    var Curr_Sum : Int
    var High_A : Bool
    init(){
        self.Table = []
        self.Rate = Float.zero
        self.Gamma = Float.zero
        self.Curr_State = 0
        self.High_A = false
        self.Curr_Sum = 0
    }
    init(Number_Of_Points: Int, Learning_Rate: Float, Gamma: Float  = 0.9, Start_Pos: Int = 2, Win_Rate: Int = 4, Num_Un_Comm: Int = 4, High_A: Bool = false) {
        self.Table = .init(repeating: .init(repeating: Float.zero, count: Num_Un_Comm), count: Number_Of_Points * 3 * 10)
        self.Rate = Learning_Rate
        self.Gamma = Gamma
        if Win_Rate != -1{
            self.Curr_State = (Start_Pos - (High_A ? 2 : 1)) * 10 + Win_Rate
        }
        else{
            self.Curr_State = -1
        }
        self.Curr_Sum = Start_Pos - (High_A ? 2 : 1)
        self.High_A = High_A
    }
    
    func update_table(Inst_Code: Int, Reward_Rec: Float, New_Card: Int, Win_Rate: Int, Next_Inst_Code: Int, Eps: Float) {
        return
    }
    
    func get_inst(State: Int?) -> Int {
        var Pos = Curr_State
        if State != nil{
            Pos = State!
        }
        let Mx_Val = self.Table[Pos].max()!
        var Buf = Int(self.Table[Pos].firstIndex(of: Mx_Val)!)
        if self.Table[Pos].firstIndex(of: Mx_Val) != self.Table[Pos].lastIndex(of: Mx_Val){
            var Mx_Num : [Int] = []
            for i in 0..<self.Table[Pos].count{
                let b_t = self.Table[Pos][i]
                if  b_t == Mx_Val{
                    Mx_Num.append(i)
                }
            }
            Buf = Mx_Num[Int.random(in: 0 ..< Mx_Num.count)]
        }
        return Buf
    }
    
    func update_pos(New_Card: Int, Win_Rate: Int) {
        self.Curr_Sum += New_Card
        self.Curr_State = Curr_Sum * 10 + Win_Rate
    }
    
    func reinit_pos(First_Cards:Int, Win_Rate: Int){
        self.Curr_Sum = First_Cards - (High_A ? 2 : 1)
        if Win_Rate != -1{
            self.Curr_State = Curr_Sum * 10 + Win_Rate
        }
        else{
            self.Curr_State = -1
        }
    }
    
    func normalize_table() {
        for i in 0 ..< self.Table.count{
            let Min_V = self.Table[i].min()!
            let Max_V = self.Table[i].max()! + (Min_V > 0 ? -1 * Min_V : Min_V)
            for j in 0 ..< self.Table[0].count{
                self.Table[i][j] = (self.Table[i][j] + (Min_V > 0 ? -1 * Min_V : Min_V)) / Max_V
            }
        }
    }
    func Get_Cards_Pts()->Int{
        return self.Curr_Sum
    }
    func Init_Win()->Bool{
        return self.Curr_State == -1
    }
    func Init_Win_Restate(){
        self.Curr_State = Curr_Sum * 10
    }
}
final class Q_Learn : Policy_Tables{
    override init(Number_Of_Points: Int, Learning_Rate: Float, Gamma: Float = 0.9, Start_Pos: Int = 0, Win_Rate: Int = 4, Num_Un_Comm: Int = 4, High_A: Bool = false) {
        super.init(Number_Of_Points: Number_Of_Points, Learning_Rate: Learning_Rate, Gamma: Gamma, Start_Pos: Start_Pos, Win_Rate: Win_Rate, Num_Un_Comm: Num_Un_Comm, High_A: High_A)
        self.rawValue = 0
    }
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    override func update_table(Inst_Code: Int, Reward_Rec: Float, New_Card: Int, Win_Rate: Int, Next_Inst_Code : Int, Eps : Float) {
        let Ns = (self.Curr_Sum + New_Card) * 10 + Win_Rate
        if Ns < Table.count && Inst_Code < Table[0].count{
            let Max_Val = Table[Ns].max()!
            self.Table[self.Curr_State][Inst_Code] += self.Rate * (Reward_Rec + self.Gamma * Max_Val - self.Table[self.Curr_State][Inst_Code])
            self.Curr_State = Ns
            self.Curr_Sum += New_Card
        }
        else{
            print("Incorrect Instruction Received")
        }
    }
}
final class Sarsa : Policy_Tables{
    override init(Number_Of_Points: Int, Learning_Rate: Float, Gamma: Float = 0.9, Start_Pos: Int = 0, Win_Rate: Int = 4, Num_Un_Comm: Int = 4, High_A: Bool = false) {
        super.init(Number_Of_Points: Number_Of_Points, Learning_Rate: Learning_Rate, Gamma: Gamma, Start_Pos: Start_Pos, Win_Rate: Win_Rate, Num_Un_Comm: Num_Un_Comm, High_A: High_A)
        self.rawValue = 1
    }
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    override func update_table(Inst_Code: Int, Reward_Rec: Float, New_Card: Int, Win_Rate: Int, Next_Inst_Code : Int, Eps : Float) {
        let Ns = (self.Curr_Sum + New_Card) * 10 + Win_Rate
        if Ns < Table.count && Inst_Code < Table[0].count && Next_Inst_Code < Table[0].count{
            self.Table[self.Curr_State][Inst_Code] += self.Rate * (Reward_Rec + self.Gamma * self.Table[Ns][Next_Inst_Code] - self.Table[self.Curr_State][Inst_Code])
            self.Curr_State = Ns
            self.Curr_Sum += New_Card
        }
        else{
            print("Incorrect Instruction Received")
        }
    }
}
final class Exp_Sarsa : Policy_Tables{
    override init(Number_Of_Points: Int, Learning_Rate: Float, Gamma: Float = 0.9, Start_Pos: Int = 0, Win_Rate: Int = 4, Num_Un_Comm: Int = 4, High_A: Bool = false) {
        super.init(Number_Of_Points: Number_Of_Points, Learning_Rate: Learning_Rate, Gamma: Gamma, Start_Pos: Start_Pos, Win_Rate: Win_Rate, Num_Un_Comm: Num_Un_Comm, High_A: High_A)
        self.rawValue = 2
    }
    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    override func update_table(Inst_Code: Int, Reward_Rec: Float, New_Card: Int, Win_Rate: Int, Next_Inst_Code : Int, Eps : Float) {
        let Ns = (self.Curr_Sum + New_Card) * 10 + Win_Rate
        if Ns < Table.count && Inst_Code < Table[0].count{
            var Exp_Q : Float = Float.zero
            var G_Act : Int = 0
            let Q_Max = self.Table[Ns].max()!
            for i in 0 ..< self.Table[Ns].count{
                if self.Table[Ns][i] == Q_Max{
                    G_Act += 1
                }
            }
            let Non_G_Prob : Float = Eps / Float(self.Table[Ns].count)
            let G_Prob : Float = (1.0 - Eps) / Float(G_Act) + Non_G_Prob
            for i in 0 ..< self.Table[Ns].count{
                if self.Table[Ns][i] == Q_Max{
                    Exp_Q += self.Table[Ns][i] * G_Prob
                }
                else{
                    Exp_Q += self.Table[Ns][i] * Non_G_Prob
                }
            }
            self.Table[self.Curr_State][Inst_Code] += self.Rate * (Reward_Rec + self.Gamma * Exp_Q - self.Table[self.Curr_State][Inst_Code])
            self.Curr_State = Ns
            self.Curr_Sum += New_Card
        }
        else{
            print("Incorrect Instruction Received")
        }
    }
}
