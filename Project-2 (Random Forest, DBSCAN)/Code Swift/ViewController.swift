//
//  ViewController.swift
//  S_Stocks
//
//  Created by Alex Glukhov on 24.11.2023.
//

import UIKit
import SwiftUI
extension Double{
    func rounded(toPlaces places: Int) -> Double{
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
protocol Cell_Btn_Handler{
    func Btn_Pressed(Expert_Name: String)
}
extension UIView {
    public var viewWidth: CGFloat {
        return self.frame.size.width
    }

    public var viewHeight: CGFloat {
        return self.frame.size.height
    }
}
struct Graph_Data: Identifiable, Equatable{
    var Time_Val : String
    var Graph_Val : Double
    let id = UUID().uuidString
}
class ViewController: UIViewController, Cell_Btn_Handler, UIPickerViewDataSource, UIPickerViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.Experts_Names.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! Custom_Cell
        let hei = super.view.viewWidth > super.view.viewHeight ? super.view.viewWidth : super.view.viewHeight
        let wid = super.view.viewWidth < super.view.viewHeight ? super.view.viewWidth : super.view.viewHeight
        cell.Expert_Name.text = self.Experts_Names[indexPath.row]
        cell.Expert_Forecast.image = resizeImage(image: UIImage(named: self.Experts_Forecast[indexPath.row] ? "Green_Arrow" : "Red_Arrow")!, targetSize: CGSize(width: CGFloat(15 / 411 * wid), height: CGFloat(25 / 896 * hei)))
        cell.Detailed_Info_Btn.setImage(resizeImage(image: UIImage(named: self.traitCollection.userInterfaceStyle == .dark ? "Eye_Button_Dark" : "Eye_Button_White")!, targetSize: CGSize(width: CGFloat(33 / 896 * hei), height: CGFloat(33 / 896 * hei))), for: .normal)
        cell.layer.borderColor = UIColor.label.cgColor
        cell.Expert_Name.textColor = UIColor.systemBackground
        cell.Expert_Name.font = UIFont(name: "Arial", size: 20 / 414 * wid)
        cell.layer.borderWidth = 4 / 411 * wid
        cell.backgroundColor = UIColor.label
        cell.layer.cornerRadius = 30 / 896 * hei
        cell.deligate = self
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let hei = super.view.viewWidth > super.view.viewHeight ? super.view.viewWidth : super.view.viewHeight
        let wid = super.view.viewWidth < super.view.viewHeight ? super.view.viewWidth : super.view.viewHeight
        return CGSize(width: CGFloat(345 / 411 * wid), height: CGFloat(75 / 896 * hei))
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return Arr_Secs.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Arr_Secs[row]
    }
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        let wid = super.view.viewWidth < super.view.viewHeight ? super.view.viewWidth : super.view.viewHeight
        return 99 / 414 * wid
    }
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        let hei = super.view.viewWidth > super.view.viewHeight ? super.view.viewWidth : super.view.viewHeight
        return 36.0 / 896 * hei
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let wid = super.view.viewWidth < super.view.viewHeight ? super.view.viewWidth : super.view.viewHeight
        var label:UILabel
        
        if let v = view as? UILabel{
            label = v
        }
        else{
            label = UILabel()
        }
        label.textColor = UIColor.label
        label.textAlignment = .center
        label.font = UIFont(name: "Arial", size: 18 / 414 * wid)
        label.text = Arr_Secs[row]
        return label
    }
    func Create_ToolBar(){
        let wid = super.view.viewWidth < super.view.viewHeight ? super.view.viewWidth : super.view.viewHeight
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.backgroundColor = UIColor.label
        toolbar.barTintColor = UIColor.label
        toolbar.tintColor = UIColor(red: 0.9969, green: 0.4784, blue: 0.8, alpha: 1.0)
        toolbar.layer.borderWidth = 3 / 414 * wid
        toolbar.layer.borderColor = UIColor.systemBackground.cgColor
        let dstring = "Done"
        let doneButton = UIBarButtonItem(title: dstring, style: .plain, target: self, action: #selector(ViewController.Close_Picker_View))
        toolbar.setItems([doneButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        dummy.inputAccessoryView = toolbar
    }
    @objc func Close_Picker_View(){
        let Selected_Full = Securities_Names.init(rawValue: picker.selectedRow(inComponent: 0))
        let Selected_Cropp = Securities.init(rawValue: picker.selectedRow(inComponent: 0))
        if Selected_Full != nil && Selected_Full!.description != "nil"{
            self.Selected_Sec = Selected_Cropp!.description
            self.Selected_Sec_Full = Selected_Full!.description
            if self.Stock_Name.text != Selected_Cropp!.description{
                self.Stock_Name.textColor = UIColor.red
                self.Stock_Name.text = Selected_Cropp!.description
            }
        }
        view.endEditing(true)
    }
    func Get_Security_Idx_By_Name(Name: String, Full_Name : Bool = false) -> Int?{
        if Full_Name{
            for Sec in Securities_Names.allCases{
                if Sec.description == Name{
                    return Sec.rawValue
                }
            }
        }
        else{
            for Sec in Securities.allCases{
                if Sec.description == Name{
                    return Sec.rawValue
                }
            }
        }
        return nil
    }
    func Create_Picker_View(){
        picker.delegate = self
        var Selected_Comp : Int = 0
        if let Selected_Buf = Get_Security_Idx_By_Name(Name: Selected_Sec){
            Selected_Comp = Selected_Buf
        }
        picker.delegate?.pickerView?(picker, didSelectRow: Selected_Comp, inComponent: 0)
        picker.selectRow(Selected_Comp, inComponent: 0, animated: false)
        picker.backgroundColor = UIColor.systemBackground
        dummy.inputView = picker
    }
    @IBOutlet weak var Experts_Collection: UICollectionView!
    @IBOutlet weak var Change_Sec_Btn: UIButton!
    @IBOutlet weak var FAQ_Btn: UIButton!
    @IBOutlet weak var Lng_Btn: UIButton!
    @IBOutlet weak var Stock_Name: UILabel!
    @IBOutlet weak var Switch_Stack: UIStackView!
    @IBOutlet weak var Period_Switch: UISwitch!
    @IBOutlet weak var Switch_Label: UILabel!
    @IBOutlet weak var Info_Btn: UIButton!
    var D_Scan = Db_Scan()
    var R_Forest = Random_Forest()
    let picker = UIPickerView()
    var graph = Stock_Chart(data: [], Start_Value: Double.zero)
    var First_Init = true
    var graph_view = UIView()
    let dummy = UITextField(frame: .zero)
    let Arr_Secs = ["Amazon", "Tesla", "Apple"]
    var Selected_Sec = "AAPL"
    var Selected_Sec_Full = "Apple"
    var Rest_Api_Controll = Rest_Api()
    var Kafka_Intr = Kafka_Interactions()
    var Graph_Scalled = false
    var Start_Value : Double = 100
    var Experts_Names : [String] = ["W. Buffet", "M. Bloomberg"]
    var Experts_Forecast : [Bool] = [true, false]
    var Gr_Data : [(Name : String, Values: [Graph_Data])] = [("Hellter", [.init(Time_Val: "12 00:00", Graph_Val: 90), .init(Time_Val: "12 01:00", Graph_Val: 90),
                                                                          .init(Time_Val: "12 02:00", Graph_Val: 90),
                                                                          .init(Time_Val: "12 03:00", Graph_Val: 90),
                                                                          .init(Time_Val: "12 04:00", Graph_Val: 90),
                                                                          .init(Time_Val: "12 05:00", Graph_Val: 90),
                                                                                                      .init(Time_Val: "12 06:00", Graph_Val: 90), .init(Time_Val: "12 07:00", Graph_Val: 90),
                                                                                                      .init(Time_Val: "12 08:00", Graph_Val: 102.5),
                                                                                                      .init(Time_Val: "12 09:00", Graph_Val: 115),
                                                                                                      .init(Time_Val: "12 10:00", Graph_Val: 127.5),
                                                                              .init(Time_Val: "12 11:00", Graph_Val: 140), .init(Time_Val: "12 12:00", Graph_Val: 140), .init(Time_Val: "12 13:00", Graph_Val: 140),
                                                                                                      .init(Time_Val: "12 14:00", Graph_Val: 127.5),
                                                                                                      .init(Time_Val: "12 15:00", Graph_Val: 115),
                                                                                                      .init(Time_Val: "12 16:00", Graph_Val: 102.5),
                                                                                                      .init(Time_Val: "12 17:00", Graph_Val: 90),
                                                                                  .init(Time_Val: "12 18:00", Graph_Val: 90),
                                                                          .init(Time_Val: "12 19:00", Graph_Val: 90),
                                                                                  .init(Time_Val: "12 20:00", Graph_Val: 90),
                                                                                  .init(Time_Val: "12 21:00", Graph_Val: 90),
                                                                                  .init(Time_Val: "12 22:00", Graph_Val: 90),
                                                                                  .init(Time_Val: "12 23:00", Graph_Val: 90)]),
                                                                                         ("Skelter", [.init(Time_Val: "12 00:00", Graph_Val: 120), .init(Time_Val: "12 01:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 02:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 03:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 04:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 05:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 06:00", Graph_Val: 120), .init(Time_Val: "12 07:00", Graph_Val: 120),
                                                                                              .init(Time_Val: "12 08:00", Graph_Val: 120),
                                                                                              .init(Time_Val: "12 09:00", Graph_Val: 120),
                                                                                              .init(Time_Val: "12 10:00", Graph_Val: 120),
                                                                                              .init(Time_Val: "12 11:00", Graph_Val: 120), .init(Time_Val: "12 12:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 13:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 14:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 15:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 16:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 17:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 18:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 19:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 20:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 21:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 22:00", Graph_Val: 120),
                                                                                          .init(Time_Val: "12 23:00", Graph_Val: 120)])]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.Experts_Collection.delegate = self
        self.Experts_Collection.dataSource = self
        self.D_Scan = Db_Scan(f_name: NSHomeDirectory() + "/Models/Paths/D_Scan")
        self.R_Forest = Random_Forest(f_Name: NSHomeDirectory() + "/Models/Paths/R_Forest")
        self.Stock_Name.textColor = UIColor.red
        self.Switch_Label.textColor = UIColor.red
        Set_Up()
        Task{
            if await Rest_Api_Controll.Create_Consumer(Name: "Swift_Cons", Topics: ["Uploaded_Data"]){
                await Graph_Auto_Update()
            }
            else{
                print("Kafka is Unreachable, Impossible to Update Graph")
            }
        }
    }
    func Form_Api_Data(Initial : Bool = true) async -> Bool{
        let Request_Res = await Kafka_Intr.Send_Api_Request(Security_Name: self.Selected_Sec_Full, Initial_Init: Initial)
        if let Sec_Raw = Get_Security_Idx_By_Name(Name: self.Selected_Sec){
            if Request_Res{
                var Api_Res = false
                var Counter = 0
                while !Api_Res{
                    if Counter == 50{
                        print("Impossible to get data from api")
                        return false
                    }
                    do{
                        if Counter != 0{
                            try await Task.sleep(nanoseconds: 100000000)
                        }
                        Api_Res = await Kafka_Intr.Form_Api_Data(Initial_Init: Initial, Group: Sec_Raw, Consumer: self.Rest_Api_Controll)
                        Counter += 1
                    }
                    catch{
                        print("Something gets really wrong during receiving of api data")
                    }
                }
                return true
            }
            else{
                print("Unable to send command, check if Kafka working properly")
            }
        }
        else{
            print("Unknown Security Name Received")
        }
        return false
    }
    func Pred_Resolution_Func(X: Double) -> Int{
        return Int(-10.666666666666666666 * pow(X, 3) + 16 * pow(X, 2) + 12.666666666666666666 * X + 1)
    }
    func Short_Dots_Arr(Clean_Dots : [Dot_Data]) -> [Dot_Data]{
        var Res : [Dot_Data] = []
        var Buf_Dots = Clean_Dots
        var Processed = 0
        while !Buf_Dots.isEmpty{
            let Items_To_Take = Pred_Resolution_Func(X: Double(Processed) / Double(Clean_Dots.count))
            let Buf_Part = Buf_Dots.prefix(upTo: min(Items_To_Take, Buf_Dots.count)).map {$0.Coordinates[0]}
            Res.append(.init(Coordinates: [Buf_Part.sum() / Double(Buf_Part.count)], Group: Clean_Dots[0].Group, Group_Sugg: Clean_Dots[0].Group_Sugg))
            Buf_Dots.removeFirst(min(Items_To_Take, Buf_Dots.count))
            Processed += Items_To_Take
        }
        return Res
    }
    func Short_Dates_Arr(Dates: [String], Begin_From : Double = Double.zero) -> [String]{
        var Res : [String] = []
        var Buf_Dates = Dates
        var Processed = 0
        while !Buf_Dates.isEmpty{
            let Items_To_Del = Pred_Resolution_Func(X: Begin_From + Double(Processed) / Double(Dates.count))
            Buf_Dates.removeFirst(min(Int(floor(Double(Items_To_Del) / 2)), Buf_Dates.count))
            if !Buf_Dates.isEmpty{
                Res.append(Buf_Dates[0])
            }
            Buf_Dates.removeFirst(min(Int(ceil(Double(Items_To_Del) / 2)), Buf_Dates.count))
            Processed += Items_To_Del
        }
        return Res
    }
    func Get_Sub_Pred(Pred_Arr : [Double], Limit : Int) -> [Double]{
        var Res : [Double] = []
        var Buf_Pred = Pred_Arr
        Buf_Pred.reverse()
        var Processed = 0
        while (Res.count != Limit) && !Buf_Pred.isEmpty{
            let Items_To_Take = Pred_Resolution_Func(X: 0.1 + Double(Processed) / Double(Pred_Arr.count))
            let Buf_Part = Array(Buf_Pred.prefix(upTo: min(Items_To_Take, Buf_Pred.count)))
            Res.append(Buf_Part.sum() / Double(Buf_Part.count))
            Buf_Pred.removeFirst(min(Items_To_Take, Buf_Pred.count))
            Processed += Items_To_Take
        }
        return Res.reversed()
    }
    func Convert_Dots_To_Any(Clean_Dots : [Dot_Data], Group: Int) -> [[Any]]{
        var Res : [[Any]] = []
        var Cln_Dots = Short_Dots_Arr(Clean_Dots: Clean_Dots)
        while !Cln_Dots.isEmpty{
            let Buf_Dots : [Dot_Data] = Array(Cln_Dots.prefix(upTo: min(10, Cln_Dots.count)))
            if Buf_Dots.count == 10{
                var Buf_Db : [Double] = Buf_Dots.map {$0.Coordinates[0]}
                Buf_Db.insert(Double(Group), at: 0)
                Res += [Buf_Db]
            }
            else{
                break
            }
            Cln_Dots.removeFirst()
        }
        return Res
    }
    func Calc_Avg_Of_Any(Clean_Dots : [Dot_Data]) -> [Double]{
        var Res : [Double] = []
        var Cln_Dots = Short_Dots_Arr(Clean_Dots: Clean_Dots)
        while !Cln_Dots.isEmpty{
            let Buf_Dots : [Dot_Data] = Array(Cln_Dots.prefix(upTo: min(10, Cln_Dots.count)))
            if Buf_Dots.count == 10{
                let Buf_Db : [Double] = Buf_Dots.map {$0.Coordinates[0]}
                Res.append(Buf_Db.sum() / Double(Buf_Db.count))
            }
            else{
                break
            }
            Cln_Dots.removeFirst()
        }
        return Res
    }
    func Dates_N_Dots_To_Graph_Dt(Dates: [String], Dots: [Dot_Data]) -> [Graph_Data]{
        var Res : [Graph_Data] = []
        let Buf_D = Dots.map {$0.Coordinates[0]}
        for i in 0 ..< Buf_D.count{
            Res.append(.init(Time_Val: Dates[i], Graph_Val: Buf_D[i]))
        }
        return Res
    }
    func Dates_N_Double_To_Graph_Dt(Dates: [String], Dots: [Double]) -> [Graph_Data]{
        var Res : [Graph_Data] = []
        for i in 0 ..< Dots.count{
            Res.append(.init(Time_Val: Dates[i], Graph_Val: Dots[i]))
        }
        return Res
    }
    func Form_Prices_N_Preds() async -> Bool{
        var Dots_W_Pred = D_Scan.Use_Model(New_Dots: Kafka_Intr.Get_Dots(), With_Sugg: false)
        var Dates = Kafka_Intr.Get_Dates()
        var Counter = 0
        while Counter < Dots_W_Pred.count{
            if Dots_W_Pred[Counter].Group != Dots_W_Pred[Counter].Group_Sugg{
                Dots_W_Pred.remove(at: Counter)
                Dates.remove(at: Counter)
            }
            Counter += 1
        }
        self.Gr_Data = [(self.Selected_Sec + " Prices On " + Kafka_Intr.Get_Start_Date(), Dates_N_Dots_To_Graph_Dt(Dates: Dates, Dots: Dots_W_Pred))]
        let Any_Arr = Convert_Dots_To_Any(Clean_Dots: Dots_W_Pred, Group: Dots_W_Pred[0].Group!)
        let Any_Avgs = Calc_Avg_Of_Any(Clean_Dots: Dots_W_Pred)
        var Forest_Res : [Double] = []
        for i in 0 ..< (Any_Avgs.count - 1){
            Forest_Res.append(Any_Avgs[i] * (R_Forest.Get_Predict_Short(Input: Any_Arr[i]) as! Double))
        }
        var Multp = 1.0
        if Dots_W_Pred.count > 10{
            Multp = Dots_W_Pred[10].Coordinates[0] / Forest_Res[0]
            Forest_Res = Forest_Res.map {$0 * Multp}
        }
        if !self.Period_Switch.isOn{
            var Full_Pred = Int(Dates.count / 2)
            var Curr_Date = Dates[Dates.count - 1]
            Curr_Date = String(Curr_Date.prefix(upTo: Curr_Date.index(Curr_Date.startIndex, offsetBy: 2)))
            var Buf_Dates_Arr : [String] = []
            let D_Formatter = DateFormatter()
            D_Formatter.dateFormat = "dd HH:mm"
            Curr_Date = Dates[Dates.count - 1]
            for i in 0 ..< Full_Pred{
                Buf_Dates_Arr.append(D_Formatter.string(from: Calendar.current.date(byAdding: .minute, value: i, to: D_Formatter.date(from: Curr_Date)!)!))
            }
            Dates = Short_Dates_Arr(Dates: Dates)
            Full_Pred = Dates.count
            Dates += Short_Dates_Arr(Dates: Buf_Dates_Arr, Begin_From: 0.3)
            Full_Pred = Dates.count - Full_Pred
            var Pred_Res_Buf = Get_Sub_Pred(Pred_Arr: Forest_Res, Limit: 10)
            Pred_Res_Buf.insert(Double(Dots_W_Pred[0].Group!), at: 0)
            var First = true
            for _ in 0 ..< Full_Pred{
                let Buf_Inp : [Any] = Pred_Res_Buf
                var Forest_Pred = (Pred_Res_Buf.sum() - Pred_Res_Buf[0]) / Double(Pred_Res_Buf.count - 1) * (R_Forest.Get_Predict_Short(Input: Buf_Inp) as! Double) * Multp
                if First && Forest_Pred < Forest_Res[Forest_Res.count - 1]{
                    Forest_Pred /= Multp
                    Multp = 1 / Multp
                }
                Forest_Res.append(Forest_Pred)
                Pred_Res_Buf.remove(at: 1)
                Pred_Res_Buf.append(Forest_Pred)
                First = false
            }
        }
        else{
            Dates = Short_Dates_Arr(Dates: Dates)
        }
        Dates.removeFirst(9)
        self.Gr_Data.append(("Prediction", Dates_N_Double_To_Graph_Dt(Dates: Dates, Dots: Forest_Res)))
        self.Start_Value = Kafka_Intr.Get_Start_Value()
        return true
    }
    func Graph_Auto_Update() async {
        let _ = await Set_Up_Graph()
        var To_Skip = 0
        while true{
            if self.Switch_Label.textColor == UIColor.red || self.Stock_Name.textColor == UIColor.red{
                To_Skip = 0
            }
            else if To_Skip != 0{
                do{
                    try await Task.sleep(nanoseconds: 7500000000)
                }
                catch{
                    print("Everything go wrong with graph updates")
                }
                To_Skip -= 1
                continue
            }
            let Api_Res = await Form_Api_Data(Initial: true)
            if Api_Res{
                let _ = await Form_Prices_N_Preds()
                if self.Switch_Label.textColor == UIColor.red{
                    self.Switch_Label.textColor = UIColor.label
                }
                if self.Stock_Name.textColor == UIColor.red{
                    self.Stock_Name.textColor = UIColor.label
                }
                let Gr_Formed = await Set_Up_Graph()
                if !Gr_Formed{
                    print("Wrong Data Received, Impossible to show Graph")
                }
            }
            else{
                print("Impossible to get api result")
            }
            do{
                try await Task.sleep(nanoseconds: 7500000000)
            }
            catch{
                print("Everything go wrong with graph updates")
            }
            To_Skip = 8
        }
    }
    func Set_Up(){
        let hei = super.view.viewWidth > super.view.viewHeight ? super.view.viewWidth : super.view.viewHeight
        self.Experts_Collection.layer.borderWidth = 5 / 896 * hei
        self.Experts_Collection.layer.borderColor = UIColor.label.cgColor
        self.Experts_Collection.layer.cornerRadius = 30 / 896 * hei
        let Btn_Dims : CGFloat = 41 / 896 * hei
        self.Info_Btn.frame.size = .init(width: 21 / 896 * hei, height: 21 / 896 * hei)
        self.Change_Sec_Btn.frame.size = .init(width: Btn_Dims, height: Btn_Dims)
        self.FAQ_Btn.frame.size = .init(width: Btn_Dims, height: Btn_Dims)
        self.Lng_Btn.frame.size = .init(width: Btn_Dims, height: Btn_Dims)
        self.Stock_Name.text = self.Selected_Sec
        self.Stock_Name.font = UIFont(name: self.Stock_Name.font.fontName, size: 20 / 896 * hei)
        if self.traitCollection.userInterfaceStyle == .dark{
            self.Change_Sec_Btn.setImage(resizeImage(image: UIImage(named: "Sec_Button_Dark")!, targetSize: CGSize(width: Btn_Dims, height: Btn_Dims)), for: .normal)
            self.FAQ_Btn.setImage(resizeImage(image: UIImage(named: "FAQ_Button_Dark")!, targetSize: CGSize(width: Btn_Dims, height: Btn_Dims)), for: .normal)
        }
        else{
            self.Change_Sec_Btn.setImage(resizeImage(image: UIImage(named: "Sec_Button_White")!, targetSize: CGSize(width: Btn_Dims, height: Btn_Dims)), for: .normal)
            self.FAQ_Btn.setImage(resizeImage(image: UIImage(named: "FAQ_Button_White")!, targetSize: CGSize(width: Btn_Dims, height: Btn_Dims)), for: .normal)
        }
    }
    func Set_Up_Graph() async -> Bool{
        let hei = super.view.viewWidth > super.view.viewHeight ? super.view.viewWidth : super.view.viewHeight
        let wid = super.view.viewWidth < super.view.viewHeight ? super.view.viewWidth : super.view.viewHeight
        self.graph = Stock_Chart(data: self.Gr_Data, Start_Value: self.Start_Value)
        let Gr_Host = UIHostingController(rootView: self.graph)
        guard let graphView = Gr_Host.view else{
            return false
        }
        graphView.layer.borderColor = UIColor.label.cgColor
        graphView.layer.borderWidth = 5 / 896 * hei
        graphView.layer.cornerRadius = 30 / 896 * hei
        graphView.isUserInteractionEnabled = true
        graphView.translatesAutoresizingMaskIntoConstraints = false
        let Gest_Rec = UITapGestureRecognizer(target: self, action: #selector(self.GraphTap(_:)))
        graphView.addGestureRecognizer(Gest_Rec)
        if !self.First_Init{
            self.graph_view.removeFromSuperview()
        }
        if self.Graph_Scalled{
            graphView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }
        self.First_Init = false
        view.addSubview(graphView)
        let Horizontal_Cost_Bottom = NSLayoutConstraint(item: graphView, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: self.Stock_Name, attribute: .top, multiplier: 1, constant: CGFloat(-10 / 896 * hei))
        let Horizontal_Cost_Top = NSLayoutConstraint(item: graphView, attribute: .top, relatedBy: .equal, toItem: Switch_Stack, attribute: .bottom, multiplier: 1, constant: CGFloat(5 / 896 * hei))
        let Width_Const = NSLayoutConstraint(item: graphView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: CGFloat(275 / 411 * wid))
        let Vertical_Cost_Middle = NSLayoutConstraint(item: graphView, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
        view.addConstraints([Horizontal_Cost_Top, Horizontal_Cost_Bottom, Vertical_Cost_Middle, Width_Const])
        self.graph_view = graphView
        return true
    }
    @objc func GraphTap(_ sender: UITapGestureRecognizer){
        if !self.Graph_Scalled{
            UIView.animate(withDuration: 0.3, animations: {
                sender.view!.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
            })
            self.Graph_Scalled = true
        }
        else{
            UIView.animate(withDuration: 0.3, animations: {
                sender.view!.transform = CGAffineTransform.identity
            })
            self.Graph_Scalled = false
        }
    }
    func Btn_Pressed(Expert_Name: String) {
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "Predictions") as! Predictions_Menu_Controller
        nextViewController.modalPresentationStyle = .overFullScreen
        nextViewController.modalTransitionStyle = .crossDissolve
        nextViewController.Header_Txt = Expert_Name + " -> " + self.Selected_Sec
        self.present(nextViewController, animated: true, completion: nil)
    }
    @IBAction func Change_Sec_Btn_Click(_ sender: Any) {
        self.Change_Sec_Btn.isEnabled = false
        self.FAQ_Btn.isEnabled = false
        self.Experts_Collection.isUserInteractionEnabled = false
        self.Info_Btn.isEnabled = false
        UIView.animate(withDuration: 0.3,
            animations: {
            self.Change_Sec_Btn.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        },
                       completion: { _ in
            UIView.animate(withDuration: 0.3, animations:{
                self.Change_Sec_Btn.transform = CGAffineTransform.identity
            },
                           completion: {_ in
                self.Change_Sec_Btn.isEnabled = true
                self.FAQ_Btn.isEnabled = true
                self.Experts_Collection.isUserInteractionEnabled = true
                self.Info_Btn.isEnabled = true
                self.Create_Picker_View()
                self.Create_ToolBar()
                self.view.addSubview(self.dummy)
                self.dummy.becomeFirstResponder()
            })
        })
    }
    @IBAction func FAQ_Btn_Click(_ sender: Any) {
        self.Change_Sec_Btn.isEnabled = false
        self.FAQ_Btn.isEnabled = false
        self.Experts_Collection.isUserInteractionEnabled = false
        self.Info_Btn.isEnabled = false
        UIView.animate(withDuration: 0.3,
            animations: {
            self.FAQ_Btn.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        },
                       completion: { _ in
            UIView.animate(withDuration: 0.3, animations:{
                self.FAQ_Btn.transform = CGAffineTransform.identity
            },
                           completion: {_ in
                self.Change_Sec_Btn.isEnabled = true
                self.FAQ_Btn.isEnabled = true
                self.Experts_Collection.isUserInteractionEnabled = true
                self.Info_Btn.isEnabled = true
            })
            
        })
    }
    func Show_Alert(Title: String, Message: String){
        let dialogMessage = UIAlertController(title: Title, message: Message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default,handler: {(action) -> Void in})
         dialogMessage.addAction(ok)
        self.present(dialogMessage, animated: true, completion: nil)
    }
    func Form_Info() -> String{
        let Org_Vals = self.Gr_Data[0].Values.map{$0.Graph_Val}
        var Pred_Vals = self.Gr_Data[1].Values.map{$0.Graph_Val}
        let Avg_Org = Org_Vals.sum() / Double(Org_Vals.count)
        var Counter = 0
        var Avg_Err = Double.zero
        var Last_In = 0
        for i in 0 ..< self.Gr_Data[0].Values.count{
            if let Buf = self.Gr_Data[1].Values.firstIndex(where: {$0.Time_Val == self.Gr_Data[0].Values[i].Time_Val}){
                Avg_Err += fabs(self.Gr_Data[0].Values[i].Graph_Val - self.Gr_Data[1].Values[Buf].Graph_Val) /  self.Gr_Data[0].Values[i].Graph_Val
                Counter += 1
                Last_In = Int(Buf)
            }
        }
        Avg_Err /= Double(Counter)
        Avg_Err *= 100
        if self.Period_Switch.isOn{
            return "Min Value(Real): " + String(Org_Vals.min()!.rounded(toPlaces: 2)) + "\nMax Value(Real): " + String(Org_Vals.max()!.rounded(toPlaces: 2)) + "\nAvg Value(Real): " + String(Avg_Org.rounded(toPlaces: 4)) + "\nPred. Error(Avg): " + String(Avg_Err.rounded(toPlaces: 5)) + "%"
        }
        else{
            Pred_Vals = Array(Pred_Vals.suffix(from: Last_In))
            if !Pred_Vals.isEmpty{
                let Avg_Pred = Pred_Vals.sum() / Double(Pred_Vals.count)
                return "Min Value(Real): " + String(Org_Vals.min()!.rounded(toPlaces: 2)) + "\nMin Value(Pred.): " + String(Pred_Vals.min()!.rounded(toPlaces: 2)) + "\nMax Value(Real): " + String(Org_Vals.max()!.rounded(toPlaces: 2)) + "\nMax Value(Pred.): " + String(Pred_Vals.max()!.rounded(toPlaces: 2)) + "\nAvg Value(Real): " + String(Avg_Org.rounded(toPlaces: 4)) + "\nAvg Value(Pred): " + String(Avg_Pred.rounded(toPlaces: 4)) + "\nTrend(Future 12H): " + (Org_Vals[Org_Vals.count - 1] > Avg_Pred ? "Falling" : "Rising") + "\nTrend(Overall 36H): " + (Avg_Org > Avg_Pred ? "Falling" : "Rising") + "\nPred. Error(Avg): " + String(Avg_Err.rounded(toPlaces: 5)) + "%"
            }
            else{
                return "Min Value(Real): " + String(Org_Vals.min()!.rounded(toPlaces: 2)) + "\nMax Value(Real): " + String(Org_Vals.max()!.rounded(toPlaces: 2)) + "\nAvg Value(Real): " + String(Avg_Org.rounded(toPlaces: 4)) + "\nPred. Error(Avg): " + String(Avg_Err.rounded(toPlaces: 5))
            }
        }
    }
    @IBAction func Info_Btn_Click(_ sender: Any) {
        self.Change_Sec_Btn.isEnabled = false
        self.FAQ_Btn.isEnabled = false
        self.Experts_Collection.isUserInteractionEnabled = false
        self.Info_Btn.isEnabled = false
        UIView.animate(withDuration: 0.3,
            animations: {
            self.Info_Btn.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        },
                       completion: { _ in
            UIView.animate(withDuration: 0.3, animations:{
                self.Info_Btn.transform = CGAffineTransform.identity
            },
                           completion: {_ in
                self.Change_Sec_Btn.isEnabled = true
                self.FAQ_Btn.isEnabled = true
                self.Experts_Collection.isUserInteractionEnabled = true
                self.Info_Btn.isEnabled = true
                self.Show_Alert(Title: self.Selected_Sec + " Info", Message: self.Form_Info())
            })
            
        })
    }
    @IBAction func Period_Changed(_ sender: Any) {
        if self.Period_Switch.isOn{
            self.Switch_Label.text = "LAST 24H"
        }
        else{
            self.Switch_Label.text = "FUTURE 12H"
        }
        self.Switch_Label.textColor = self.Switch_Label.textColor == UIColor.red ? UIColor.label : UIColor.red
    }
}
func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let size = image.size
    let widthRatio  = targetSize.width  / size.width
    let heightRatio = targetSize.height / size.height
    var newSize: CGSize
    if(widthRatio > heightRatio) {
        newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
    } else {
        newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
    }
    let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    image.draw(in: rect)
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage!
}
