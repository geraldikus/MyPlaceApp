//
//  MainViewController.swift
//  MyPlaces
//
//  Created by Anton on 12.04.23.
//

import UIKit
import RealmSwift


class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var places: Result<[Place], Error>!
    private var filtredPlaces: Result<[Place], Error>?
    private var ascendingSorting = true
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    private var isSearchBarHidden = true
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var reversedSortingbutton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let realm = try! Realm()
        let placeResults = realm.objects(Place.self)
        let placeArray = Array(placeResults)
        places = .success(placeArray)
        
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.delegate = self
        
        // Set up the search bar as the table view header
        let searchBar = searchController.searchBar
        searchBar.sizeToFit()
        tableView.tableHeaderView = searchBar
        
        // Hide the search bar when scrolling
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.searchBarStyle = .prominent
        searchController.hidesNavigationBarDuringPresentation = false // если тру, то поиск улетает на место navigation bar
        
        // Hide the search bar at launch
        searchController.isActive = false
        tableView.setContentOffset(CGPoint(x: 0, y: searchBar.frame.height), animated: true)
        
        definesPresentationContext = true
        
    }
    
    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows

        if isFiltering, let filtredPlaces = try? filtredPlaces?.get() {
               // Возвращаем количество элементов в успешном результате фильтрации
               return filtredPlaces.count
           } else if let places = places, case .success(let placesArray) = places {
               // Возвращаем количество элементов в успешном результате
               return placesArray.count
           } else {
               // Возвращаем 0 в случае ошибки или отсутствия результата
               return 0
           }
        
    }
    
    // MARK: cell for row at
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
        
        var place = Place()
        
        if isFiltering, let filtredPlaces = try? filtredPlaces?.get() {
                place = filtredPlaces[indexPath.row]
            } else if case .success(let places) = places {
                place = places[indexPath.row]
            }
        
            cell.nameLabel.text = place.name
            cell.locationLabel.text = place.location
            cell.typeLabel.text = place.type
            cell.imageOfPlace.image = UIImage(data: place.imageData!)
        
            cell.cosmosView.rating = place.rating

        return cell
    }
    // MARK: - Table view Delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if case .success(let places) = places {
            let place = places[indexPath.row]
            let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { (_, _, completion) in
                StorageManager.deleteObject(place)
                var updatedPlaces = places
                updatedPlaces.remove(at: indexPath.row)
                self.places = .success(updatedPlaces)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
        return nil
    }
    
    //  MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "showDetail" {
               guard let indexPath = tableView.indexPathForSelectedRow else { return }
               if let places = places, case .success(let placesArray) = places {
                   let place: Place
                   if isFiltering, let filtredPlaces = try? filtredPlaces?.get() {
                       place = filtredPlaces[indexPath.row]
                   } else {
                       place = placesArray[indexPath.row]
                   }
                   let newPlaceVC = segue.destination as! NewPlaceViewController
                   newPlaceVC.currentPlace = place
               }
           }
    }
    
    @IBAction func unwindSegue(_ segue: UIStoryboardSegue) {
        guard let newPlaceVC = segue.source as? NewPlaceViewController else { return }
        newPlaceVC.savePlace()
        let realm = try! Realm()
        let placeResults = realm.objects(Place.self)
        let placeArray = Array(placeResults)
        places = .success(placeArray)
        tableView.reloadData()
    }
    
    @IBAction func sortedSelection(_ sender: UISegmentedControl) {
       sorting()
    }
    
    @IBAction func reversedSorting(_ sender: Any) {
        
        ascendingSorting.toggle()
        
        if ascendingSorting {
            reversedSortingbutton.image = UIImage(imageLiteralResourceName: "AZ")
        } else {
            reversedSortingbutton.image = UIImage(imageLiteralResourceName: "ZA")
        }
        
        sorting()
    }
    
    private func sorting() {
        
        if case .success(_) = places {
            if case .success(var placesArray) = places {
                   switch segmentedControl.selectedSegmentIndex {
                   case 0:
                       placesArray = placesArray.sorted(by: { $0.date < $1.date })
                   case 1:
                       placesArray = placesArray.sorted(by: { $0.name < $1.name })
                   default:
                       break
                   }
                   if !ascendingSorting {
                       placesArray.reverse()
                   }
                   places = .success(placesArray)
                   tableView.reloadData()
               }
            tableView.reloadData()
        }
    }
}

extension MainViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
       filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        
        if case .success(let placesArray) = places {
                filtredPlaces = .success(placesArray.filter { place in
                    let result = place.name.localizedCaseInsensitiveContains(searchText) || ((place.location ?? "").localizedCaseInsensitiveContains(searchText))
                    
                    return result
                })
                tableView.reloadData()
            }
        }
    }



    
