//
//  SceneDelegate.swift
//  MyLocations
//
//  Created by 曾一笑 on 2022/4/16.
//

import UIKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    lazy var managedObjectContext = persistentContainer.viewContext

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // 1 - 先找到UITabBarController
        let tabController = window!.rootViewController as! UITabBarController
        if let tabViewControllers = tabController.viewControllers {
            // 2 - 查看viewControllers里有几个数组
            var navController = tabViewControllers[0] as! UINavigationController
            // 3 - 找到第一个viewController 作为CurrentLocationViewController的controller
            let controller1 = navController.viewControllers.first as! CurrentLocationViewController
            // 4 - 将此处生成的controlller赋值给CurrentLocationViewController的controller
            controller1.managedObjectContext = managedObjectContext
            // second tab
            navController = tabViewControllers[1] as! UINavigationController
            let controller2 = navController.viewControllers.first as! LocationsViewController
            controller2.managedObjectContext = managedObjectContext
            // third tab
            navController = tabViewControllers[2] as! UINavigationController
            let controller3 = navController.viewControllers.first as! MapViewController
            controller3.managedObjectContext = managedObjectContext
        }
        // 设置Core Data监听器
        listenForFatalCoreDataNotification()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        saveContext()
    }
    
    // MARK: - Core Data stack
    // lazy懒加载，需要的时候才加载
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MyLocations")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // MARK: - Helper Methods
    func listenForFatalCoreDataNotification() {
        // 1 - 使用NotificationCenter观察什么时候出现了dataSaveFailedNotification
        NotificationCenter.default.addObserver(forName: dataSaveFailedNotification, object: nil, queue: OperationQueue.main) { _ in
            // 2 - 设置提示的信息
            let message = """
            There was a fatal error in the app and it cannot continue.

            Press OK to terminate the app. Sorry for the inconvenience.
            """
            // 3 - alert
            let alert = UIAlertController(title: "Internal Error", message: message, preferredStyle: .alert)
            // 4 - alert action
            let action = UIAlertAction(title: "OK", style: .default) { _ in
                let exception = NSException(name: NSExceptionName.internalInconsistencyException, reason: "Fatal Core Data Error", userInfo: nil)
                exception.raise()
            }
            alert.addAction(action)
            // 5 - 使用tabController来展示星系
            let tabController = self.window!.rootViewController!
            tabController.present(alert, animated: true, completion: nil)
        }
    }
}

