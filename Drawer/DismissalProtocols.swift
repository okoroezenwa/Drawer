//
//  File.swift
//  Drawer
//
//  Created by Ezenwa Okoro on 14/02/2021.
//  Copyright © 2021 Ezenwa Okoro. All rights reserved.
//

import UIKit

protocol ScrollViewDismissable: ViewControllerOperationAttaching {
    
    /// Whether the current user interface style is a dark theme.
//    var isDarkUserInterfaceStyle: Bool { get }
    
    /// The gesture recogniser, if any, that will work in tandem with the dismissal gesture recogniser.
    var gestureRecogniser: UIPanGestureRecognizer? { get }
    
    /// The minimum offset the scroll view should typically maintain while a dismissal is active.
    var preferredOffset: CGFloat { get }
    
    /// The current offset the scrollview is at during a dismissal.
    var currentOffset: CGFloat { get set }
    
    /// The scroll view, if any, that needs to have scroll functionality maintained during the transition.
    var scroller: UIScrollView? { get }
    
    /// The refresh control, if any, attached to the participating scroll view. If a refresh control is present, dismissal is non-interactive and requires a harder swipe to be invoked.
    var refreshControl: UIRefreshControl? { get }
    
    /// Whether the dismissal attempt begins while the scroll view is at its start point.
    var isAtTop: Bool { get }
    
    /// The animation block, if any, that should follow a presentation.
    var presentationAnimation: (() -> ())? { get }
    
    /// Whether the presented view controller uses the full screen dimensions or is presented as a card.
    var isPresentedFullScreen: Bool { get }
    
    /// Whether snapshots of the presenting view controller should be placed behind the presented view controller. Useful for blurred backgrounds.
    var shouldUseBackingSnapshots: Bool { get }
    
    /// Whether the scroll view does not contain the current touch. If `true`, the dismissal begins immediately.
    func scrollerDoesNotContainTouch(from gr: UIPanGestureRecognizer) -> Bool
    
    /// Whether the dismissal can begin.
    func canBeginDismissal(with gr: UIPanGestureRecognizer) -> Bool
    
    /// Whether the direction currently being scrolled on the scroll view matches the dismissal gesture direction.
    func scrollDirectionMatchesDismissal(via gr: UIPanGestureRecognizer) -> Bool
    
    /// Whether the given dismissal gesture recogniser should be recognised.
    func allowRecognition(of gr: UIGestureRecognizer) -> Bool
    
    /// Any further gestures that should be simultaneously recognised alongside the dismissal gestures.
    func gesturesToBeRecognised(with gr: UIGestureRecognizer) -> Set<UIGestureRecognizer>
    
    /// The animation to use for the presentation and/or dismissal of the presented view controller. If `nil`, the standard bottom-up slide animation is used.
    func animation(for controller: UIViewController, at state: PresentationAnimator.State, finalFrame: CGRect) -> (() -> ())?
    
    func preparation(for controller: UIViewController, at state: PresentationAnimator.State)
    
//    func completion(for controller: UIViewController, completed: Bool)
}

protocol StatusBarControlling: AnyObject {
    
    /// Whether a `lightContent` status bar should be used, otherwise the default for the view controller will be used.
    var useLightStatusBar: Bool { get set }
}

protocol ViewControllerOperationAttaching: AnyObject {
    
    /// The view whose background will be modified during presentation/dismissal.
//    var backgroundView: UIView? { get }
    
    /// Any preparations that need to be made before presenting the view controller.
    func presentationPreparation()
    
    /// Any animations that should occur alongside the presentation transition.
    func complementaryPresentationAnimation()
    
    /// Any completion that needs to occur after presentation.
    func presentationCompletion(_ completed: Bool)
    
    /// Any preparations that need to be made before dimissing the view controller.
    func dismissalPreparation()
    
    /// Any animations that should occur alongside the dismissal transition.
    func complementaryDismissalAnimation()
    
    /// Any completion that needs to occur after dismissal.
    func dismissalCompletion(_ completed: Bool)
}

extension ViewControllerOperationAttaching {
    
//    var backgroundView: UIView? { (self as? UIViewController)?.view }
}

// Default implementations of a few of the protocol properties and methods
extension ScrollViewDismissable {
    
    var presentationAnimation: (() -> ())? { nil }
    
    var isPresentedFullScreen: Bool { false }
    
    var refreshControl: UIRefreshControl? { nil }
    
    var shouldUseBackingSnapshots: Bool { false }
    
    func preparation(for controller: UIViewController, at state: PresentationAnimator.State) {  }
    
//    func completion(for controller: UIViewController, completed: Bool) {  }
    
    func animation(for controller: UIViewController, at state: PresentationAnimator.State, finalFrame: CGRect) -> (() -> ())? { nil }
    
    func scrollDirectionMatchesDismissal(via gr: UIPanGestureRecognizer) -> Bool { gr.translation(in: gr.view).y > 0 }
    
    func canBeginDismissal(with gr: UIPanGestureRecognizer) -> Bool {
        
        if scrollerDoesNotContainTouch(from: gr) {
            
            return true
        }
    
        if let _ = scroller {
            
            return isAtTop && scrollDirectionMatchesDismissal(via: gr)
        }
        
        return true
    }
    
    func allowRecognition(of gr: UIGestureRecognizer) -> Bool { true }
    
    func gesturesToBeRecognised(with gr: UIGestureRecognizer) -> Set<UIGestureRecognizer> { [] }
}

extension ViewControllerOperationAttaching {
    
    func presentationPreparation() {  }
    func complementaryPresentationAnimation() {  }
    func presentationCompletion(_ completed: Bool) {  }
    func dismissalPreparation() {  }
    func complementaryDismissalAnimation() {  }
    func dismissalCompletion(_ completed: Bool) {  }
}

protocol SnapshotContaining: AnyObject {
    var presenterSnapshot: UIView? { get set }
}

protocol ViewController: SnapshotContaining {  }

protocol RequiresPresenterSnapshot: AnyObject {
    
    var snapshotImageView: UIImageView? { get set }
}
