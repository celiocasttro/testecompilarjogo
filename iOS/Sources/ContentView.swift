import SwiftUI
import SpriteKit

struct ContentView: View {
    private var scene: SKScene {
        let scene = GameScene()
        scene.size = CGSize(width: 390, height: 844)
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
            .background(Color(red: 0.047, green: 0.071, blue: 0.149))
    }
}

final class GameScene: SKScene {
    private let player = SKShapeNode(rectOf: CGSize(width: 44, height: 44), cornerRadius: 12)
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let titleLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private var blocks: [SKShapeNode] = []
    private var score = 0
    private var spawnTimer: TimeInterval = 0
    private var lastUpdate: TimeInterval = 0
    private var gameOver = false
    private var best = UserDefaults.standard.integer(forKey: "bestScore")

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.047, green: 0.071, blue: 0.149, alpha: 1)
        setupLabels()
        setupPlayer()
    }

    private func setupLabels() {
        titleLabel.text = "DESVIE DOS BLOCOS"
        titleLabel.fontSize = 21
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height - 72)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        scoreLabel.text = "PONTOS: 0"
        scoreLabel.fontSize = 18
        scoreLabel.fontColor = SKColor(red: 0.53, green: 0.9, blue: 1, alpha: 1)
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 108)
        scoreLabel.zPosition = 10
        addChild(scoreLabel)
    }

    private func setupPlayer() {
        player.fillColor = SKColor(red: 0.3, green: 0.86, blue: 1, alpha: 1)
        player.strokeColor = .white
        player.lineWidth = 1.5
        player.position = CGPoint(x: size.width / 2, y: size.height * 0.22)
        player.zPosition = 5
        player.name = "player"
        addChild(player)
    }

    private func spawnBlock() {
        let side = CGFloat.random(in: 30...55)
        let block = SKShapeNode(rectOf: CGSize(width: side, height: side), cornerRadius: 8)
        block.fillColor = SKColor(red: 1, green: 0.25, blue: 0.42, alpha: 1)
        block.strokeColor = SKColor(red: 1, green: 0.63, blue: 0.68, alpha: 1)
        block.lineWidth = 2
        block.position = CGPoint(x: CGFloat.random(in: side...(max(side, size.width - side))), y: size.height + side)
        block.name = "block"
        addChild(block)
        blocks.append(block)
        let duration = max(1.1, 3.0 - Double(score) * 0.018)
        block.run(.sequence([
            .moveTo(y: -side, duration: duration),
            .run { [weak self, weak block] in
                guard let self, let block else { return }
                block.removeFromParent()
                self.blocks.removeAll { $0 === block }
                if !self.gameOver {
                    self.score += 1
                    self.scoreLabel.text = "PONTOS: \(self.score)"
                    if self.score > self.best {
                        self.best = self.score
                        UserDefaults.standard.set(self.best, forKey: "bestScore")
                    }
                }
            }
        ]))
    }

    override func update(_ currentTime: TimeInterval) {
        let dt = lastUpdate == 0 ? 0 : min(0.05, currentTime - lastUpdate)
        lastUpdate = currentTime
        guard !gameOver else { return }
        spawnTimer += dt
        if spawnTimer >= max(0.38, 0.82 - Double(score) * 0.006) {
            spawnTimer = 0
            spawnBlock()
        }
        for block in blocks {
            if block.frame.insetBy(dx: 5, dy: 5).intersects(player.frame.insetBy(dx: 3, dy: 3)) {
                endGame()
                break
            }
        }
    }

    private func endGame() {
        guard !gameOver else { return }
        gameOver = true
        removeAllActions()
        for block in blocks { block.removeAllActions() }
        let shade = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height))
        shade.fillColor = SKColor.black.withAlphaComponent(0.72)
        shade.strokeColor = .clear
        shade.zPosition = 20
        addChild(shade)
        let gameOverLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        gameOverLabel.text = "FIM DE JOGO"
        gameOverLabel.fontSize = 32
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.54)
        gameOverLabel.zPosition = 21
        gameOverLabel.name = "gameOverOverlay"
        addChild(gameOverLabel)
        let result = SKLabelNode(fontNamed: "AvenirNext-Bold")
        result.text = "Pontos: \(score)  •  Recorde: \(best)"
        result.fontSize = 18
        result.fontColor = SKColor(red: 0.53, green: 0.9, blue: 1, alpha: 1)
        result.position = CGPoint(x: size.width / 2, y: size.height * 0.48)
        result.zPosition = 21
        result.name = "gameOverOverlay"
        addChild(result)
        let retry = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
        retry.text = "Toque para jogar novamente"
        retry.fontSize = 17
        retry.fontColor = .white
        retry.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        retry.zPosition = 21
        retry.name = "gameOverOverlay"
        addChild(retry)
    }

    private func restart() {
        removeAllChildren()
        removeAllActions()
        blocks.removeAll()
        score = 0
        spawnTimer = 0
        lastUpdate = 0
        gameOver = false
        setupLabels()
        setupPlayer()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        if gameOver {
            restart()
            return
        }
        movePlayer(to: location)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !gameOver else { return }
        movePlayer(to: touch.location(in: self))
    }

    private func movePlayer(to point: CGPoint) {
        player.position = CGPoint(
            x: min(max(24, point.x), size.width - 24),
            y: min(max(size.height * 0.12, point.y), size.height * 0.78)
        )
    }
}
