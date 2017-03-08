////
///  PostService.swift
//

import Foundation
import FutureKit

typealias PostSuccessCompletion = (_ post: Post, _ responseConfig: ResponseConfig) -> Void
typealias PostCommentsSuccessCompletion = (_ comments: [ElloComment], _ responseConfig: ResponseConfig) -> Void
typealias PostLoversSuccessCompletion = (_ users: [User], _ responseConfig: ResponseConfig) -> Void
typealias PostRepostersSuccessCompletion = (_ users: [User], _ responseConfig: ResponseConfig) -> Void
typealias UsernamesSuccessCompletion = (_ usernames: [String]) -> Void
typealias CommentSuccessCompletion = (_ comment: ElloComment, _ responseConfig: ResponseConfig) -> Void
typealias DeletePostSuccessCompletion = () -> Void

struct PostService {

    func loadPost(
        _ postParam: String,
        needsComments: Bool) -> Future<Post>
    {
        let commentCount = needsComments ? 10 : 0
        let promise = Promise<Post>()
        ElloProvider.shared.elloRequest(
            ElloAPI.postDetail(postParam: postParam, commentCount: commentCount),
            success: { (data, responseConfig) in
                if let post = data as? Post {
                    Preloader().preloadImages([post])
                    promise.completeWithSuccess(post)
                }
                else {
                    let error = NSError.uncastableJSONAble()
                    promise.completeWithFail(error)
                }
            },
            failure: { (error, _) in
                promise.completeWithFail(error)
            })
        return promise.future
    }

    func sendPostDetailView(
        id postId: String,
        userId: String?)
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.postViews(streamId: postId, streamKind: "post", postIds: [postId], currentUserId: userId),
            success: { _ in })
    }

    func sendPostViews(
        posts: [Post],
        streamId: String?,
        streamKind: String,
        userId: String?)
    {
        guard posts.count > 0 else { return }

        let postIds = Set(posts.map { $0.id })
        ElloProvider.shared.elloRequest(
            ElloAPI.postViews(streamId: streamId, streamKind: streamKind, postIds: postIds, currentUserId: userId),
            success: { _ in })
    }

    func loadPostComments(
        _ postId: String,
        success: @escaping PostCommentsSuccessCompletion,
        failure: @escaping ElloFailureCompletion = { _ in })
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.postComments(postId: postId),
            success: { (data, responseConfig) in
                if let comments = data as? [ElloComment] {
                    Preloader().preloadImages(comments)
                    for comment in comments {
                        comment.loadedFromPostId = postId
                    }
                    success(comments, responseConfig)
                }
                else {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: { (error, statusCode) in
                failure(error, statusCode)
        })
    }

    func loadPostLovers(
        _ postId: String,
        success: @escaping PostLoversSuccessCompletion,
        failure: @escaping ElloFailureCompletion = { _ in })
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.postLovers(postId: postId),
            success: { (data, responseConfig) in
                if let users = data as? [User] {
                    Preloader().preloadImages(users)
                    success(users, responseConfig)
                }
                else {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: { (error, statusCode) in
                failure(error, statusCode)
            })
    }

    func loadPostReposters(
        _ postId: String,
        success: @escaping PostRepostersSuccessCompletion,
        failure: @escaping ElloFailureCompletion = { _ in })
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.postReposters(postId: postId),
            success: { (data, responseConfig) in
                if let users = data as? [User] {
                    Preloader().preloadImages(users)
                    success(users, responseConfig)
                }
                else {
                    ElloProvider.unCastableJSONAble(failure)
                }
            },
            failure: { (error, statusCode) in
                failure(error, statusCode)
        })
    }

    func loadComment(
        _ postId: String,
        commentId: String,
        success: @escaping CommentSuccessCompletion,
        failure: @escaping ElloFailureCompletion = { _ in })
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.commentDetail(postId: postId, commentId: commentId),
            success: { (data, responseConfig) in
                if let comment = data as? ElloComment {
                    comment.loadedFromPostId = postId
                    success(comment, responseConfig)
                }
                else {
                    ElloProvider.unCastableJSONAble(failure) // FIXME - These were optional pre Swift 3, are we preared for this fire?
                }
            },
            failure: { (error, statusCode) in
                failure(error, statusCode)
            })
    }

    func loadReplyAll(
        _ postId: String,
        success: @escaping UsernamesSuccessCompletion,
        failure: @escaping ElloEmptyCompletion)
    {
        ElloProvider.shared.elloRequest(
            ElloAPI.postReplyAll(postId: postId),
            success: { (usernames, _) in
                if let usernames = usernames as? [Username] {
                    let strings = usernames
                        .map { $0.username }
                    let uniq = strings.unique()
                    success(uniq)
                }
                else {
                    failure()
                }
            }, failure: { _ in failure() })
    }

    func deletePost(
        _ postId: String,
        success: @escaping ElloEmptyCompletion,
        failure: @escaping ElloFailureCompletion)
    {
        ElloProvider.shared.elloRequest(ElloAPI.deletePost(postId: postId),
            success: { (_, _) in
                URLCache.shared.removeAllCachedResponses()
                success()
            }, failure: failure
        )
    }

    func deleteComment(_ postId: String, commentId: String, success: @escaping ElloEmptyCompletion, failure: @escaping ElloFailureCompletion) {
        ElloProvider.shared.elloRequest(ElloAPI.deleteComment(postId: postId, commentId: commentId),
            success: { (_, _) in
                success()
            }, failure: failure
        )
    }

    func toggleWatchPost(_ post: Post, watching: Bool) -> Future<Post> {
        let api: ElloAPI
        if watching {
            api = ElloAPI.createWatchPost(postId: post.id)
        }
        else {
            api = ElloAPI.deleteWatchPost(postId: post.id)
        }

        let promise = Promise<Post>()
        ElloProvider.shared.elloRequest(api,
            success: { data, _ in
                if watching,
                    let watch = data as? Watch,
                    let post = watch.post
                {
                    promise.completeWithSuccess(post)
                }
                else if !watching {
                    post.watching = false
                    ElloLinkedStore.sharedInstance.setObject(post, forKey: post.id, type: .postsType)
                    promise.completeWithSuccess(post)
                }
                else {
                    let error = NSError.uncastableJSONAble()
                    promise.completeWithFail(error)
                }
            },
            failure: { error, _ in
                promise.completeWithFail(error)
            }
        )
        return promise.future
    }
}
