//
//  PresentationController.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 09/07/2020.
//  Copyright © 2020 Ezenwa Okoro. All rights reserved.
//

import UIKit

func statusBarHeightValue(from view: UIView?) -> CGFloat {
    
    if #available(iOS 13, *) {
        
        return (view?.window ?? DrawerConstants.appDelegate.window)?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
    
    } else {
        
        return UIApplication.shared.statusBarFrame.height
    }
}

class PresentationController: UIPresentationController {
    
    private lazy var dimmingView: UIView = {
        
        let view = UIView(frame: containerView?.bounds ?? UIScreen.main.bounds)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        view.alpha = 0.0
        
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        view.addGestureRecognizer(recognizer)
        
        return view
    }()
    
    lazy var shouldUseBackingSnapshots = (presentedViewController as? ScrollViewDismissable)?.shouldUseBackingSnapshots ?? false
    var leftSnapshot: UIView? {
        
        didSet {
            
            oldValue?.removeFromSuperview()
        }
    }
    var rightSnapshot: UIView? {
        
        didSet {
            
            oldValue?.removeFromSuperview()
        }
    }
    var lowerSnapshot: UIView? {
        
        didSet {
            
            oldValue?.removeFromSuperview()
        }
    }
    
    lazy var presenter = previousDismissableViewController(from: presentingViewController) ?? DrawerConstants.root
    lazy var grandPresenter = (previousDismissableViewController(from: presenter?.presentingViewController) ?? DrawerConstants.root).value(if: { $0 != presenter })
    
    var newOrigin: CGFloat { statusBarHeight + 10 }
    var grandParentYTranslation = 10 as CGFloat
    var statusBarHeight: CGFloat { statusBarHeightValue(from: containerView) }
    
    override var shouldRemovePresentersView: Bool { false }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        
        var frame: CGRect = .zero
        frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView?.bounds.size ?? UIScreen.main.bounds.size)
        
        if let vc = presentedViewController as? ScrollViewDismissable, !vc.isPresentedFullScreen {
            
            frame.origin.y = UIScreen.main.bounds.height - frame.size.height + 20 + DrawerConstants.cornerRadius
        }
        
        return frame
    }
    
    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onStatusBarChanged),
                                               name: UIApplication.willChangeStatusBarFrameNotification,
                                               object: nil)
        
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(themeChanged),
//                                               name: .themeChanged,
//                                               object: nil)
    }
    
    @objc func themeChanged() {
        
        createSnapshots(forStart: false)
    }
    
    @objc func onStatusBarChanged(_ notification: Notification) {
        
//        UniversalMethods.banner(withTitle: "Status bar frame changed").show(for: 0.3)
    }
    
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        
        presentingViewController.dismiss(animated: true)
    }
    
    func createSnapshots(forStart: Bool) {
        
        let xRatio = (UIScreen.main.bounds.width - 32) / UIScreen.main.bounds.width
        let yRatio = (UIScreen.main.bounds.height - (newOrigin * 2)) / UIScreen.main.bounds.height
        let frame = frameOfPresentedViewInContainerView
        let difference = ((1 - yRatio) * UIScreen.main.bounds.height) / 2
        let sideWidth = ((1 - xRatio) * UIScreen.main.bounds.width) / 2
        
        guard shouldUseBackingSnapshots,
              let leftSnapshot = presenter?.view.resizableSnapshotView(from: .init(x: 0, y: presenter is ViewController ? statusBarHeight + 10 + 10 : 0, width: sideWidth, height: presenter is ViewController ? UIScreen.main.bounds.height : frame.size.height), afterScreenUpdates: false, withCapInsets: .zero),
              let rightSnapshot = presenter?.view.resizableSnapshotView(from: .init(x: UIScreen.main.bounds.width - sideWidth, y: presenter is ViewController ? statusBarHeight + 10 + 10 : 0, width: sideWidth, height: presenter is ViewController ? UIScreen.main.bounds.height : frame.size.height), afterScreenUpdates: false, withCapInsets: .zero),
              let lowerSnapshot = presenter?.view.resizableSnapshotView(from: .init(x: 0, y: frame.height - difference - (presenter is ViewController ? 0 : (20 + DrawerConstants.cornerRadius)), width: UIScreen.main.bounds.width, height: difference/* + 20 + DrawerConstants.cornerRadius*/), afterScreenUpdates: false, withCapInsets: .zero),
              let view = containerView else { return }
        
        [leftSnapshot, rightSnapshot, lowerSnapshot].forEach({ $0.translatesAutoresizingMaskIntoConstraints = false })
        
        self.leftSnapshot = leftSnapshot
        self.rightSnapshot = rightSnapshot
        self.lowerSnapshot = lowerSnapshot
        
        if forStart {
        
            view.addSubview(leftSnapshot)
            view.addSubview(rightSnapshot)
            view.addSubview(lowerSnapshot)
            
        } else {
            
            view.insertSubview(leftSnapshot, at: view.subviews.endIndex - 1)
            view.insertSubview(rightSnapshot, at: view.subviews.endIndex - 1)
            view.insertSubview(lowerSnapshot, at: view.subviews.endIndex - 1)
        }

        NSLayoutConstraint.activate([
            
            leftSnapshot.topAnchor.constraint(equalTo: view.topAnchor, constant: statusBarHeight + 10 + 10),
            leftSnapshot.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftSnapshot.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20 + DrawerConstants.cornerRadius),
            leftSnapshot.widthAnchor.constraint(equalToConstant: sideWidth),
            rightSnapshot.topAnchor.constraint(equalTo: view.topAnchor, constant: statusBarHeight + 10 + 10),
            rightSnapshot.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rightSnapshot.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 20 + DrawerConstants.cornerRadius),
            rightSnapshot.widthAnchor.constraint(equalToConstant: sideWidth),
            lowerSnapshot.heightAnchor.constraint(equalToConstant: difference),
            lowerSnapshot.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            lowerSnapshot.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            lowerSnapshot.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        lowerSnapshot.transform = .init(translationX: 0, y: difference)
        
        leftSnapshot.clipsToBounds = true
        leftSnapshot.layer.cornerRadius = DrawerConstants.cornerRadius
        leftSnapshot.transform = .init(translationX: 0, y: UIScreen.main.bounds.height)
        
        rightSnapshot.clipsToBounds = true
        rightSnapshot.layer.cornerRadius = DrawerConstants.cornerRadius
        rightSnapshot.transform = .init(translationX: 0, y: UIScreen.main.bounds.height)
        
//        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
//        lowerSnapshot.addGestureRecognizer(recognizer)
//
//        let other = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
//        leftSnapshot.addGestureRecognizer(other)
    }
    
    override func presentationTransitionWillBegin() {
        
        guard let presenter = presenter else { return }

        containerView?.insertSubview(dimmingView, at: 0)
        presentedView?.clipsToBounds = true
        
        if let vc = presentedViewController as? ScrollViewDismissable, !vc.isPresentedFullScreen {
            
            presentedView?.layer.cornerRadius = DrawerConstants.cornerRadius
        }

        if let vc = presentedViewController as? StatusBarControlling {
            
            vc.useLightStatusBar = (vc as? ScrollViewDismissable)?.isPresentedFullScreen == false
        }
        
        createSnapshots(forStart: true)
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            
            dimmingView.alpha = 1.0
            
            return
        }
        
        (presentedViewController as? ViewControllerOperationAttaching)?.presentationPreparation()
        (presenter as? ViewControllerOperationAttaching)?.presentationPreparation()
        
        if animateWithPresentation, let dismissable = self.presentedViewController as? ScrollViewDismissable, let animation = dismissable.presentationAnimation {
            
            // risky, but it gives me what I want
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.allowUserInteraction, .curveEaseOut], animations: animation, completion: nil) })
        }
        
        if #available(iOS 11, *) { } else {
            
            presenter.view.layer.animate(#keyPath(CALayer.cornerRadius), from: 0, to: DrawerConstants.cornerRadius, duration: coordinator.transitionDuration, timingFunctionName: .linear)
        }
        
        if #available(iOS 11, *) { } else {
            
            coordinator.animateAlongsideTransition(in: presenter.view, animation: { _ in
                
                if use3DTransforms {
                    
                    presenter.view.layer.transform = self.transform3D(for: presenter, completed: true)
//                    (presenter.presentationController as? PresentationController)?.snapshot?.layer.transform = self.transform3D(for: presenter, completed: true)
                    
                } else {
                
                    presenter.view.transform = self.transform(for: presenter, completed: true)
//                    (presenter.presentationController as? PresentationController)?.snapshot?.transform = self.transform(for: presenter, completed: true)
                }
                
            }, completion: nil)
            
            coordinator.animateAlongsideTransition(in: grandPresenter?.view, animation: { _ in
                
                if use3DTransforms {
                    
                    self.grandPresenter?.view.layer.transform = self.transform3D(for: self.grandPresenter, completed: true).concatenating(.translation(x: 0, y: self.grandParentYTranslation, z: 1.00001))
                    
                } else {
                
                    self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true).translatedBy(x: 0, y: self.grandParentYTranslation)
                }
                
            }, completion: nil)
        }
        
        coordinator.animate(alongsideTransition: { context in
            
            self.dimmingView.alpha = 1.0
            self.dimmingView.frame.size.height = self.statusBarHeight + DrawerConstants.cornerRadius + 10
            self.leftSnapshot?.transform = .identity
            self.rightSnapshot?.transform = .identity
            self.lowerSnapshot?.transform = .identity
            
            (self.presentedViewController as? ViewControllerOperationAttaching)?.complementaryPresentationAnimation()
            
//            UIView.animateKeyframes(withDuration: context.transitionDuration, delay: 0, options: .calculationModeCubic, animations: {
//
//                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.8, animations: { appDelegate.window?.transform = .init(translationX: 20, y: 0) })
//
//            }, completion: nil)
            
            if #available(iOS 11, *) {
                
                presenter.view.layer.cornerRadius = DrawerConstants.cornerRadius
                
                if use3DTransforms {
                    
                    presenter.view.layer.transform = self.transform3D(for: presenter, completed: true)
                    self.grandPresenter?.view.layer.transform = self.transform3D(for: self.grandPresenter, completed: true).concatenating(.translation(x: 0, y: self.grandParentYTranslation, z: 1.00001))
                    
                    (presenter.presentationController as? PresentationController)?.leftSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: 100, y: 1, z: 1.00001))//self.transform3D(for: presenter, completed: true)
                    (self.grandPresenter?.presentationController as? PresentationController)?.leftSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: 100, y: 1, z: 1.00001))
                    
                    (presenter.presentationController as? PresentationController)?.rightSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: -100, y: 1, z: 1.00001))//self.transform3D(for: presenter, completed: true)
                    (self.grandPresenter?.presentationController as? PresentationController)?.rightSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: -100, y: 1, z: 1.00001))
                
                } else {
                    
                    presenter.view.transform = self.transform(for: presenter, completed: true)
                    self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true).translatedBy(x: 0, y: self.grandParentYTranslation)
                    
                    (presenter.presentationController as? PresentationController)?.leftSnapshot?.transform = self.transform(for: presenter, completed: true)
                    (self.grandPresenter?.presentationController as? PresentationController)?.leftSnapshot?.transform = self.transform(for: self.grandPresenter, completed: true).translatedBy(x: 0, y: self.grandParentYTranslation)
                }
            }
        })
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        
        guard let presenter = presenter else { return }
        
        if completed {
            
            DrawerConstants.numberOfControllers += 1
        }
        
        if use3DTransforms {
        
            presenter.view.layer.transform = transform3D(for: presenter, completed: true)
            grandPresenter?.view.layer.transform = transform3D(for: grandPresenter, completed: true).concatenating(.translation(x: 0, y: completed ? grandParentYTranslation : 0, z: 0))
            
            (presenter.presentationController as? PresentationController)?.leftSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: 100, y: 1, z: 0))
            (grandPresenter?.presentationController as? PresentationController)?.leftSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: 100, y: 1, z: 0))
            
            (presenter.presentationController as? PresentationController)?.rightSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: -100, y: 1, z: 1.00001))
            (self.grandPresenter?.presentationController as? PresentationController)?.rightSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: -100, y: 1, z: 0))
            
        } else {
            
            presenter.view.transform = transform(for: presenter, completed: completed)
            grandPresenter?.view.transform = transform(for: grandPresenter, completed: true).translatedBy(x: 0, y: completed ? grandParentYTranslation : 0)
            
            (presenter.presentationController as? PresentationController)?.leftSnapshot?.transform = transform(for: presenter, completed: completed)
            (grandPresenter?.presentationController as? PresentationController)?.leftSnapshot?.transform = transform(for: grandPresenter, completed: true).translatedBy(x: 0, y: completed ? grandParentYTranslation : 0)
        }
        
        if presenter is ViewController {
        
            presenter.view.layer.cornerRadius = radius(for: .presentation, completed: completed)
            
            if #available(iOS 11, *) { } else { presenter.view.layer.removeAllAnimations() }
            
            if completed {
                
                presenter.view.bounds.size.height += 1
                presenter.view.bounds.size.height -= 1
            }
        }
        
        (presentedViewController as? ViewControllerOperationAttaching)?.presentationCompletion(completed)
        (presenter as? ViewControllerOperationAttaching)?.presentationCompletion(completed)
    }
    
    override func dismissalTransitionWillBegin() {
        
        guard let coordinator = presentedViewController.transitionCoordinator else {
            
            dimmingView.alpha = 0.0
            
            return
        }
        
        (presentedViewController as? ViewControllerOperationAttaching)?.dismissalPreparation()
        (presenter as? ViewControllerOperationAttaching)?.dismissalPreparation()
        
        // apparently the `animateTransition` method in the animation controller is not called when a transition is not animated, thus the presented subview is simply removed here.
        if !coordinator.isAnimated {
            
            presentedView?.removeFromSuperview()
            
            if presenter is ViewController || (presenter as? ScrollViewDismissable)?.isPresentedFullScreen == true {
                  
                presenter?.view.layer.cornerRadius = 0
            }
            
            if let vc = presentingViewController as? StatusBarControlling, let previous = presenter as? StatusBarControlling {
                
                vc.useLightStatusBar = previous.useLightStatusBar
            }
            
            if use3DTransforms {
            
                self.presenter?.view.layer.transform = .identity
                self.grandPresenter?.view.layer.transform = self.transform3D(for: self.grandPresenter, completed: true)
                
                (self.presenter?.presentationController as? PresentationController)?.leftSnapshot?.layer.transform = .identity
                (self.grandPresenter?.presentationController as? PresentationController)?.leftSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: 100, y: 1, z: 0))
                
                (self.presenter?.presentationController as? PresentationController)?.rightSnapshot?.layer.transform = .identity
                (self.grandPresenter?.presentationController as? PresentationController)?.rightSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: -100, y: 1, z: 0))
            
            } else {
                
                self.presenter?.view.transform = .identity
                self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true)
                
                (self.presenter?.presentationController as? PresentationController)?.leftSnapshot?.transform = .identity
                (self.grandPresenter?.presentationController as? PresentationController)?.leftSnapshot?.transform = self.transform(for: self.grandPresenter, completed: true)
            }
            
            dimmingView.isHidden = true
            leftSnapshot?.isHidden = true
            rightSnapshot?.isHidden = true
            lowerSnapshot?.isHidden = true
            
            return
        }
        
        if !coordinator.isInteractive {
            
            if let vc = presentingViewController as? StatusBarControlling, let previous = presenter as? StatusBarControlling {
                
                vc.useLightStatusBar = previous.useLightStatusBar
            }
        
            if #available(iOS 11, *) { } else {

                if presenter is ViewController || (presenter as? ScrollViewDismissable)?.isPresentedFullScreen == true {
                      
                    presenter?.view.layer.animate(#keyPath(CALayer.cornerRadius), from: DrawerConstants.cornerRadius, to: 0, duration: coordinator.transitionDuration, timingFunctionName: .linear)
                }
            }
        }
        
        if #available(iOS 11, *) { } else {
            
            coordinator.animateAlongsideTransition(in: presenter?.view, animation: { _ in
                
                if use3DTransforms {
                
                    self.presenter?.view.layer.transform = .identity
                
                } else {
                    
                    self.presenter?.view.transform = .identity
                }
                
            }, completion: nil)
            
            coordinator.animateAlongsideTransition(in: grandPresenter?.view, animation: { _ in
                
                if use3DTransforms {
                
                    self.grandPresenter?.view.layer.transform = self.transform3D(for: self.grandPresenter, completed: true)
                
                } else {
                    
                    self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true)
                }
                
            }, completion: nil)
        }
        
        coordinator.animate(alongsideTransition: { context in
            
            if self.presenter is ViewController {
                
                self.presenter?.view.layoutIfNeeded()
            }
            
            self.dimmingView.alpha = 0.0
            self.dimmingView.frame.size.height = self.containerView?.bounds.height ?? UIScreen.main.bounds.height
            
            self.leftSnapshot?.transform = .init(translationX: 0, y: UIScreen.main.bounds.height)
            self.rightSnapshot?.transform = .init(translationX: 0, y: UIScreen.main.bounds.height)
            self.lowerSnapshot?.transform = .init(translationX: 0, y: self.lowerSnapshot?.frame.size.height ?? 0)
            
            (self.presentedViewController as? ScrollViewDismissable)?.complementaryDismissalAnimation()
            
            if #available(iOS 11, *) {
                
                if self.presenter is ViewController || (self.presenter as? ScrollViewDismissable)?.isPresentedFullScreen == true {
                    
                    self.presenter?.view.layer.cornerRadius = 0
                }
                
                if use3DTransforms {
                    
                    self.presenter?.view.layer.transform = .identity
                    self.grandPresenter?.view.layer.transform = self.transform3D(for: self.grandPresenter, completed: true)
                    
                    (self.presenter?.presentationController as? PresentationController)?.leftSnapshot?.layer.transform = .identity
                    (self.grandPresenter?.presentationController as? PresentationController)?.leftSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: 100, y: 1, z: 0))
                    
                    (self.presenter?.presentationController as? PresentationController)?.rightSnapshot?.layer.transform = .identity
                    (self.grandPresenter?.presentationController as? PresentationController)?.rightSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: -100, y: 1, z: 0))
                
                } else {
                    
                    self.presenter?.view.transform = .identity
                    self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true)
                    
                    (self.presenter?.presentationController as? PresentationController)?.leftSnapshot?.transform = .identity
                    (self.grandPresenter?.presentationController as? PresentationController)?.leftSnapshot?.transform = self.transform(for: self.grandPresenter, completed: true)
                }
            }
        })
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        
        guard let presenter = presenter else { return }
        
        guard let coordinator = presentedViewController.transitionCoordinator, coordinator.isAnimated else {
            
            var viewIndex: Int?
            var parent: UIView?
            
            if presenter is ViewController, let superview = presenter.view.superview, let index = superview.subviews.firstIndex(of: presenter.view) {

                presenter.view.removeFromSuperview()
                viewIndex = index
                parent = superview
            }
            
            (presentedViewController as? ViewControllerOperationAttaching)?.dismissalCompletion(completed)
            (presenter as? ViewControllerOperationAttaching)?.dismissalCompletion(completed)
            
            if presenter is ViewController, let superview = parent, let index = viewIndex {

                superview.insertSubview(presenter.view, at: index)
            }
            
            
            return
        }
        
        if completed {
            
            DrawerConstants.numberOfControllers -= 1
        }
        
        if use3DTransforms {
            
            presenter.view.layer.transform = completed ? .identity : transform3D(for: presenter, completed: true)
            grandPresenter?.view.layer.transform = transform3D(for: grandPresenter, completed: true).concatenating(.translation(x: 0, y: completed ? 0 : grandParentYTranslation, z: 1.00001))
            
            (presenter.presentationController as? PresentationController)?.leftSnapshot?.layer.transform = completed ? .identity : CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: 100, y: 1, z: 0))
            (grandPresenter?.presentationController as? PresentationController)?.leftSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: 100, y: 1, z: 0))
            
            (self.presenter?.presentationController as? PresentationController)?.rightSnapshot?.layer.transform = completed ? .identity : CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: -100, y: 1, z: 0))
            (self.grandPresenter?.presentationController as? PresentationController)?.rightSnapshot?.layer.transform = CATransform3D.scale(x: 1, y: 0.5, z: 1.00001).concatenating(.translation(x: -100, y: 1, z: 0))
            
        } else {
            
            presenter.view.transform = completed ? .identity : transform(for: presenter, completed: true)
            grandPresenter?.view.transform = transform(for: grandPresenter, completed: true).translatedBy(x: 0, y: completed ? 0 : grandParentYTranslation)
            
            (presenter.presentationController as? PresentationController)?.leftSnapshot?.transform = completed ? .identity : transform(for: presenter, completed: true)
            (grandPresenter?.presentationController as? PresentationController)?.leftSnapshot?.transform = transform(for: grandPresenter, completed: true).translatedBy(x: 0, y: completed ? 0 : grandParentYTranslation)
        }
        
        if presenter is ViewController || (presenter as? ScrollViewDismissable)?.isPresentedFullScreen == true {
        
            presenter.view.layer.cornerRadius = completed ? 0 : DrawerConstants.cornerRadius
            
            if #available(iOS 11, *) { } else { presenter.view.layer.removeAllAnimations() }
        }
        
        if !completed, let coordinator = presentedViewController.transitionCoordinator, !coordinator.isInteractive, let vc = presentingViewController as? StatusBarControlling {

            vc.useLightStatusBar = (vc as? ScrollViewDismissable)?.isPresentedFullScreen == false
        }
        
        var viewIndex: Int?
        var parent: UIView?

        if presenter is ViewController, completed, let superview = presenter.view.superview, let index = superview.subviews.firstIndex(of: presenter.view) {

            presenter.view.removeFromSuperview()
            viewIndex = index
            parent = superview
        }

        (presentedViewController as? ViewControllerOperationAttaching)?.dismissalCompletion(completed)
        (presenter as? ViewControllerOperationAttaching)?.dismissalCompletion(completed)

        if presenter is ViewController, completed, let superview = parent, let index = viewIndex {

            superview.insertSubview(presenter.view, at: index)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        super.viewWillTransition(to: size, with: coordinator)
        
        guard presentedViewController.transitionCoordinator == nil else { return }
        #warning("Still some issues during rotation")
        coordinator.animate(alongsideTransition: { _ in }, completion: { _ in
            
            if self.grandPresenter == nil {
                
                if use3DTransforms {

                    self.presenter?.view.layer.transform = .identity
                    
                } else {
                    
                    self.presenter?.view.transform = .identity
                }
                
                self.presenter?.view.frame = .init(origin: .zero, size: size)
                
                if use3DTransforms {

                    self.presenter?.view.layer.transform = self.transform3D(for: self.presenter, completed: true)
                    
                } else {
                    
                    self.presenter?.view.transform = self.transform(for: self.presenter, completed: true)
                }

            } else if self.grandPresenter is ViewController {
                
                if use3DTransforms {

                    self.grandPresenter?.view.layer.transform = .identity
                    
                } else {
                    
                    self.grandPresenter?.view.transform = .identity
                }
                
                self.grandPresenter?.view.frame = .init(origin: .zero, size: size)
                
                if use3DTransforms {

                    self.grandPresenter?.view.layer.transform = self.transform3D(for: self.grandPresenter, completed: true).concatenating(.translation(x: 0, y: self.grandParentYTranslation, z: 1.00001))
                    self.presenter?.view.layer.transform = self.transform3D(for: self.presenter, completed: true)
                    
                } else {
                    
                    self.presenter?.view.transform = self.transform(for: self.presenter, completed: true)
                    self.grandPresenter?.view.transform = self.transform(for: self.grandPresenter, completed: true).translatedBy(x: 0, y: self.grandParentYTranslation)
                }
            }
        })
    }

    override func containerViewWillLayoutSubviews() {
        
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
    
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        
        var difference: CGFloat {
            
            guard let vc = presentedViewController as? ScrollViewDismissable, !vc.isPresentedFullScreen else { return 0 }
            
            return statusBarHeight + 20
        }
        
        return .init(width: parentSize.width, height: parentSize.height - difference + 20 + DrawerConstants.cornerRadius) // `20 + DrawerConstants.cornerRadius` takes care of swiping up instead of down during dismissal
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        
        guard presentedViewController.transitionCoordinator == nil else { return }
        
        if #available(iOS 11, *) { } else {
        
            if let dismissable = presentedViewController as? ScrollViewDismissable & UIViewController {
            
                dismissable.view.layer.animate(#keyPath(CALayer.cornerRadius), from: dismissable.isPresentedFullScreen ? DrawerConstants.cornerRadius : 0, to: dismissable.isPresentedFullScreen ? 0 : DrawerConstants.cornerRadius, duration: 0.3, timingFunctionName: .linear)
            }
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.containerView?.setNeedsLayout()
            self.containerView?.layoutIfNeeded()
            
            if #available(iOS 11, *), let dismissable = self.presentedViewController as? ScrollViewDismissable & UIViewController {
                
                dismissable.view.layer.cornerRadius = dismissable.isPresentedFullScreen ? 0 : DrawerConstants.cornerRadius
            }
        
        }, completion: { _ in
            
            if let dismissable = self.presentedViewController as? ScrollViewDismissable & UIViewController {
                
                dismissable.view.layer.cornerRadius = dismissable.isPresentedFullScreen ? 0 : DrawerConstants.cornerRadius
            }
        })
    }
}

extension PresentationController {
    
    func transform(for vc: UIViewController?, completed: Bool) -> CGAffineTransform {
        
        guard completed else { return .identity }
        
        if let vc = vc as? ScrollViewDismissable, !vc.isPresentedFullScreen {
            
            let ratio = (UIScreen.main.bounds.width - 32) / UIScreen.main.bounds.width
            let height = frameOfPresentedViewInContainerView.height
            let newHeight = height * ratio
            let translation = (height - newHeight) / 2
            
            return CGAffineTransform.init(scaleX: ratio, y: ratio).concatenating(.init(translationX: 0, y: -translation - 10))
            
        } else {
            
            let fullScreenPresentationExtraHeight: CGFloat = vc is ViewController ? 0 : (20 + 16)
            
            return .init(scaleX: (UIScreen.main.bounds.width - 32) / UIScreen.main.bounds.width, y: (UIScreen.main.bounds.height + fullScreenPresentationExtraHeight - (newOrigin * 2)) / (UIScreen.main.bounds.height + fullScreenPresentationExtraHeight))
        }
    }
    
    func transform3D(for vc: UIViewController?, completed: Bool) -> CATransform3D {
        
        guard completed else { return .identity }
        
        if let vc = vc as? ScrollViewDismissable, !vc.isPresentedFullScreen {
        
            let ratio = (UIScreen.main.bounds.width - 32) / UIScreen.main.bounds.width
            let height = frameOfPresentedViewInContainerView.height
            let newHeight = height * ratio
            let translation = (height - newHeight) / 2
            
            return CATransform3D.scale(x: ratio, y: ratio, z: 1.00001).concatenating(.translation(x: 0, y: -translation - 10, z: 1.00001))
            
        } else {
            
            let fullScreenPresentationExtraHeight: CGFloat = vc is ViewController ? 0 : (20 + 16)
            
            return .scale(x: (UIScreen.main.bounds.width - 32) / UIScreen.main.bounds.width, y: (UIScreen.main.bounds.height + fullScreenPresentationExtraHeight - (newOrigin * 2)) / (UIScreen.main.bounds.height + fullScreenPresentationExtraHeight), z: 1.00001)
        }
    }
    
    func radius(for state: PresentationAnimator.State, completed: Bool) -> CGFloat {
        
        switch state {
                
            case .presentation: return completed ? DrawerConstants.cornerRadius : 0
            
            case .dismissal: return completed ? 0 : DrawerConstants.cornerRadius
        }
    }
}

extension UIView {
    
   func round(_ corners: UIRectCorner, radius: CGFloat) {
    
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

extension CALayer {
    
    func animate(_ value: String, from start: Any?, to end: Any?, duration: TimeInterval, timingFunctionName: CAMediaTimingFunctionName) {
        
        let animation = CABasicAnimation(keyPath: value)
        animation.duration = duration
        animation.fromValue = start
        animation.toValue = end
        animation.timingFunction = .init(name: timingFunctionName)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        
        add(animation, forKey: value)
    }
}

extension CATransform3D {
    
    static var identity: CATransform3D { CATransform3DIdentity }
    
    func concatenating(_ transform: CATransform3D) -> CATransform3D { CATransform3DConcat(self, transform) }
    
    static func scale(x: CGFloat, y: CGFloat, z: CGFloat) -> CATransform3D { CATransform3DMakeScale(x, y, z) }
    
    static func translation(x: CGFloat, y: CGFloat, z: CGFloat) -> Self { CATransform3DMakeTranslation(x, y, z) }
}

extension Optional {
    
    func value(if condition: (Wrapped?) -> Bool) -> Wrapped? {
        
        condition(self) ? self : nil
    }
}

extension UIView {
    
    func createCutout(of frame: CGRect) {
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bounds
        maskLayer.fillColor = UIColor.black.cgColor

        // Create the path.
        let path = UIBezierPath(rect: bounds)
        maskLayer.fillRule = .evenOdd

        // Append the overlay image to the path so that it is subtracted.
        path.append(UIBezierPath(rect: frame))
        maskLayer.path = path.cgPath
        
        // Set the mask of the view.
        layer.mask = maskLayer
    }
}
