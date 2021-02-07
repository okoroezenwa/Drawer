//
//  ViewController.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 15/03/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var presentSwitch: UISwitch!
    @IBOutlet var refreshSwitch: UISwitch!
    @IBOutlet var transformSwitch: UISwitch!
    @IBOutlet var titleLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet var rowStepper: UIStepper!
    @IBOutlet var rowLabel: UILabel!
    @IBOutlet var animateSwitch: UISwitch!
    
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
        
        transformSwitch.isOn = use3DTransforms
        transformSwitch.addTarget(self, action: #selector(toggleSwitches(_:)), for: .valueChanged)
        
        animateSwitch.isOn = animateBottomView
        animateSwitch.addTarget(self, action: #selector(toggleSwitches(_:)), for: .valueChanged)
        
        rowStepper.value = Double(rowCount)
        updateLabel()
    }
    
    func updateLabel() {
        
        rowLabel.text = "\(rowCount) \(rowCount == 1 ? "Row" : "Rows")"
    }
    
    @objc func toggleSwitches(_ sender: UISwitch) {
        
        switch sender {
            
            case presentSwitch: presentScrollable.toggle()
                
            case refreshSwitch: useRefreshControl.toggle()
                
            case transformSwitch: use3DTransforms.toggle()
                
            case animateSwitch: animateBottomView.toggle()
                
            default: break
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
    
    @IBAction func changeDefaultRowCount(_ sender: UIStepper) {
        
        rowCount = Int(sender.value)
        updateLabel()
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        if identifier == "second", !presentScrollable {
            
            present(UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TableViewController"), animated: true, completion: nil)
            
            return false
        }
        
        return true
    }
}
