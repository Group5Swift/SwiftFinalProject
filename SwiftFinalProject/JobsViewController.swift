//
//  MainViewController.swift
//  SwiftFinalProject
//
//  Created by Dam Vu Duy on 4/7/16.
//  Copyright © 2016 dotRStudio. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD

enum FetchDataMode {
    case Job // job created by employer
    case Seeker // job created by employee
    case Saved // saved jobs
    case Favorited // favorited jobs
}

class JobsViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var mainCollectionView: UICollectionView!
    @IBOutlet weak var mainTabar: UITabBar!
    @IBOutlet weak var backgroundImage: UIImageView!

    var dataMode: FetchDataMode = .Job

    var selectedCell: JobCollectionViewCell?

    var jobs: [Job] = []

    override func viewDidLoad() {
        mainCollectionView.delegate = self
        mainCollectionView.dataSource = self

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
        // Sets shadow (line below the bar) to a blank image
        self.navigationController?.navigationBar.shadowImage = UIImage()
        // Sets the translucent background color
        self.navigationController?.navigationBar.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        // Set translucent. (Default value is already true, so this can be removed if desired.)
        self.navigationController?.navigationBar.translucent = true
        
        if view.frame.size.width < 375 && view.frame.size.height < 500 {
            (mainCollectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize = CGSize(width: 260, height: 300)
        }
        
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        getJobs()
    }
    
    func getJobs() {
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        let completeHandler = {(objects: [PFObject]?, error: NSError?) -> Void in
            if error == nil {
                if let objects = objects as? [Job] {
                    if objects.count > 0 {
                        self.jobs = objects
                        self.mainCollectionView.reloadData()
                        self.setThumbnailBackgroundImage(0)
                    }
                }
            }
            MBProgressHUD.hideHUDForView(self.view, animated: true)
        }
        
        switch dataMode {
        case .Job:
            JobService.getJobs(completeHandler)
        case .Saved:
            JobService.getSavedJobs(completeHandler)
        case .Seeker:
            JobService.getSeekers(completeHandler)
        default:
            JobService.getJobs(completeHandler)
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.sharedApplication().statusBarStyle = .LightContent
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.sharedApplication().statusBarStyle = .Default
    }
    
    @IBAction func onLogout(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName(User.USER_DID_LOGOUT_NOTIFICATION, object: nil)
    }


    @IBAction func onChooseCategory(sender: AnyObject) {
        performSegueWithIdentifier("CategoryView", sender: self)
    }

    @IBAction func onPostNewJob(sender: AnyObject) {
        performSegueWithIdentifier("PostNewJob", sender: nil)
    }
    
    func openJobDetailView(job: Job) {
        performSegueWithIdentifier("ViewJobDetail", sender: job)
    }

    func setThumbnailBackgroundImage(index: Int) {
        self.jobs[index].thumbnail?.getDataInBackgroundWithBlock({ (data: NSData?, error: NSError?) in
            if error == nil {
                self.backgroundImage.image = UIImage(data: data!)
            } else {
                print(error!.localizedDescription)
            }
        }, progressBlock: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ViewJobDetail" {
            let vc = (segue.destinationViewController as! UINavigationController).viewControllers[0] as! JobDetailViewController
            vc.job = sender as? Job
        }
    }
    
    @IBAction func onTapOutside(sender: AnyObject) {
        self.view.endEditing(true)
    }
}

extension JobsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return jobs.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = mainCollectionView.dequeueReusableCellWithReuseIdentifier("JobCollectionCell", forIndexPath: indexPath) as! JobCollectionViewCell

        cell.job = jobs[indexPath.row]
        cell.jobsView = self

        return cell
    }

    func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
    }

    func collectionView(collectionView: UICollectionView, willDisplayCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = mainCollectionView.cellForItemAtIndexPath(indexPath) as! JobCollectionViewCell

        if cell != selectedCell {
            selectedCell?.stopVideo()
            
            if cell.videoView.player?.isStopped() == true {
                cell.playVideo()
            }
            selectedCell = cell
        } else {
            if cell.videoView.player?.isStopped() == false {
                cell.stopVideo()
            } else {
                cell.playVideo()
            }
        }
        
    }
}

extension JobsViewController: UIScrollViewDelegate {
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        let width = UIScreen.mainScreen().bounds.size.width
        
        let layout = self.mainCollectionView.collectionViewLayout as! UICollectionViewFlowLayout
        let cellWidthIncludingSpacing = layout.itemSize.width + layout.minimumLineSpacing
        
        var offset = targetContentOffset.memory
        
//        let index = (offset.x - scrollView.contentInset.left) / cellWidthIncludingSpacing
        let index = (offset.x - 20) / cellWidthIncludingSpacing
        let roundedIndex = round(index)
        
        let x = roundedIndex * cellWidthIncludingSpacing - (width - layout.itemSize.width) / 2 + layout.minimumLineSpacing + 10;
        
        offset = CGPoint(x: x, y: scrollView.contentInset.top)
        
        if Int(roundedIndex) < self.jobs.count {
            setThumbnailBackgroundImage(Int(roundedIndex))
        }

        targetContentOffset.memory = offset
    }
}
