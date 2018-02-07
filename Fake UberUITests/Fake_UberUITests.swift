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
    
    func testExample() {
        
        
 
        let menuBtn = app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 2).children(matching: .button).element
        let SignUpLogInBtnMenu = app.buttons["Sign Up /Login"]
        let SignUpLognInBtnExecute = app.buttons["Sign Up / Login"]
        let emailTextField = app.textFields["email"]
        let passwordSecureTextField = app.secureTextFields["password"]
        
        menuBtn.tap()
        SignUpLogInBtnMenu.tap()
        emailTextField.tap()
        emailTextField.typeText("test@thing.com")
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("lyle5953")
        SignUpLognInBtnExecute.tap()
        
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
