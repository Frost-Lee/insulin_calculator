//
//  DataManager.swift
//  insulin_calculator
//
//  Created by 李灿晨 on 10/11/19.
//  Copyright © 2019 李灿晨. All rights reserved.
//

import Foundation

class DataManager: NSObject {
    
    /**
     The shared instance of object `DataManager`.
     */
    static var shared: DataManager = DataManager()
    
    /**
     Save `data` as a temporary file in `documentDirectory` with extension name `extensionName`.
     The file name would be a UUID string.
     
     - parameters:
        - data: The data to be saved. Callers are responsible for converting objects to `Data` with proper encoding.
        - extensionName: The extension name of the saved file.
        - completion: The completion handler. This closure will be called once the saving process finished, the parameter
            is the URL of the saved temporary file.
     */
    func saveFile(
        data: Data,
        extensionName: String,
        completion: ((URL) -> ())?
    ) {
        let url = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appendingPathComponent(UUID().uuidString).appendingPathExtension(extensionName)
        try! data.write(to: url)
        completion?(url)
    }
    
    /**
     Remove the file with the given URL.
     
     - parameters:
        - url: The url of the file to be removed.
     */
    func removeFile(url: URL?) {
        guard url != nil else {return}
        guard FileManager.default.fileExists(atPath: url!.path) else {return}
        try! FileManager.default.removeItem(at: url!)
    }
    
}
