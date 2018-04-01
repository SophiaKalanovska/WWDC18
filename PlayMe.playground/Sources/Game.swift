import UIKit
import XCPlayground

import GameplayKit

import AVFoundation

let playerBass = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "bassloop", withExtension: "wav")!)
let playerDrum = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "drumloop", withExtension: "wav")!)
let playerGuitar = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "guitarloop", withExtension: "wav")!)
let playerMix = try! AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "mixloop", withExtension: "wav")!)



var cardsLeft = 4
public extension UIImage { // (2)
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        guard let cgImage = image!.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

let cardWidth = CGFloat(120)
let cardHeight = CGFloat(210)

public class Card: UIImageView {
    public let x: Int
    public let y: Int
    public init(image: UIImage?, x: Int, y: Int) {
        self.x = x
        self.y = y
        super.init(image: image)
        self.backgroundColor = .gray
        self.layer.cornerRadius = 10.0
        self.isUserInteractionEnabled = true
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


public class GameController: UIViewController {

    public var padding = CGFloat(20) {
        didSet {
            resetGrid()
        }
    }
    
    public var backImage: UIImage = UIImage(
        color: .red ,
        size: CGSize(width: cardWidth, height: 3.99))!

    var viewWidth: CGFloat {
        get {
            return 4 * cardWidth + 5 * padding
        }
    }
    
    var viewHeight: CGFloat {
        get {
            return 4 * cardHeight + 5 * padding
        }
    }
    
    var shuffledNumbers = [Int]()
    
    var firstCard: Card?
    
    @objc func handleTap(gr: UITapGestureRecognizer) {
        let v = view.hitTest(gr.location(in: view), with: nil)!
        if let card = v as? Card {
            UIView.transition(
                with: card, duration: 0.5,
                options: .transitionFlipFromLeft,
                animations: {card.image = UIImage(named: String(card.tag))}) {
                    _ in
                    card.isUserInteractionEnabled = false
                    if let pCard = self.firstCard {
                        if pCard.tag == card.tag {
                            self.play(card: pCard)
                            cardsLeft = cardsLeft - 1
                            UIView.animate(
                                withDuration: 0.5,
                                animations: {card.alpha = 0.0},
                                completion: {_ in card.removeFromSuperview()})
                            UIView.animate(
                                withDuration: 0.5,
                                animations: {pCard.alpha = 0.0},
                                completion: {_ in pCard.removeFromSuperview()})
                            if (cardsLeft == 0){
                                sleep(4)
                                playerDrum.stop()
                                playerGuitar.stop()
                                playerBass.stop()
                                playerMix.stop()
                            }
                            
                        } else {
                            UIView.transition(
                                with: card,
                                duration: 0.5,
                                options: .transitionFlipFromLeft,
                                animations: {card.image = self.backImage})
                            { _ in card.isUserInteractionEnabled = true }
                            UIView.transition(
                                with: pCard,
                                duration: 0.5,
                                options: .transitionFlipFromLeft,
                                animations: {pCard.image = self.backImage})
                            { _ in pCard.isUserInteractionEnabled = true }
                        }
                        self.firstCard = nil
                    } else {
                        self.firstCard = card
                    }
            }
        }
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = CGSize(width: viewWidth, height: viewHeight)
        shuffle()
        setupGrid()
        // uncomment later:
        let tap = UITapGestureRecognizer(target: self, action: #selector(GameController.handleTap(gr:)))
        view.addGestureRecognizer(tap)
        
    }
    
    func play(card : Card){
        if (card.tag == 1){
            playerDrum.play()
            playerDrum.numberOfLoops = -1
        }
        if (card.tag == 2){
            playerGuitar.play()
            playerGuitar.numberOfLoops = -1
            playerGuitar.volume = 0.6
        }
        if (card.tag == 3){
            playerBass.play()
            playerBass.numberOfLoops = -1
            playerGuitar.volume = 1.0
        }
        if (card.tag == 4){
            playerMix.play()
            playerMix.numberOfLoops = -1
            playerMix.volume = 0.2
        }
        
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func loadView() {
        view = UIView()
        view.backgroundColor = .black
        view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        playerDrum.play()
        playerDrum.pause()
        playerGuitar.play()
        playerGuitar.pause()
        playerBass.play()
        playerBass.pause()
        playerMix.play()
        playerMix.pause()
    }
    
    
    func shuffle() {
        let numbers = (1...4).flatMap{[$0, $0]}
        shuffledNumbers =
            GKRandomSource.sharedRandom().arrayByShufflingObjects(in: numbers) as! [Int]
    }
    

    func cardNumberAt(x: Int, _ y: Int) -> Int {
        assert(0 <= x && x < 2 && 0 <= y && y < 4)
        
        return shuffledNumbers[2*x + y]
    }

    func centerOfCardAt(x: Int, _ y: Int) -> CGPoint {
        assert(0 <= x && x < 2 && 0 <= y && y < 2)
        let (w, h) = (cardWidth + padding, cardHeight + padding)
        return CGPoint(
            x: CGFloat(x) * w + w/2 + padding/2,
            y: CGFloat(y) * h + h/2 + padding/2)
        
    }
    
    func setupGrid() {
        for i in 0..<4 {
            for j in 0..<2 {
                let n = cardNumberAt(x: i, j)
                let card = Card(image: UIImage(named: String(n)), x: i, y: j)
                card.tag = n
                card.center = centerOfCardAt(x: i, j)
                view.addSubview(card)
            }
        }
    }

    
    func resetGrid() {
        view.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
        for v in view.subviews {
            if let card = v as? Card {
                card.center = centerOfCardAt(x : card.x,  card.y)
            }
        }
        
    }
    
    override public func viewDidAppear(_ animated: Bool){
        for v in view.subviews {
            if let card = v as? Card {   
                UIView.transition(
                    with: card,
                    duration: 1.0,
                    options: .transitionFlipFromLeft,
                    animations:{
                        card.image =  self.backImage
                },completion: nil)
            }
        }
    }
    
    
}
