//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Riham Mastour on 22/12/1441 AH.
//  Copyright © 1441 Riham Mastour. All rights reserved.
//

import UIKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    var dataController: DataController!
    var pin: Pin!
    var photosUrl = [URL]()
    var photosSelected = [IndexPath]()
    private var blockOperation = BlockOperation()
    private var blockOperations: [BlockOperation] = []

    
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var imageLabel: UILabel!

    
    
    var fetchedResultsController:NSFetchedResultsController<Photo>!
       
       fileprivate func setUpFetchedResultsController() {
            let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
            let predicate = NSPredicate(format: "pin == %@", self.pin)
            fetchRequest.predicate = predicate
            let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
           
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
    
           setUpFetchedResultsController()
        
        newCollectionButton.isEnabled = false
        
        //no images downloaded yet
          if self.fetchedResultsController.fetchedObjects?.count == 0 {
            //Download images
            getFlickrPhotos()
          }
        
        //Tapping a cell adds it to the current selection, tapping the cell again removes it from the selection
        collectionView.allowsMultipleSelection = true
                       
       }
       
       override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           
           setUpFetchedResultsController()
           
       }
    
    override func viewDidAppear(_ animated: Bool) {
         super.viewDidAppear(animated)
         fetchedResultsController.delegate = self
         try? fetchedResultsController.performFetch()
     }
       
       override func viewDidDisappear(_ animated: Bool) {
           super.viewDidDisappear(animated)
           fetchedResultsController = nil
       }
    
    fileprivate func downloadPhotos(_ url: URL) {
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            if error != nil {
                print(error!)
            }
            if let data = data {
                self.addPhotos(data:data)
                print("successfuly adding Photo")
            }else{
                 print("Failed adding Photo")
            }
        }
        dataTask.resume()
    }
    
    func getFlickrPhotos() {
        FlickrAPI.getPhotos(lat: pin.lat, lon: pin.lon) { (photos,  err) in
                DispatchQueue.main.async {
                    self.imageLabel.isHidden = true
                }

            if let photos = photos as? [PhotoParse] {
                for photo in photos {
                    self.photosUrl.append(URL(string: photo.url_m)!)
                }
                
                if ((self.fetchedResultsController.fetchedObjects?.isEmpty)!) {
                    for url in self.photosUrl {
                        self.downloadPhotos(url)
                        print("successfuly fetching Photo")
                    }
                }
                
                if self.photosUrl.isEmpty {
                    DispatchQueue.main.async {
                        self.imageLabel.isHidden = false
                        self.imageLabel.text = "No Images Found"
                    }
                }
                
            } else {
       
                    
                print(err ?? "Something wrong happened")
            }
        }
    }

    func addPhotos(data: Data) {
         let photo = Photo(context: dataController.viewContext)
        print("adding to coreData")
             photo.creationDate = Date()
        print(data)
             photo.imageData = data
             photo.pin = pin
  
        try? dataController.viewContext.save()
     }
        
     func deletePhotos(){
        var photosToDelete: [Photo] = [Photo]()
        for photo in photosSelected {
            photosToDelete.append(fetchedResultsController.object(at: photo))
        }

        for photo in photosToDelete {
            dataController.viewContext.delete(photo)
            try? dataController.viewContext.save()
        }
        
        photosSelected.removeAll()
     }
    
    
    func activityIndAnim(cell:PhotoAlbumCollectionViewCell, status:Bool) {
        if status == true {
            cell.activityInd.stopAnimating()
            cell.activityInd.isHidden = true
        } else {
            cell.activityInd.isHidden = false
            cell.activityInd.startAnimating()
        }
    }
    
    
    @IBAction func newCollectionPressed(_ sender: UIButton) {
            //if the button named "New Collection" == defualt State
        if sender.currentTitle == "New Collection" {
            guard let fetchedResults = self.fetchedResultsController.fetchedObjects else {
                return
            }
            //remove photos to update
            photosUrl.removeAll()
            for photo in fetchedResults {
                dataController.viewContext.delete(photo)
                try? dataController.viewContext.save()
            }
            
            //get photos to update
            getFlickrPhotos()

            //if the button named "Remove Selected Pictures" when pressed an image
        } else if sender.currentTitle == "Remove Selected Pictures" {
            sender.setTitle("New Collection", for: .normal)
            deletePhotos()
        }
    }

}

extension PhotoAlbumViewController: UICollectionViewDelegate {
    
    //MARK: Restyle cells
      
      func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
          // resize the cell
          return CGSize(width: (view.frame.size.width - (2 * 3)) / 3.0, height: (view.frame.size.width - (2 * 3)) / 3.0)
      }

      func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
          // Minimum Interitem Spacing For Section
          return 3
      }

      func collectionView(_ collectionView: UICollectionView, layout
          collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
          // Minimum Line Spacing For Section
          return 3
      }
      
      func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets{
          // Padding
          return UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
      }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let cell = collectionView.cellForItem(at: indexPath) as! PhotoAlbumCollectionViewCell

        cell.selectedView.isHidden = false
        newCollectionButton.setTitle("Remove Selected Pictures", for: .normal)

        photosSelected.append(indexPath)

    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {

        let cell = collectionView.cellForItem(at: indexPath) as! PhotoAlbumCollectionViewCell

        cell.selectedView.isHidden = true

        photosSelected.remove(at: indexPath.startIndex)

        if photosSelected.count == 0 {
            newCollectionButton.setTitle("New Collection", for: .normal)
        }
    }
}


extension PhotoAlbumViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photosCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        cell.selectedView.isHidden = true

//            DispatchQueue.main.async {
        //start animating
        self.activityIndAnim(cell: cell, status: false)
        //fetching from CoreData
                let photo = self.fetchedResultsController.object(at: indexPath)
        if let image = photo.imageData{
            cell.image.image = UIImage(data:image)
        } else {
            self.imageLabel.isHidden = false
            self.imageLabel.text = "No Images Found"
        }

        //end animating
        self.activityIndAnim(cell: cell, status: true)

                self.newCollectionButton.isEnabled = true
//        }
        return cell

    }
    
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperation = BlockOperation()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let sectionIndexSet = IndexSet(integer: sectionIndex)

        switch type {
        case .insert:
            blockOperation.addExecutionBlock {
                self.collectionView?.insertSections(sectionIndexSet)
            }
        case .delete:
            blockOperation.addExecutionBlock {
                self.collectionView?.deleteSections(sectionIndexSet)
            }
        case .update:
            blockOperation.addExecutionBlock {
                self.collectionView?.reloadSections(sectionIndexSet)
            }
        case .move:
            assertionFailure()
            break
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { break }

            blockOperation.addExecutionBlock {
                self.collectionView?.insertItems(at: [newIndexPath])
            }
        case .delete:
            guard let indexPath = indexPath else { break }

            blockOperation.addExecutionBlock {
                self.collectionView?.deleteItems(at: [indexPath])
            }
        case .update:
            guard let indexPath = indexPath else { break }

            blockOperation.addExecutionBlock {
                self.collectionView?.reloadItems(at: [indexPath])
            }
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }

            blockOperation.addExecutionBlock {
                self.collectionView?.moveItem(at: indexPath, to: newIndexPath)
            }
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates({self.blockOperation.start()}, completion: nil)
    }
}


