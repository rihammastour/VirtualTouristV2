//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Riham Mastour on 22/12/1441 AH.
//  Copyright © 1441 Riham Mastour. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!


//    var dataController: DataController!
    var dataController = (UIApplication.shared.delegate as! AppDelegate).dataController
    var pinSelected:Pin!
    var annotations = [MKAnnotation]()
    
    @IBOutlet weak var deletePinsButton: UIButton!
    
    @IBOutlet weak var appearanceSegment: UISegmentedControl!
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    
    fileprivate func setUpFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        debugPrint(dataController)
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do{
            try fetchedResultsController.performFetch()
        } catch {
            print("can't perform fetch: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action:
            #selector(longTap(_:)))
        mapView.addGestureRecognizer(longPressGesture)

        mapView.delegate = self
        setUpFetchedResultsController()
        showPins()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(deletePins(_:)))
        deletePinsButton.addGestureRecognizer(tap)
        
        setUpFetchedResultsController()
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "photosSegue" {
            if let vc = segue.destination as? PhotoAlbumViewController {
                vc.dataController = dataController
                vc.pin = pinSelected
                vc.appearanceSement = appearanceSegment
                vc.segmentControl(segment: appearanceSegment)

            }
        }
    }
    
    
    @objc func longTap(_ sender: UIGestureRecognizer){
        if sender.state == .ended {
            let touchLocation = sender.location(in: mapView)
            let coordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            addPin(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
    }
    
    func addPin(latitude: Double ,longitude: Double) {
        let pin = Pin(context: dataController.viewContext)
        pin.lon = longitude
        pin.lat = latitude
        pin.creationDate = Date()
        try? dataController.viewContext.save()
    }
    
    @objc func deletePins(_ sender: UIGestureRecognizer) {
          if var result = fetchedResultsController.fetchedObjects {
                for pin in result {
                    for annotaion in annotations {
                        mapView.removeAnnotation(annotaion)
                    }
                    dataController.viewContext.delete(pin)
                    mapView.reloadInputViews()
                    try? dataController.viewContext.save()
              }
            
              print("Successfully deleted")
              result.removeAll()
          }
       }
        
    func showPins(){
    
        for location in fetchedResultsController.fetchedObjects! {
            
            let latitude = location.lat
            let longitude = location.lon
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            self.annotations.append(annotation)
            
        }
        DispatchQueue.main.async {
            self.mapView.addAnnotations(self.annotations)
            
        }
        
        if let lastPin = fetchedResultsController.fetchedObjects?.first {
            zooming(lastPin: lastPin)
            
        }

    }
    
    func zooming(lastPin:Pin){
        let coredinate:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lastPin.coordinate.latitude, lastPin.coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 3.0, longitudeDelta: 3.0)
        let region = MKCoordinateRegion(center: coredinate, span: span)
        self.mapView.setRegion(region, animated: true)
        
    }
    
    @IBAction func segmentControl(_ sender: Any) {
        switch appearanceSegment.selectedSegmentIndex {
            case 0:
                overrideUserInterfaceStyle = .light
            case 1:
                overrideUserInterfaceStyle = .dark
            case 2:
                overrideUserInterfaceStyle = .unspecified
            default:
                break
             }
    }
    
}

extension Pin: MKAnnotation {
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(lat), longitude:  CLLocationDegrees(lon))
    }
    
}


extension TravelLocationsMapViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        guard let pin = anObject as? Pin else {
            return
        }
        
        switch type {
            case .insert:
                DispatchQueue.main.async {
                    self.mapView.addAnnotation(pin)
                }
            case .delete:
                mapView.removeAnnotation(pin)
            case .update:
                mapView.removeAnnotation(pin)
                mapView.addAnnotation(pin)
                   
            case .move:
                break
            default:
                break
        }
    }
    
}


extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
            let reuseId = "pin"
    
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
    
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView!.pinTintColor = .red
                pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            else {
                pinView!.annotation = annotation
            }
    
            return pinView
        }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let annotation = view.annotation
        let annotationLat = annotation?.coordinate.latitude
        let annotationLong = annotation?.coordinate.longitude
        if let result = fetchedResultsController.fetchedObjects {
            for pin in result {
                if pin.lat == annotationLat && pin.lon == annotationLong {
                    pinSelected = pin
                    performSegue(withIdentifier: "photosSegue", sender: self)
                      
                    break
                }
            }
        }
    }
    
    
}
