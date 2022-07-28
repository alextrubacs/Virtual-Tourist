//
//  SceneDelegate.swift
//  Virtual Tourist
//
//  Created by Aleksandrs Trubacs on 15/06/2022.
//

import UIKit


class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    let dataController = DataController(modelName: "Virtual_Tourist")
  
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        dataController.load()
        let navigationView = self.window?.rootViewController as! UINavigationController
        let mainView = navigationView.topViewController as! MainMapViewController
        mainView.dataController = self.dataController
        guard let _ = (scene as? UIWindowScene) else { return }
        
        
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        saveViewContext()
    }
    
    func saveViewContext() {
        try? dataController.viewContext.save()
    }
    
    

}

