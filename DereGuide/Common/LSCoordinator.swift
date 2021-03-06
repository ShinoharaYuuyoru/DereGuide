//
//  CGSSLiveCoordinator.swift
//  DereGuide
//
//  Created by zzk on 16/8/8.
//  Copyright © 2016年 zzk. All rights reserved.
//

import Foundation

fileprivate let difficultyFactor: [Int: Double] = [
    5: 1.0,
    6: 1.025,
    7: 1.05,
    8: 1.075,
    9: 1.1,
    10: 1.2,
    11: 1.225,
    12: 1.25,
    13: 1.275,
    14: 1.3,
    15: 1.4,
    16: 1.425,
    17: 1.45,
    18: 1.475,
    19: 1.5,
    20: 1.6,
    21: 1.65,
    22: 1.7,
    23: 1.75,
    24: 1.8,
    25: 1.85,
    26: 1.9,
    27: 1.95,
    28: 2,
    29: 2.1,
    30: 2.2,
]

fileprivate let skillBoostValue = [1: 1200]

fileprivate let comboFactor: [Double] = [1.0, 1.1, 1.2, 1.3, 1.4, 1.5, 1.7, 2.0]

fileprivate let criticalPercent: [Int] = [0, 5, 10, 25, 50, 70, 80, 90]

class LSCoordinator {
    var unit: Unit
    var scene: CGSSLiveScene
    var simulatorType: CGSSLiveSimulatorType
    var grooveType: CGSSGrooveType?
    var fixedAppeal: Int?
    var appeal: Int {
        if grooveType != nil {
            return unit.getAppealBy(simulatorType: simulatorType, liveType: CGSSLiveTypes.init(grooveType: grooveType!)).total + Int(unit.supportAppeal)
        } else {
            return unit.getAppealBy(simulatorType: simulatorType, liveType: scene.live.filterType).total + Int(unit.supportAppeal)
        }
    }
    
    var life: Int {
        if grooveType != nil {
            return unit.getAppealBy(simulatorType: simulatorType, liveType: CGSSLiveTypes.init(grooveType: grooveType!)).life
        } else {
            return unit.getAppealBy(simulatorType: simulatorType, liveType: scene.live.filterType).life
        }
    }
    
    var beatmap: CGSSBeatmap {
        return self.scene.beatmap!
    }
    
    init(unit: Unit, scene: CGSSLiveScene, simulatorType: CGSSLiveSimulatorType, grooveType: CGSSGrooveType?) {
        self.unit = unit
        self.scene = scene
        self.simulatorType = simulatorType
        self.grooveType = grooveType
        self.fixedAppeal = unit.usesCustomAppeal ? Int(unit.customAppeal) : nil
    }
    
    var baseScorePerNote: Double {
        return Double(fixedAppeal ?? appeal) / Double(beatmap.numberOfNotes) * (difficultyFactor[scene.stars] ?? 1)
    }
    
    func getCriticalPointNoteIndexes(total: Int) -> [Int] {
        var arr = [Int]()
        for i in criticalPercent {
            arr.append(Int(floor(Float(total * i) / 100)))
        }
        return arr
    }
    
    func getComboFactor(of combo: Int, criticalPoints: [Int]) -> Double {
        var result: Double = 1
        for i in 0..<criticalPoints.count {
            if combo >= criticalPoints[i] {
                result = comboFactor[i]
            } else {
                break
            }
        }
        return result
    }
    
    private func generateLSNotes() -> [LSNote] {
        var lsNotes = [LSNote]()
        
        let baseScore = baseScorePerNote
        
        let notes = beatmap.validNotes
        
        let criticalPoints = getCriticalPointNoteIndexes(total: beatmap.numberOfNotes)
        for i in 0..<notes.count {
            
            let comboFactor = getComboFactor(of: i + 1, criticalPoints: criticalPoints)
    
            let lsNote = LSNote(comboFactor: comboFactor, baseScore: baseScore, sec: notes[i].sec, rangeType: notes[i].rangeType)
            
            lsNotes.append(lsNote)
        }
        return lsNotes
    }
    
    fileprivate func generateBonuses() -> [LSSkill] {
        var bonuses = [LSSkill]()
        let leaderSkillUpContent = unit.getLeaderSkillUpContentBy(simulatorType: simulatorType)
        
        for i in 0...4 {
            let member = unit[i]
            let level = Int(member.skillLevel)
            guard let card = member.card else {
                continue
            }
            if let skill = card.skill {
                let rankedSkill = CGSSRankedSkill(level: level, skill: skill)
                if let type = LSSkillType.init(type: skill.skillFilterType) {
                    let cardType = card.cardType
                    // 计算同属性歌曲 技能发动率的提升数值(groove活动中是同类型的groove类别)
                    var rateBonus = 0
                    if grooveType != nil {
                        if member.card!.cardType == CGSSCardTypes.init(grooveType: grooveType!) {
                            rateBonus += 30
                        }
                    } else {
                        if member.card!.cardType == scene.live.filterType || scene.live.filterType == .allType {
                            rateBonus += 30
                        }
                    }
                    // 计算触发几率提升类队长技
                    if let leaderSkillBonus = leaderSkillUpContent[cardType]?[.proc] {
                        rateBonus += leaderSkillBonus
                    }
                    
                    // 生成所有可触发范围
                    let ranges = rankedSkill.getUpRanges(lastNoteSec: beatmap.timeOfLastNote)
                    for range in ranges {
                        switch type {
                        case .skillBoost:
                            let bonus = LSSkill.init(range: range, value: skillBoostValue[skill.value] ?? 1000, value2: skill.value2, type: .skillBoost, rate: rankedSkill.chance, rateBonus: rateBonus, triggerLife: skill.skillTriggerValue)
                            bonuses.append(bonus)
                        case .deep:
                            if unit.isAllOfType(cardType, isInGrooveOrParade: (simulatorType != .normal)) {
                                fallthrough
                            } else {
                                break
                            }
                        default:
                            let bonus = LSSkill.init(range: range, value: skill.value, value2: skill.value2, type: type, rate: rankedSkill.chance, rateBonus: rateBonus, triggerLife: skill.skillTriggerValue)
                            bonuses.append(bonus)
                        }
                    }
                }
            }
        }
        return bonuses
    }
    
    func generateLiveSimulator() -> CGSSLiveSimulator {
        let bonuses = generateBonuses()
        let notes = generateLSNotes()
        let simulator = CGSSLiveSimulator(notes: notes, bonuses: bonuses, totalLife: life, difficulty: scene.difficulty)
        return simulator
    }
    
    func generateLiveFormulator() -> CGSSLiveFormulator {
        let bonuses = generateBonuses()
        let notes = generateLSNotes()
        let formulator = CGSSLiveFormulator(notes: notes, bonuses: bonuses)
        return formulator
    }
}

fileprivate extension Unit {
    func isAllOfType(_ type: CGSSCardTypes, isInGrooveOrParade: Bool) -> Bool {
        let c = isInGrooveOrParade ? 5 : 6
        var result = true
        for i in 0..<c {
            let member = self[i]
            guard let cardType = member.card?.cardType, cardType == type else {
                result = false
                break
            }
        }
        return result
    }
}
