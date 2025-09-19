import SpriteKit

// Cena de créditos exibida após o final da história
final class CreditsScene: SKScene {
    // Configuração visual
    private let lineSpacing: CGFloat = 36
    private let baseFontSize: CGFloat = 20
    private let titleFontSize: CGFloat = 28
    private let scrollSpeed: CGFloat = 40 // pontos por segundo
    private let pauseDurationAtCenter: TimeInterval = 2.0

    private var container = SKNode()
    private var labels: [SKLabelNode] = []
    private var hasStartedScroll = false
    private var hasFinished = false

    // Textos de créditos
    var creditLines: [String] = [
        "Creditos e Agradecimentos",
        "Direção: Aria Monteiro",
        "Roteiro: Caio Duarte",
        "Arte: L. Nogueira",
        "Programação: M. Salles",
        "Trilha Sonora: N. Figueiredo",
        "QA: P. Carvalho",
        "Produtor: J. Campos",
        "Team Eclipsa"
    ]

    // Callback quando a cena finaliza (após o último texto parar no centro por um tempo)
    var onFinished: (() -> Void)?

    override func didMove(to view: SKView) {
        backgroundColor = .black
        isUserInteractionEnabled = false // sem skip

        addChild(container)
        layoutLabels()
    }

    // Cria labels com a mesma "ideia" de estilo local do EndDialogueScene (fonte/tamanho)
    private func layoutLabels() {
        labels.forEach { $0.removeFromParent() }
        labels.removeAll()

        // Posição inicial: o primeiro texto começa centralizado na tela (verticalmente)
        let centerY = size.height / 2
        var currentY = centerY

        for (index, text) in creditLines.enumerated() {
            let label = SKLabelNode(text: text)
            label.fontName = nil // usa a fonte padrão do projeto/sistema; se houver fonte global, ela prevalece
            label.fontSize = index == 0 || index == creditLines.count - 1 ? titleFontSize : baseFontSize
            label.fontColor = .white
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: size.width / 2, y: currentY)

            container.addChild(label)
            labels.append(label)

            // O primeiro começa no centro. Os demais inicialmente ficam abaixo, empilhados para subir.
            currentY -= lineSpacing
        }

        // Depois de posicionar, iniciamos a animação de rolagem após pequeno atraso para dar ênfase ao título
        run(.wait(forDuration: 0.6)) { [weak self] in
            self?.startScroll()
        }
    }

    private func startScroll() {
        guard !hasStartedScroll, labels.count >= 2 else { return }
        hasStartedScroll = true

        // Comportamento desejado:
        // - O primeiro (título) está no centro. Em seguida, toda a pilha sobe a uma velocidade constante.
        // - O último texto deve parar no centro e ficar lá.
        // Estratégia: rolamos o container até que o último label alinhe com o centro, então paramos.

        // Calcula quanto precisamos mover o container para que o último label chegue ao centro
        guard let last = labels.last else { return }

        // Posição atual do último label no espaço da cena
        let lastInScene = last.convert(last.position, to: self)
        let targetY = size.height / 2
        let deltaY = targetY - lastInScene.y

        // Tempo para percorrer deltaY à velocidade scrollSpeed
        let distance = abs(deltaY)
        let duration = TimeInterval(distance / scrollSpeed)

        let move = SKAction.moveBy(x: 0, y: deltaY, duration: duration)
        move.timingMode = .linear

        let sequence = SKAction.sequence([
            move,
            .wait(forDuration: pauseDurationAtCenter)
        ])

        container.run(sequence) { [weak self] in
            guard let self = self, !self.hasFinished else { return }
            self.hasFinished = true
            self.onFinished?()
        }
    }
}
