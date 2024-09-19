//
//  main.swift
//  Multi_Agent_1
//
//  Created by Alex Glukhov on 15.02.2024.
//

import Foundation

class Black_Jack{
    private var Play_Deck : Deck
    private var Dealer : Player
    private var Players : [Player]
    private var High_A : Bool
    private var Base_Bet : Float
    private var Players_Bets : [Int]
    private var More_2_Win : Bool
    //VV init for learning
    init(Num_Of_Decks: Int, AI_Types: [Int], Base_Bet: Float, Num_Of_Bets: Int = 10, Saving_Path: String, Number_Of_Points: Int = 10, Learning_Rate: Float = 0.1, Eps_Start : Float = 0.001, Eps_Finish : Float = 1, High_A: Bool = false, Epochs_Count:Int = 1000, Episode_Lim: Int = 10, Gamma: Float = 0.9, More_2_Win: Bool = true){
        self.Play_Deck = .init(Num_Of_Decks: Num_Of_Decks)
        self.Dealer = .init(Budget: Base_Bet * Float(Num_Of_Bets) * Float(AI_Types.count), Number_Of_Points: Number_Of_Points)
        self.Players = []
        self.High_A = High_A
        self.Base_Bet = Base_Bet
        self.Players_Bets = .init(repeating: 1, count: AI_Types.count)
        self.More_2_Win = More_2_Win
        match_reset(Init: true, Num_Players: AI_Types.count, Number_Of_Points: Number_Of_Points, Learning_Rate: Learning_Rate, Gamma: Gamma, Num_Of_Bets: Num_Of_Bets, AI_Types: AI_Types)
        Learning(Eps_Start: Eps_Start, Eps_Finish: Eps_Finish, Epochs_Count: Epochs_Count, Episode_Lim: Episode_Lim, Saving_Path: Saving_Path)
    }
    //VV init for playing solo
    init(Num_Of_Decks: Int, Base_Bet: Float, Num_Of_Bets: Int = 10, High_A: Bool = false, More_2_Win: Bool = true, Max_Rounds: Int = 666){
        self.Play_Deck = .init(Num_Of_Decks: Num_Of_Decks)
        self.Dealer = .init(Budget: Base_Bet * Float(Num_Of_Bets), Number_Of_Points: 10)
        self.Players = []
        self.High_A = High_A
        self.Base_Bet = Base_Bet
        self.Players_Bets = .init(repeating: 1, count: 1)
        self.More_2_Win = More_2_Win
        match_reset(Play_Init: true, Num_Players: 0, Num_Of_Bets: Num_Of_Bets)
        Play(Max_Rounds: Max_Rounds)
    }
    //VV init for playing with bots
    init(Saves_Path: String, Max_Rounds: Int = 666){
        self.Play_Deck = .init(Num_Of_Decks: 0)
        self.Dealer = .init(Budget: 0, Number_Of_Points: 0)
        self.Players = []
        self.High_A = false
        self.Base_Bet = 0
        self.Players_Bets = []
        self.More_2_Win = false
        let AI_Files = Get_Saves_Names(Saves_Path: Saves_Path)
        let Ai_Types = Get_Ai_Types(AI_Files: AI_Files)
        let Specs_Path = Get_Saves_Names(Saves_Path: Saves_Path, Specs: true)
        if AI_Files.count != 0 && AI_Files.count == Ai_Types.count && Specs_Path.count == 1{
            let Dec = JSONDecoder()
            let Url = URL(fileURLWithPath: Specs_Path[0])
            guard let data = try? Data(contentsOf: Url) else{
                print("Impossible to Read Specs File")
                return
            }
            guard let Decd_Specs = try? Dec.decode(Specs.self, from: data) else{
                print("Impossible to Decode Specs File")
                return
            }
            self.Play_Deck = .init(Num_Of_Decks: Decd_Specs.Num_Of_Decks)
            self.Dealer = .init(Budget: Decd_Specs.Base_Bet * Float(Decd_Specs.Num_Of_Bets) * Float(AI_Files.count + 1), Number_Of_Points: 10)
            self.High_A = Decd_Specs.High_A
            self.Base_Bet = Decd_Specs.Base_Bet
            self.Players_Bets = .init(repeating: 1, count: AI_Files.count + 1)
            self.More_2_Win = Decd_Specs.More_2_Win
            match_reset(Play_Init: true, Num_Players: AI_Files.count, Num_Of_Bets: Decd_Specs.Num_Of_Bets, AI_Types: Ai_Types, AI_Files: AI_Files)
            Play(Max_Rounds: Max_Rounds)
        }
        else{
            print("Directory Doesn't Contains AI Files or Specs, Try Another One")
        }
    }
    private func Get_Saves_Names(Saves_Path: String, Specs: Bool = false) -> [String]{
        let fm = FileManager.default
        var Res : [String] = []
        do{
            let items = try fm.contentsOfDirectory(atPath: Saves_Path)
            for item in items {
                if item != ".DS_Store"{
                    if Specs && item.contains("Specs.json"){
                        return [Saves_Path + item]
                    }
                    else if item.contains("QLearn") || item.contains("Sarsa") || item.contains("Exp_Sarsa"){
                        Res.append(Saves_Path + item)
                    }
                }
            }
        }
        catch{
            print("Error During Reading Files(Get_Saves_Names)")
        }
        return Res
    }
    private func Get_Ai_Types(AI_Files: [String]) -> [Int]{
        var Res : [Int] = []
        for AI_File in AI_Files {
            if AI_File.contains("QLearn"){
                Res.append(0)
            }
            else if AI_File.contains("Exp_Sarsa"){
                Res.append(2)
            }
            else{
                Res.append(1)
            }
        }
        return Res
    }
    private func Win_Rate_Counter(Player_Cards: [String], Dealer_Median: Float, Dealer_Hidden_Pts: Int, Playing: Bool = true) -> Int{
        let More_Add = self.More_2_Win ? 0 : -1
        let Player_Points = self.Points_Counter(Cards: Player_Cards)
        if Player_Points >= 21{
            return -1
        }
        else if Player_Points < 12 && !self.High_A || Player_Points < 11 && self.High_A{
            return 9
        }
        let All_Pos_Points = self.Play_Deck.Get_All_Card_Points(High_A: self.High_A) + [Dealer_Hidden_Pts]
        let Avg_Card = Get_Median(Inp: All_Pos_Points.sorted())
        let Player_Sums = Sums_Counter(Curr_Pts: Player_Points, All_Pos_Pts: All_Pos_Points, Max_Mooves: self.High_A && Playing ? 2 : 3, Dealer_Median: Dealer_Median, Avg_Card: Avg_Card).sorted()
        if Player_Sums.isEmpty{
            return -1
        }
        let Player_Median = Get_Median(Inp: Player_Sums)
        if 34 >= self.Play_Deck.Get_Deck_Size(){
            if Dealer_Median > 21 && Player_Median <= 21{
                return 9
            }
            else if Player_Sums.min()! > 21{
                return -1
            }
            else{
                if Dealer_Median > 21{
                    if let Win_Idx = Player_Sums.lastIndex(where: {Float($0) < Dealer_Median - Float(More_Add)}){
                        let Win_Rt = (Float(Player_Sums.distance(to: Win_Idx)) / Float(Player_Sums.count)) * 10
                        return Int(Win_Rt.rounded()) - 1
                    }
                    else{
                        return -1
                    }
                }
                else if Dealer_Median < 21{
                    if let First_Win_Idx = Player_Sums.firstIndex(where: {Float($0) - Float(More_Add) > Dealer_Median}){
                        if let Last_Win_Idx = Player_Sums.lastIndex(where: {Float($0) < 22}){
                            let Win_Rt = (Float(Player_Sums.distance(from: First_Win_Idx, to: Last_Win_Idx)) / Float(Player_Sums.count)) * 10
                            return Int(Win_Rt.rounded()) - 1
                        }
                        else{
                            let Win_Rt = (Float(Player_Sums.distance(from: First_Win_Idx, to: Player_Sums.count - 1)) / Float(Player_Sums.count)) * 10
                            return Int(Win_Rt.rounded()) - 1
                        }
                    }
                    else{
                        return -1
                    }
                }
                else{
                    let Sums_Filter = Player_Sums.filter {$0 == 21}
                    let Win_Rt = (Float(Sums_Filter.count) / Float(Player_Sums.count)) * 10
                    return Int(Win_Rt.rounded()) - 1
                }
            }
        }
        else if 104 > self.Play_Deck.Get_Deck_Size(){
            if Player_Sums.firstIndex(where: {$0 > 21}) == nil{
                return 9
            }
            else if Player_Sums.firstIndex(where: {$0 < 22}) == nil{
                return -1
            }
            else if let Last_Win_Idx = Player_Sums.lastIndex(where: {Float($0) < 22}){
                let Win_Rt = (Float(Player_Sums.distance(to: Last_Win_Idx)) / Float(Player_Sums.count)) * 10
                return Int(Win_Rt.rounded()) - 1
            }
            return -1
        }
        else{
            if Float(Player_Points) + Avg_Card < 21{
                return 9
            }
            else if Float(Player_Points) + Avg_Card == 21{
                return 4
            }
            else if Float(Player_Points) + Avg_Card < Dealer_Median{
                return 2
            }
            else{
                return 0
            }
        }
    }
    //VV
    private func Sums_Counter(Curr_Pts: Int, All_Pos_Pts: [Int], Max_Mooves: Int = 2, Curr_Mooves: Int = 1, For_Dealer: Bool = false, Dealer_Median: Float = Float.zero, Avg_Card: Float = Float.zero) -> [Int]{
        var Res : [Int] = []
        if All_Pos_Pts.isEmpty || Curr_Mooves > Max_Mooves{
            return []
        }
        for i in 0 ..< All_Pos_Pts.count{
            var Pos_Copy = All_Pos_Pts
            let N_Val = Curr_Pts + Pos_Copy[i]
            Pos_Copy.remove(at: i)
            if !For_Dealer && N_Val < min(Int(Dealer_Median - Avg_Card), 21){
                Res += [N_Val] + Sums_Counter(Curr_Pts: N_Val, All_Pos_Pts: Pos_Copy, Max_Mooves: Max_Mooves, Curr_Mooves: Curr_Mooves + 1, For_Dealer: For_Dealer, Dealer_Median: Dealer_Median, Avg_Card: Avg_Card)
            }
            else if For_Dealer && N_Val < 17{
                Res += Sums_Counter(Curr_Pts: N_Val, All_Pos_Pts: Pos_Copy, Max_Mooves: Max_Mooves, Curr_Mooves: Curr_Mooves + 1, For_Dealer: For_Dealer, Dealer_Median: Dealer_Median, Avg_Card: Avg_Card)
            }
            else if (For_Dealer && N_Val >= 17) || (!For_Dealer && N_Val >= min(Int(Dealer_Median - Avg_Card), 21)){
                Res += [N_Val]
            }
        }
        return Res
    }
    //VV
    private func Points_Counter(Cards: [String]) -> Int{
        var Points : Int = 0
        for Val in Cards{
            Points += self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Val)
        }
        return Points
    }
    //VV
    private func Get_Median(Inp: [Int]) -> Float{
        let Inp_Sorted = Inp.sorted()
        if Inp_Sorted.count % 2 == 0{
            return Float(Inp_Sorted[Inp_Sorted.count / 2] + Inp_Sorted[Inp_Sorted.count / 2 - 1]) / 2
        }
        else{
            return Float(Inp_Sorted[(Inp_Sorted.count - 1) / 2])
        }
    }
    private func Learning(Eps_Start: Float, Eps_Finish: Float, Epochs_Count: Int, Episode_Lim: Int, Saving_Path: String){
        let Decay = expf(logf(Eps_Finish / Eps_Start) / Float(Episode_Lim * Epochs_Count))
        var Eps = Eps_Start
        for Epoch_c in 0 ..< Epochs_Count{
            var Rounds_Survived : [Int] = .init(repeating: 0, count: self.Players.count)
            for Episode_c in 0 ..< Episode_Lim{
                if !self.Dealer.In_Game_Now(){
                    break
                }
                var Dead_Plrs = 0
                for i in 0 ..< self.Players.count{
                    let Plr_Pts = Points_Counter(Cards: self.Players[i].Get_Cards())
                    if Plr_Pts == 0{
                        Dead_Plrs += 1
                    }
                }
                if Dead_Plrs == self.Players.count{
                    break
                }
                var Leave_Cards : [String] = .init(repeating: "A", count: self.Players.count)
                let Dealer_Cards = self.Dealer.Get_Cards()
                let Shown_Card_Pts = self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Dealer_Cards[0])
                let Hidden_Card_Pts = self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Dealer_Cards[1])
                while true{
                    var Game_End: Bool = true
                    if self.Play_Deck.Is_Empty(){
                        break
                    }
                    for i in 0 ..< self.Players.count{
                        if self.Players[i].In_Game_Now(){
                            if self.Players[i].Init_Win(){
                                self.Players[i].Leave_Game()
                                Leave_Cards[i] = "Dummy"
                            }
                            else{
                                Game_End = false
                                let Inst_Code = self.Players[i].generate_command(Eps: Eps)
                                if Inst_Code == 1{
                                    self.Players[i].Leave_Game()
                                    Leave_Cards[i] = "Dummy"
                                }
                                else{
                                    let New_Card = self.Play_Deck.Get_Card()
                                    let Dealer_Sums = Sums_Counter(Curr_Pts: Shown_Card_Pts, All_Pos_Pts: self.Play_Deck.Get_All_Card_Points(High_A: self.High_A) + [Hidden_Card_Pts], Max_Mooves: self.High_A ? 2 : 3, For_Dealer: true)
                                    let Dealer_Median = Get_Median(Inp: Dealer_Sums)
                                    var Wn_Rate = Win_Rate_Counter(Player_Cards: self.Players[i].Get_Cards() + [New_Card], Dealer_Median: Dealer_Median, Dealer_Hidden_Pts: Hidden_Card_Pts)
                                    var Bad_Cmd = false
                                    if (Inst_Code == 2 || Inst_Code == 3) && Float(self.Players_Bets[i] + Inst_Code) * self.Base_Bet > self.Players[i].Get_Budget(){
                                        Bad_Cmd = true
                                    }
                                    else if (Inst_Code == 2 || Inst_Code == 3){
                                        self.Players_Bets[i] += Inst_Code
                                    }
                                    if Wn_Rate == -1{
                                        Wn_Rate = 4
                                        self.Players[i].Leave_Game()
                                        Leave_Cards[i] = New_Card
                                    }
                                    if self.Players[i].In_Game_Now(){
                                        self.Players[i].update_table(Reward_Rec: 0, New_Card: New_Card, New_Pts: self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: New_Card),Win_Rate: Wn_Rate, Eps: Eps, Cmd_Fail: Bad_Cmd)
                                    }
                                }
                            }
                        }
                    }
                    if Game_End{
                        break
                    }
                }
                var Dlr_Pts = Shown_Card_Pts + Hidden_Card_Pts
                while Dlr_Pts < 17{
                    if self.Play_Deck.Is_Empty(){
                        break
                    }
                    Dlr_Pts += self.Play_Deck.Get_Card_Points(High_A: self.High_A)
                }
                var Dlr_Loss : [Float] = []
                for i in 0 ..< self.Players.count{
                    if self.Players[i].Get_Budget() < self.Base_Bet{
                        Dlr_Loss.append(Float.zero)
                        continue
                    }
                    let Pts : Int = Points_Counter(Cards: Players[i].Get_Cards())
                    var Reward : Float
                    if (Pts > Dlr_Pts && Pts <= 21) || (Dlr_Pts > 21 && Pts < Dlr_Pts){
                        Reward = self.Base_Bet * Float(self.Players_Bets[i])
                    }
                    else if !self.More_2_Win && (Pts == Dlr_Pts){
                        Reward = self.Base_Bet * Float(self.Players_Bets[i]) * 0.5
                    }
                    else{
                        Reward = -1 * self.Base_Bet * Float(self.Players_Bets[i])
                    }
                    Dlr_Loss.append(-1 * Reward)
                    if self.Players[i].Get_Budget() + Reward >= self.Base_Bet{
                        Rounds_Survived[i] += 1
                    }
                    if Reward < 0{
                        self.Players[i].update_table(Reward_Rec: Reward / max(0.5, Float(Rounds_Survived[i])) * fabsf(Reward / self.Players[i].Get_Budget()), New_Card: Leave_Cards[i], New_Pts: self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Leave_Cards[i]), Eps: Eps)
                    }
                    else{
                        self.Players[i].update_table(Reward_Rec: Reward * max(0.5, Float(Rounds_Survived[i])) / Float(Episode_Lim) * fabsf(Reward / self.Players[i].Get_Budget()), New_Card: Leave_Cards[i], New_Pts: self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Leave_Cards[i]), Eps: Eps)
                    }
                }
                var Ep_C = String(Episode_c)
                if Ep_C.count == 1{
                    Ep_C = "0" + Ep_C
                }
                print("\t" + Ep_C + " Episode On " + String(Epoch_c) + " Epoch Done")
                match_reset(Num_Players: self.Players.count, Dealer_Loss: Dlr_Loss, Eps: Eps)
            }
            if Eps < Eps_Finish{
                Eps *= Decay
            }
            print(String(Epoch_c) + " Epoch Done")
            deep_reset(Eps: Eps)
        }
        Save_Models(Save_Path: Saving_Path)
    }
    private func Save_Models(Save_Path: String){
        let Folder_Name = fileNameCrt() + "/"
        let Url = URL(fileURLWithPath: Save_Path + Folder_Name)
        do{
            try FileManager.default.createDirectory(at: Url, withIntermediateDirectories: true)
            Save_Spec(Save_Path: Save_Path + Folder_Name)
            for i in 0 ..< Players.count {
                Players[i].Save_Logic(f_name: Save_Path + Folder_Name, Plr_Num: i)
            }
        }
        catch{
            print("Unable to Create Folder For Saving Files")
        }
    }
    private func Save_Spec(Save_Path: String){
        let Specs_C = Specs(Num_Of_Decks: self.Play_Deck.Get_Init_Deck_Size() / 52, Base_Bet: self.Base_Bet, High_A: self.High_A, More_2_Win: self.More_2_Win, Num_Of_Bets: Int(self.Players[0].Get_Base_Budget() / self.Base_Bet))
        let Enc = JSONEncoder()
        guard let Encd = try? Enc.encode(Specs_C) else{
            print("Error During Encoding Process(Save Specs)")
            return
        }
        let Url = URL(fileURLWithPath: Save_Path + "Specs.json")
        do{
            try Encd.write(to: Url)
        }
        catch{
            print("Error During Saving Process(Save Specs)")
        }
    }
    private func Emoji_Cards(Inp: String) -> String{
        switch Inp{
        case "2":
            return "2️⃣"
        case "3":
            return "3️⃣"
        case "4":
            return "4️⃣"
        case "5":
            return "5️⃣"
        case "6":
            return "6️⃣"
        case "7":
            return "7️⃣"
        case "8":
            return "🎱"
        case "9":
            return "9️⃣"
        case "10":
            return "🔟"
        case "J":
            return "👶🏾"
        case "Q":
            return "👸🏼"
        case "K":
            return "🤴🏻"
        default:
            return "🅰️"
        }
    }
    private func Nums_To_Emojis(Num: Int) -> String{
        var Res = ""
        let Buf = String(Num)
        for Dig in Buf{
            Res += Emoji_Cards(Inp: String(Dig))
        }
        return Res
    }
    public func Play(Max_Rounds: Int){
        var Exit_Game : Bool = false
        while !Exit_Game{
            var Game_Over : Bool = false
            var Rounds_Survived : [Int] = .init(repeating: 0, count: self.Players.count)
            print("\n\n\n🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨 New 🕹 🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨")
            while !Game_Over{
                print("\n\n\t💙💙💙💙💙💙💙💙💙💙 Next 🔔 💙💙💙💙💙💙💙💙💙💙")
                let Dealer_Cards = self.Dealer.Get_Cards()
                let Shown_Card_Pts = self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Dealer_Cards[0])
                let Hidden_Card_Pts = self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Dealer_Cards[1])
                var Time_On : Bool = true
                var Leaved_Players : Int = 0
                while Time_On{
                    if Leaved_Players != self.Players.count{
                        if self.Play_Deck.Is_Empty(){
                            print("\tPlaying Deck Is Empty, Impossible To Continue the Round...")
                            break
                        }
                        Time_On = false
                        print("\n\t\t💛💛💛💛💛💛💛💛 Next 🕐 💛💛💛💛💛💛💛💛")
                        print("\t\t\t🤵🏼‍♂️ Dealer Cards: " + Emoji_Cards(Inp: Dealer_Cards[0]) + ",❓")
                        for i in 0 ..< self.Players.count{
                            let Playr_Crd = self.Players[i].Get_Cards()
                            var Plyr_Pts = 0
                            for Crd in Playr_Crd{
                                Plyr_Pts += self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Crd)
                            }
                            if self.Players[i].In_Game_Now(){
                                if !(i != (self.Players.count - 1) && self.Players[i].Init_Win()){
                                    Time_On = true
                                }
                                if i != (self.Players.count - 1){
                                    print("\t\t🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖")
                                }
                                else{
                                    print("\t\t🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶")
                                }
                            }
                            if Plyr_Pts != 0{
                                if i != (self.Players.count - 1){
                                    let Pl_Cards = self.Players[i].Get_Cards()
                                    var Emojis = ""
                                    for Pl in Pl_Cards{
                                        Emojis += Emoji_Cards(Inp: Pl) + ","
                                    }
                                    print("\t\t\t🙎🏿‍♂️ Player " + String(i) + " Cards: " + Emojis.dropLast())
                                }
                                else{
                                    let Pl_Cards = self.Players[i].Get_Cards()
                                    var Emojis = ""
                                    for Pl in Pl_Cards{
                                        Emojis += Emoji_Cards(Inp: Pl) + ","
                                    }
                                    print("\t\t\tYour Cards: " + Emojis.dropLast())
                                }
                                print("\t\t\t💰 Budget 💰: " + String(self.Players[i].Get_Budget()) + "💵")
                                print("\t\t\tCurrent Bet: " + String(Float(self.Players_Bets[i]) * self.Base_Bet) + "💵")
                            }
                            if self.Players[i].In_Game_Now(){
                                if i != (self.Players.count - 1){
                                    print("\t\t🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖🤖")
                                }
                                else{
                                    print("\t\t🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶🐶")
                                }
                                if i != (self.Players.count - 1) && self.Players[i].Init_Win(){
                                    self.Players[i].Leave_Game()
                                    print("\t\t🙎🏿‍♂️ Player " + String(i) + " has Finished the Round")
                                    Leaved_Players += 1
                                }
                                else{
                                    let Inst_Code = self.Players[i].get_inst()
                                    if Inst_Code == 1{
                                        self.Players[i].Leave_Game()
                                        Leaved_Players += 1
                                        if i != (self.Players.count - 1){
                                            print("\t\t🙎🏿‍♂️ Player " + String(i) + " has Finished the Round")
                                        }
                                    }
                                    else{
                                        let New_Card = self.Play_Deck.Get_Card()
                                        let Dealer_Sums = Sums_Counter(Curr_Pts: Shown_Card_Pts, All_Pos_Pts: self.Play_Deck.Get_All_Card_Points(High_A: self.High_A) + [Hidden_Card_Pts], Max_Mooves: self.High_A ? 2 : 3, For_Dealer: true)
                                        let Dealer_Median = Get_Median(Inp: Dealer_Sums)
                                        let Wn_Rate = Win_Rate_Counter(Player_Cards: self.Players[i].Get_Cards() + [New_Card], Dealer_Median: Dealer_Median, Dealer_Hidden_Pts: Hidden_Card_Pts)
                                        if (Inst_Code == 2 || Inst_Code == 3) && Float(self.Players_Bets[i] + Inst_Code) * self.Base_Bet > self.Players[i].Get_Budget(){
                                            if i == (self.Players.count - 1){
                                                print("\t\tIt is Impossible to Raise the Bid Because Your Budget is Too Small. Instead, You Will Receive Another Card With the Old Bet...")
                                            }
                                        }
                                        else if (Inst_Code == 2 || Inst_Code == 3){
                                            if i != (self.Players.count - 1){
                                                print("\t\t🙎🏿‍♂️ Player " + String(i) + " Raised the Bid by " + String(Inst_Code) + "🅱️🅱️")
                                                print("\t\tAnd Got 🆕 Card: " + Emoji_Cards(Inp: New_Card))
                                            }
                                            else{
                                                print("\t\tYour 🆕 Card: " + Emoji_Cards(Inp: New_Card))
                                            }
                                            self.Players_Bets[i] += Inst_Code
                                        }
                                        if Inst_Code == 0{
                                            if i != (self.Players.count - 1){
                                                print("\t\t🙎🏿‍♂️ Player " + String(i) + " Took 🆕 Card: " + Emoji_Cards(Inp: New_Card))
                                            }
                                            else{
                                                print("\t\tYour 🆕 Card: " + Emoji_Cards(Inp: New_Card))
                                            }
                                        }
                                        if Wn_Rate == -1 && i != (self.Players.count - 1){
                                            self.Players[i].Leave_Game()
                                            print("\t\t🙎🏿‍♂️ Player " + String(i) + " has Finished the 🔔")
                                        }
                                        self.Players[i].update_state(New_Card_Val: self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: New_Card), New_Card: New_Card, Win_Rate: Wn_Rate)
                                    }
                                }
                            }
                        }
                    }
                    else{
                        break
                    }
                }
                print("\n\t💙💙💙💙💙💙💙💙💙💙 🔔 Results 💙💙💙💙💙💙💙💙💙💙")
                var Dealer_Emojis = ""
                for Card in Dealer_Cards{
                    Dealer_Emojis += Emoji_Cards(Inp: Card) + ","
                }
                print("\t🤵🏼‍♂️ Dealer Initial Cards: " + Dealer_Emojis.dropLast())
                var Dlr_Pts = Shown_Card_Pts + Hidden_Card_Pts
                if Dlr_Pts < 17{
                    print("\t🤵🏼‍♂️ Dealer Takes Cards Up to 1️⃣7️⃣ Points or More...")
                }
                while Dlr_Pts < 17{
                    if self.Play_Deck.Is_Empty(){
                        break
                    }
                    let New_Card = self.Play_Deck.Get_Card()
                    print("\t🆕 🤵🏼‍♂️ Dealer Card: " + Emoji_Cards(Inp: New_Card))
                    Dlr_Pts += self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: New_Card)
                }
                print("\tTotal 🤵🏼‍♂️ Dealer Points: " + String(Dlr_Pts))
                var Dlr_Loss : [Float] = []
                for i in 0 ..< self.Players.count{
                    if self.Players[i].Get_Budget() < self.Base_Bet{
                        Dlr_Loss.append(Float.zero)
                        continue
                    }
                    let Pts : Int = Points_Counter(Cards: Players[i].Get_Cards())
                    var Reward : Float
                    if (Pts > Dlr_Pts && Pts <= 21) || (Dlr_Pts > 21 && Pts < Dlr_Pts){
                        Reward = self.Base_Bet * Float(self.Players_Bets[i])
                    }
                    else if !self.More_2_Win && (Pts == Dlr_Pts){
                        Reward = self.Base_Bet * Float(self.Players_Bets[i]) * 0.5
                    }
                    else{
                        Reward = -1 * self.Base_Bet * Float(self.Players_Bets[i])
                    }
                    if i != (self.Players.count - 1){
                        print("\n\t🙎🏿‍♂️ Number " + String(i) + (Reward > 0 ? " 🏆 Won 📈 " : " 🗑 Lose 📉 ") + String(fabsf(Reward)) + "💵")
                    }
                    else{
                        print("\n\tYou've" + (Reward > 0 ? " 🏆 Won 📈 " : " 🗑 Lose 📉 ") + String(fabsf(Reward)) + "💵")
                    }
                    Dlr_Loss.append(-1 * Reward)
                    if self.Players[i].Get_Budget() + Reward >= self.Base_Bet{
                        Rounds_Survived[i] += 1
                    }
                }
                print("\n\t🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁🏁")
                match_reset(Num_Players: self.Players.count, Dealer_Loss: Dlr_Loss)
                Game_Over = Rounds_Survived.max()! == Max_Rounds
                if Game_Over{
                    print("\n🔔 Limit has Been Reached, 🕹 Game is Done!...")
                    continue
                }
                Game_Over = !self.Dealer.In_Game_Now()
                if Game_Over{
                    print("\n🎰 Casino Run Out Of Its Budget!☠️ Congrats...")
                    continue
                }
                var Dead_Plrs = 0
                for i in 0 ..< self.Players.count{
                    let Plr_Pts = Points_Counter(Cards: self.Players[i].Get_Cards())
                    if Plr_Pts == 0{
                        Dead_Plrs += 1
                    }
                }
                Game_Over = Dead_Plrs == self.Players.count
                if Game_Over{
                    print("\n🎰 Сasino has won🏆, we're waiting for you all again with a lot of money 💵.")
                    continue
                }
            }
            Show_Stat(Rounds_S: Rounds_Survived)
            Exit_Game = Inp_String(Show_Cont: "Game Over 🪦, Do you Wanna Exit ❌?(yes/no): ", Show_Warn: "Error, Only 'yes' or 'no' avalible to choose from, try again...", Pos_Values: ["yes", "no"]) == "yes"
            if !Exit_Game{
                deep_reset(Playing: true)
            }
        }
    }
    private func Emoji_Trofy(Place: Int) -> String{
        switch Place{
        case 0:
            return "🥇"
        case 1:
            return "🥈"
        case 2:
            return "🥉"
        default:
            return "🗑"
        }
    }
    private func Show_Stat(Rounds_S: [Int]){
        print("--------------------🕹Game Stats🕹--------------------")
        var Money_Stat : [String : Float] = ["Dealer" : self.Dealer.Get_Budget()]
        var Survive_Stat : [String : Int] = ["Dealer" : Rounds_S.max()!]
        for i in 0 ..< self.Players.count {
            if i != (self.Players.count - 1){
                Money_Stat.updateValue(self.Players[i].Get_Budget(), forKey: "Player " + String(i))
                Survive_Stat.updateValue(Rounds_S[i], forKey: "Player " + String(i))
            }
            else{
                Money_Stat.updateValue(self.Players[i].Get_Budget(), forKey: "You")
                Survive_Stat.updateValue(Rounds_S[i], forKey: "You")
            }
        }
        let Mn_Stat_Sort = Money_Stat.sorted {$0.value > $1.value}
        Survive_Stat.removeValue(forKey: "Dealer")
        let Sr_Stat_Sort = Survive_Stat.sorted {$0.value > $1.value}
        print("💰💰💰💰💰💰💰💰💰💰 Money 💰💰💰💰💰💰💰💰💰💰")
        var Min_Dlr : Int = 0
        for i in 0 ..< Mn_Stat_Sort.count{
            if Mn_Stat_Sort[i].key == "Dealer"{
                print(Emoji_Trofy(Place: i) + " " + Mn_Stat_Sort[i].key + " - " + String(Mn_Stat_Sort[i].value) + "💵 " + (Mn_Stat_Sort[i].value > self.Dealer.Get_Base_Budget() ? "⬆️" : "⬇️"))
                Min_Dlr = -1
            }
            else{
                print(Emoji_Trofy(Place: i) + " " + Mn_Stat_Sort[i].key + " - " + String(Mn_Stat_Sort[i].value) + "💵 " + (Mn_Stat_Sort[i].value > self.Players[i + Min_Dlr].Get_Base_Budget() ? "⬆️" : "⬇️"))
            }
        }
        print("🩼🩼🩼🩼🩼🩼🩼🩼🩼🩼 Survive 🩼🩼🩼🩼🩼🩼🩼🩼🩼🩼")
        for i in 0 ..< Sr_Stat_Sort.count{
            print(Emoji_Trofy(Place: i) + " " + Sr_Stat_Sort[i].key + " - " + String(Sr_Stat_Sort[i].value) + "🔔")
        }
        print("--------------------🕹Game Stats🕹--------------------")
    }
    //VV
    private func match_reset(Init:Bool = false, Play_Init:Bool = false, Num_Players: Int, Dealer_Loss: [Float] = [], Number_Of_Points: Int = 10, Learning_Rate: Float = 0.1, Gamma: Float = 0.9, Num_Of_Bets:Int = 10, Eps: Float = 0.01, AI_Types: [Int] = [], AI_Files: [String] = []){
        
        if !Init && !Play_Init{
            self.Play_Deck.Reset()
            self.Players_Bets = .init(repeating: 1, count: Num_Players)
        }
        var Leaved_Players : [Bool] = []
        for i in 0 ..< self.Players.count{
            Leaved_Players.append(self.Players[i].Get_Budget() - Dealer_Loss[i] <= 0)
        }
        let Leaved_Players_Cnt = Leaved_Players.filter{$0 == true}.count
        let Add_Play = Play_Init ? 1 : 0
        let Start_Cards = self.Play_Deck.Get_Start_Cards(Num_Of_Players: Num_Players - Leaved_Players_Cnt + Add_Play)
        let Dealer_Pts = self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Start_Cards[Num_Players - Leaved_Players_Cnt + Add_Play])
        let Dealer_Sums = Sums_Counter(Curr_Pts: Dealer_Pts, All_Pos_Pts: self.Play_Deck.Get_All_Card_Points(High_A: self.High_A) + [self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Start_Cards[Start_Cards.count - 1])], Max_Mooves: self.High_A ? 2 : 3, For_Dealer: true)
        let Dealer_Median = Get_Median(Inp: Dealer_Sums)
        if Init || Play_Init{
            self.Dealer.update_state(New_Card_Val: Dealer_Pts, New_Card: Start_Cards[Num_Players - Leaved_Players_Cnt + Add_Play])
            self.Dealer.update_state(New_Card_Val: Dealer_Pts, New_Card: Start_Cards[Start_Cards.count - 1])
        }
        else{
            let Total_Loss = Dealer_Loss.reduce(0, +)
            self.Dealer.match_reset_dealer(First_Cards: [Start_Cards[Num_Players - Leaved_Players_Cnt], Start_Cards[Start_Cards.count - 1]], Total_Loss: Total_Loss, Base_Bet: self.Base_Bet)
        }
        for i in 0 ..< Num_Players {
            if Leaved_Players.isEmpty || !Leaved_Players[i]{
                var Left_Before = 0
                for j in 0 ..< i{
                    if Leaved_Players.isEmpty{
                        break
                    }
                    if Leaved_Players[j]{
                        Left_Before += 1
                    }
                }
                let N_Cards = [Start_Cards[i - Left_Before], Start_Cards[Num_Players - Leaved_Players_Cnt + i - Left_Before + 1 + Add_Play]]
                let Wn_Rate = Win_Rate_Counter(Player_Cards: N_Cards, Dealer_Median: Dealer_Median, Dealer_Hidden_Pts: self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Start_Cards[Start_Cards.count - 1]), Playing: false)
                if Init && !Play_Init{
                    self.Players.append(.init(Ai_Type: AI_Types[i], Budget: Base_Bet * Float(Num_Of_Bets), Number_Of_Points: Number_Of_Points, Learning_Rate: Learning_Rate, Gamma: Gamma, Start_Pos: self.Play_Deck.Get_Card_Points(High_A: High_A, Card_Received: N_Cards[0]) + self.Play_Deck.Get_Card_Points(High_A: High_A, Card_Received: N_Cards[1]), Win_Rate: Wn_Rate, Num_Un_Comm: 4, High_A: High_A, Cards: N_Cards))
                }
                else if Play_Init{
                    self.Players.append(.init(Ai_Type: AI_Types[i], Budget: Base_Bet * Float(Num_Of_Bets), AI_File: AI_Files[i] ,Number_Of_Points: 10, Start_Pos: self.Play_Deck.Get_Card_Points(High_A: High_A, Card_Received: N_Cards[0]) + self.Play_Deck.Get_Card_Points(High_A: High_A, Card_Received: N_Cards[1]), Win_Rate: Wn_Rate, High_A: High_A, Cards: N_Cards))
                }
                else{
                    self.Players[i].match_reset(First_Cards: N_Cards, First_Pts: self.Play_Deck.Get_Card_Points(High_A: High_A, Card_Received: N_Cards[0]) + self.Play_Deck.Get_Card_Points(High_A: High_A, Card_Received: N_Cards[1]), Win_Rate: Wn_Rate, Eps: Eps, Dlr_Loss: Dealer_Loss[i], Base_Bet: self.Base_Bet)
                }
            }
            else{
                self.Players[i].match_reset(First_Cards: ["Dummy", "Dummy"], First_Pts: 0, Win_Rate: 0, Eps: Eps, Dlr_Loss: Dealer_Loss[i], Base_Bet: self.Base_Bet)
            }
        }
        if Play_Init{
            self.Players.append(.init(Budget: Base_Bet * Float(Num_Of_Bets), Number_Of_Points: 10, Cards: [Start_Cards[AI_Files.count], Start_Cards[Start_Cards.count - 2]]))
        }
    }
    private func deep_reset(Eps:Float = 1, Playing: Bool = false){
        self.Play_Deck.Reset()
        let Adding_Num = Playing ? 1 : 0
        self.Players_Bets = .init(repeating: 1, count: self.Players.count)
        let Start_Cards = self.Play_Deck.Get_Start_Cards(Num_Of_Players: self.Players.count)
        let Dealer_Pts = self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Start_Cards[self.Players.count])
        let Dealer_Sums = Sums_Counter(Curr_Pts: Dealer_Pts, All_Pos_Pts: self.Play_Deck.Get_All_Card_Points(High_A: self.High_A) + [self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Start_Cards[Start_Cards.count - 1])], Max_Mooves: self.High_A ? 2 : 3, For_Dealer: true)
        let Dealer_Median = Get_Median(Inp: Dealer_Sums)
        self.Dealer.deep_reset(First_Cards: [Start_Cards[self.Players.count], Start_Cards[Start_Cards.count - 1]], First_Pts: Dealer_Pts + self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Start_Cards[Start_Cards.count - 1]))
        for i in 0 ..< self.Players.count{
            let N_Cards = [Start_Cards[i], Start_Cards[self.Players.count + i + 1 + Adding_Num]]
            let Wn_Rate = Win_Rate_Counter(Player_Cards: N_Cards, Dealer_Median: Dealer_Median, Dealer_Hidden_Pts: self.Play_Deck.Get_Card_Points(High_A: self.High_A, Card_Received: Start_Cards[Start_Cards.count - 1]), Playing: false)
            self.Players[i].deep_reset(First_Cards: N_Cards, First_Pts: self.Play_Deck.Get_Card_Points(High_A: High_A, Card_Received: N_Cards[0]) + self.Play_Deck.Get_Card_Points(High_A: High_A, Card_Received: N_Cards[1]), Win_Rate: Wn_Rate, Eps: Eps)
        }
    }
}
//Play Demo/Test With All Basic Values, No Bots
//let Test = Black_Jack(Num_Of_Decks: 1, Base_Bet: 666, High_A: false)

//Test Training
//let Test_3 = Black_Jack(Num_Of_Decks: 1, AI_Types: [0, 1, 2, 0, 1, 2], Base_Bet: 666, Saving_Path: "Path/to/save/final/models", Epochs_Count: 1500, Episode_Lim: 666)

//Test Playing With Bots
let Test_4 = Black_Jack(Saves_Path: "Path/to/folder/with/saves")
