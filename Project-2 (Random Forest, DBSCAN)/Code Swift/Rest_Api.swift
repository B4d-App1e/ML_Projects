//
//  Rest_Api.swift
//  S_Stocks
//
//  Created by Alex Glukhov on 22.12.2023.
//

import Foundation
struct Response_Json{
    enum RootKeys: String, CodingKey{
        case topic, key, value, partition, offset
    }
    enum ValueKeys: String, CodingKey{
        case HateKafka = "data"
    }
    let topic : String
    let key : String?
    let value : String
    let partition : Int
    let offset : Int
}
extension Response_Json: Decodable{
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: RootKeys.self)
        self.topic = try container.decode(String.self, forKey: .topic)
        self.key = try container.decode(String?.self, forKey: .key)
        self.partition = try container.decode(Int.self, forKey: .partition)
        self.offset = try container.decode(Int.self, forKey: .offset)
        let Val_Container = try container.nestedContainer(keyedBy: ValueKeys.self, forKey: .value)
        self.value = try Val_Container.decode(String.self, forKey: .HateKafka)
    }
}
class Rest_Api{
    private var Message = ""
    private var Cons_Name = ""
    public func Test_All(Name: String, Topics : [String]) async -> Bool{
        var Succ = await Create_Consumer(Name: Name, Topics: Topics)
        if Succ{
            Succ = false
            var Counter = 0
            while !Succ && Counter < 10{
                Succ = await Read_Message(Consumer_Name: Name)
                Counter += 1
                do{
                    try await Task.sleep(nanoseconds: 50000000)
                }
                catch{
                    print("Everything go wrong with Messsage Receiving")
                }
            }
            Succ = await Delete_Consumer(Consumer_Name: Name)
        }
        else{
            print("Impossible to receive message, consumer wasn't created")
        }
        return Succ
    }
    public func Create_Consumer(Name: String, Topics : [String]) async -> Bool{
        var Succ = await Create_Consumer(Name: Name)
        if Succ{
            print("Consumer Created!")
            self.Cons_Name = Name
            Succ = await Subscribe_Consumer(Name: Name, Topics: Topics)
            if Succ{
                print("Consumer Subscribed!")
            }
        }
        return Succ
    }
    private func Create_Consumer(Name: String) async -> Bool{
        let dt = ["name" : Name, "format" : "json", "auto.offset.reset" : "earliest"] as Dictionary<String, String>
        let url = URL(string: "http://localhost:8082/consumers/cg2/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: dt, options: [])
        request.setValue("application/vnd.kafka.json.v2+json", forHTTPHeaderField: "Content-Type")
        do{
            let (data, _) = try await URLSession.shared.data(for: request)
            do{
                let json = try JSONSerialization.jsonObject(with: data) as! Dictionary<String, AnyObject>
                print(json)
                return true
            }
            catch{
                print("Bad Data Received (Consumer Creation)")
            }
        }
        catch{
            print("Error During Consumer Creating Process")
        }
        return false
    }
    private func Subscribe_Consumer(Name: String, Topics: [String]) async -> Bool{
        let dt = ["topics" : Topics] as Dictionary<String, [String]>
        let url = URL(string: "http://localhost:8082/consumers/cg2/instances/" + Name + "/subscription/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: dt, options: [])
        request.setValue("application/vnd.kafka.json.v2+json", forHTTPHeaderField: "Content-Type")
        do{
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 || httpResponse.statusCode == 204{
                    return true
                }
            }
        }
        catch{
            print("Error During Subscribing Consumer Process")
        }
        return false
    }
    public func Read_Message(Consumer_Name: String) async -> Bool{
        if let url = URL(string: "http://localhost:8082/consumers/cg2/instances/" + Consumer_Name + "/records/"){
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/vnd.kafka.json.v2+json", forHTTPHeaderField: "Accept")
            do{
                let (data, response) = try await URLSession.shared.data(for: request)
                let decoder = JSONDecoder()
                do{
                    if String(data: data, encoding: .utf8)! != "[]"{
                        let Json_resp = try decoder.decode([Response_Json].self, from: data)
                        self.Message = Json_resp[0].value
                    }
                    else{
                        print("No Message To Receive or Status is not 'Stable'")
                        return false
                    }
                }
                catch{
                    print("Bad Data Received (Message Reading)")
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200{
                        return true
                    }
                }
            }
            catch{
                print("Error During Reading Message Process")
            }
        }
        else{
            print("Impossible to Read Message, Consumer Named: " + Consumer_Name + ", Doesn't Exist")
        }
        return false
    }
    public func Delete_Consumer(Consumer_Name: String) async -> Bool{
        if let url = URL(string: "http://localhost:8082/consumers/cg2/instances/" + Consumer_Name){
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("application/vnd.kafka.json.v2+json", forHTTPHeaderField: "Content-Type")
            do{
                let (_, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 || httpResponse.statusCode == 204{
                        return true
                    }
                }
            }
            catch{
                print("Error During Deleting Consumer Process")
            }
        }
        else{
            print("Not Able to Delete Consumer Named: " + Consumer_Name + ", It Doesn't Exist")
        }
        return false
    }
    public func Get_Message() -> String{
        return self.Message
    }
    public func Get_Cons_Name() -> String{
        return self.Cons_Name
    }
}
