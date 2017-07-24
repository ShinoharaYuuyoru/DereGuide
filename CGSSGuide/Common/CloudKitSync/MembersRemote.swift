//
//  MembersRemote.swift
//  CGSSGuide
//
//  Created by zzk on 2017/7/14.
//  Copyright © 2017年 zzk. All rights reserved.
//

import CloudKit

final class MembersRemote: Remote {
    
    static let subscriptionID: String = "My Members"

    typealias R = RemoteMember
    typealias L = Member
    
}
