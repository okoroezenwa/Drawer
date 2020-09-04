//
//  ViewController.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 15/03/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

typealias ScrollableViewController = UIViewController & Scrollable

var presentScrollable: Bool {
    
    get { UserDefaults.standard.bool(forKey: "presentScrollable") }
    
    set { UserDefaults.standard.set(newValue, forKey: "presentScrollable") }
}

var useRefreshControl: Bool {
    
    get { UserDefaults.standard.bool(forKey: "useRefreshControl") }
    
    set { UserDefaults.standard.set(newValue, forKey: "useRefreshControl") }
}

class ViewController: UIViewController {
    
    @IBOutlet var presentSwitch: UISwitch!
    @IBOutlet var refreshSwitch: UISwitch!
    @IBOutlet var titleLabelTopConstraint: NSLayoutConstraint!
    
    var useLightStatusBar = false {
        
        didSet {
            
            guard oldValue != useLightStatusBar else { return }
            
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: { self.setNeedsStatusBarAppearanceUpdate() })
        }
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        titleLabelTopConstraint.constant = 20 + statusBarHeight(from: view)
        
        presentSwitch.isOn = presentScrollable
        presentSwitch.addTarget(self, action: #selector(toggleSwitches(_:)), for: .valueChanged)
        
        refreshSwitch.isOn = useRefreshControl
        refreshSwitch.addTarget(self, action: #selector(toggleSwitches(_:)), for: .valueChanged)
    }
    
    @objc func toggleSwitches(_ sender: UISwitch) {
        
        if sender == presentSwitch {
            
            presentScrollable.toggle()
            
        } else if sender == refreshSwitch {
            
            useRefreshControl.toggle()
        }
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) { }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { useLightStatusBar ? .lightContent : .default }
    
    @IBAction func showAlertVC(_ gr: UILongPressGestureRecognizer) {
        
        guard gr.state == .began else { return }
        
        let alert = UIAlertAction.init(title: "Present", style: .default, handler: { _ in
            
            self.present(UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SecondViewController"), animated: true, completion: nil)
        })
        
        let cancel = UIAlertAction.init(title: "Cancel", style: .cancel, handler: nil)
        
        let vc = UIAlertController.init(title: nil, message: nil, preferredStyle: .actionSheet)
        vc.addAction(alert)
        vc.addAction(cancel)
        
        present(vc, animated: true, completion: nil)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == "second", !presentScrollable {
            
            present(UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TableViewController"), animated: true, completion: nil)
            
            return false
        }
        
        return true
    }
}

var root: ViewController? { appDelegate.window?.rootViewController as? ViewController }

func previousScrollableViewController(from viewController: UIViewController?) -> ScrollableViewController? {
    
    guard viewController != nil else { return nil }
    
    if let scrollable = rootOfPresentedViewController(from: viewController) as? ScrollableViewController { return scrollable }
    
    return previousScrollableViewController(from: viewController?.presentingViewController)
}

func rootOfPresentedViewController(from viewController: UIViewController?) -> UIViewController? {
    
    if viewController?.parent == nil { return viewController }
    
    return rootOfPresentedViewController(from: viewController?.parent)
}

var topViewController: UIViewController? { return topVC(startingFrom: appDelegate.window?.rootViewController) }

func topVC(startingFrom vc: UIViewController? = topViewController) -> UIViewController? {
    
    if let presented = vc?.presentedViewController {
        
        return topVC(startingFrom: presented)
        
    } else {
        
        return vc
    }
}

let appDelegate = UIApplication.shared.delegate as! AppDelegate
