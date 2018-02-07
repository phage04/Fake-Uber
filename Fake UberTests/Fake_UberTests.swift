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
    
    func test_UserIsDriverASYNC() {
        
        let userKey = "DRHlZGDe98bupuFBQlhNlIRsgVu2"
        let promise = expectation(description: "user is driver")
        var isDriverResult: Bool?
        var responseError: Error?
        FIRAuth.auth()?.signInAnonymously(completion: { (user, error) in
            if error == nil {
                self.sessionUnderTest.userIsDriver(userKey: userKey) { (isDriver) in
                    isDriverResult = isDriver
                    if isDriver! {
                        promise.fulfill()
                    }else{
                        XCTFail("user is NOT driver")
                    }
                }
            }else{
                 responseError = error
            }
            
        })
        
        
        waitForExpectations(timeout: 5, handler: nil)
        
        XCTAssertNil(responseError)
        XCTAssertEqual(isDriverResult, true)
    }
    
    func test_VolumeOfRectangleSYNC() {
        let length = 5
        let width = 6
        let height = 7
        let volume = sessionUnderTest.returnVolumeOfRectangle(length: length, width: width, height: height)
        
        XCTAssertEqual(volume, 210, "returnVolumeOfRectangle is NOT 210 - SUMTIN IZ WRONG")
    }
    
    func test_VolumeOfRectangleSYNC_Perf() {
        let length = 5
        let width = 6
        let height = 7
        var volume: Int = 0
        
        self.measure {
            volume = sessionUnderTest.returnVolumeOfRectangle(length: length, width: width, height: height)
        }
        
        XCTAssertEqual(volume, 210, "returnVolumeOfRectangle is NOT 210 - SUMTIN IZ WRONG")
    }
    
}
