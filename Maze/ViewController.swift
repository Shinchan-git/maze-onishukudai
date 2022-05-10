//
//  ViewController.swift
//  Maze
//
//  Created by Owner on 2022/05/10.
//

import UIKit
import CoreMotion

class ViewController: UIViewController {
    
    let maze = [
        [1, 0, 0, 0, 1, 0],
        [1, 0, 1, 0, 1, 0],
        [3, 0, 1, 0, 1, 0],
        [1, 1, 1, 0, 0, 0],
        [1, 0, 0, 1, 1, 0],
        [0, 0, 1, 0, 0, 0],
        [0, 1, 1, 0, 1, 0],
        [0, 0, 0, 0, 1, 1],
        [0, 1, 1, 0, 0, 0],
        [0, 0, 1, 1, 1, 2]
    ]
    
    let screenSize = UIScreen.main.bounds.size
    
    var playerView: UIView!
    var playerSightView: UIView!
    var startView: UIView!
    var goalView: UIView!
    var wallRectArray = [CGRect]()

    var playerMotionManager: CMMotionManager!
    
    var speedX: Double = 0.0
    var speedY: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createMaze()
        createPlayerView()
        createPlayerSightView()
        createMotionManager()
        startAccelermeter()
    }
    
    func createMaze() {
        let cellWidth = screenSize.width / CGFloat(maze[0].count)
        let cellHeight = screenSize.height / CGFloat(maze.count)
        let cellOffsetX = cellWidth / 2
        let cellOffsetY = cellHeight / 2
        
        for y in 0..<maze.count {
            for x in 0..<maze[y].count {
                switch maze[y][x] {
                case 1:
                    let wallView = createView(x: x, y: y, width: cellWidth, height: cellHeight, offsetX: cellOffsetX, offsetY: cellOffsetY)
                    wallView.backgroundColor = .darkGray
                    self.view.addSubview(wallView)
                    wallRectArray.append(wallView.frame)
                case 2:
                    startView = createView(x: x, y: y, width: cellWidth, height: cellHeight, offsetX: cellOffsetX, offsetY: cellOffsetY)
                    startView.backgroundColor = .green
                    self.view.addSubview(startView)
                case 3:
                    goalView = createView(x: x, y: y, width: cellWidth, height: cellHeight, offsetX: cellOffsetX, offsetY: cellOffsetY)
                    goalView.backgroundColor = .red
                    self.view.addSubview(goalView)
                default:
                    break
                }
            }
        }
    }

    func createView(x: Int, y: Int, width: CGFloat, height: CGFloat, offsetX: CGFloat, offsetY: CGFloat) -> UIView {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        let view = UIView(frame: rect)
        let center = CGPoint(x: offsetX + width * CGFloat(x), y: offsetY + height * CGFloat(y))
        view.center = center
        
        return view
    }
    
    func createPlayerView() {
        let cellWidth = screenSize.width / CGFloat(maze[0].count)
        let cellHeight = screenSize.height / CGFloat(maze.count)
        playerView = UIView(frame: CGRect(x: 0, y: 0, width: cellWidth / 6, height: cellHeight / 6))
        playerView.center = startView.center
        playerView.backgroundColor = .gray
        self.view.addSubview(playerView)
    }
    
    func createPlayerSightView() {
        let radius = screenSize.width / 2
        playerSightView = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width * 2, height: screenSize.height * 2))
        playerSightView.center = playerView.center
        playerSightView.backgroundColor = .black
        playerSightView.makeHole(at: playerSightView.center, radius: radius)
        self.view.addSubview(playerSightView)
    }
    
    func createMotionManager() {
        playerMotionManager = CMMotionManager()
        playerMotionManager.accelerometerUpdateInterval = 0.02
    }
    
    func startAccelermeter() {
        let handler: CMAccelerometerHandler = {(accelermeterData: CMAccelerometerData?, error: Error?) -> Void in
            self.speedX += accelermeterData!.acceleration.x
            self.speedY += accelermeterData!.acceleration.y
            
            var posX: CGFloat = self.playerView.center.x + CGFloat(self.speedX) / 3
            var posY: CGFloat = self.playerView.center.y - CGFloat(self.speedY) / 3
            
            if posX <= self.playerView.frame.width / 2 {
                self.speedX = 0
                posX = self.playerView.frame.width / 2
            }
            if posY <= self.playerView.frame.height / 2 {
                self.speedY = 0
                posY = self.playerView.frame.height / 2
            }
            if posX >= self.screenSize.width - self.playerView.frame.width / 2 {
                self.speedX = 0
                posX = self.screenSize.width - self.playerView.frame.width / 2
            }
            if posY >= self.screenSize.height - self.playerView.frame.height / 2 {
                self.speedY = 0
                posY = self.screenSize.height - self.playerView.frame.height / 2
            }
            
            for wallRect in self.wallRectArray {
                if wallRect.intersects(self.playerView.frame) {
                    self.gameCheck(result: "Game Over", message: "壁に当たりました")
                    return
                }
            }
            
            if self.goalView.frame.intersects(self.playerView.frame) {
                self.gameCheck(result: "Cler", message: "クリア！！！")
                return
            }
            
            self.playerView.center = CGPoint(x: posX, y: posY)
            self.playerSightView.center = CGPoint(x: posX, y: posY)
        }
        
        playerMotionManager.startAccelerometerUpdates(to: OperationQueue.main, withHandler: handler)
    }
    
    func gameCheck(result: String, message: String) {
        if playerMotionManager.isAccelerometerActive {
            playerMotionManager.stopAccelerometerUpdates()
        }
        
        let gameCheckAlert = UIAlertController(title: result, message: message, preferredStyle: .alert)
        let retryAction = UIAlertAction(title: "再チャレンジする", style: .default, handler: {(action: UIAlertAction!) -> Void in
            self.retry()
        })
        
        gameCheckAlert.addAction(retryAction)
        self.present(gameCheckAlert, animated: true, completion: nil)
    }

    func retry() {
        playerView.center = startView.center
        if !playerMotionManager.isAccelerometerActive {
            self.startAccelermeter()
        }
        speedX = 0.0
        speedY = 0.0
    }
    
}

extension UIView {
    func makeHole(at point: CGPoint, radius: CGFloat) {
        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = .evenOdd
        
        let maskPath = UIBezierPath(rect: self.frame)
        maskPath.move(to: point)
        maskPath.addArc(withCenter: point, radius: radius, startAngle: 0.0, endAngle: 2.0 * CGFloat.pi, clockwise: true)
        maskLayer.path = maskPath.cgPath
        
        self.layer.mask = maskLayer
    }
}
