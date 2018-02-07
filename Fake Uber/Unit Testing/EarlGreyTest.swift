//
//  EarlGreyTest.swift
//  Fake UberTests
//
//  Created by Lyle Christianne Jover on 2/7/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import XCTest
import EarlGrey

class EarlGreyTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        EarlGrey.select(elementWithMatcher: grey_keyWindow())
            .assert(grey_sufficientlyVisible())
    }
    
}
