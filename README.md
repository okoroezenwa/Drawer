# Drawer

My attempt at recreating iOS 13's default modal presentation style using UIPresentationController, UIViewControllerAnimatedTransitioning, and UIPercentDrivenInteraction. I also specifically deal with 2 conflicts that may affect dismissal:

- when within a navigation stack and attempting to dismiss via an edge swipe,
- when within a presented view controller with a scroll view containing a refresh control and attempting to dismiss via a downward swipe.
