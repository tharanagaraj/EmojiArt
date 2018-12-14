//
//  EmojiArtViewController.swift
//  EmojiArt
//
//  Created by Thara Nagaraj on 11/18/18.
//  Copyright © 2018 Thara Nagaraj. All rights reserved.
//

import UIKit

extension EmojiArt.EmojiInfo{
    init?(label : UILabel){
        if let attributedString = label.attributedText, let font = label.font{
            x = Int(label.center.x)
            y = Int(label.center.y)
            text = attributedString.string
            size = Int(font.pointSize)
        } else {
        return nil
        }
    }
}



class EmojiArtViewController: UIViewController, UIDropInteractionDelegate, UIScrollViewDelegate , UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate {

    //MARK: Model
    var emojiArt : EmojiArt?{
        get{
            if let url = emojiArtBackgroundImage.url{
                let emojis = emojiArtView.subviews.compactMap{ $0 as? UILabel }.compactMap{EmojiArt.EmojiInfo(label: $0) }
                return EmojiArt(url: url, emojis: emojis)
            }
            return nil
        }
        set{
            emojiArtBackgroundImage = (nil, nil)
            emojiArtView.subviews.compactMap{$0 as? UILabel}.forEach{$0.removeFromSuperview()}
            if let url = newValue?.url{
                imageFetcher = ImageFetcher(fetch: url){(url, image) in
                    DispatchQueue.main.async {
                        self.emojiArtBackgroundImage = (url, image)
                        newValue?.emojis.forEach {
                            let attributedText = $0.text.attributedString(withTextStyle: .body, ofSize: CGFloat($0.size))
                            self.emojiArtView.addLabel(with: attributedText, centered: CGPoint(x : $0.x, y: $0.y))
                        }
                    }
                    
                }
            }
        }
    }
    
    
    
    var emojiArtView = EmojiArtView()
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet{
            scrollView.minimumZoomScale = 0.1
            scrollView.maximumZoomScale = 5.0
            scrollView.delegate = self
            scrollView.addSubview(emojiArtView)
        }
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return emojiArtView
    }
    
    private var _emojiBackgroundImageURL : URL?
    
    var emojiArtBackgroundImage : (url: URL?, image: UIImage?){
        get{
            return (_emojiBackgroundImageURL, emojiArtView.backgroundImage)
        }
        set{
            _emojiBackgroundImageURL = newValue.url;
            scrollView?.zoomScale =  1.0
            emojiArtView.backgroundImage = newValue.image
            let size = newValue.image?.size ?? CGSize.zero
            emojiArtView.frame = CGRect(origin: CGPoint.zero, size: size)
            scrollView.contentSize = size
            scrollViewHeight?.constant = size.height
            scrollViewWidth?.constant = size.width
            if let dropZone = self.dropZone, size.width > 0, size.height > 0 {
                scrollView?.zoomScale = max(dropZone.bounds.size.width/size.width, dropZone.bounds.size.height/size.height)
            }
        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewHeight.constant = scrollView.contentSize.height
        scrollViewWidth.constant = scrollView.contentSize.width
    }
    
    
    
    var emojis = "😡🐮🦐🌶⛸🛷🚴🏾‍♂️🚜💿🈺🇦🇶♲".map {String($0)}
    
    @IBOutlet weak var emojiCollectionView: UICollectionView!{
        didSet{
            emojiCollectionView.dataSource = self
            emojiCollectionView.delegate = self
            emojiCollectionView.dragDelegate = self
            emojiCollectionView.dropDelegate = self
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojis.count
    }
    private var font : UIFont{
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: UIFont.preferredFont(forTextStyle: .body).withSize(64.0))
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath)
        if let emojiCell = cell as? EmojiCollectionViewCell{
            let text = NSAttributedString(string: emojis[indexPath.item], attributes: [.font : font])
            emojiCell.label.attributedText = text
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        //sets the context of the drop. within app or from/to another app
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForAddingTo session: UIDragSession, at indexPath: IndexPath, point: CGPoint) -> [UIDragItem] {
        return dragItems(at: indexPath)
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem]{
        //first get emoji from collectionview, then it's outlet, then it's attributed string.
        if let attributedString = (emojiCollectionView.cellForItem(at: indexPath) as? EmojiCollectionViewCell)?.label?.attributedText{
            let dragItem  = UIDragItem(itemProvider: NSItemProvider(object: attributedString))
            //for local dragging, within the same app.
            dragItem.localObject = attributedString
            return [dragItem]
        }
        return []
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSAttributedString.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        //optional is equatable
        let isLocal = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isLocal ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items{
            if let sourceIndexPath = item.sourceIndexPath{
                // local case, within the app
                if let attributedString = item.dragItem.localObject as? NSAttributedString{
                    
                    //performs everything as one operation so it never gets out of sync with your model
                    collectionView.performBatchUpdates({
                        emojis.remove(at: sourceIndexPath.item)
                        emojis.insert(attributedString.string, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            }else{
                let placeholderContext = coordinator.drop(
                    item.dragItem,
                    to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
                item.dragItem.itemProvider.loadObject(ofClass: NSAttributedString.self){(provider, error) in
                    DispatchQueue.main.async {
                        if let attributedString = provider as? NSAttributedString{
                            //always use insertionIndexPath to update the model since the destinationIndexPath could've changed because of changes in collection view
                            placeholderContext.commitInsertion(dataSourceUpdates: {insertionIndexPath in
                                //use self since we're inside the closure.
                                self.emojis.insert(attributedString.string, at: insertionIndexPath.item)
                            })
                        } else{
                            placeholderContext.deletePlaceholder()
                        }
                    }
                }
            }
        }
    }
    
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        if let json = emojiArt?.json{
//            if let jsonString = String(data: json, encoding: .utf8){
                if let url = try? FileManager.default.url(
                    for : .documentDirectory,
                    in : .userDomainMask,
                    appropriateFor : nil,
                    create : true).appendingPathComponent("Untitled.json"){
                    do{
                    try json.write(to: url)
                    print("Saved successfully")
                    } catch let error {
                        print("Couldn't save \(error)")
                    }
                }
//            }
        }
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let url = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true).appendPathComponent("Untitled.json"){
            if let jsonData = try? Data(contentsOf: url){
                emojiArt = EmojiArt(json: jsonData)
            }
        }
    }
    
    
    @IBOutlet weak var dropZone: UIView!{
        didSet{
            dropZone.addInteraction(UIDropInteraction(delegate: self))
        }
    }
    
    
    //accept drops that have both URL and image
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .copy)
    }
    
    
    var imageFetcher : ImageFetcher!
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        imageFetcher = ImageFetcher(){(url, image) in
            DispatchQueue.main.async {
                self.emojiArtBackgroundImage = (url,image)
            }
        }
        
        //nsurl is of type ItemProvider, so cast to URL
       session.loadObjects(ofClass: NSURL.self) {nsurls in
        if let url = nsurls.first as? URL{
            self.imageFetcher.fetch(url)
        }
       }
        //uiimage is of type ItemProvider, so cast to URL
        session.loadObjects(ofClass: UIImage.self) {images in
            if let image = images.first as? UIImage{
                 self.imageFetcher.backup = image
            }
        }
    }
}
