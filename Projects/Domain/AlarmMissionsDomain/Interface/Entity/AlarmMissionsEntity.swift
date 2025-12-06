import Foundation

public struct AlarmMissionsEntity: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let alarmId: UUID
    public let missionType: String
    public let difficulty: Int
    public let config: MissionConfig?
    public let createdAt: Date
    public let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case alarmId = "alarm_id"
        case missionType = "mission_type"
        case difficulty
        case config
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(
        id: UUID,
        alarmId: UUID,
        missionType: String,
        difficulty: Int,
        config: MissionConfig?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.alarmId = alarmId
        self.missionType = missionType
        self.difficulty = difficulty
        self.config = config
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum MissionConfig: Codable, Equatable, Sendable {
    case math(problemCount: Int)
    case qr(requiredCode: String)
    case motion(requiredSteps: Int)
    case shake(requiredShakes: Int)

    private enum CodingKeys: String, CodingKey {
        case type, value
    }

    private enum MissionType: String, Codable {
        case math, qr, motion, shake
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MissionType.self, forKey: .type)
        
        switch type {
        case .math:
            let v = try container.decode([String: Int].self, forKey: .value)
            self = .math(problemCount: v["problemCount"] ?? 1)

        case .qr:
            let v = try container.decode([String: String].self, forKey: .value)
            self = .qr(requiredCode: v["requiredCode"] ?? "")

        case .motion:
            let v = try container.decode([String: Int].self, forKey: .value)
            self = .motion(requiredSteps: v["requiredSteps"] ?? 10)

        case .shake:
            let v = try container.decode([String: Int].self, forKey: .value)
            self = .shake(requiredShakes: v["requiredShakes"] ?? 10)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .math(let problemCount):
            try container.encode(MissionType.math, forKey: .type)
            try container.encode(["problemCount": problemCount], forKey: .value)

        case .qr(let requiredCode):
            try container.encode(MissionType.qr, forKey: .type)
            try container.encode(["requiredCode": requiredCode], forKey: .value)

        case .motion(let requiredSteps):
            try container.encode(MissionType.motion, forKey: .type)
            try container.encode(["requiredSteps": requiredSteps], forKey: .value)

        case .shake(let requiredShakes):
            try container.encode(MissionType.shake, forKey: .type)
            try container.encode(["requiredShakes": requiredShakes], forKey: .value)
        }
    }
}
