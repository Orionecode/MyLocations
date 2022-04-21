//
//  LocationsViewController.swift
//  MyLocations
//
//  Created by 曾一笑 on 2022/4/19.
//

import UIKit
import CoreData
import CoreLocation

class LocationsViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    // 数据库接口传入点（An object space to manipulate and track changes to managed objects.）
    var managedObjectContext: NSManagedObjectContext!
    // 懒加载控制器
    lazy var fetchedResultsController: NSFetchedResultsController<Location> = {
        // 1 - 确定要fetch的对象类型，创建fetchRequest
        let fetchRequest = NSFetchRequest<Location>()
        // 2 - 声明对象实体
        let entity = Location.entity()
        fetchRequest.entity = entity
        // 3 - 告诉对象以类型中的时间顺序索取
        let sortDescriptor1 = NSSortDescriptor(key: "category", ascending: true)
        let sortDescriptor2 = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor1, sortDescriptor2]
        // 限制fetch大小，先返回20条数据
        fetchRequest.fetchBatchSize = 20

        // 初始化NSFetchedResultsController
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "category", cacheName: "Locations")

        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        performFetch()
        navigationItem.rightBarButtonItem = editButtonItem
    }

    deinit {
        fetchedResultsController.delegate = nil
    }

    // MARK: - Table view data source
    override func numberOfSections(
        in tableView: UITableView
    ) -> Int {
        return fetchedResultsController.sections!.count
    }

    override func tableView(
        _ tableView: UITableView,
        titleForHeaderInSection section: Int
    ) -> String? {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.name
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as! LocationCell
        let location = fetchedResultsController.object(at: indexPath)
        cell.configure(for: location)
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let location = fetchedResultsController.object(at: indexPath)
            managedObjectContext.delete(location)
            do {
                try managedObjectContext.save()
            } catch {
                fatalCoreDataError(error)
            }
        }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditLocation" {
            let controller = segue.destination as! LocationDetailViewController
            controller.managedObjectContext = managedObjectContext

            if let indexPath = tableView.indexPath(for: sender as! UITableViewCell) {
                let location = fetchedResultsController.object(at: indexPath)
                controller.locationToEdit = location
            }
        }
    }

    // MARK: - Helper methods
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalCoreDataError(error)
        }
    }
}

// MARK: - NSFetchedResultsController Delegate Extension
// 这个Delegate用来观察NSFetchedResultsController是否发生了改变，如果有——>更新tableView
extension LocationsViewController {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("*** controllerWillChangeContent ***")
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?
    ) {
        switch type {
        case .insert:
            print("*** NSFetchedResultChangeInsert (object) ***")
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            print("*** NSFetchedResultChangeInsert (object) ***")
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .move:
            print("*** NSFetchedResultsChangeMove (object) ***")
            tableView.deleteRows(at: [indexPath!], with: .fade)
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .update:
            print("*** NSFetchedResultsChangeUpdate (object) ***")
            if let cell = tableView.cellForRow(at: indexPath!) as? LocationCell {
                let location = controller.object(at: indexPath!) as! Location
                cell.configure(for: location)
            }
        @unknown default:
            print("*** NSFetchedResults unknown type ***")
        }
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange sectionInfo: NSFetchedResultsSectionInfo,
        atSectionIndex sectionIndex: Int,
        for type: NSFetchedResultsChangeType
    ) {
        switch type {
        case .insert:
            print("*** NSFetchedResultsChangeInsert (section) ***")
            tableView.insertSections(
                IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            print("*** NSFetchedResultsChangeDelete (section) ***")
            tableView.deleteSections(
                IndexSet(integer: sectionIndex), with: .fade)
        case .update:
            print("*** NSFetchedResultsChangeUpdate (section) ***")
        case .move:
            print("*** NSFetchedResultsChangeMove (section) ***")
        @unknown default:
            print("*** NSFetchedResults unknown type ***")
        }
    }

    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        print("*** controllerDidChangeContent ***")
        tableView.endUpdates()
    }
}

