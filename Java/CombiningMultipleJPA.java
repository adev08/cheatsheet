

List<PostComment> comments = postCommentRepository.findAll(
    orderByCreatedOn(
        byPost(post)
        .and(byStatus(PostComment.Status.PENDING))
        .and(byReviewLike(reviewPatter))
        .and(byVotesGreaterThanEqual(minVotes))
    )
);