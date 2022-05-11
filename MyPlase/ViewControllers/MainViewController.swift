//
//  MainViewController.swift
//  MyPlase
//
//  Created by Marina on 30.03.22.
//

import UIKit
import RealmSwift

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var places: Results<Place>!
    private var ascendingSorting = true
    private let searchController = UISearchController(searchResultsController: nil)
    private var filteredPlaces: Results<Place>!
    private var searchBarIsEmpty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    
    @IBOutlet var tableView: UITableView!
   // @IBOutlet var segmentedcontrol: UISegmentedControl!
    @IBOutlet var reversedSortingButton: UIBarButtonItem!
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        places = realm.objects(Place.self)
        
        //Setup the search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    // MARK: - Table view data source

     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         if isFiltering {
             return filteredPlaces.count
         }
         return places.count
    }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
        
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
        
        cell.nameLabel.text = place.name
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        cell.imageOfPlace.image = UIImage(data: place.imageData!)
        cell.cosmosView.rating = place.rating

        return cell
    }

    
    // MARK: Table view deledate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let place = places[indexPath.row]
            StorageManager.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation

     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if segue.identifier == "showDetail"{
             guard let indexPath = tableView.indexPathForSelectedRow else {return}
             
             let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
            // можно записать и так
//             let place: Place
//             if isFiltering {
//                 place = filteredPlaces[indexPath.row]
//             } else {
//                 place = places[indexPath.row]
//             }
             
             let newPlaceVC = segue.destination as! NewPlaceViewController
             newPlaceVC.currentPlace = place
         }
    }

    
    @IBAction func unwindSegue(_ segue: UIStoryboardSegue) {
        
        guard let newPlaceVC = segue.source as? NewPlaceViewController else { return }
        
        newPlaceVC.savePlace()
        tableView.reloadData()
    }

    @IBAction func sortSelection(_ sender: UISegmentedControl) {
        sorting()
    }
    
    @IBAction func reversedSorting(_ sender: Any) {
        ascendingSorting.toggle()
        
        if ascendingSorting {
            reversedSortingButton.image = #imageLiteral(resourceName: "AZ")
        } else {
            reversedSortingButton.image = #imageLiteral(resourceName: "ZA")
        }
        
        sorting()
    }
    private func sorting() {
        
        if segmentedControl.selectedSegmentIndex == 0 {
            places = places.sorted(byKeyPath: "date", ascending: ascendingSorting)
        } else {
            places = places.sorted(byKeyPath: "name", ascending: ascendingSorting)
        }
        
        tableView.reloadData()
    }
}
extension MainViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        
        filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText)
        
        tableView.reloadData()
    }
}

