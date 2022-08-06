//
//  TableViewController.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 11/07/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class TableViewController: UIViewController {
    
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var effectView: UIVisualEffectView! {
        
        didSet {
            
            effectView.layer.borderWidth = 1.1
            updateEffectViewBorder()
        }
    }
    @IBOutlet var effectViewBottomConstraint: NSLayoutConstraint!
    
    var count = rowCount
    
    lazy var refresher: UIRefreshControl? = {
        
        guard useRefreshControl else { return nil }
        
        let refreshControl = UIRefreshControl.init()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        return refreshControl
    }()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        updateTopInsets(to: (parent as? ScrollViewDismissable)?.preferredOffset ?? (84 /*+ (useFullscreen ? statusBarHeightValue(from: view) : 0)*/))
        
        let effectViewHeight = 54 as CGFloat
        
        if #available(iOS 11, *), let inset = DrawerConstants.appDelegate.window?.rootViewController?.view.safeAreaInsets.bottom {
            
            let bottomConstant = inset == 0 ? 12 : inset
            effectViewBottomConstraint.constant = bottomConstant
            
            tableView.contentInset.bottom = bottomConstant + effectViewHeight
            
            if #available(iOS 13, *) {
            
                tableView.verticalScrollIndicatorInsets.bottom = inset
                
            } else {
                
                tableView.scrollIndicatorInsets.bottom = inset
            }
        
        } else {
            
            tableView.contentInset.bottom = 12 + effectViewHeight
        }
        
        if animateWithPresentation {
        
            effectView.transform = .init(translationX: 0, y: tableView.contentInset.bottom)
        }
        
        tableView.tableFooterView = UIView.init(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0.00001))
//        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        updateLabel()
    }
    
    func updateLabel() {
        
        countLabel.text = "\(count)"
    }
    
    func updateTopInsets(to value: CGFloat) {
        
        let number = value - {
            
            if let vc = parent as? ScrollViewDismissable, vc.isPresentedFullScreen {
                
                return statusBarHeightValue(from: view)
            }
            
            return 0
        }()
        
        tableView.contentInset.top = number
        
        if #available(iOS 13, *) {
            
            tableView.verticalScrollIndicatorInsets.top = number
            
        } else {
            
            tableView.scrollIndicatorInsets.top = number
        }
    }
    
    func updateEffectViewBorder() {
        
        let value = 0.08 as CGFloat
        
        if #available(iOS 13.0, *) {
            
            effectView.layer.borderColor = UIColor.label.withAlphaComponent(value).cgColor
            
        } else {
            
            effectView.layer.borderColor = UIColor.black.withAlphaComponent(value).cgColor
        }
    }
    
    @IBAction func dismiss(_ sender: UIButton) {
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func unwindToFirstPresented(_ gr: UILongPressGestureRecognizer) {
        
        guard gr.state == .began else { return }
        
        DrawerConstants.isUnwind = true
        performSegue(withIdentifier: "unwind", sender: nil)
    }
    
    @IBAction func changeCount(_ sender: UIButton) {
        
        if sender.tag == 0, count < 20 {
            
            count += 1
            
        } else if sender.tag == 1, count > 1 {
            
            count -= 1
        }
        
        updateLabel()
        tableView.reloadData()
    }
    
    @objc func refresh(_ control: UIRefreshControl) {
            
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { self.refresher?.endRefreshing() })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        
        super.traitCollectionDidChange(previousTraitCollection)
        
        guard #available(iOS 13, *) else { return }
        
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            
            updateEffectViewBorder()
        }
    }
}

extension TableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int { 1 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.backgroundColor = .clear
        cell.textLabel?.text = indexPath.row % 2 == 0 ? "Presented" : "Pushed"
        cell.detailTextLabel?.text = indexPath.row % 2 == 0 ? "Presents a new view controller with the system-default presentation controller" : "Pushes a new view controller onto the screen"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TableViewController")
        
        if indexPath.row % 2 == 0 {
        
            present(vc, animated: true, completion: nil)
            
        } else {
            
            navigationController?.pushViewController(vc, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
