import GameplayKit

/// Enum que representa os times do jogo.
public enum Team: Int, Codable {
    case sun = 1
    case moon = 2
}

/// Componente que identifica a qual time a entidade pertence.
public class TeamComponent: GKComponent {
    public let team: Team
    
    public init(team: Team) {
        self.team = team
        super.init()
    }
    
    public required init?(coder: NSCoder) {
        guard let rawValue = coder.decodeObject(forKey: "team") as? Int,
              let team = Team(rawValue: rawValue) else {
            return nil
        }
        self.team = team
        super.init(coder: coder)
    }
    
    public override func encode(with coder: NSCoder) {
        coder.encode(team.rawValue, forKey: "team")
        super.encode(with: coder)
    }
}
