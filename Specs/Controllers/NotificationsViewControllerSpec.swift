//
//  NotificationsViewControllerSpec.swift
//  Ello
//
//  Created by Sean Dougherty on 11/21/14.
//  Copyright (c) 2014 Ello. All rights reserved.
//

@testable
import Ello
import Quick
import Nimble


class FakeNavigationController: UINavigationController {
    override func pushViewController(viewController: UIViewController, animated: Bool) {
        super.pushViewController(viewController, animated: false)
    }
}


class NotificationsViewControllerSpec: QuickSpec {
    override func spec() {

        var subject: NotificationsViewController!
        describe("NotificationsViewController") {

            beforeEach {
                subject = NotificationsViewController()
            }

            describe("can open notification links") {
                it("can open notifications/posts/12") {
                    let navigationController = FakeNavigationController(rootViewController: subject)
                    subject.respondToNotification(["posts", "12"])
                    expect(navigationController.childViewControllers.count).to(equal(2))
                }
                it("can open notifications/users/12") {
                    let navigationController = FakeNavigationController(rootViewController: subject)
                    subject.respondToNotification(["users", "12"])
                    expect(navigationController.childViewControllers.count).to(equal(2))
                }
                it("can handle unknown links") {
                    let navigationController = UINavigationController(rootViewController: subject)
                    subject.respondToNotification(["flibbity", "jibbet"])
                    expect(navigationController.childViewControllers.count) == 1
                }
            }

            context("when receiving a reload notification") {
                it("should always reload") {
                    subject.hasNewContent = true
                    postNotification(NewContentNotifications.reloadNotifications, value: nil)
                    expect(subject.hasNewContent) == false
                }
            }
        }
    }
}
