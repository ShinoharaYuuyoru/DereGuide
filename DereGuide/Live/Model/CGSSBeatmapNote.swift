//
//  CGSSBeatmapNote.swift
//  DereGuide
//
//  Created by zzk on 21/10/2017.
//  Copyright © 2017 zzk. All rights reserved.
//

import Foundation

class CGSSBeatmapNote {
    
    // 判定范围类型(用于计算得分, 并非按键类型)
    enum RangeType: Int {
        case click
        case flick
        case slide
        static let hold = RangeType.click
    }
    
    var id: Int!
    var sec: Float!
    var type: Int!
    var startPos: Int!
    var finishPos: Int!
    var status: Int!
    var sync: Int!
    var groupId: Int!
    
    // 0 no press, 1 start, 2 end
    var longPressType = 0
    // used in shifting bpm
    var offset: Float = 0
    
    // from 1 to max combo
    var comboIndex: Int = 1
    
    // context free note information, so each long press slide and filck note need to know the related note
    weak var previous: CGSSBeatmapNote?
    weak var next: CGSSBeatmapNote?
    weak var along: CGSSBeatmapNote?
}

extension CGSSBeatmapNote {
    
    func append(_ anotherNote: CGSSBeatmapNote) {
        self.next = anotherNote
        anotherNote.previous = self
    }
    
    func intervalTo(_ anotherNote: CGSSBeatmapNote) -> Float {
        return anotherNote.sec - sec
    }
    
    var offsetSecond: Float {
        return sec + offset
    }
}

extension CGSSBeatmapNote {
    
    var rangeType: RangeType {
        if type == 3 {
            if status != 2 && status != 1 {
                return .flick
            } else {
                return .slide
            }
        } else if type == 2 {
            return .hold
        } else {
            return .click
        }
    }
    
}
