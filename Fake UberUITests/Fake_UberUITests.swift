//
//  Fake_UberUITests.swift
//  Fake UberUITests
//
//  Created by Lyle Christianne Jover on 2/7/18.
//  Copyright © 2018 OnionApps Inc. All rights reserved.
//

import XCTest

class Fake_UberUITests: XCTestCase {
    
    var app: XCUIApplication!
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testUIBehavior() {
        
        let destinationTextField = app.textFields["Where are you going?"]
        let resultTable = app.tables["Empty list"]
        
        XCTAssertFalse(resultTable.exists)
        XCTAssertTrue(destinationTextField.exists)
        destinationTextField.tap()
        destinationTextField.typeText("in n out")
        XCTAssertTrue(resultTable.exists)
        
    }
    
}
