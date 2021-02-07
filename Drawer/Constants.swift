//
//  Constants.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 04/02/2021.
//  Copyright © 2021 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias ScrollableViewController = UIViewController & Scrollable
var root: ViewController? { appDelegate.window?.rootViewController as? ViewController }
var topViewController: UIViewController? { return topVC(startingFrom: appDelegate.window?.rootViewController) }
let appDelegate = UIApplication.shared.delegate as! AppDelegate

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

var animateBottomView: Bool {
    
    get { UserDefaults.standard.bool(forKey: .animateBottomView) }
    
    set { UserDefaults.standard.set(newValue, forKey: .animateBottomView) }
}

var rowCount: Int {
    
    get { UserDefaults.standard.integer(forKey: .rowCount) }
    
    set { UserDefaults.standard.set(newValue, forKey: .rowCount) }
}

func previousScrollableViewController(from viewController: UIViewController?) -> ScrollableViewController? {
    
    guard viewController != nil else { return nil }
    
    if let scrollable = rootOfPresentedViewController(from: viewController) as? ScrollableViewController { return scrollable }
    
    return previousScrollableViewController(from: viewController?.presentingViewController)
}

func rootOfPresentedViewController(from viewController: UIViewController?) -> UIViewController? {
    
    if viewController?.parent == nil { return viewController }
    
    return rootOfPresentedViewController(from: viewController?.parent)
}

func topVC(startingFrom vc: UIViewController? = topViewController) -> UIViewController? {
    
    if let presented = vc?.presentedViewController {
        
        return topVC(startingFrom: presented)
        
    } else {
        
        return vc
    }
}

extension String {
    
    static var presentScrollable = "presentScrollable"
    static var useRefreshControl = "useRefreshControl"
    static var use3DTransforms = "use3DTransforms"
    static var rowCount = "rowCount"
    static var animateBottomView = "animateBottomView"
}
