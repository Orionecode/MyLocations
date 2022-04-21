//
//  Functions.swift
//  MyLocations
//
//  Created by 曾一笑 on 2022/4/18.
//

import Foundation

func afterDelay(_ delayInSeconds: Double, run: @escaping () -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delayInSeconds, execute: run)
}

let applicationDocumentsDirectory: URL = {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}()

let dataSaveFailedNotification = Notification.Name(rawValue: "DataSaveFailedNotification")

func fatalCoreDataError(_ error: Error) {
    print("*** Fatal Error: \(error.localizedDescription)")
    NotificationCenter.default.post(name: dataSaveFailedNotification, object: nil)
}
