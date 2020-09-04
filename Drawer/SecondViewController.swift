//
//  SecondViewController.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 09/07/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, Scrollable {
    
    // MARK: - Storyboard Views
    
    @IBOutlet var navigationBar: UIVisualEffectView!
    @IBOutlet var titleLabel: UILabel!
    
    // MARK: - Scrollable Conformance
    
    var gestureRecogniser: UIPanGestureRecognizer? {
        
        guard let child = (children.first as? UINavigationController)?.topViewController as? TableViewController else { return nil }
        
        return child.tableView.panGestureRecognizer
    }
    
    var currentOffset = 0 as CGFloat
    
    var scroller: UIScrollView? {
        
        guard let child = (children.first as? UINavigationController)?.topViewController as? TableViewController else { return nil }
        
        return child.tableView
    }
    
    var isAtTop: Bool {
        
        guard let child = (children.first as? UINavigationController)?.topViewController as? TableViewController else { return true }
        
        return child.tableView.contentOffset.y <= -84
    }
    
    var refreshControl: UIRefreshControl? {
        
        guard let child = (children.first as? UINavigationController)?.topViewController as? TableViewController else { return nil }
        
        return child.refreshControl
    }
    
    // MARK: - Other Variables
    
    var index = 0
    
    // MARK: - Presentation Variables
    
    lazy var presenter = PresentationManager(interactor: PresentationInteractionController())
    
    let navigationPresenter = NavigationAnimationController()
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        
        get { .custom }
        
        set { }
    }
    
    override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        
        get { presenter }
        
        set { }
    }
    
    // MARK: - View Controller Methods

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        presenter.interactor.addToVC(self)
        index = numberOfControllers
        titleLabel.text = (numberOfControllers + 1).description
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) { }
    
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, sender: Any?) -> Bool {
        
        presentingViewController?.presentingViewController == nil && topViewController != self
    }
    
    func scrollerDoesNotContainTouch(from gr: UIPanGestureRecognizer) -> Bool {
        
        navigationBar.frame.contains(gr.location(in: view))
    }
    
    func scrollDirectionMatchesDismissal(via gr: UIPanGestureRecognizer) -> Bool {
        
        gr.translation(in: gr.view).y > 0
    }
    
    func canBeginDismissal(with gr: UIPanGestureRecognizer) -> Bool {
        
        if scrollerDoesNotContainTouch(from: gr) {
            
            return true
        }
    
        if let _ = scroller {
            
            return isAtTop && scrollDirectionMatchesDismissal(via: gr)
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "embed", let navigationController = segue.destination as? UINavigationController {
            
            navigationController.delegate = navigationPresenter
            navigationPresenter.interactor.add(to: navigationController)
        }
    }
}

protocol Scrollable: class {
    
    var gestureRecogniser: UIPanGestureRecognizer? { get }
    var currentOffset: CGFloat { get set }
    var scroller: UIScrollView? { get }
    var refreshControl: UIRefreshControl? { get }
    var isAtTop: Bool { get }
    func scrollerDoesNotContainTouch(from gr: UIPanGestureRecognizer) -> Bool
    func canBeginDismissal(with gr: UIPanGestureRecognizer) -> Bool
    func scrollDirectionMatchesDismissal(via gr: UIPanGestureRecognizer) -> Bool
}

