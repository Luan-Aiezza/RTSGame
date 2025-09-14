//
//  TeamView.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 14/09/25.
//

import UIKit

final class TeamView: UIView {

    /// Callback disparado quando a animação terminar
    var onFinished: (() -> Void)?

    private let logoImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "Eclipsa_Team"))
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.alpha = 0.0
        return iv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .black
        addSubview(logoImageView)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            // Aumenta o tamanho relativo do logo (de 0.6 -> 0.8) ≈ 2x de área visível
            logoImageView.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.7),
            logoImageView.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor, multiplier: 0.7)
        ])
    }

    /// Inicia a sequência de animação: fade in -> hold -> fade out
    /// Duração total aproximada: 10s (3.0 + 4.0 + 3.0)
    func startAnimation(totalDuration: TimeInterval = 10.0) {
        // Durations dobradas em relação à versão anterior (~5s)
        let fadeInDuration: TimeInterval = 3.0
        let fadeOutDuration: TimeInterval = 3.0
        // Garante que o hold não seja negativo caso alguém passe totalDuration menor
        let holdDuration: TimeInterval = max(0.0, totalDuration - (fadeInDuration + fadeOutDuration))

        logoImageView.alpha = 0.0

        UIView.animate(withDuration: fadeInDuration, delay: 0.0, options: [.curveEaseInOut]) { [weak self] in
            self?.logoImageView.alpha = 1.0
        } completion: { [weak self] _ in
            guard let self else { return }
            UIView.animate(withDuration: holdDuration, delay: 0.0, options: [.curveLinear]) {
                // mantém alpha 1.0 durante o hold
                self.logoImageView.alpha = 1.0
            } completion: { [weak self] _ in
                guard let self else { return }
                UIView.animate(withDuration: fadeOutDuration, delay: 0.0, options: [.curveEaseInOut]) { [weak self] in
                    self?.logoImageView.alpha = 0.0
                } completion: { [weak self] _ in
                    self?.onFinished?()
                }
            }
        }
    }
}
