//
//  SecondViewController.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 09/07/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

class SecondViewController: UIViewController, ScrollViewDismissable, StatusBarControlling {
    
    // MARK: - Storyboard Views
    
    @IBOutlet var navigationBar: UIVisualEffectView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var fullScreenButton: UIButton!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
    // MARK: - ScrollViewDismissable Conformance
    
    var gestureRecogniser: UIPanGestureRecognizer? {
        
        guard let child = (children.first as? UINavigationController)?.topViewController as? TableViewController else { return nil }
        
        return child.tableView.panGestureRecognizer
    }
    
    var currentOffset = 0 as CGFloat
    var preferredOffset: CGFloat { 84/* + (isFullScreen ? statusBarHeightValue(from: view) : 0)*/ }
    
    var scroller: UIScrollView? {
        
        guard let child = (children.first as? UINavigationController)?.topViewController as? TableViewController else { return nil }
        
        return child.tableView
    }
    
    var isAtTop: Bool {
        
        guard let child = (children.first as? UINavigationController)?.topViewController as? TableViewController else { return true }
        
        return child.tableView.contentOffset.y <= -preferredOffset
    }
    
    var refreshControl: UIRefreshControl? {
        
        guard let child = (children.first as? UINavigationController)?.topViewController as? TableViewController else { return nil }
        
        return child.refresher
    }
    
    var presentationAnimation: (() -> ())? {
        
        guard let child = (children.first as? UINavigationController)?.topViewController as? TableViewController else { return nil }
        
        return { child.effectView?.transform = .identity }
    }
    
    var isPresentedFullScreen: Bool { isFullScreen }
    
    // MARK: - Other Variables
    
    var index = 0
    
    // MARK: - Presentation Variables
    
    lazy var presenter = PresentationManager(interactor: PresentationInteractor())
    var isFullScreen = useFullscreen
    let navigationPresenter = NavigationAnimator()
    lazy var useLightStatusBar = isFullScreen {
        
        didSet {
            
            guard oldValue != useLightStatusBar else { return }
            
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: { self.setNeedsStatusBarAppearanceUpdate() })
        }
    }
    
    override var modalPresentationStyle: UIModalPresentationStyle {
        
        get { .custom }
        
        set { }
    }
    
    override var transitioningDelegate: UIViewControllerTransitioningDelegate? {
        
        get { presenter }
        
        set { }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { return useLightStatusBar ? .lightContent : .default }
    
//    override var modalPresentationCapturesStatusBarAppearance: Bool { return }
    
    // MARK: - View Controller Methods

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        modalPresentationCapturesStatusBarAppearance = true
        presenter.interactor.addToVC(self)
        index = numberOfControllers
        titleLabel.text = (numberOfControllers + 1).description
        updateConstraint()
        updateButton()
    }
    
    func scrollerDoesNotContainTouch(from gr: UIPanGestureRecognizer) -> Bool {
        
        return navigationBar.frame.contains(gr.location(in: view))
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
    
    func updateConstraint() {
        
        bottomConstraint.constant = 20 + cornerRadius//isFullScreen ? 0 : 20
    }
    
    func updateButton() {
        
        fullScreenButton.setTitle(isFullScreen ? "Unfill Screen" : "Fill Screen", for: .normal)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "embed", let navigationController = segue.destination as? UINavigationController {
            
            navigationController.delegate = navigationPresenter
            navigationPresenter.interactor.add(to: navigationController)
        }
    }
    
    @IBAction func updateScreenSize(_ sender: Any) {
        
        guard let controller = presentationController as? PresentationController, let child = (children.first as? UINavigationController)?.topViewController as? TableViewController else { return }
        
        isFullScreen.toggle()
        
        updateButton()
        preferredContentSize = controller.frameOfPresentedViewInContainerView.size
        useLightStatusBar = !isFullScreen
        child.updateTopInsets(to: preferredOffset)
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) { }
    
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, withSender sender: Any) -> Bool {
        
        return presentingViewController?.presentingViewController == nil && topViewController != self
    }
    
    @available(iOS 13, *)
    override func canPerformUnwindSegueAction(_ action: Selector, from fromViewController: UIViewController, sender: Any?) -> Bool {
        
        return presentingViewController?.presentingViewController == nil && topViewController != self
    }
}
