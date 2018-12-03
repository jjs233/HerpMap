//
//  ViewController.swift
//  HerpMap
//  Created by Justin Sung on 11/25/18.
//  Copyright © 2018 Justin Sung. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SQLite
import Foundation

// Define value type for entries in our datalog
struct herpEntry {
    
    // Name of the entry
    var herp: String?
    
    // Date the entry was made
    var date: String?
    
    // Additional notes about the entry
    var notes: String?
}

// Define class type for annotations on the map
class herpMapAnnotation: NSObject, MKAnnotation {
    
    // Location where the entry was made
    var coordinate: CLLocationCoordinate2D
    
    // Text shown under annotation
    var title: String?
    
    // Initialize herpMapAnnotation
    init(coordinate: CLLocationCoordinate2D, title: String?) {
        self.coordinate = coordinate
        self.title = title
        
        super.init()
    }
}

class ViewController: UIViewController {
    
    // Declare location manager
    let locationManager = CLLocationManager()
    
    // Scope required for database
    var database: Connection!
    
    // SQLite database to store all uploaded information
    let herpsTable = Table("Herps")
    
    // Array to store annotations for easy reference
    var herpsLoc = [herpMapAnnotation]()
    
    // Array to store entries for easy reference
    var herpEntries = [herpEntry]()
    
    // Declare columns
    let herp = Expression<String>("herp")
    let lat = Expression<Double>("lat")
    let long = Expression<Double>("long")
    let date = Expression<String>("date")
    let notes = Expression<String>("notes")
    
    // Need a variable with scope that locationManager can update
    var crtLat: Double = 0
    var crtLong: Double = 0
    
    // Gets current Date in NSDate format and converts it to a string
    let crtDate = Date().makeString(dateFormat: "MM-dd")

    // Map outlet
    @IBOutlet weak var herpMap: MKMapView!
    
    // Function to transfer data between the two view controllers
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Not entirely sure how this line works - copied syntax from https://youtu.be/7fbTHFH3tl4?t=437
        let tableController = segue.destination as! TableViewController
        tableController.Entries = herpEntries
        
    }
    
    // Functino called when the app loads
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            
            // Create file directory
            let documentDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            
            // Create file "Herps" with extension "sqlite3"
            let fileUrl = documentDirectory.appendingPathComponent("Herps").appendingPathExtension("sqlite3")
            
            // Create connection that saves to "Herps" file
            let database = try Connection(fileUrl.path)
            self.database = database
            
        } catch{
            print(error)
        }
        
        // Declare what the chart will look like when we create it
        let createChart = self.herpsTable.create { (table) in
            table.column(self.herp)
            table.column(self.lat)
            table.column(self.long)
            table.column(self.date)
            table.column(self.notes)
            
        }
        
        // Try to create the chart
        do {
            try self.database.run(createChart)
            
        } catch {
            print(error)
        }
        
        // Request permission to use user's location
        self.locationManager.requestWhenInUseAuthorization()
        
        // If user has granted permission
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        // Register MapKit annotations with map
        self.herpMap.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        
        // Load in data from database to entries and annotations arrays
        do {
            let herps = try self.database.prepare(self.herpsTable)
            
            // Iterate over rows in database
            for i in herps {
                
                // Store columns "herp", "date", and "notes" into entries array
                let loadEntry = herpEntry(herp: "\(i[self.herp])", date: "\(i[self.date])", notes: "\(i[self.notes])")
                self.herpEntries.insert(loadEntry, at: 0)
                
                // Store columns "herp" and location("lat","long") into annotations array
                let loadCoord = CLLocationCoordinate2D(latitude: i[self.lat], longitude: i[self.long])
                let loadAnnotation = herpMapAnnotation(coordinate: loadCoord, title: "\(i[self.herp])")
                self.herpsLoc.append(loadAnnotation)
                
                // Place annotations on map
                self.herpMap.addAnnotation(loadAnnotation)
            }
        } catch {
            print(error)
        }
        

    }
    
    
    // Upload herp and place annotation when "Upload" button is pressed
    @IBAction func upload(_ sender: Any) {
        
        // Defines an alert prompting user to enter the type of reptile/amphibian they've found and any additional notes
        let alert = UIAlertController(title: "What kind of herp?", message: nil, preferredStyle: .alert)
        alert.addTextField { (tf) in tf.placeholder = "Herp" }
        alert.addTextField { (tf) in tf.placeholder = "Additional notes" }
        
        // If user taps the "Submit" button
        let action1 = UIAlertAction(title: "Submit", style: .default) { (_) in
            
            // Store user input to variables
            guard let herp = alert.textFields?.first?.text, let notes = alert.textFields?.last?.text
                else { return }
            
            //  Declare variables to facilitate storing user input into the database and arrays
            let newCoord = CLLocationCoordinate2D(latitude: self.crtLat, longitude: self.crtLong)
            let newAnnotation = herpMapAnnotation(coordinate: newCoord, title: "\(herp)")
            let newEntry = herpEntry(herp: "\(herp)", date: "\(self.crtDate)", notes: "\(notes)")
            
            // Insert a new entry at the beginning of the entries array so iterating through will result in the most recent results entries being first
            self.herpEntries.insert(newEntry, at: 0)
            
            // Append annotation to annotations array because in that case the order doesn't matter
            self.herpsLoc.append(newAnnotation)
            
            // Place new annotation on the map
            self.herpMap.addAnnotation(newAnnotation)
            
            // Store all information in SQLite database
            let insertHerp = self.herpsTable.insert(self.herp <- herp, self.lat <- self.crtLat, self.long <- self.crtLong, self.date <- self.crtDate, self.notes <- notes)
            do {
                try self.database.run(insertHerp)
            } catch {
                print(error)
            }
            print("Uploaded")
        }
        
        // If user taps the "Cancel" button
        let action2 = UIAlertAction(title: "Cancel", style: .cancel) { (action:UIAlertAction) in
            print("Nothing uploaded")
        }
        
        // Attaches defined actions to the alert
        alert.addAction(action1)
        alert.addAction(action2)
        
        // Presents alert to user
        self.present(alert, animated: true, completion: nil)
        
        
    }
    
    // If user taps "Center" button on map
    @IBAction func recenter(_ sender: Any) {
        
        // Resets and recenters user view onto their location
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(crtLat, crtLong)
        let region = MKCoordinateRegion.init(center: myLocation, span: span)
        herpMap.setRegion(region, animated: true)
    }
    
    //Outlet for switching views
    @IBAction func viewChart(_ sender: Any) {
    }
    
}

// Function to convert type NSDate to a string with a specific format, copied from https://stackoverflow.com/questions/42524651/convert-nsdate-to-string-in-ios-swift/42524788
extension Date
{
    func makeString( dateFormat format  : String ) -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
}

// Extension for delegating annotations onto the map, syntax copied from https://youtu.be/LJ7PG-o5XLA?t=431
extension ViewController: MKMapViewDelegate
{
    func herpMap(_ herpMap: MKMapView, viewfor annotation: MKAnnotation) -> MKAnnotationView? {
        if let herpMapAnnotation = herpMap.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier) as? MKMarkerAnnotationView {
            herpMapAnnotation.animatesWhenAdded = true
            herpMapAnnotation.titleVisibility = .adaptive
            return herpMapAnnotation
        }
        return nil
    }
}

// Extension for location manager delegate that gets called whenever the user location is updated
extension ViewController: CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // Declare newest location as variable
        guard let location = locations.last else { return }
        
        // Modify variables declared earlier with current location
        crtLat = location.coordinate.latitude
        crtLong = location.coordinate.longitude
        
        // Resize and center map on user
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: myLocation, span: span)
        herpMap.setRegion(region, animated: true)
    }
}
