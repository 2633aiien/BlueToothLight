//
//  ViewController.swift
//  BlueToothLight
//
//  Created by allen on 2023/7/11.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    var connectedPeripheral : CBPeripheral!
    var peripherals : [CBPeripheral] = []
    var services: [CBService] = []
    var characteristics : [CBCharacteristic] = []
    var writeCharacteristic : CBCharacteristic!
    var central = CBCentralManager()

    @IBOutlet weak var listTableView: UITableView!
    @IBOutlet weak var listButton: UIButton!
    @IBOutlet weak var lightOpenButton: UIButton!
    @IBOutlet weak var disconnectButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        listTableView.delegate = self
        listTableView.dataSource = self
        central = CBCentralManager(delegate: self, queue: nil)
    }
    
    @IBAction func listButtonPressed(_ sender: Any) {
        let valueString = ("c" as NSString).data(using: String.Encoding.utf8.rawValue)
        
        if let connectedPeripheral = connectedPeripheral {
            
            if let writeCharacteristic = writeCharacteristic {
                
                connectedPeripheral.writeValue(valueString!, for: writeCharacteristic, type: CBCharacteristicWriteType.withResponse)
            }
        }
    }
    @IBAction func lightOpenButtonPressed(_ sender: Any) {
        if lightOpenButton.titleLabel?.text == "開啟" {
            lightOpenButton.setTitle("關閉", for: .normal)
            let valueString = ("a" as NSString).data(using: String.Encoding.utf8.rawValue)
            
            if let connectedPeripheral = connectedPeripheral {
                
                if let writeCharacteristic = writeCharacteristic {
                    
                    connectedPeripheral.writeValue(valueString!, for: writeCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
            }
        } else {
            lightOpenButton.setTitle("開啟", for: .normal)
            let valueString = ("b" as NSString).data(using: String.Encoding.utf8.rawValue)
            
            if let connectedPeripheral = connectedPeripheral {
                
                if let writeCharacteristic = writeCharacteristic {
                    
                    connectedPeripheral.writeValue(valueString!, for: writeCharacteristic, type: CBCharacteristicWriteType.withResponse)
                }
            }
        }
    }
    @IBAction func disconnectButtonPressed(_ sender: Any) {
        central.cancelPeripheralConnection(connectedPeripheral)
    }
    
    func propertiesString(properties: CBCharacteristicProperties)-> (String)! {
        var propertiesReturn = ""
        
        if properties.rawValue & CBCharacteristicProperties.broadcast.rawValue != 0 {
            propertiesReturn += "broadcast|"
        }
        if properties.rawValue & CBCharacteristicProperties.read.rawValue != 0 {
            propertiesReturn += "read|"
        }
        if properties.rawValue & CBCharacteristicProperties.writeWithoutResponse.rawValue != 0 {
            propertiesReturn += "write without response|"
        }
        if properties.rawValue & CBCharacteristicProperties.write.rawValue != 0 {
            propertiesReturn += "write|"
        }
        if properties.rawValue & CBCharacteristicProperties.notify.rawValue != 0 {
            propertiesReturn += "notify|"
        }
        if properties.rawValue & CBCharacteristicProperties.indicate.rawValue != 0 {
            propertiesReturn += "indicate|"
        }
        if properties.rawValue & CBCharacteristicProperties.authenticatedSignedWrites.rawValue != 0 {
            propertiesReturn += "authenticated signed writes|"
        }
        if properties.rawValue & CBCharacteristicProperties.extendedProperties.rawValue != 0 {
            propertiesReturn += "extended properties|"
        }
        if properties.rawValue & CBCharacteristicProperties.notifyEncryptionRequired.rawValue != 0 {
            propertiesReturn += "notify encryption required|"
        }
        if properties.rawValue & CBCharacteristicProperties.indicateEncryptionRequired.rawValue != 0 {
            propertiesReturn += "indicate encryption required|"
        }

        return propertiesReturn
    }
}

extension ViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case CBManagerState.poweredOn:
            print("藍芽開啟")
        case CBManagerState.unauthorized:
            print("沒有藍芽功能")
        case CBManagerState.poweredOff:
            print("藍芽關閉")
        default:
            print("未知狀態")
        }
        central.scanForPeripherals(withServices: nil)
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name {
            print(name)
        }
        
        for newPeripheral in peripherals {
            if peripheral.name == newPeripheral.name {
                return
            }
        }
        
        if peripheral.name != nil {
            peripherals.append(peripheral)
        }
        listTableView.reloadData()
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if let name = peripheral.name {
            print(name)
        }
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        lightOpenButton.isEnabled = true
        disconnectButton.isEnabled = true
        central.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        lightOpenButton.isEnabled = false
        disconnectButton.isEnabled = false
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("尋找services時\(peripheral.name)發生錯誤\(error?.localizedDescription)")
        }
        services = peripheral.services!
        
        for service in peripheral.services! {
            
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("尋找characteristics時\(peripheral.name)發生錯誤\(error?.localizedDescription)")
        }
        characteristics = service.characteristics!
        
        for characteristic in service.characteristics! {
            
            peripheral.readValue(for: characteristic)
            peripheral.setNotifyValue(true, for: characteristic)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        writeCharacteristic = characteristic
        let resultString = NSString(data: characteristic.value ?? Data(base64Encoded: "")!, encoding: String.Encoding.utf8.rawValue)
        
        print("characteristic uuid: \(characteristic.uuid.uuidString) properties: \(propertiesString(properties: characteristic.properties) ?? " ") value: \(characteristic.value?.hexEncodedString()) \(characteristic.value)")
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
//        print("response: \(characteristic.value)")
        if characteristic.value != nil {
            let str = String(decoding: characteristic.value!, as: UTF8.self)
            print("response: \(str)")
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = peripherals[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        central.connect(peripherals[indexPath.row], options: nil)
        connectedPeripheral = peripherals[indexPath.row]
    }
    
}

extension Data {
    func hexEncodedString() -> String {
        return map { String(format: "%02hhx", $0)}.joined()
    }
}

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
}


