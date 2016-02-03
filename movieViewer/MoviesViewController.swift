//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Elijah Bullard on 1/25/16.
//  Copyright © 2016 Elijah Bullard. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UISearchBarDelegate {
    
    @IBOutlet weak var networkErrorView: UIView!
    @IBOutlet weak var NetworkErrorViewText: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var movies: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    var filteredMovies: [NSDictionary]!
    var endpoint: String!
    
    
    
    
    
    //keep UISearchbar property
    lazy   var searchBar:UISearchBar = UISearchBar(frame: CGRectMake(0, 0, 200, 20))
    
    //hide status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        searchBar.delegate = self
        networkErrorView.viewWithTag(0)!.hidden = true
        
        //make network error view visible over collection view
        view.bringSubviewToFront(networkErrorView)
        NetworkErrorViewText.text = "Network Error"
        
        collectionView.backgroundColor = UIColor.blackColor()
        
        
        //implement searchBar
        searchBar.placeholder = "Search by Title"
        var leftNavBarButton = UIBarButtonItem(customView:searchBar)
        self.navigationItem.leftBarButtonItem = leftNavBarButton
        
        
        // Initialize a UIRefreshControl
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "didRefresh", forControlEvents: .ValueChanged)
        collectionView.insertSubview(refreshControl, atIndex: 0)
        
        networkRequest() //declaring the network request function
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let movies = filteredMovies {
            return movies.count
        } else {
            return 0
        }
        
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        filteredMovies = searchText.isEmpty ? movies : movies!.filter({(movie: NSDictionary) -> Bool in
            return (movie["title"] as! String).rangeOfString(searchText, options: .CaseInsensitiveSearch) != nil
        })
        
        self.collectionView.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        //disallow multiple cells from being selected at once
        collectionView.allowsMultipleSelection = false
        let movie = filteredMovies![indexPath.row]
        //let title = movie["title"] as! String
        //let overview = movie["overview"] as! String
        if let posterPath = movie["poster_path"] as? String {
            
        
        let baseUrl = "http://image.tmdb.org/t/p/w500"
        let imageUrl = NSURL(string: baseUrl + posterPath)
        
        
        //cell.titleLabel.text = title
        //cell.overviewLabel.text = overview
        cell.posterImage.setImageWithURL(imageUrl!)
        print("row \(indexPath.row)")
        }
        return cell
    }
    
    //set collection view cell selection action
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.layer.borderColor = .None
        cell!.layer.borderWidth = 2.0
        cell!.layer.borderColor = UIColor.whiteColor().CGColor

    }
    
    //set collection view cell deselection action
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.layer.borderColor = .None
        cell!.layer.borderWidth = 0
    }

    
    // Makes a network request to get updated data
    // Updates the tableView with the new data
    // Hides the RefreshControl
    
    func networkRequest() {
        
        // ... Create the NSURLRequest (myRequest) ...
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string: "https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(apiKey)")
        let request = NSURLRequest(
            URL: url!)
        
        // Configure session so that completion handler is executed on main UI thread
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: nil,
            delegateQueue: NSOperationQueue.mainQueue()
        )
        
        // Display HUD right before the request is made
        
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        let task: NSURLSessionDataTask = session.dataTaskWithRequest(request,
            completionHandler: { (dataOrNil, response, error) in
                
                // Hide HUD once the network request comes back (must be done on main UI thread)
                MBProgressHUD.hideHUDForView(self.view, animated: true)
                
                // ... Use the new data to update the data source ...
                if let data = dataOrNil {
                    if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                        data, options:[]) as? NSDictionary {
                            //print("response: \(responseDictionary)")
                            
                            self.movies = responseDictionary["results"] as? [NSDictionary]
                            self.filteredMovies = self.movies
                            print(self.movies![1]["title"])
                            self.collectionView.reloadData()
                            
                            // Tell the refreshControl to stop spinning
                            self.refreshControl.endRefreshing()
                            
                    }
                }
                else {
                    print("There was a network error")
                    self.networkErrorView.viewWithTag(0)!.hidden = false
                }
        });
        task.resume()
    }
    
    func didRefresh() {
        self.networkErrorView.viewWithTag(0)!.hidden = true
        networkRequest()
    }

    //Shows cancel button when user begins typing in search bar
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    //Removes keyboard when user taps cancel
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.text = ""
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let cell = sender as! UICollectionViewCell
        let indexPath = collectionView.indexPathForCell(cell)
        let movie = movies![indexPath!.row]
        let detailViewController = segue.destinationViewController as! DetailViewController
        detailViewController.movie = movie
        
        
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    
    
}