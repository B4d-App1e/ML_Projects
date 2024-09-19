//
//  Db_Scan.swift
//  S_Stocks
//
//  Created by Alex Glukhov on 02.12.2023.
//

import Foundation
extension Sequence where Element: AdditiveArithmetic {
    func sum() -> Element { reduce(.zero, +) }
}
struct Dot_Data : Equatable, Codable{
    var Coordinates : [Double]
    var Group : Int?
    var Group_Sugg : Int?
    init(){
        Coordinates = []
    }
    init(Coordinates : [Double], Group : Int? = nil, Group_Sugg : Int? = nil){
        self.Coordinates = Coordinates
        self.Group = Group
        self.Group_Sugg = Group_Sugg
    }
}
protocol Calc_Distance : Codable{
    var rawValue : Int{get}
    func Get_Distance(First: [Double], Second: [Double] )-> Double?
}
struct Manhattan_Distance : Calc_Distance, Codable{
    var rawValue: Int = 1
    func Get_Distance(First: [Double], Second: [Double]) -> Double? {
        if First.count != Second.count || First.count == 0 {return nil}
        var Res : Double = 0.0
        for i in 0..<First.count{
            Res += fabs(First[i] - Second[i])
        }
        return Res
    }
}
struct Euclid_Distance : Calc_Distance, Codable{
    var rawValue: Int = 2
    func Get_Distance(First: [Double], Second: [Double]) -> Double? {
        if First.count != Second.count || First.count == 0 {return nil}
        var Res : Double = 0.0
        for i in 0..<First.count{
            Res += pow(First[i] - Second[i], 2)
        }
        return sqrt(Res)
    }
}
struct Chebychev_Distance : Calc_Distance, Codable{
    var rawValue: Int = 3
    func Get_Distance(First: [Double], Second: [Double]) -> Double? {
        if First.count != Second.count || First.count == 0 {return nil}
        var Res : Double = -1 * Double.greatestFiniteMagnitude
        for i in 0..<First.count{
            let Buf = fabs(First[i] - Second[i])
            if Res < Buf{
                Res = Buf
            }
        }
        return Res
    }
}
struct Degree_Distance : Calc_Distance, Codable{
    var rawValue: Int = 4
    var P : Double
    var R : Double
    init(){
        P = 2
        R = 2
    }
    init(p: Double, r: Double){
        self.P = p
        self.R = r
    }
    func Get_Distance(First: [Double], Second: [Double]) -> Double? {
        if First.count != Second.count || First.count == 0 {return nil}
        var Res : Double = 0.0
        for i in 0..<First.count{
            Res += pow(First[i] - Second[i], P)
        }
        return pow(Res, 1/R)
    }
}
enum Distance : Int, CaseIterable, CustomStringConvertible, Codable{
    case Manhattan = 1
    case Euclid = 2
    case Chebychev = 3
    case Degree = 4
    var description: String{
        switch self {
        case .Manhattan:
            return "Manhattan"
        case .Euclid:
            return "Euclid"
        case .Chebychev:
            return "Chebychev"
        case .Degree:
            return "Degree"
        }
    }
}
class Db_Scan : Codable{
    private enum Coding_Keys : String, CodingKey{
        case R
        case Limit
        case Dots
        case Distancies
        case Degree_P
        case Degree_R
    }
    public func encode(to encoder: Encoder) throws {
        var cont = encoder.container(keyedBy: Coding_Keys.self)
        try cont.encode(R, forKey: .R)
        try cont.encode(Limit, forKey: .Limit)
        try cont.encode(Dots, forKey: .Dots)
        try cont.encode(Distancies.rawValue, forKey: .Distancies)
        if Calc_Function.rawValue == 4{
            try cont.encode((Calc_Function as! Degree_Distance).P, forKey: .Degree_P)
            try cont.encode((Calc_Function as! Degree_Distance).R, forKey: .Degree_R)
        }
        else{
            try cont.encode(Double.greatestFiniteMagnitude, forKey: .Degree_P)
            try cont.encode(Double.greatestFiniteMagnitude, forKey: .Degree_R)
        }
    }
    public required init(from decoder: Decoder) throws {
        let cont = try decoder.container(keyedBy: Coding_Keys.self)
        let Dist_Raw = try cont.decode(Int.self, forKey: .Distancies)
        Distancies = Distance.init(rawValue: Dist_Raw)!
        Calc_Function = Euclid_Distance()
        R = try cont.decode(Double.self, forKey: .R)
        Limit = try cont.decode(Int.self, forKey: .Limit)
        Dots = try cont.decode([Dot_Data].self, forKey: .Dots)
        let Dist_P = try cont.decode(Double.self, forKey: .Degree_P)
        let Dist_R = try cont.decode(Double.self, forKey: .Degree_R)
        Set_Up(Distance_Type: Distancies.description, Degree_Distance_P: Dist_P, Degree_Distance_R: Dist_R)
    }
    private var R : Double
    private var Limit : Int
    private var Dots : [Dot_Data]
    private var Distancies : Distance
    private var Calc_Function : Calc_Distance
    init(){
        self.R = Double.zero
        self.Limit = 0
        self.Dots = []
        self.Distancies = .Euclid
        self.Calc_Function = Euclid_Distance()
    }
    init(Dots : [Dot_Data], R : Double, Limit : Int, Distance_Type : String = "Euclid", Degree_Distance_P : Double? = nil, Degree_Distance_R : Double? = nil){
        self.Dots = Dots
        self.R = R
        self.Limit = Limit
        self.Distancies = .Euclid
        self.Calc_Function = Euclid_Distance()
        if Distance_Type == "Degree" && (Degree_Distance_R == nil || Degree_Distance_P == nil){
            Set_Up(Distance_Type: "Euclid", Degree_Distance_P: Degree_Distance_P, Degree_Distance_R: Degree_Distance_R)
        }
        else{
            Set_Up(Distance_Type: Distance_Type, Degree_Distance_P: Degree_Distance_P, Degree_Distance_R: Degree_Distance_R)
        }
    }
    private func Set_Up(Distance_Type : String, Degree_Distance_P: Double?, Degree_Distance_R : Double?){
        for Val in Distance.allCases{
            if Val.description == Distance_Type{
                self.Distancies = Val
                switch Val.rawValue{
                case 1:
                    self.Calc_Function = Manhattan_Distance()
                case 2:
                    self.Calc_Function = Euclid_Distance()
                case 3:
                    self.Calc_Function = Chebychev_Distance()
                default:
                    self.Calc_Function = Degree_Distance(p: Degree_Distance_P!, r: Degree_Distance_R!)
                }
            }
        }
    }
    //VV 
    public func Train_Scan(Min_R : Double = 1.0, Max_R : Double = 100.0, Min_Lim : Int = 3, Max_Lim : Int = 20, Step_R : Double = 0.1, Step_Lim : Int = 1){
        let Base_Dots = self.Dots
        var Lowest_Err : Double = Double.greatestFiniteMagnitude
        var Best_Dots : [Dot_Data] = []
        var Best_R : Double = -1.0
        var Best_Lim : Int = -1
        let SyncQueu = DispatchQueue(label: "...")
        DispatchQueue.concurrentPerform(iterations: Int((Max_R - Min_R) / Step_R), execute: {i in
            let Buf_R = Min_R + Step_R * Double(i)
            DispatchQueue.concurrentPerform(iterations: Int((Max_Lim - Min_Lim) / Step_Lim), execute: {j in
                let Buf_Lim = Min_Lim + Step_Lim * j
                let Dots = Create_Clusters(R: Buf_R, Limit: Buf_Lim, Dts: Base_Dots)
                print("Another Clusters Variant Created(R: " + String(Buf_R) + "; Lim: " + String(Buf_Lim) + " )")
                //let Err = Davies_Bouldin_Idx(Clust_Res: Dots)
                let Err = Lame_Error_Idx(Clust_Res: Dots)
                print("Error For Newly Created Clusters Distribution: " + String(Err))
                if Err < Lowest_Err{
                    SyncQueu.sync {
                        Lowest_Err = Err
                        Best_R = Buf_R
                        Best_Lim = Buf_Lim
                        Best_Dots = Dots
                    }
                }
            })
        })
        self.R = Best_R
        self.Limit = Best_Lim
        self.Dots = Replace_Mist(Clust_Res: Best_Dots)
        print("Best R for Current Data Set is: " + String(Best_R) + ", Best Limit: " + String(Best_Lim))
        
    }
    private func Replace_Mist(Clust_Res: [Dot_Data], D_Use : Bool = false) -> [Dot_Data]{
        var Res : [Dot_Data] = []
        Clust_Res.withUnsafeBufferPointer{ Clt_Res in
            for i in 0 ..< Clt_Res.count{
                if Clt_Res[i].Group_Sugg == nil || Clt_Res[i].Group == Clt_Res[i].Group_Sugg{
                    Res.append(Clt_Res[i])
                }
                else{
                    var Buf = Clt_Res[i]
                    Buf.Group = -1
                    if D_Use{
                        Res.append(Buf)
                    }
                    else{
                        Res.insert(Buf, at: 0)
                    }
                }
            }
        }
        return Res
    }
    private func Lame_Error_Idx(Clust_Res: [Dot_Data]) -> Double{
        var Res : Double = Double.zero
        var Count : Int = 0
        for Dot in Clust_Res{
            if let Buf = Dot.Group{
                if Buf != -1{
                    Count += 1
                }
                if Buf != -1 && Buf != (Dot.Group_Sugg ?? -1){
                    Res += 1.0
                }
            }
        }
        return Res / max(Double(Count) / Double(Clust_Res.count), 0.000001)
    }
    private func Davies_Bouldin_Idx(Clust_Res : [Dot_Data]) -> Double{
        var SD_Arr : [Double] = []
        var Centroids_Arr : [Dot_Data] = []
        let Clusters_Count = (Clust_Res[Clust_Res.count - 1].Group ?? -1) + 1
        let SyncQueu = DispatchQueue(label: "...")
        DispatchQueue.concurrentPerform(iterations: Clusters_Count, execute: {Clust_Num in
            let Cluster = Array(Clust_Res[(Clust_Res.firstIndex(where: {$0.Group == Clust_Num}) ?? 0) ... (Clust_Res.lastIndex(where: {$0.Group == Clust_Num}) ?? 0)])
            let Centroid = Find_Centroid(Cluster: Cluster)
            let Centroid_Dist = Calc_Dist(Curr_Dot: Centroid, Dot_Arr: Cluster)
            SyncQueu.sync {
                SD_Arr.append(Centroid_Dist.sum() / Double(Centroid_Dist.count))
                Centroids_Arr.append(Centroid)
            }
        })
        if Centroids_Arr.count < 2{
            return Double.greatestFiniteMagnitude
        }
        var R_Arr : [[Double]] = []
        for i in 0 ..< SD_Arr.count{
            var R_Row : [Double] = []
            for j in 0 ..< SD_Arr.count{
                if i != j{
                    R_Row.append((SD_Arr[i] + SD_Arr[j]) / (Calc_Function.Get_Distance(First: Centroids_Arr[i].Coordinates, Second: Centroids_Arr[j].Coordinates) ?? -1.0 / Double.greatestFiniteMagnitude))
                }
                else{
                    R_Row.append(Double.greatestFiniteMagnitude * -1.0)
                }
            }
            R_Arr.append(R_Row)
        }
        SD_Arr = []
        for i in 0 ..< R_Arr.count{
            SD_Arr.append(R_Arr[i].max() ?? -1.0 * Double.greatestFiniteMagnitude)
        }
        return SD_Arr.sum() / Double(SD_Arr.count)
    }
    private func Find_Centroid(Cluster: [Dot_Data]) -> Dot_Data{
        var Res_C : [Double] = []
        for i in 0..<Cluster[0].Coordinates.count{
            let Buf_Sort = Cluster.sorted(by: {$0.Coordinates[i] < $1.Coordinates[i]})
            Res_C.append((Buf_Sort[0].Coordinates[i] + Buf_Sort[Buf_Sort.count - 1].Coordinates[i]) / 2.0)
        }
        return .init(Coordinates: Res_C, Group: Cluster[0].Group)
    }
    //takes dots and return same dots but whit recognized cluster
    public func Use_Model(New_Dots: [Dot_Data], With_Sugg: Bool = false) -> [Dot_Data]{
        var Res = New_Dots
        DispatchQueue.concurrentPerform(iterations: Res.count, execute:{ i in
            let Dist_Main_Srt : [( Dt : Dot_Data, Dist : Double)] = Create_Comp_Arr(Dots: self.Dots, Distance: Calc_Dist(Curr_Dot: Res[i], Dot_Arr: self.Dots)).sorted(by: {$0.Dist < $1.Dist})
            let Count_Main = Int(Dist_Main_Srt.firstIndex(where: {$0.Dist > self.R}) ?? self.Dots.count)
            if Count_Main >= 0{
                let Cropped_Dots = Crop_Comp_Arr_DD(From: 0, To: Count_Main, Arr: Dist_Main_Srt)
                var Cluster_Nums : [Int] = []
                for Dt in Cropped_Dots{
                    if !Cluster_Nums.contains(Dt.Group!){
                        Cluster_Nums.append(Dt.Group!)
                    }
                }
                var Centroids_Arr : [Dot_Data] = []
                var Modified_Centroids : [Dot_Data] = []
                for Vl in Cluster_Nums{
                    if Vl != -1{
                        var Cluster = Array(self.Dots[(self.Dots.firstIndex(where: {$0.Group == Vl}) ?? 0) ... (self.Dots.lastIndex(where: {$0.Group == Vl}) ?? 0)])
                        Centroids_Arr.append(Find_Centroid(Cluster: Cluster))
                        Cluster.append(Res[i])
                        Modified_Centroids.append(Find_Centroid(Cluster: Cluster))
                    }
                }
                var Best_Cluster : Int = -1
                var Best_Dist : Double = Double.greatestFiniteMagnitude
                for j in 0 ..< Centroids_Arr.count{
                    if Centroids_Arr[j] == Modified_Centroids[j]{
                        if let Dist = self.Calc_Function.Get_Distance(First: Centroids_Arr[j].Coordinates, Second: Res[i].Coordinates){
                            if Dist < Best_Dist{
                                Best_Dist = Dist
                                Best_Cluster = Centroids_Arr[j].Group!
                            }
                        }
                    }
                }
                Res[i].Group = Best_Cluster
            }
            else{
                Res[i].Group = -1
            }
        })
        if With_Sugg{
            Res = Replace_Mist(Clust_Res: Res, D_Use: true)
        }
        return Res
    }
    private func Create_Clusters(R: Double, Limit: Int, Dts: [Dot_Data]) -> [Dot_Data]{
        var Groups_Count = -1
        var i = 0
        var Done_Arr : [Dot_Data] = []
        var Dots = Dts
        while i < Dots.count{
            var Dist_Main_Srt : [(Dt : Dot_Data, Dist : Double)] = Create_Comp_Arr(Dots: Dots, Distance: Calc_Dist(Curr_Dot: Dots[i], Dot_Arr: Dots)).sorted(by: {$0.Dist < $1.Dist})
            var Count_Main = Int(Dist_Main_Srt.firstIndex(where: {$0.Dist > R}) ?? Dots.count)
            if Count_Main >= Limit{
                Groups_Count += 1
                Dots[i].Group = Groups_Count
                Done_Arr.append(Dots[i])
                Dots.remove(at: i)
                var Can_Arr : [Dot_Data] = Crop_Comp_Arr_DD(From: 1, To: Count_Main, Arr: Dist_Main_Srt)
                Dots = Remove_Added_Dots_Main(Dot_Remove: Can_Arr, Remove_Fr: Dots)
                
                while !Can_Arr.isEmpty{
                    Dist_Main_Srt = Create_Comp_Arr(Dots: Dots, Distance: Calc_Dist(Curr_Dot: Can_Arr[0], Dot_Arr: Dots)).sorted(by: {$0.Dist < $1.Dist})
                    Count_Main = Int(Dist_Main_Srt.firstIndex(where: {$0.Dist > R}) ?? Dots.count)
                    let Dist_Can_Srt = Create_Comp_Arr(Dots: Can_Arr, Distance: Calc_Dist(Curr_Dot: Can_Arr[0], Dot_Arr: Can_Arr))
                    let Count_Can = Int(Dist_Can_Srt.firstIndex(where: {$0.Dist > R}) ?? Can_Arr.count)
                    if Count_Main + Count_Can >= Limit{
                        let Buf = Crop_Comp_Arr_DD(From: 0, To: Count_Main, Arr: Dist_Main_Srt)
                        Can_Arr += Buf
                        Dots = Remove_Added_Dots_Main(Dot_Remove: Buf, Remove_Fr: Dots)
                        
                    }
                    Can_Arr[0].Group = Groups_Count
                    Done_Arr.append(Can_Arr[0])
                    Can_Arr.remove(at: 0)
                }
            }
            else{
                Dots[i].Group = -1
                i += 1
            }
        }
        Dots += Done_Arr
        return Dots
    }
    private func Remove_Added_Dots_Main(Dot_Remove: [Dot_Data], Remove_Fr: [Dot_Data]) -> [Dot_Data]{
        var Remove_From = Remove_Fr
        for Vl in Dot_Remove{
            Remove_From.removeAll(where: {$0 == Vl})
        }
        return Remove_From
    }
    private func Calc_Dist(Curr_Dot : Dot_Data, Dot_Arr : [Dot_Data]) -> [Double]{
        var Res : [Double] = []
        Dot_Arr.withUnsafeBufferPointer{ D_Arr in
            for Dt in D_Arr{
                if let Buf = self.Calc_Function.Get_Distance(First: Dt.Coordinates, Second: Curr_Dot.Coordinates){
                    Res.append(Buf)
                }
                else{
                    Res.append(Double.greatestFiniteMagnitude)
                }
            }
        }
        return Res
    }
    private func Create_Comp_Arr(Dots : [Dot_Data], Distance : [Double]) -> [(Dt : Dot_Data, Dist : Double)]{
        var Res : [(Dt : Dot_Data, Dist : Double)] = []
        Dots.withUnsafeBufferPointer{ Dt in
            Distance.withUnsafeBufferPointer{ Dis in
                for i in 0 ..< Dt.count{
                    Res.append((Dt[i], Dis[i]))
                }
            }
            
        }
        return Res
    }
    private func Crop_Comp_Arr_DD(From: Int, To: Int, Arr: [(Dt : Dot_Data, Dist : Double)]) -> [Dot_Data]{
        var Res : [Dot_Data] = []
        Arr.withUnsafeBufferPointer{Ar in
            for i in From ..< To{
                Res.append(Ar[i].Dt)
            }
        }
        return Res
    }
    public func Save_Model(f_name: String){
        let Enc = JSONEncoder()
        guard let Encd = try? Enc.encode(self) else{
            print("Error During Encoding Process(DBSCAN)")
            return
        }
        let Url = URL(fileURLWithPath: f_name)
        do {
            try Encd.write(to: Url)
        }
        catch{
            print("Error During Writing Process(DBSCAN)")
        }
    }
    public init(f_name: String){
        let Dec = JSONDecoder()
        let Url = URL(fileURLWithPath: f_name)
        guard let data = try? Data(contentsOf: Url) else{
            print("Error During Reading Process(DBSCAN)")
            self.R = Double.zero
            self.Limit = 0
            self.Dots = []
            self.Distancies = .Euclid
            self.Calc_Function = Euclid_Distance()
            return
        }
        guard let Decd = try? Dec.decode(Db_Scan.self, from: data) else{
            print("Error During Decoding Process(DBSCAN)")
            self.R = Double.zero
            self.Limit = 0
            self.Dots = []
            self.Distancies = .Euclid
            self.Calc_Function = Euclid_Distance()
            return
        }
        self.R = Decd.R
        self.Limit = Decd.Limit
        self.Dots = Decd.Dots
        self.Distancies = Decd.Distancies
        self.Calc_Function = Decd.Calc_Function
    }
}
