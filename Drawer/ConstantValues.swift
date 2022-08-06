//
//  Constants.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 04/02/2021.
//  Copyright © 2021 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias DismissableViewController = UIViewController & ScrollViewDismissable

var presentScrollable: Bool {
    
    get { UserDefaults.standard.bool(forKey: .presentScrollable) }
    
    set { UserDefaults.standard.set(newValue, forKey: .presentScrollable) }
}

var useRefreshControl: Bool {
    
    get { UserDefaults.standard.bool(forKey: .useRefreshControl) }
    
    set { UserDefaults.standard.set(newValue, forKey: .useRefreshControl) }
}

var use3DTransforms: Bool {
    
    get { UserDefaults.standard.bool(forKey: .use3DTransforms) }
    
    set { UserDefaults.standard.set(newValue, forKey: .use3DTransforms) }
}

var animateWithPresentation: Bool {
    
    get { UserDefaults.standard.bool(forKey: .animateWithPresentation) }
    
    set { UserDefaults.standard.set(newValue, forKey: .animateWithPresentation) }
}

var rowCount: Int {
    
    get { UserDefaults.standard.integer(forKey: .rowCount) }
    
    set { UserDefaults.standard.set(newValue, forKey: .rowCount) }
}

var useFullscreen: Bool {
    
    get { UserDefaults.standard.bool(forKey: .useFullscreen) }
    
    set { UserDefaults.standard.set(newValue, forKey: .useFullscreen) }
}

func previousDismissableViewController(from viewController: UIViewController?) -> DismissableViewController? {
    
    guard viewController != nil else { return nil }
    
    if let dismissable = rootOfPresentedViewController(from: viewController) as? DismissableViewController { return dismissable }
    
    return previousDismissableViewController(from: viewController?.presentingViewController)
}

func rootOfPresentedViewController(from viewController: UIViewController?) -> UIViewController? {
    
    if viewController?.parent == nil { return viewController }
    
    return rootOfPresentedViewController(from: viewController?.parent)
}

extension String {
    
    static var presentScrollable = "presentScrollable"
    static var useRefreshControl = "useRefreshControl"
    static var use3DTransforms = "use3DTransforms"
    static var rowCount = "rowCount"
    static var animateWithPresentation = "animateBottomView"
    static var useFullscreen = "useFullscreen"
}

struct DrawerConstants {
    
    static let cornerRadius = 18/*12*/ as CGFloat
    static var numberOfControllers = 0
    static var root: (ViewController & UIViewController)? { appDelegate.window?.rootViewController as? ViewController & UIViewController }
    static var topViewController: UIViewController? { return topVC(startingFrom: appDelegate.window?.rootViewController) }
    static let appDelegate = UIApplication.shared.delegate as! AppDelegate
    static let themeChanged = Notification.Name.init("themeChanged")
    static let significantChangeOccurred = Notification.Name.init("significantChangeOccurred")
    static var isUnwind = false
    
    static func topVC(startingFrom vc: UIViewController? = topViewController) -> UIViewController? {
        
        if let presented = vc?.presentedViewController {
            
            return topVC(startingFrom: presented)
            
        } else {
            
            return vc
        }
    }
}
