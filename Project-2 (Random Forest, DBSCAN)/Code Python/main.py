from confluent_kafka import Producer, Consumer
import requests
import json


def Get_Info_Api(Command):
    Res = Command.value().decode('utf-8')
    Response = requests.get(Res)
    return Response.text


def Delivery_Report(Err, Msg):
    if Err is not None:
        print('Api response delivery failed: {}'.format(Err))
    else:
        print('Api response delivered to {} [{}]'.format(Msg.topic(), Msg.partition()))


Get_Swift_Command_Topic = "Upload_Data"
Upload_Data_Swift_Topic = "Uploaded_Data"
Full_Buf_Directory_Path = ""
Consumer_Get_Command = Consumer({
    "bootstrap.servers": "localhost:9092",
    "group.id": "Get_Command_Group",
    "auto.offset.reset": "earliest"
})
Consumer_Get_Command.subscribe([Get_Swift_Command_Topic])
Data_Prod = Producer({
    "bootstrap.servers": "localhost:9092"
})

while True:
    Command_Api = Consumer_Get_Command.poll(1.0)
    if Command_Api is None:
        continue
    if Command_Api.error():
        print("Error During Receiving Command Process:{}".format(Command_Api.error()))
        continue
    print("Api Command From Swift Received")
    Response = Get_Info_Api(Command_Api)
    Lame_Shit = {"data": Response}
    Lame_Shit = json.dumps(Lame_Shit)
    Data_Prod.produce(Upload_Data_Swift_Topic, value=Lame_Shit.encode('utf-8'), callback=Delivery_Report)
    Data_Prod.flush()
