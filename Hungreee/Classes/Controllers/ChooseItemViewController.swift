//
//  ChooseItemViewController.swift
//  Hungreee
//
//  Created by Hiroki Matsue on 6/27/15.
//  Copyright (c) 2015 Hungreee. All rights reserved.
//

import UIKit
import MDCSwipeToChoose
import RKNotificationHub
import GoogleMobileAds

class ChooseItemViewController: UIViewController, MDCSwipeToChooseDelegate {
    
    let ChooseItemButtonHorizontalPadding: CGFloat = 80.0
    let ChooseItemButtonVerticalPadding: CGFloat = 20.0
    var items: [Item] = []
    var frontCardView: ChooseItemView!
    var backCardView: ChooseItemView!
    var numHub: RKNotificationHub!
    @IBOutlet weak var nopeButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var homeButton: UIImageView!
    @IBOutlet weak var nopeBackgroundImabeView: CircleImageView!
    @IBOutlet weak var likeBackgroundImabeView: CircleImageView!
    @IBOutlet weak var bannerView: GADBannerView!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadItems()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        loadItems()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        self.bannerView.rootViewController = self
        self.bannerView.loadRequest(GADRequest())
        
        //show everytime
        let welcomeVc = WelcomeViewController()
        self.presentViewController(welcomeVc, animated: true, completion: nil)
        
        showFirstCards()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //
        // Navigation
        //
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        // Navigation background color
        navigationController?.navigationBar.barTintColor = UIColor(red: 255.0/255.0, green: 204.0/255.0, blue: 0.0/255.0, alpha: 1.0);
        navigationController?.navigationBar.translucent = false;
        
        // Logo in navigation bar
        // TODO: Regenerate good size logo
        var image = UIImage(named: "hungreee_logo")!.resizableImageWithCapInsets(UIEdgeInsetsMake(0, 0, 0, 0), resizingMode: .Stretch)
        let newSize = CGSizeMake(view.frame.width, navigationController!.navigationBar.frame.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.drawInRect(CGRectMake(70.0, 0, newSize.width - 140.0, newSize.height))
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        navigationController?.navigationBar.addSubview(UIImageView(image: image))
        
        // latest numbers
        numHub = RKNotificationHub(view: homeButton)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        // set observer
        print("adding notification")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handlePushNotification:", name: "hungreeework", object: nil)
        
    }

    
    override func viewDidDisappear(animated: Bool) {
        print("removing observer")

        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // observer fired
    func handlePushNotification(notification: NSNotification) {
        numHub.increment()
        numHub.bump()
        
        print("Remote Push Received!!")
        print(notification.userInfo)
        let works = notification.userInfo!["work"] as! String
        let reviewScore = notification.userInfo!["review_avg"] as! Int
        let lat = notification.userInfo!["lat"] as! Double
        let lng = notification.userInfo!["lng"] as! Double
        var item = Item(
            id: "1",
            title: notification.userInfo!["title"] as! String,
            imageUrl: notification.userInfo!["image_url"] as! String,
            paybackTypes: [works],
            reviewScore:  String(reviewScore),
            lat: String("\(lat)"),
            lng: String("\(lng)")
        )
        self.items.append(item)
        showFirstCards()
        layoutButtonsIfNeeded()
    }
    
    func suportedInterfaceOrientations() -> UIInterfaceOrientationMask{
        return UIInterfaceOrientationMask.Portrait
    }
    
    
    // This is called when a user didn't fully swipe left or right.
    func viewDidCancelSwipe(view: UIView) -> Void{
        println("You couldn't decide on \(self.currentItem()?.title)")
    }
    
    // This is called then a user swipes the view fully left or right.
    func view(view: UIView, wasChosenWithDirection: MDCSwipeDirection) -> Void {
        layoutButtonsIfNeeded()
        
        // decrement numHbu!!
        numHub.decrement()
        
        // MDCSwipeToChooseView shows "NOPE" on swipes to the left,
        // and "LIKED" on swipes to the right.
        if(wasChosenWithDirection == MDCSwipeDirection.Left){
            println("You noped: \(self.currentItem()?.title)")
        } else{
            println("You liked: \(self.currentItem()?.title)")
            
            // Customize animation for pushViewController
            var transition = CATransition()
            transition.duration = 0.45
            transition.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            transition.type = kCATransitionMoveIn
            transition.subtype = kCATransitionFromTop
            navigationController!.view.layer.addAnimation(transition, forKey: kCATransition)
            
            // Open next page
            let itemDetailTableViewController = storyboard?.instantiateViewControllerWithIdentifier("ItemDetailTableViewControllerID") as! ItemDetailTableViewController
            itemDetailTableViewController.constructWithItem(currentItem()!)
            navigationController?.pushViewController(itemDetailTableViewController, animated: true)
        }
        
        // MDCSwipeToChooseView removes the view from the view hierarchy
        // after it is swiped (this behavior can be customized via the
        // MDCSwipeOptions class). Since the front card view is gone, we
        // move the back card to the front, and create a new back card.
        if(self.backCardView != nil){
            frontCardView = backCardView
        }
        
        backCardView = self.popItemViewWithFrame(self.backCardViewFrame())
        //if(true){
        // Fade the back card into view.
        if(backCardView != nil){
            self.backCardView.alpha = 0.0
            self.view.insertSubview(self.backCardView, belowSubview: self.frontCardView)
            UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseInOut, animations: {
                self.backCardView.alpha = 1.0
                },completion:nil)
        }
    }
    
    func defaultItems() -> [Item] {
        let items = [
            Item(
                id: "3",
                title: "Let's eat together, Humberger",
                imageUrl: "https://s3-ap-northeast-1.amazonaws.com/makemirror/hungreee/PHOT000000000009A505_500_0.jpg",
                paybackTypes: ["review"],
                reviewScore: "4",
                lat: "35.666851",
                lng: "139.74955"
            ),
            Item(
                id: "4",
                title: "New menu \"Steak\" at Restaurant \"Meat\"",
                imageUrl: "https://s3-ap-northeast-1.amazonaws.com/makemirror/hungreee/PHOT000000000011C7B7.jpg",
                paybackTypes: ["review"],
                reviewScore: "3",
                lat: "35.666851",
                lng: "139.74955"
            ),
            Item(
                id: "5",
                title: "New Great \"Sushi\"",
                imageUrl: "https://s3-ap-northeast-1.amazonaws.com/makemirror/hungreee/PHOT000000000012DDAF.jpg",
                paybackTypes: ["review"],
                reviewScore: "5",
                lat: "35.666851",
                lng: "139.74955"
            ),
            Item(
                id: "1",
                title: "Excellent pizzaaaa!!!",
                imageUrl: "https://farm6.staticflickr.com/5174/5499265262_094f6db195_q_d.jpg",
                paybackTypes: ["review"],
                reviewScore: "2",
                lat: "35.666851",
                lng: "139.74955"
            )
        ]
        
        return items
    }
    
    func popItemViewWithFrame(frame:CGRect) -> ChooseItemView? {
        if(items.count == 0) {
            return nil
        }
        
        // UIView+MDCSwipeToChoose and MDCSwipeToChooseView are heavily customizable.
        // Each take an "options" argument. Here, we specify the view controller as
        // a delegate, and provide a custom callback that moves the back card view
        // based on how far the user has panned the front card view.
        var options:MDCSwipeToChooseViewOptions = MDCSwipeToChooseViewOptions()
        options.delegate = self
        //options.threshold = 160.0
        options.onPan = { state -> Void in
            if(self.backCardView != nil){
                var frame:CGRect = self.frontCardViewFrame()
                self.backCardView.frame = CGRectMake(frame.origin.x, frame.origin.y-(state.thresholdRatio * 10.0), CGRectGetWidth(frame), CGRectGetHeight(frame))
            }
        }
        
        var itemView:ChooseItemView = ChooseItemView(frame: frame, item: self.items[0], options: options)
        self.items.removeAtIndex(0)
        return itemView
    }
    
    func frontCardViewFrame() -> CGRect {
        var horizontalPadding:CGFloat = 20.0
        var topPadding:CGFloat = 60.0
        var bottomPadding:CGFloat = 200.0
        return CGRectMake(horizontalPadding,topPadding,CGRectGetWidth(self.view.frame) - (horizontalPadding * 2), CGRectGetHeight(self.view.frame) - bottomPadding)
    }
    
    func backCardViewFrame() ->CGRect {
        var frontFrame:CGRect = frontCardViewFrame()
        return CGRectMake(frontFrame.origin.x, frontFrame.origin.y + 10.0, CGRectGetWidth(frontFrame), CGRectGetHeight(frontFrame))
    }
    
    func nopeFrontCardView() -> Void {
        self.frontCardView.mdc_swipe(MDCSwipeDirection.Left)
    }
    
    func likeFrontCardView() -> Void {
        self.frontCardView.mdc_swipe(MDCSwipeDirection.Right)
    }
    
    // Mark: Private
    
    private func loadItems() -> Void {
        self.items = defaultItems()
    }
    
    private func layoutButtonsIfNeeded() {
        if backCardView == nil {
            nopeButton.hidden = true
            likeButton.hidden = true
            nopeBackgroundImabeView.hidden = true
            likeBackgroundImabeView.hidden = true
        } else {
            nopeButton.hidden = false
            likeButton.hidden = false
            nopeBackgroundImabeView.hidden = false
            likeBackgroundImabeView.hidden = false
        }
    }
    
    private func showFirstCards() -> Void {
        // Display the first ChooseItemView in front. Users can swipe to indicate
        // whether they like or dislike the item displayed.
        frontCardView = popItemViewWithFrame(frontCardViewFrame())!
        view.addSubview(frontCardView)
        
        // Display the second ChooseItemView in back. This view controller uses
        // the MDCSwipeToChooseDelegate protocol methods to update the front and
        // back views after each user swipe.
        if (items.count > 0) {
        backCardView = popItemViewWithFrame(backCardViewFrame())!
        view.insertSubview(backCardView, belowSubview: frontCardView)
        }
    }
    
    private func currentItem() -> Item? {
        return frontCardView.item
    }
    
    // Mark: IBActions
    
    @IBAction func nopeFrontCardView(sender: UIButton) {
        nopeFrontCardView()
    }
    
    @IBAction func likeFrontCardView(sender: UIButton) {
        likeFrontCardView()
    }
    
    @IBAction func reloadItems(sender: UIButton) {
        loadItems()
        showFirstCards()
        layoutButtonsIfNeeded()
    }
    
}
