//
//  MainPageViewController.swift
//  Drom
//
//  Created by Дмитрий Болучевских on 10.02.2022.
//

import UIKit
import CoreData
import Network

class MainPageViewController: UIViewController {
    
    static let identifier = "MainPageViewControllerIdentifier"
    
    /// Constant list of url
    var listOfUrls = [
        "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/Myzomela_sanguinolenta_1_-_Windsor_Downs_Nature_Reserve.jpg/1280px-Myzomela_sanguinolenta_1_-_Windsor_Downs_Nature_Reserve.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Aythya_australis_male_-_Hurstville_Golf_Course.jpg/1280px-Aythya_australis_male_-_Hurstville_Golf_Course.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/8/8f/Blue-footed_Booby_%28Sula_nebouxii%29_-one_leg_raised.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dc/Gypful.jpg/1280px-Gypful.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/a/a7/Actitis_hypoleucos_-_Laem_Pak_Bia.jpg/1024px-Actitis_hypoleucos_-_Laem_Pak_Bia.jpg",
        "https://upload.wikimedia.org/wikipedia/commons/thumb/a/ae/Pitta_sordida_-_Sri_Phang_Nga.jpg/1024px-Pitta_sordida_-_Sri_Phang_Nga.jpg"
    ]
    var needToDownload: [String] = []
    var numberToShow = 0
    var listOfImages: [UIImage?] = [] {
        didSet {
            var triger = true
            if listOfImages.isEmpty {
                triger = false
            } else {
                triger = true
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.emptyLabel.isHidden = triger
            }
        }
    }
    
    let collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: UICollectionViewFlowLayout()
        )
        collectionView.register(CardItemCell.self,
                                forCellWithReuseIdentifier: CardItemCell.identifier)
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()
    
    /// Label for empty collectionView with instruction
    let emptyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = .black
        label.text = "Refresh page by scroll down"
        return label
    }()
    
    /// Pull to refresh control
    let refreshControl = UIRefreshControl()
    
    /// Get CoreData context
    static var persistentContainer: NSPersistentContainer = {
       let container = NSPersistentContainer(name: "Drom")
        container.loadPersistentStores { _, error in
            guard error == nil else {
                return
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        MainPageViewController.persistentContainer.viewContext
    }
    var cardsFromCoredata: [CardItems] = []
    
    /// Internet Conection monitor
    var weHaveInternetConection = true
    let monitor = NWPathMonitor()
    let queue = DispatchQueue(label: "InternetConectionMonitor", qos: .background)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)
        
        numberToShow = listOfUrls.count
        needToDownload = listOfUrls
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refreshCollectionView), for: .valueChanged)
        collectionView.addSubview(refreshControl)
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let strongSelf = self else {
                return
            }
            if path.status == .satisfied {
                strongSelf.weHaveInternetConection = true
                strongSelf.numberToShow = strongSelf.needToDownload.count
            } else {
                strongSelf.weHaveInternetConection = false
                strongSelf.numberToShow = strongSelf.cardsFromCoredata.count
            }
        }
        monitor.start(queue: queue)
        monitor.cancel()
        
        getAllCards()
        collectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = view.bounds
        collectionView.backgroundColor = .gray
        title = "Some birds from Wikipedia day photo"
        emptyLabel.frame = CGRect(x: collectionView.frame.width/2 - (collectionView.frame.width/6) - 10,
                                  y: collectionView.frame.height/2,
                                  width: collectionView.frame.width/3 + 20,
                                  height: 60)
    }
    
    func getImage(from url: String) -> UIImage? {
        guard let url = URL(string:url) else {
            print("Failed to get url")
            return nil
        }
        
        guard let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            print("Failed to get data from url")
            return nil
        }
        
        return image
    }
    
    @objc func refreshCollectionView(_ sender: AnyObject) {
        needToDownload = listOfUrls
        numberToShow = needToDownload.count
        
        if weHaveInternetConection {
            clearCoreData()
        }
        getAllCards()
        collectionView.reloadData()
        refreshControl.endRefreshing()
    }
}

// MARK: - CollectionView stack
extension MainPageViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberToShow
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CardItemCell.identifier, for: indexPath) as! CardItemCell
        if listOfImages.count < numberToShow && weHaveInternetConection {
            guard let image = getImage(from: needToDownload[indexPath.row]),
                  let imageData = image.pngData() else {
                print("Failed to get image")
                return cell
            }
            if !itemInCoredata(with: imageData, andUrl: needToDownload[indexPath.row]) {
                createNewItem(with: imageData, andUrl: needToDownload[indexPath.row])
                getAllCards()
            }
            
            cell.configure(with: image)
        } else if listOfImages.count == numberToShow {
            guard let image = listOfImages[indexPath.row] else {
                print("Failed to get image")
                return cell
            }
            cell.configure(with: image)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        UIView.animate(withDuration: 1) {
            guard let cell = collectionView.cellForItem(at: indexPath) else {
                return
            }
            cell.center = CGPoint(x: cell.center.x + cell.frame.width + 10,
                                  y: cell.center.y)
            cell.alpha = 0
        } completion: { [weak self] success in
            guard let strongSelf = self else {
                return
            }
            if success {
                strongSelf.needToDownload.remove(at: indexPath.row)
                strongSelf.listOfImages.remove(at: indexPath.row)
                strongSelf.getAllCards()
                strongSelf.numberToShow -= 1
                collectionView.deleteItems(at: [indexPath])
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.frame.width - 20,
                      height: view.frame.width - 20)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10,
                            left: 10,
                            bottom: 10,
                            right: 10)
    }
    
}

// MARK: - Core Data stack
extension MainPageViewController {
    func getAllCards() {
        guard let models = try? context.fetch(CardItems.fetchRequest()) as? [CardItems] else {
            print("Failed to load data from CoreData")
            return
        }
        cardsFromCoredata = models
        if !models.isEmpty {
            listOfImages = []
            for item in models {
                if needToDownload.contains(item.stringUrl) {
                    guard let data = item.image,
                          let image = UIImage(data: data) else {
                        print("Failed to get image from coredata")
                        return
                    }
                    listOfImages.append(image)
                }
            }
        }
    }
    
    func createNewItem(with data: Data, andUrl url: String) {
        let newItem = CardItems(context: context)
        newItem.image = data
        newItem.stringUrl = url
        
        guard (try? context.save()) != nil else {
            print("Faield to save newItem to CoreData")
            return
        }
    }
    
    func itemInCoredata(with image: Data, andUrl url: String) -> Bool {
        for cardFromCoredata in cardsFromCoredata {
            if cardFromCoredata.stringUrl == url,
               cardFromCoredata.image == image {
                return true
            }
        }
        return false
    }
    
    func clearCoreData() {
        for item in cardsFromCoredata {
            context.delete(item)
            guard (try? context.save()) != nil else {
                print("Failed ti delete item")
                return
            }
        }
    }
}
