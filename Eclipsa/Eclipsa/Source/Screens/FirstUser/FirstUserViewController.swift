//
//  FirstUserViewController.swift
//  Eclipsa
//
//  Created by Luan Aiezza on 22/09/25.
//

import UIKit

final class FirstUserViewController: UIViewController {
    private weak var flowDelegate: FirstUserFlowDelegate?
    
    // MARK: - UI
    private let backgroundImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(named: "Menu_Background"))
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        return iv
    }()
    
    private let overlayView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .black
        v.alpha = 0.8
        return v
    }()
    
    private let contentStack: UIStackView = {
        let st = UIStackView()
        st.translatesAutoresizingMaskIntoConstraints = false
        st.axis = .vertical
        st.alignment = .center
        st.spacing = 24
        return st
    }()
    
    private let titleLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.text = NSLocalizedString("firstUserTitle", comment: "")
        lb.textColor = .yellow
        lb.textAlignment = .center
        if let joystickFont = UIFont(name: "CCPixelArcade-Display", size: 28) {
            lb.font = joystickFont
        } else {
            lb.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        }
        return lb
    }()
    
    private func makeButton(title: String) -> UIButton {
        let bt = UIButton(type: .system)
        bt.translatesAutoresizingMaskIntoConstraints = false
        bt.setTitle(title, for: .normal)
        bt.setTitleColor(.white, for: .normal)
        if let joystickFont = UIFont(name: "CCPixelArcade-Joystick", size: 20) {
            bt.titleLabel?.font = joystickFont
        } else {
            bt.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        }
        bt.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        bt.layer.cornerRadius = 8
        bt.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        return bt
    }
    
    private lazy var yesButton: UIButton = {
        let bt = makeButton(title: NSLocalizedString("firstUserButtonYes", comment: ""))
        bt.addTarget(self, action: #selector(handleYes), for: .touchUpInside)
        return bt
    }()
    
    private lazy var noButton: UIButton = {
        let bt = makeButton(title: NSLocalizedString("firstUserButtonNo", comment: ""))
        bt.addTarget(self, action: #selector(handleNo), for: .touchUpInside)
        return bt
    }()
    
    private let buttonStack: UIStackView = {
        let st = UIStackView()
        st.translatesAutoresizingMaskIntoConstraints = false
        st.axis = .horizontal
        st.spacing = 32
        st.distribution = .fillEqually
        return st
    }()
    
    private let infoLabel: UILabel = {
        let lb = UILabel()
        lb.translatesAutoresizingMaskIntoConstraints = false
        lb.text = NSLocalizedString("firstUserText", comment: "")
        lb.textColor = .white
        lb.textAlignment = .center
        lb.numberOfLines = 0
        if let joystickFont = UIFont(name: "CCPixelArcade-Display", size: 16) {
            lb.font = joystickFont
        } else {
            lb.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }
        return lb
    }()
    
    // MARK: - Init
    init(flowDelegate: FirstUserFlowDelegate) {
        self.flowDelegate = flowDelegate
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        view.addSubview(backgroundImageView)
        view.addSubview(overlayView)
        view.addSubview(contentStack)
        
        buttonStack.addArrangedSubview(yesButton)
        buttonStack.addArrangedSubview(noButton)
        
        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(buttonStack)
        contentStack.addArrangedSubview(infoLabel)
        
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            
            buttonStack.leadingAnchor.constraint(equalTo: contentStack.leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: contentStack.trailingAnchor)
        ])
    }
    
    // MARK: - Actions
    @objc private func handleYes() {
        flowDelegate?.firstUserGoTutorial()
    }
    
    @objc private func handleNo() {
        flowDelegate?.firstUserGoHome()
    }
}

protocol FirstUserFlowDelegate: AnyObject {
    func firstUserGoTutorial()
    func firstUserGoHome()
}
