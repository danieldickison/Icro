//
//  Created by martin on 31.03.18.
//  Copyright © 2018 Martin Hartl. All rights reserved.
//

import UIKit
import SafariServices
import ImageViewer

final class ItemNavigator {
    private let navigationController: UINavigationController
    private let userSettings: UserSettings

    init(navigationController: UINavigationController,
         userSettings: UserSettings = .shared) {
        self.navigationController = navigationController
        self.userSettings = userSettings
    }

    func open(url: URL) {
        if let username = username(from: url) {
            open(authorName: username)
            return
        }

        let safariViewController = SFSafariViewController(url: url)
        navigationController.present(safariViewController, animated: true, completion: nil)
    }

    func openMicroBlog() {
        guard let url = URL(string: "https://micro.blog") else { return }
        open(url: url)
    }

    func open(author: Author) {
        let viewModel = ListViewModel(type: .user(user: author))
        let viewController = ListViewController(viewModel: viewModel, itemNavigator: self)
        navigationController.pushViewController(viewController, animated: true)
    }

    func open(authorName: String) {
        let viewModel = ListViewModel(type: .username(username: authorName))
        let viewController = ListViewController(viewModel: viewModel, itemNavigator: self)
        navigationController.pushViewController(viewController, animated: true)
    }

    func openFollowing(for user: Author) {
        let viewModel = UserListViewModel(resource: user.followingResource())
        let viewController = UserListViewController(viewModel: viewModel, itemNavigator: self)
        navigationController.pushViewController(viewController, animated: true)
    }

    func openConversation(item: Item) {
        let viewModel = ListViewModel(type: .conversation(item: item))
        let viewController = ListViewController(viewModel: viewModel, itemNavigator: self)
        navigationController.pushViewController(viewController, animated: true)
    }

    func openImages(datasource: GalleryItemsDataSource, at index: Int) {
        let gallery = GalleryViewController(startIndex: index,
                                            itemsDataSource: datasource,
                                            configuration: [GalleryConfigurationItem.deleteButtonMode(.none)])
        navigationController.presentImageGallery(gallery)
    }

    func openReply(item: Item) {
        let navController = UINavigationController()
        let viewModel = ComposeViewModel(mode: .reply(item: item))
        let navigator = ComposeNavigator(navigationController: navController, viewModel: viewModel)
        let viewController = ComposeViewController(viewModel: viewModel, composeNavigator: navigator)
        navController.viewControllers = [viewController]
        navigationController.present(navController, animated: true, completion: nil)
    }

    func share(item: Item, sourceView: UIView?) {
        let someText = "\(item.author.name): \"\(item.content.string)\""
        let objectsToShare = item.url
        let sharedObjects = [someText, objectsToShare] as [Any]
        let activityViewController = UIActivityViewController(activityItems: sharedObjects, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sourceView

        navigationController.present(activityViewController, animated: true, completion: nil)
    }

    func openMore(item: Item, sourceView: UIView?) {
        let alert = UIAlertController(title: "More", message: nil, preferredStyle: .actionSheet)

        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: .cancel,
                                      handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))

        alert.addAction(UIAlertAction(title: "Mute @\(item.author.username ?? "User")",
                                      style: .destructive,
                                      handler: { [weak self] _ in
            guard let strongSelf = self else { return }

            if let username = item.author.username {
                strongSelf.userSettings.addToBlacklist(word: username)
            }

            let blackListViewModel = BlacklistViewModel(userSettings: strongSelf.userSettings)
            let blackListViewController = BlacklistViewController(viewModel: blackListViewModel,
                                                                  itemNavigator: strongSelf)
            strongSelf.navigationController.pushViewController(blackListViewController, animated: true)
        }))

        alert.addAction(UIAlertAction(title: "Community Guidelines",
                                      style: .default,
                                      handler: { [weak self] _ in
            self?.openCommunityGuidlines()
        }))

        alert.popoverPresentationController?.sourceView = sourceView

        navigationController.present(alert, animated: true, completion: nil)
    }

    func openCommunityGuidlines() {
        guard let url = URL(string: "http://help.micro.blog/2017/community-guidelines/") else { return }

        let itemNavigator = ItemNavigator(navigationController: navigationController)
        itemNavigator.open(url: url)
    }

    // MARK: - Private

    func username(from url: URL) -> String? {
        guard url.host == "micro.blog",
            url.pathComponents.count == 2,
            let username = url.pathComponents.last else { return nil }
        return username
    }
}
