//
//  Fake_UberTests.swift
//  Fake UberTests
//
//  Created by Lyle Christianne Jover on 2/7/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import XCTest
import Firebase
@testable import Fake_Uber

class Fake_UberTests: XCTestCase {
    
    var sessionUnderTest: DataService!
    
    
    override func setUp() {
        super.setUp()
        sessionUnderTest = DataService()
        
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        sessionUnderTest = nil
        super.tearDown()
    }
    
    func testExample() {
        
        let userKey = "DRHlZGDe98bupuFBQlhNlIRsgVu2"
        let promise = expectation(description: "user is driver")
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
            if error == nil {
                self.sessionUnderTest.userIsDriver(userKey: userKey) { (isDriver) in
                    if isDriver! {
                        promise.fulfill()
                    }else{
                        XCTFail("user is NOT driver")
                    }
                }
            }else{
                 XCTFail("sign in error")
            }
            
        })
        
        
        waitForExpectations(timeout: 5, handler: nil)
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
