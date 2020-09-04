//
//  TableViewController.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 11/07/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
    
    @IBOutlet var headerView: UIView!
    
    let count = 20
    
    lazy var refresher: UIRefreshControl = {
        
        let refreshControl = UIRefreshControl.init()
        self.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        return refreshControl
    }()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tableView.contentInset.top = 84
        
        if #available(iOS 13, *) {
            
            tableView.verticalScrollIndicatorInsets.top = 84
            
        } else {
            
            tableView.scrollIndicatorInsets.top = 84
        }
        
        if #available(iOS 11, *), let inset = appDelegate.window?.rootViewController?.view.safeAreaInsets.bottom {
            
            tableView.contentInset.bottom = inset
            
            if #available(iOS 13, *) {
            
                tableView.verticalScrollIndicatorInsets.bottom = inset
                
            } else {
                
                tableView.scrollIndicatorInsets.bottom = inset
            }
        }
        
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = UIView.init(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0.00001))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        refreshControl = useRefreshControl ? refresher : nil
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    @IBAction func dismiss(_ sender: UIButton) {
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func unwindToFirstPresented(_ gr: UILongPressGestureRecognizer) {
        
        guard gr.state == .began else { return }
        
        performSegue(withIdentifier: "unwind", sender: nil)
    }
    
    @objc func refresh(_ control: UIRefreshControl) {
            
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: { self.refreshControl?.endRefreshing() })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { count }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        cell.backgroundColor = .clear
        cell.textLabel?.text = indexPath.row % 2 == 0 ? "Presented" : "Pushed"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let vc = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TableViewController")
        
        if indexPath.row % 2 == 0 {
        
            present(vc, animated: true, completion: nil)
            
        } else {
            
            navigationController?.pushViewController(vc, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
