//
//  Environment_Basics.swift
//  Multi_Agent_1
//
//  Created by Alex Glukhov on 16.02.2024.
//

import Foundation

struct Specs : Codable{
    var Num_Of_Decks : Int
    var Base_Bet : Float
    var High_A : Bool
    var More_2_Win : Bool
    var Num_Of_Bets : Int
}
enum In_Game_Options : Int, CustomStringConvertible, CaseIterable{
    case g = 0
    case s
    case d
    case t
    var description: String{
        switch self {
        case .g:
            return "g"
        case .s:
            return "s"
        case .d:
            return "d"
        case .t:
            return "t"
        }
    }
}
struct Deck {
    private var Cards : [String]
    private var Num_Of_Decks: Int
    private var Need_Shuffle : Bool
    init(Num_Of_Decks: Int, Shuffle: Bool = true){
        self.Cards = []
        self.Num_Of_Decks = Num_Of_Decks
        self.Need_Shuffle = Shuffle
        Reset()
    }
    mutating func Reset(){
        let Buf : [[String]] = .init(repeating: ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"], count: 4 * self.Num_Of_Decks)
        self.Cards = Buf.flatMap{$0}.sorted()
        if self.Need_Shuffle{
            self.Shuffle()
        }
    }
    mutating func Shuffle(){
        self.Cards.shuffle()
    }
    mutating func Get_Card() -> String{
        let Card = self.Cards[0]
        self.Cards.removeFirst()
        return Card
    }
    mutating func Get_Start_Cards(Num_Of_Players: Int) -> [String]{
        let Res = Array(self.Cards.prefix(upTo: 2 * (Num_Of_Players + 1)))
        self.Cards.removeFirst(2 * (Num_Of_Players + 1))
        return Res
    }
    mutating func Get_Card_And_Shuffle() -> String{
        let Card = self.Get_Card()
        self.Shuffle()
        return Card
    }
    mutating func Get_Card_Points(High_A: Bool = false, Card_Received: String? = nil) -> Int{
        let Card = Card_Received ?? self.Get_Card()
        switch Card{
        case "J", "Q", "K", "10":
            return 10
        case "A":
            return High_A ? 11 : 1
        default:
            return Card.integerValue ?? 0
        }
    }
    mutating func Get_Card_Points_And_Shuffle(High_A: Bool = false, Card_Received: String? = nil) -> Int{
        let Points = self.Get_Card_Points(High_A: High_A, Card_Received: Card_Received)
        self.Shuffle()
        return Points
    }
    mutating func Get_All_Card_Points(High_A: Bool = false) -> [Int]{
        var Res : [Int] = []
        for Card in self.Cards{
            Res.append(Get_Card_Points(High_A: High_A, Card_Received: Card))
        }
        return Res
    }
    func Is_Empty()->Bool{
        return self.Cards.isEmpty
    }
    func Get_Init_Deck_Size()->Int{
        return self.Num_Of_Decks * 52
    }
    func Get_Deck_Size()->Int{
        return self.Cards.count
    }
}
struct Player{
    private var AI : Bool
    private var Logic : Policy_Tables?
    private var Base_Budget : Float
    private var Budget : Float
    private var In_Game : Bool
    private var Num_Un_Comm : Int
    private var Reward : Float
    private var Last_Inst : Int
    private var Cards : [String]
    init(Ai_Type : Int? = nil, Budget : Float, AI_File: String? = nil, Number_Of_Points: Int, Learning_Rate: Float = 0.1, Gamma: Float = 0.9, Start_Pos: Int = 0, Win_Rate: Int = 4, Num_Un_Comm: Int = 4, High_A: Bool = false, Cards: [String] = []){
        
        if let Type = Ai_Type{
            self.AI = true
            switch Type{
            case 1:
                if AI_File != nil{
                    let Dec = JSONDecoder()
                    let Url = URL(fileURLWithPath: AI_File!)
                    guard let data = try? Data(contentsOf: Url) else{
                        print("Impossible To Read File - Sarsa")
                        self.Logic = nil
                        self.AI = true
                        self.Base_Budget = 0
                        self.Budget = 0
                        self.In_Game = false
                        self.Num_Un_Comm = 0
                        self.Reward = 0
                        self.Last_Inst = -1
                        self.Cards = []
                        return
                    }
                    guard let Decd = try? Dec.decode(Sarsa.self, from: data) else{
                        print("Impossible To Decode File - Sarsa")
                        self.Logic = nil
                        self.AI = true
                        self.Base_Budget = 0
                        self.Budget = 0
                        self.In_Game = false
                        self.Num_Un_Comm = 0
                        self.Reward = 0
                        self.Last_Inst = -1
                        self.Cards = []
                        return
                    }
                    self.Logic = Decd
                    self.Logic!.reinit_pos(First_Cards: Start_Pos, Win_Rate: Win_Rate)
                }
                else{
                    self.Logic = Sarsa(Number_Of_Points: Number_Of_Points, Learning_Rate: Learning_Rate, Gamma: Gamma, Start_Pos: Start_Pos, Win_Rate: Win_Rate, Num_Un_Comm: Num_Un_Comm, High_A: High_A)
                }
            case 2:
                if AI_File != nil{
                    let Dec = JSONDecoder()
                    let Url = URL(fileURLWithPath: AI_File!)
                    guard let data = try? Data(contentsOf: Url) else{
                        print("Impossible To Read File - Exp_Sarsa")
                        self.Logic = nil
                        self.AI = true
                        self.Base_Budget = 0
                        self.Budget = 0
                        self.In_Game = false
                        self.Num_Un_Comm = 0
                        self.Reward = 0
                        self.Last_Inst = -1
                        self.Cards = []
                        return
                    }
                    guard let Decd = try? Dec.decode(Exp_Sarsa.self, from: data) else{
                        print("Impossible To Decode File - Exp_Sarsa")
                        self.Logic = nil
                        self.AI = true
                        self.Base_Budget = 0
                        self.Budget = 0
                        self.In_Game = false
                        self.Num_Un_Comm = 0
                        self.Reward = 0
                        self.Last_Inst = -1
                        self.Cards = []
                        return
                    }
                    self.Logic = Decd
                    self.Logic!.reinit_pos(First_Cards: Start_Pos, Win_Rate: Win_Rate)
                }
                else{
                    self.Logic = Exp_Sarsa(Number_Of_Points: Number_Of_Points, Learning_Rate: Learning_Rate, Gamma: Gamma, Start_Pos: Start_Pos, Win_Rate: Win_Rate, Num_Un_Comm: Num_Un_Comm, High_A: High_A)
                }
            default:
                if AI_File != nil{
                    let Dec = JSONDecoder()
                    let Url = URL(fileURLWithPath: AI_File!)
                    guard let data = try? Data(contentsOf: Url) else{
                        print("Impossible To Read File - Q_Learn")
                        self.Logic = nil
                        self.AI = true
                        self.Base_Budget = 0
                        self.Budget = 0
                        self.In_Game = false
                        self.Num_Un_Comm = 0
                        self.Reward = 0
                        self.Last_Inst = -1
                        self.Cards = []
                        return
                    }
                    guard let Decd = try? Dec.decode(Q_Learn.self, from: data) else{
                        print("Impossible To Decode File - Q_Learn")
                        self.Logic = nil
                        self.AI = true
                        self.Base_Budget = 0
                        self.Budget = 0
                        self.In_Game = false
                        self.Num_Un_Comm = 0
                        self.Reward = 0
                        self.Last_Inst = -1
                        self.Cards = []
                        return
                    }
                    self.Logic = Decd
                    self.Logic!.reinit_pos(First_Cards: Start_Pos, Win_Rate: Win_Rate)
                }
                else{
                    self.Logic = Q_Learn(Number_Of_Points: Number_Of_Points, Learning_Rate: Learning_Rate, Gamma: Gamma, Start_Pos: Start_Pos, Win_Rate: Win_Rate, Num_Un_Comm: Num_Un_Comm, High_A: High_A)
                }
            }
        }
        else{
            self.AI = false
        }
        self.Budget = Budget
        self.Base_Budget = Budget
        self.In_Game = true
        self.Num_Un_Comm = Num_Un_Comm
        self.Reward = Float.zero
        self.Last_Inst = -1
        self.Cards = Cards
        if let Type = Ai_Type{
            self.Last_Inst = Type == 1 ? self.policy(State: self.Logic!.Curr_State, Eps: 0.001) : -1
        }
    }
    private func policy(State: Int, Eps: Float) -> Int{
        if Float.random(in: 0.0 ... 1.0) > Eps{
            return Int.random(in: 0 ..< self.Num_Un_Comm)
        }
        return self.Logic!.get_inst(State: State)
    }
    public mutating func update_table(Reward_Rec: Float, New_Card: String, New_Pts: Int, Win_Rate: Int = 4, Eps: Float, Cmd_Fail: Bool = false){
        self.Cards.append(New_Card)
        if Cmd_Fail{
            self.Last_Inst = 0
        }
        if Logic != nil{
            if Logic!.Init_Win(){
                Logic!.Init_Win_Restate()
            }
            if let Method_Raw = Logic!.rawValue{
                let New_State = (self.Logic!.Curr_Sum + New_Pts) * 10 + Win_Rate
                let Next_Inst_Code = self.policy(State: New_State, Eps: Eps)
                if New_State != self.Logic!.Curr_State || New_Card == "Dummy"{
                    self.Reward += Reward_Rec
                    self.Logic!.update_table(Inst_Code: self.Last_Inst, Reward_Rec: self.Reward, New_Card: New_Pts, Win_Rate: Win_Rate, Next_Inst_Code: Next_Inst_Code, Eps: Eps)
                    if Method_Raw == 1{
                        self.Last_Inst = Next_Inst_Code
                    }
                }
            }
            else{
                print("Impossible to train 'cause wrong 'rawValue' of training method received.")
            }
        }
        else{
            print("Impossible to train 'cause wrong 'rawValue' of training method received.")
        }
    }
    public mutating func generate_command(Eps: Float) -> Int{
        if Logic != nil{
            if let Method_Raw = Logic!.rawValue{
                if Method_Raw == 1{
                    return self.Last_Inst
                }
                else{
                    let Res = self.policy(State: Logic!.Curr_State, Eps: Eps)
                    self.Last_Inst = Res
                    return Res
                }
            }
            else{
                print("Impossible to generate command, since wrong training method 'rawValue' was used.")
            }
        }
        else{
            print("Impossible to generate command, since wrong training method 'rawValue' was used.")
        }
        return 0
    }
    public mutating func match_reset_dealer(First_Cards: [String], Total_Loss: Float, Base_Bet: Float){
        self.Cards = First_Cards
        self.Budget += Total_Loss
        self.In_Game = Budget >= Base_Bet
    }
    public mutating func match_reset(First_Cards: [String], First_Pts: Int, Win_Rate: Int = 4, Eps: Float = 1, Dlr_Loss: Float = 0, Base_Bet: Float){
        self.Cards = First_Cards
        if Logic != nil{
            if let Method_Raw = Logic!.rawValue{
                self.Budget -= Dlr_Loss
                self.Reward = 0
                self.In_Game = Budget >= Base_Bet
                self.Logic!.Curr_Sum = max(First_Pts - (self.Logic!.High_A ? 2 : 1), 0)
                self.Logic!.Curr_State = max(First_Pts * 10 + Win_Rate, 0)
                if Method_Raw == 1 && Eps != 1{
                    self.Last_Inst = policy(State: self.Logic!.Curr_State, Eps: Eps)
                }
                else{
                    self.Last_Inst = -1
                }
            }
            else{
                print("Impossible to reset unknown training method!")
            }
        }
        else{
            self.Budget -= Dlr_Loss
            self.In_Game = Budget >= Base_Bet
        }
    }
    public mutating func deep_reset(First_Cards: [String], First_Pts: Int, Win_Rate: Int = 4, Eps: Float = 1){
        self.Cards = First_Cards
        self.In_Game = true
        self.Budget = self.Base_Budget
        if Logic != nil{
            if let Method_Raw = Logic!.rawValue{
                self.Reward = 0
                self.Logic!.Curr_Sum = First_Pts - (self.Logic!.High_A ? 2 : 1)
                self.Logic!.Curr_State = First_Pts * 10 + Win_Rate
                if Method_Raw == 1 && Eps != 1{
                    self.Last_Inst = policy(State: self.Logic!.Curr_State, Eps: Eps)
                }
                else{
                    self.Last_Inst = -1
                }
            }
            else{
                print("Impossible to reset unknown training method!")
            }
        }
    }
    public func get_inst() -> Int{
        if Logic != nil{
            return Logic!.get_inst(State: Logic!.Curr_State)
        }
        else{
            let Pick = Inp_String(Show_Cont: "\n\tWhat You Wanna Do? (g - 🆕 card 💪🏾, s - stay 🤡, d - ⏩ bet 🤯, t - ⏭ bet 🤑): ", Show_Warn: "Wrong Option was Entered, Try Again...", Pos_Values: ["g", "s", "d", "t"])
            switch Pick{
            case "g":
                return 0
            case "s":
                return 1
            case "d":
                return 2
            case "t":
                return 3
            default:
                return -1
            }
        }
    }
    public mutating func update_state(New_Card_Val: Int, New_Card: String, Win_Rate: Int = 4) {
        self.Cards.append(New_Card)
        if Logic != nil{
            self.Logic!.Curr_State = (self.Logic!.Curr_Sum + New_Card_Val) * 10 + Win_Rate
            self.Logic!.Curr_Sum += New_Card_Val
            
        }
    }
    public func Get_Cards()-> [String]{
        return self.Cards
    }
    public func In_Game_Now()-> Bool{
        return self.In_Game
    }
    public mutating func Leave_Game(){
        self.In_Game = false
    }
    public func Get_Budget()->Float{
        return self.Budget
    }
    public func Save_Logic(f_name: String, Plr_Num: Int){
        if Logic != nil{
            let Enc = JSONEncoder()
            var Type = ""
            switch Logic!.rawValue{
            case 0:
                Type = "QLearn"
            case 1:
                Type = "Sarsa"
            case 2:
                Type = "Exp_Sarsa"
            default:
                Type = ""
            }
            guard let Encd = try? Enc.encode(Logic!) else{
                print("Error During Encoding Process(Save Logic)")
                return
            }
            let Url = URL(fileURLWithPath: f_name + Type + "_" + String(Plr_Num) + ".json")
            do{
                try Encd.write(to: Url)
            }
            catch{
                print("Error During Writing Process(Save Logic)")
            }
        }
        else{
            print("Error, Impossible to Save Real Players Model!(Save Logic)")
        }
    }
    public func Get_Base_Budget()->Float{
        return self.Base_Budget
    }
    public func Init_Win()->Bool{
        if Logic != nil{
            return Logic!.Init_Win()
        }
        else{
            print("Impossible to Check for Real Person!")
            return false
        }
    }
}
