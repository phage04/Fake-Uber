//
//  DataService.swift
//  Fake Uber
//
//  Created by Lyle Christianne Jover on 1/19/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import Foundation
import Firebase

let DB_BASE = FIRDatabase.database().reference()

class DataService {
    static let instance = DataService()
    
    private var _REF_BASE = DB_BASE
    private var _REF_USERS = DB_BASE.child("users")
    private var _REF_DRIVERS = DB_BASE.child("drivers")
    private var _REF_TRIPS = DB_BASE.child("trips")
    
    var REF_BASE: FIRDatabaseReference {
        return _REF_BASE
    }
    
    var REF_USERS: FIRDatabaseReference {
        return _REF_USERS
    }
    
    var REF_DRIVERS: FIRDatabaseReference {
        return _REF_DRIVERS
    }
    
    var REF_TRIPS: FIRDatabaseReference {
        return _REF_TRIPS
    }
    
    func createFirebaseDBUser(uid: String, userData: Dictionary<String, Any>, isDriver: Bool) {
    
        if isDriver {
            REF_DRIVERS.child(uid).updateChildValues(userData)
        } else{
            REF_USERS.child(uid).updateChildValues(userData)
        }
        
    }
    
    
    
    
    
    
    
}
