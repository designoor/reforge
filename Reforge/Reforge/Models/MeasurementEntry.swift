import Foundation
import SwiftData

@Model
final class MeasurementEntry {
    var id: UUID
    var date: Date
    var waistCm: Double?
    var chestCm: Double?
    var leftArmCm: Double?
    var rightArmCm: Double?
    var leftThighCm: Double?
    var rightThighCm: Double?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        waistCm: Double? = nil,
        chestCm: Double? = nil,
        leftArmCm: Double? = nil,
        rightArmCm: Double? = nil,
        leftThighCm: Double? = nil,
        rightThighCm: Double? = nil
    ) {
        self.id = id
        self.date = date
        self.waistCm = waistCm
        self.chestCm = chestCm
        self.leftArmCm = leftArmCm
        self.rightArmCm = rightArmCm
        self.leftThighCm = leftThighCm
        self.rightThighCm = rightThighCm
    }
}
