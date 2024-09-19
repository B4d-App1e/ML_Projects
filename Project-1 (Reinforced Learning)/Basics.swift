//
//  Basics.swift
//  Multi_Agent_1
//
//  Created by Alex Glukhov on 15.02.2024.
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
extension Collection {
    func distance(to index: Index) -> Int { distance(from: startIndex, to: index) }
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
}
func Inp_Double(Show_Cont: String, Show_Warn: String, Unsigned : Bool = false, Specified : Bool = false) -> Double{
    while true{
        print(Show_Cont)
        let buf = readLine()!
        if Specified && buf == ""{
            return -1 * Double.greatestFiniteMagnitude
        }
        if let Res = buf.doubleValue{
            if Res > 0 || Unsigned == false{
                return Res
            }
        }
        else{
            print(Show_Warn)
        }
    }
}
func Inp_String(Show_Cont: String, Show_Warn: String, Pos_Values: [String]) -> String{
    while true{
        print(Show_Cont)
        let buf = readLine()!
        if Pos_Values.contains(buf.lowercased()){
            return buf
        }
        else{
            print(Show_Warn)
        }
    }
}
func Inp_Int(Show_Cont: String, Show_Warn: String, Unsigned : Bool = false, Specified : Bool = false) -> Int{
    while true{
        print(Show_Cont)
        let buf = readLine()!
        if Unsigned && Specified && buf == ""{
            return -1
        }
        if let Res = buf.integerValue{
            if Res > 0 || Unsigned == false{
               return Res
            }
            else{
                print(Show_Warn)
            }
        }
        else{
            print(Show_Warn)
        }
    }
}
func getDate() -> String{
    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd hh:mm:ss.SSS"
    let date = df.string(from: Date())
    return(date)
}
func fileNameCrt() -> String{
    var res = String(getDate()).replacingOccurrences(of: " ", with: "")
    res = res.replacingOccurrences(of: ".", with: "?")
    return(res.replacingOccurrences(of: ":", with: "?"))
}
