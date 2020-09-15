//
//  GameScene.swift
//  FlappyBird
//
//  Created by 伊藤光次郎 on 2020/09/11.
//  Copyright © 2020 kojiro.ito. All rights reserved.
//

import SpriteKit
import AVFoundation

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    var scrollNode:SKNode!
    var wallNode:SKNode!
    var bird:SKSpriteNode!
    var itemNode:SKNode!
    
    //衝突判定カテゴリー
    let birdCategory: UInt32 = 1<<0
    let groundCategory: UInt32 = 1<<1
    let wallCategory:UInt32 = 1<<2
    let scoreCategory:UInt32 = 1<<3
    let itemCategory:UInt32 = 1<<4
    
    //スコア用
    var score = 0
    var scoreLabelNode:SKLabelNode!
    var bestScoreLabelNode:SKLabelNode!
    var userDefaults:UserDefaults = UserDefaults.standard
    
    //アイテムスコア用
    var itemScore = 0
    var itemScoreLabelNode:SKLabelNode!
    
    //サウンド
    let soundIdRing:SystemSoundID = 1000
    
    //SkView上にシーンが表示される時に呼ばれるメソッド
    override func didMove(to view: SKView) {
        
        //重力を設定
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        
        physicsWorld.contactDelegate = self
        
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        
        //スクロールするスプライトの親ノード
        scrollNode = SKNode()
        
        //親ノードをシーンに追加
        addChild(scrollNode)
        
        //壁用ノード
        wallNode = SKNode()
        //wallNodeをscrollNodeに追加
        scrollNode.addChild(wallNode)
        
        //アイテム用ノード
        itemNode = SKNode()
        //itemNodeをscrollNodeに追加
        scrollNode.addChild(itemNode)
        
        setupGround()
        setupCloud()
        setupWall()
        setupBird()
        setupItem()
        setupScoreLabel()
    }
    
    func setupGround(){
        //地面の画像を認識させる。
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        //地面の枚数。
        let needNumber = Int(self.frame.size.width / groundTexture.size().width)+2
        //スクロールアクション
        let moveGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        //元の位置に戻すアクション
        let resetGround = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([moveGround,resetGround]))
        //テクスチャを指定して、ノードを使ってスプライトを作成する。この作ったスプライトを使って地面や鳥などを表示させる。
        
        for i in 0..<needNumber{
            let sprite = SKSpriteNode(texture: groundTexture)
            //スプライトを表示する位置を指定
            sprite.position = CGPoint(
                x: groundTexture.size().width/2 + groundTexture.size().width*CGFloat(i),
                y: groundTexture.size().height/2)
            
            //スプライトにアクションを追加
            sprite.run(repeatScrollGround)
            //地面のスプライトに物理演算を設定する
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            //衝突のカテゴリーを設定する
            sprite.physicsBody?.categoryBitMask = groundCategory
            //衝突時に動かないように設定する
            sprite.physicsBody?.isDynamic = false
            //スプライトをscrollNodeに追加している。
            scrollNode.addChild(sprite)
        }
    }
    
    func setupCloud(){
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud,resetCloud]))
        
        for i in 0..<needCloudNumber{
            let sprite = SKSpriteNode(texture: cloudTexture)
            
            sprite.zPosition = -100
            
            sprite.position = CGPoint(x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i), y: self.size.height - cloudTexture.size().height / 2)
            
            sprite.run(repeatScrollCloud)
            
            scrollNode.addChild(sprite)
            
        }
    }
    func setupWall(){
        let wallTexture = SKTexture(imageNamed: "wall")//画像の読み込み
        
        wallTexture.filteringMode = .linear//画質を優先
        //移動する距離を計算
        let moveingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        //画面の外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x:-moveingDistance, y: 0, duration: 4)
        
        //自信を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall,removeWall])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が通り抜ける隙間の長さを鳥のサイズの3倍とする
        let slit_length = birdSize.height * 3
        
        //隙間いちの上下の振れ幅を鳥のサイズの3倍とする
        let random_y_range = birdSize.height * 3
        
        //下の壁のＹ軸下限位置（中央位置から下方向の最大振れ幅で下の壁を表示する位置）を計算
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y  = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lowest_y = center_y-slit_length/2 - wallTexture.size().height / 2 - random_y_range/2
        
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            //壁関連のノードを乗せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width+wallTexture.size().width/2, y: 0)
            wall.zPosition = -50//雲より手前、地面より奥
            
            //0~random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            //Ｙ軸の加減にランダムな値を足して、下の壁のＹ軸を決定
            let under_wall_y = under_wall_lowest_y + random_y
            
            //下側の壁のスプライトを作成
            let under = SKSpriteNode(texture: wallTexture)
            //下の壁の位置と高さを指定
            under.position = CGPoint(x: 0, y: under_wall_y)
            //下側の壁のスプライトに物理演算を設定
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            //categoryBitMaskで自身のカテゴリーを設定
            under.physicsBody?.categoryBitMask = self.wallCategory
            //衝突時に動かないように設定する
            under.physicsBody?.isDynamic = false
            //壁をシートに追加
            wall.addChild(under)
            
            //上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x:0,y:under_wall_y+wallTexture.size().height+slit_length)
            //上側の壁のスプライトに物理演算を設定
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            //categoryBitMaskで自身のカテゴリーを設定。これで識別できる。
            upper.physicsBody?.categoryBitMask = self.wallCategory
            //衝突時に動かないように設定する
            upper.physicsBody?.isDynamic = false
            //upperをwallノードに追加
            wall.addChild(upper)
            
            wall.run(wallAnimation)
            //動いているwallをwallノードに追加
            self.wallNode.addChild(wall)
            
            //スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width+birdSize.width/2, y: self.frame.height/2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            wall.addChild(scoreNode)
            
            
        })
        //次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁を作成->時間待ち->壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation,waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
    func setupBird(){
        //2種類の鳥の画像を読み込み
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //2種類のテクスチャを交互に変更するアニメーションを作成
        let textureAnimation = SKAction.animate(with: [birdTextureA,birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(textureAnimation)
        
        //スプライトを作成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //物理演算を設定
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height/2)
        
        //衝突した時に回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のCategoryを設置
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        bird.physicsBody?.contactTestBitMask = groundCategory | wallCategory
        
        //アニメーションを設定
        bird.run(flap)
        
        //スプライトをシート追加
        addChild(bird)
    }
    
    func setupItem(){
        
        var groupAction: SKAction!
        
        let wallTexture = SKTexture(imageNamed: "wall")
        
        let itemTexture = SKTexture(imageNamed: "item")
        itemTexture.filteringMode = .linear
        
        let movingDistance = CGFloat(self.frame.size.width + itemTexture.size().width)
        
        let moveItem = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        let removeItem = SKAction.removeFromParent()
        
        let itemAnimation = SKAction.sequence([moveItem,removeItem])
        
        let createItemAnimation = SKAction.run({
            let random = Int.random(in: 0..<3)
            
            let item = SKSpriteNode(texture: itemTexture)
            
            item.position = CGPoint(x: self.frame.size.width+wallTexture.size().width/2, y: self.frame.size.height/2)
            
            item.physicsBody = SKPhysicsBody(circleOfRadius: item.size.height/3)
            
            item.physicsBody?.categoryBitMask = self.itemCategory
            
            item.physicsBody?.contactTestBitMask = self.birdCategory
            
            item.physicsBody?.isDynamic = false
            
            item.run(itemAnimation)
            
            if self.itemNode.children.count == 0 && random == 0{
                self.itemNode.addChild(item)
            }
        })
        
        
        let waitAnimation1sec = SKAction.wait(forDuration: 1)
        
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([waitAnimation,createItemAnimation]))
        
        groupAction = SKAction.sequence([waitAnimation1sec,repeatForeverAnimation])
        
        itemNode.run(groupAction)
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if scrollNode.speed>0{
            //鳥の速度をゼロにする
            bird.physicsBody?.velocity = CGVector.zero
            
            //鳥に縦方向の力を与える
            bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
            
        }else if bird.speed == 0{
            restart()
        }
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        //ゲームオーバーの時は何もしない
        if scrollNode.speed <= 0{
            return
        }
        
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            
            //スコア用の物体と衝突した
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"
            
            var bestScore = userDefaults.integer(forKey: "BEST")
            
            if score > bestScore{
                bestScore = score
                
                bestScoreLabelNode.text = "BEST Score:\(bestScore)"
                
                userDefaults.set(bestScore, forKey: "BEST")
                
                userDefaults.synchronize()
            }
            
        }else if   (contact.bodyA.categoryBitMask & itemCategory) == itemCategory || (contact.bodyB.categoryBitMask & itemCategory) == itemCategory {
            
            //アイテムの物体と衝突した
            print("ItemGet")
            
            AudioServicesPlaySystemSound(soundIdRing)
            
            itemScore += 1
            
            itemScoreLabelNode.text = "Item:\(itemScore)"
            
            itemNode.removeChildren(in: itemNode.children)
            
            
            
            
        }else{
            //壁か地面と衝突した
            print("GameOver")
            
            //スクロールを停止させる
            scrollNode.speed = 0
            
            bird.physicsBody?.collisionBitMask = groundCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi)*CGFloat(bird.position.y)*0.01, duration: 1)
            
            bird.run(roll, completion:{
                
                self.bird.speed=0
                
            })
        }
    }
    
    func restart(){
        score = 0
        
        scoreLabelNode.text = "Score:\(score)"
        
        itemScore = 0
        
        itemScoreLabelNode.text = "Item:\(itemScore)"
        
        bird.position =  CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        bird.physicsBody?.velocity = CGVector.zero
        
        bird.physicsBody?.collisionBitMask = groundCategory | wallCategory
        
        bird.zRotation = 0
        
        wallNode.removeAllChildren()
        
        itemNode.removeAllChildren()
        
        bird.speed = 1
        
        scrollNode.speed = 1
    }
    
    func setupScoreLabel(){
        score = 0
        
        scoreLabelNode = SKLabelNode()
        
        scoreLabelNode.fontColor = UIColor.black
        
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height-60)
        
        scoreLabelNode.zPosition = 100
        
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        scoreLabelNode.text = "Score:\(score)"
        
        self.addChild(scoreLabelNode)
        
        bestScoreLabelNode = SKLabelNode()
        
        bestScoreLabelNode.fontColor = UIColor.black
        
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        
        bestScoreLabelNode.zPosition = 100
        
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        let bestScore = userDefaults.integer(forKey: "BEST")
        
        bestScoreLabelNode.text = "BEST Score:\(bestScore)"
        
        self.addChild(bestScoreLabelNode)
        
        itemScore = 0
        
        itemScoreLabelNode = SKLabelNode()
        
        itemScoreLabelNode.fontColor = UIColor.black
        
        itemScoreLabelNode.position = CGPoint(x:10, y: self.frame.height - 120)
        
        itemScoreLabelNode.zPosition = 100
        
        itemScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        
        itemScoreLabelNode.text = "Item:\(itemScore)"
        
        self.addChild(itemScoreLabelNode)
    }
    
}






