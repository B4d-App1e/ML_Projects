//
//  Kafka_Inter.swift
//  S_Stocks
//
//  Created by Alex Glukhov on 24.11.2023.
//

import Foundation
import Franz
enum Securities: Int, CaseIterable, CustomStringConvertible{
    case Apple = 2
    case Tesla = 1
    case Amazon = 0
    var description: String{
        switch self {
        case .Apple:
            return "AAPL"
        case .Tesla:
            return "TSLA"
        case .Amazon:
            return "AMZN"
        }
    }
}
enum Securities_Names: Int, CaseIterable,CustomStringConvertible{
    case Apple = 2
    case Tesla = 1
    case Amazon = 0
    var description: String{
        switch self {
        case .Apple:
            return "Apple"
        case .Tesla:
            return "Tesla"
        case .Amazon:
            return "Amazon"
        }
    }
}
func Get_Security_Stock_By_Name(Name: String) -> String?{
    for Vl in Securities_Names.allCases{
        if Name == Vl.description{
            return Securities.init(rawValue: Vl.rawValue)!.description
        }
    }
    return nil
}
func Get_Security_Stock_By_Code(Code: Int) -> String?{
    if let Sec = Securities.init(rawValue: Code){
        return Sec.description
    }
    return nil
}
class Kafka_Interactions{
    private let cluster = Cluster(brokers: [("localhost", 9092)], clientId: "Prod", nodeId: 1337)
    private var Start_Value : Double = Double.zero
    private var Graph_Date : String = "0000-00-00"
    private var Curr_Data : [Dot_Data] = []
    private var Dates_Arr : [String] = []
    public func Send_Msg(Msg: String) async{
        cluster.sendMessage("Upload_Data", message: Msg)
    }
    public func Form_Api_Data(Initial_Init: Bool, Group: Int, Consumer: Rest_Api) async -> Bool{
        if await Consumer.Read_Message(Consumer_Name: Consumer.Get_Cons_Name()){
            var Raw_Data = Consumer.Get_Message().components(separatedBy: "\n").map{$0.components(separatedBy: ";")}
            Raw_Data.removeFirst()
            Raw_Data.reverse()
            Raw_Data.removeFirst()
            if Raw_Data[0].count == 6{
                self.Curr_Data.removeAll()
                self.Dates_Arr.removeAll()
                var St_Val : Double = Double.zero
                for i in 0 ..< Raw_Data.count{
                    if Raw_Data[i].count != 6{
                        continue
                    }
                    if i == 0 && Initial_Init{
                        if let buf = Double(Raw_Data[i][1]){
                            self.Start_Value = buf
                        }
                    }
                    if let buf = Double(Raw_Data[i][4]){
                        let Buf_Arr = Raw_Data[i][0].components(separatedBy: " ")
                        self.Graph_Date = Buf_Arr[0]
                        let Buf_Sub = Buf_Arr[0].components(separatedBy: "-")
                        var Bf_Date = Buf_Sub[2] + " " + Buf_Arr[1]
                        Bf_Date.removeLast(3)
                        self.Dates_Arr.append(Bf_Date)
                        self.Curr_Data.append(.init(Coordinates: [buf], Group_Sugg: Group))
                        if !Initial_Init{
                            St_Val = Curr_Data[0].Coordinates[0]
                            self.Dates_Arr.removeFirst()
                            self.Curr_Data.removeFirst()
                        }
                    }
                }
                if !Initial_Init{
                    self.Start_Value = St_Val
                }
                return true
            }
            else{
                print("Error During Api Request")
            }
        }
        else{
            print("Impossible to Get Api Data")
        }
        return false
    }
    private func Get_Date_Time(Yesterday: Bool = false, Tommorow: Bool = false) -> String{
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        let date = df.string(from: Date())
        if Yesterday{
            var Diff = -1
            while Calendar.current.isDateInWeekend(Calendar.current.date(byAdding: .day, value: Diff, to: Date())!){
                Diff -= 1
            }
            let Yest = df.string(from: Calendar.current.date(byAdding: .day, value: Diff, to: Date())!)
            return Yest
        }
        else if Tommorow{
            let Tomm = df.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
            return Tomm
        }
        else{
            return date
        }
    }
    private func Form_Api_Command(Security_Name: String, Initial_Init: Bool) async -> String?{
        let Curr_Date = Get_Date_Time()
        let Yest_Date = Get_Date_Time(Yesterday: true)
        let Outp_Size = Initial_Init ? "5000" : "10"
        if let Stock_Name = Get_Security_Stock_By_Name(Name: Security_Name){
            return "https://apilink" + Stock_Name + "&somethinghere=" + Outp_Size + "&somemore=" + Yest_Date + "&evenmore=" + Curr_Date
        }
        return nil
    }
    public func Send_Api_Request(Security_Name: String, Initial_Init: Bool) async -> Bool{
        if let Command = await Form_Api_Command(Security_Name: Security_Name, Initial_Init: Initial_Init){
            //print(Command)
            await Send_Msg(Msg: Command)
            return true
        }
        return false
    }
    public func Get_Start_Value() -> Double{
        return self.Start_Value
    }
    public func Get_Dots() -> [Dot_Data]{
        return self.Curr_Data
    }
    public func Get_Dates() -> [String]{
        return self.Dates_Arr
    }
    public func Get_Start_Date() -> String{
        return self.Graph_Date
    }
}
