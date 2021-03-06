//
//  Remote.swift
//  DereGuide
//
//  Created by Florian on 21/09/15.
//  Copyright © 2015 objc.io. All rights reserved.
//

import CoreData
import CloudKit

enum RemoteRecordChange<T: RemoteRecord> {
    case insert(T)
    case update(T)
    case delete(RemoteIdentifier)
}

enum RemoteError {
    case permanent([RemoteIdentifier])
    case temporary(TimeInterval?)

    var isPermanent: Bool {
        switch self {
        case .permanent: return true
        default: return false
        }
    }
}

extension RemoteError {
    init?(cloudKitError: Error?) {
        guard let error = cloudKitError as NSError? else { return nil }
        if error.permanentCloudKitError {
            self = .permanent(error.partiallyFailedRecordIDsWithPermanentError.map { $0.recordName })
        } else {
            self = .temporary(error.userInfo[CKErrorRetryAfterKey] as? TimeInterval)
        }
    }
}

extension RemoteRecordChange {
    init?(change: CloudKitRecordChange) {
        switch change {
        case .created(let r):
            guard let remoteRecord = T(record: r) else { return nil }
            self = RemoteRecordChange.insert(remoteRecord)
        case .updated(let r):
            guard let remoteRecord = T(record: r) else { return nil }
            self = RemoteRecordChange.update(remoteRecord)
        case .deleted(let id):
            self = RemoteRecordChange.delete(id.recordName)
        }
    }
}

protocol Remote {
    associatedtype R: RemoteRecord
    associatedtype L: RemoteUploadable, RemoteDeletable
    
    static var subscriptionID: String { get }
    var cloudKitContainer: CKContainer { get }
    func setupSubscription()
    func fetchLatestRecords(completion: @escaping ([R], [RemoteError]) -> ())
    func fetchNewRecords(completion: @escaping ([RemoteRecordChange<R>], @escaping (_ success: Bool) -> ()) -> ())
    func upload(_ locals: [L], completion: @escaping ([R], RemoteError?) -> ())
    func remove(_ locals: [L], completion: @escaping ([RemoteIdentifier], RemoteError?) -> ())
}

extension Remote {
    
    var cloudKitContainer: CKContainer {
        return CKContainer.default()
    }
    
    var defaultSortDescriptor: NSSortDescriptor {
        return NSSortDescriptor(key: #keyPath(CKRecord.modificationDate), ascending: false)
    }
    
    func predicateOfUser(_ userID: CKRecordID) -> NSPredicate {
        return NSPredicate(format: "creatorUserRecordID == %@", userID)
    }
    
    private var subscrptionIsCached: Bool {
        get {
            return UserDefaults.standard.value(forKey: "CKSubscription \(Self.subscriptionID)") as? Bool ?? false
        }
    }
    
    private func setSubscriptionCached() {
        UserDefaults.standard.set(true, forKey: "CKSubscription \(Self.subscriptionID)")
    }
    
    func setupSubscription() {
        
        if subscrptionIsCached { return }
        
        cloudKitContainer.fetchUserRecordID { userRecordID, error in
            guard let userID = userRecordID else {
                return
            }
            
            let reference = CKReference(recordID: userID, action: .none)
            
            let predicate = NSPredicate(format: "creatorUserRecordID == %@", reference)

            let info = CKNotificationInfo()
            info.shouldSendContentAvailable = true
            info.soundName = ""
            
            let subscription: CKSubscription
            
            if #available(iOS 10.0, *) {
                let options: CKQuerySubscriptionOptions = [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
                subscription = CKQuerySubscription(recordType: R.recordType, predicate: predicate, subscriptionID: Self.subscriptionID, options: options)
            } else {
                subscription = CKSubscription(recordType: R.recordType, predicate: predicate, subscriptionID: Self.subscriptionID, options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
            }
            subscription.notificationInfo = info
            let op = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
            op.modifySubscriptionsCompletionBlock = { (foo, bar, error: Error?) -> () in
                if let e = error as NSError?, e.code == CKError.serverRejectedRequest.rawValue {
                    // ignore
                } else if error != nil {
                    print("Failed to modify subscription: \(error!)")
                } else {
                    // since we should only register the subscription once, when succeed we set that subscription a flag "cached" in user defaults
                    self.setSubscriptionCached()
                }
            }
            self.cloudKitContainer.publicCloudDatabase.add(op)
        }
    }

    func fetchNewRecords(completion: @escaping ([RemoteRecordChange<R>], @escaping (_ success: Bool) -> ()) -> ()) {
        cloudKitContainer.fetchAllPendingNotifications(changeToken: nil, subcriptionID: Self.subscriptionID) { changeReasons, error, callback in
            guard error == nil else { return completion([], { _ in }) } // TODO We should handle this case with e.g. a clean refetch
            guard changeReasons.count > 0 else { return completion([], callback) }
            self.cloudKitContainer.publicCloudDatabase.fetchRecords(for: changeReasons) { changes, error in
                completion(changes.map { RemoteRecordChange(change: $0) }.flatMap { $0 }, callback)
            }
        }
    }
    
    func fetchRecordsWith(_ predicates: [NSPredicate], _ sortDescriptors: [NSSortDescriptor], completion: @escaping ([R]) -> ()) {
        let query = CKQuery(recordType: R.recordType, predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates))
        query.sortDescriptors = sortDescriptors
        let op = CKQueryOperation(query: query)
        //        op.resultsLimit = maximumNumberOfUnits
        op.fetchAggregateResults(in: self.cloudKitContainer.publicCloudDatabase, previousResults: [], previousErrors: []) { records, errors in
            if errors.count > 0 {
                print(errors)
            }
            completion(records.map { R(record: $0) }.flatMap { $0 })
        }
    }
    
    func fetchRecordsWith(_ predicates: [NSPredicate], _ sortDescriptors: [NSSortDescriptor], resultsLimit: Int, completion: @escaping ([R], CKQueryCursor?, RemoteError?) -> ()) {
        let query = CKQuery(recordType: R.recordType, predicate: NSCompoundPredicate(andPredicateWithSubpredicates: predicates))
        query.sortDescriptors = sortDescriptors
        let op = CKQueryOperation(query: query)
        op.resultsLimit = resultsLimit
        
        var results = [CKRecord]()
        op.recordFetchedBlock = { record in
            results.append(record)
        }
        
        op.queryCompletionBlock = { cursor, error in
            completion(results.map { R(record: $0) }.flatMap { $0 }, cursor, RemoteError(cloudKitError: error))
        }
  
        cloudKitContainer.publicCloudDatabase.add(op)
        
    }
    
    func fetchRecordsWith(cursor: CKQueryCursor, resultsLimit: Int, completion: @escaping ([R], CKQueryCursor?, RemoteError?) -> ()) {
        let op = CKQueryOperation(cursor: cursor)
        op.resultsLimit = resultsLimit
        var results = [CKRecord]()
        op.recordFetchedBlock = { record in
            results.append(record)
        }
        op.queryCompletionBlock = { cursor, error in
            completion(results.map { R(record: $0) }.flatMap { $0 }, cursor, RemoteError(cloudKitError: error))
        }
        cloudKitContainer.publicCloudDatabase.add(op)
    }
    
    func fetchRecordsForCurrentUserWith(_ predicates: [NSPredicate], _ sortDescriptors: [NSSortDescriptor], completion: @escaping ([R]) -> ()) {
        cloudKitContainer.fetchUserRecordID { userRecordID, error in
            guard let userID = userRecordID else {
                completion([])
                return
            }
            var allPredicates = [self.predicateOfUser(userID)]
            allPredicates.append(contentsOf: predicates)
            self.fetchRecordsWith(allPredicates, sortDescriptors, completion: completion)
        }
    }
    
    func fetchLatestRecords(completion: @escaping ([R], [RemoteError]) -> ()) {
        cloudKitContainer.fetchUserRecordID { userRecordID, error in
            guard let userID = userRecordID else {
                completion([], [])
                return
            }
            let query = CKQuery(recordType: R.recordType, predicate: self.predicateOfUser(userID))
            query.sortDescriptors = [self.defaultSortDescriptor]
            let op = CKQueryOperation(query: query)
            //        op.resultsLimit = maximumNumberOfUnits
            op.fetchAggregateResults(in: self.cloudKitContainer.publicCloudDatabase, previousResults: [], previousErrors: []) { records, errors in
                if errors.count > 0 {
                    print(errors)
                }
                completion(records.map { R(record: $0) }.flatMap { $0 }, errors.map(RemoteError.init).flatMap { $0 })
            }
        }
    }
    
    func upload(_ locals: [L], completion: @escaping ([R], RemoteError?) -> ()) {
        let recordsToSave = locals.map { $0.toCKRecord() }
        let op = CKModifyRecordsOperation(recordsToSave: recordsToSave,
                                          recordIDsToDelete: nil)
        op.modifyRecordsCompletionBlock = { modifiedRecords, _, error in
            if error != nil {
                print(error!)
            }
            let remoteRecords = modifiedRecords?.map { R(record: $0) }.flatMap { $0 } ?? []
            let remoteError = RemoteError(cloudKitError: error)
            completion(remoteRecords, remoteError)
        }
        cloudKitContainer.publicCloudDatabase.add(op)
    }
    
    func modify(_ locals: [L], modification: @escaping ([CKRecord], @escaping () -> ()) -> (), completion: @escaping ([R], RemoteError?) -> ()) {
        
        let op = CKFetchRecordsOperation(recordIDs: locals.flatMap{ $0.remoteIdentifier }.map(CKRecordID.init(recordName:)))
        
        op.fetchRecordsCompletionBlock = { records, error in
            modification(records?.map { $0.value } ?? []) {
                let op = CKModifyRecordsOperation(recordsToSave: records?.map { $0.value }, recordIDsToDelete: nil)
                op.modifyRecordsCompletionBlock = { modifiedRecords, _, error in
                    let remoteRecords = modifiedRecords?.map { R(record: $0) }.flatMap { $0 } ?? []
                    let remoteError = RemoteError(cloudKitError: error)
                    completion(remoteRecords, remoteError)
                }
                self.cloudKitContainer.publicCloudDatabase.add(op)
            }
        }
        cloudKitContainer.publicCloudDatabase.add(op)
    }
    
    func remove(_ locals: [L], completion: @escaping ([RemoteIdentifier], RemoteError?) -> ()) {
        let recordIDsToDelete = locals.map { (l: L) -> CKRecordID in
            guard let name = l.remoteIdentifier else { fatalError("Must have a remote ID") }
            return CKRecordID(recordName: name)
        }
        let op = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsToDelete)
        op.modifyRecordsCompletionBlock = { _, deletedRecordIDs, error in
            completion((deletedRecordIDs ?? []).map { $0.recordName }, RemoteError(cloudKitError: error))
        }
        cloudKitContainer.publicCloudDatabase.add(op)
    }
    
    func remove(_ ids: [RemoteIdentifier], completion: @escaping ([RemoteIdentifier], RemoteError?) -> ()) {
        let recordIDsToDelete = ids.map(CKRecordID.init(recordName:))
        let op = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDsToDelete)
        op.modifyRecordsCompletionBlock = { _, deletedRecordIDs, error in
            completion((deletedRecordIDs ?? []).map { $0.recordName }, RemoteError(cloudKitError: error))
        }
        cloudKitContainer.publicCloudDatabase.add(op)
    }
    
}
