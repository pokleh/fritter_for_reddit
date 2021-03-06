import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_provider_app/helpers/comment_color_annotations/colors.dart';
import 'package:flutter_provider_app/helpers/design_system/color_enums.dart';
import 'package:flutter_provider_app/helpers/design_system/colors.dart';
import 'package:flutter_provider_app/helpers/functions/conversion_functions.dart';
import 'package:flutter_provider_app/models/comment_chain/comment.dart'
    as CommentPojo;
import 'package:flutter_provider_app/pages/subreddit_feed.dart';
import 'package:flutter_provider_app/providers/comments_provider.dart';
import 'package:flutter_provider_app/widgets/common/swiper.dart';
import 'package:html_unescape/html_unescape.dart';

import '../../exports.dart';

class CommentItem extends StatefulWidget {
  final CommentPojo.Child _comment;
  final String name;
  final String postId;
  final int commentIndex;

  CommentItem(this._comment, this.name, this.postId, this.commentIndex);

  @override
  _CommentItemState createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        SizedBox(
          width: 16.0 * widget._comment.data.depth,
        ),
        Expanded(
          child: widget._comment.data.collapseParent == true
              ? CollapsedCommentParent(
                  comment: widget._comment,
                  postId: widget.postId,
                  commentIndex: widget.commentIndex,
                )
              : AnimatedSize(
                  vsync: this,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.linearToEaseOut,
                  child: widget._comment.data.collapse == true
                      ? Container()
                      : widget._comment.kind == CommentPojo.Kind.MORE
                          ? MoreCommentKind(
                              comment: widget._comment,
                              postFullName: widget.name,
                              id: widget.postId,
                            )
                          : Column(
                              children: <Widget>[
                                Swiper(
                                  comment: widget._comment,
                                  postId: widget.postId,
                                  child: CommentBody(
                                    context: context,
                                    commentIndex: widget.commentIndex,
                                    comment: widget._comment,
                                    postId: widget.postId,
                                  ),
                                ),
                                Divider(
                                  indent: 16,
                                ),
                              ],
                            ),
                ),
        ),
      ],
    );
  }
}

class CollapsedCommentParent extends StatelessWidget {
  final CommentPojo.Child comment;
  final String postId;
  final int commentIndex;
  CollapsedCommentParent({
    @required this.comment,
    @required this.postId,
    @required this.commentIndex,
  });
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, CommentsProvider model, _) {
        return Material(
          color: Theme.of(context).cardColor,
          child: Container(
            margin: EdgeInsets.all(8.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.0),
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
            ),
            child: ListTile(
              dense: true,
              onTap: () {
                collapse(commentIndex, context);
              },
              title: Text(
                comment.data.author +
                    " [+${model.collapsedChildrenCount[comment.data.id].toString()}]",
                style: Theme.of(context).textTheme.subtitle,
              ),
              trailing: Icon(Icons.expand_more),
            ),
          ),
        );
      },
    );
  }

  void collapse(int commentIndex, BuildContext context) {
    Provider.of<CommentsProvider>(context, listen: false)
        .collapseUncollapseComment(
      collapse: false,
      postId: postId,
      parentCommentIndex: commentIndex,
    );
  }
}

class CommentBody extends StatelessWidget {
  final CommentPojo.Child comment;
  final String postId;
  final int commentIndex;
  final Widget htmlCommentBody;
  final BuildContext context;

  static final HtmlUnescape _unescape = new HtmlUnescape();

  CommentBody({
    @required this.comment,
    @required this.postId,
    @required this.commentIndex,
    @required this.context,
  }) : htmlCommentBody = Html(
            data: _unescape.convert(comment.data.bodyHtml),
            useRichText: true,
            showImages: false,
            onLinkTap: (url) {
              if (url.startsWith("/r/") || url.startsWith("r/")) {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    fullscreenDialog: false,
                    builder: (BuildContext context) {
                      return SubredditFeedPage(
                          subreddit: url.startsWith("/r/")
                              ? url.replaceFirst("/r/", "")
                              : url.replaceFirst("r/", ""));
                    },
                  ),
                );
              } else if (url.startsWith("/u/") || url.startsWith("u/")) {
              } else {
                launchURL(context, url);
              }
            });

  Brightness _platformBrightness;

  @override
  Widget build(BuildContext context) {
    String _htmlContent = _unescape.convert(comment.data.bodyHtml);
    _platformBrightness = MediaQuery.of(context).platformBrightness;
    return Material(
      color: Theme.of(context).cardColor,
      child: Container(
        padding: const EdgeInsets.only(top: 4.0),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: comment.data.depth != 0
                  ? colorsRainbow.elementAt(comment.data.depth % 5)
                  : Colors.transparent,
              width: comment.data.depth != 0 ? 2 : 0,
            ),
          ),
        ),
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            collapse(comment, context);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              comment.data.stickied
                  ? PinnedCommentTag(platformBrightness: _platformBrightness)
                  : Container(),
              Flexible(
                child: AuthorTag(
                  comment: comment,
                  platformBrightness: _platformBrightness,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                  top: 0.0,
                ),
                child: htmlCommentBody,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void collapse(CommentPojo.Child comment, BuildContext context) async {
    Provider.of<CommentsProvider>(context, listen: false)
        .collapseUncollapseComment(
      parentCommentIndex: commentIndex,
      collapse: true,
      postId: postId,
    );
  }
}

class AuthorTag extends StatelessWidget {
  const AuthorTag({
    Key key,
    @required this.comment,
    @required Brightness platformBrightness,
  })  : _platformBrightness = platformBrightness,
        super(key: key);

  final CommentPojo.Child comment;
  final Brightness _platformBrightness;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 4.0, right: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          comment.data.isSubmitter
              ? Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: comment.data.isSubmitter
                      ? Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).accentColor,
                        )
                      : Container(),
                )
              : Container(),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: comment.data.author + " ",
                  style: comment.data.isSubmitter
                      ? Theme.of(context).textTheme.caption.copyWith(
                            color: Theme.of(context).accentColor,
                          )
                      : Theme.of(context).textTheme.caption,
                ),
                comment.data.distinguished.toString().compareTo("moderator") ==
                        0
                    ? TextSpan(
                        text: "MOD",
                        style: Theme.of(context).textTheme.subtitle.copyWith(
                              color: Theme.of(context).accentColor,
                              letterSpacing: 1,
                            ),
                      )
                    : TextSpan(),
              ],
            ),
          ),
          Row(
            children: <Widget>[
              Icon(
                Icons.arrow_upward,
                color: comment.data.likes != null
                    ? comment.data.likes == true
                        ? getColor(
                            _platformBrightness, ColorObjects.UpvoteColor)
                        : getColor(
                            _platformBrightness, ColorObjects.DownvoteColor)
                    : Theme.of(context).textTheme.subtitle.color,
                size: 14,
              ),
              Text(
                (comment.data.scoreHidden
                    ? " [?]"
                    : " " + getRoundedToThousand(comment.data.score)),
                style: comment.data.likes != null
                    ? comment.data.likes == true
                        ? Theme.of(context).textTheme.subtitle.copyWith(
                              color: getColor(_platformBrightness,
                                  ColorObjects.UpvoteColor),
                            )
                        : Theme.of(context).textTheme.subtitle.copyWith(
                              color: getColor(_platformBrightness,
                                  ColorObjects.DownvoteColor),
                            )
                    : Theme.of(context).textTheme.subtitle,
                softWrap: true,
                overflow: TextOverflow.clip,
                maxLines: 100,
              ),
            ],
          ),
          Expanded(
            child: Text(
              " • " + getTimePosted(comment.data.createdUtc),
              style: Theme.of(context).textTheme.subtitle,
              overflow: TextOverflow.fade,
              maxLines: 100,
            ),
          ),
        ],
      ),
    );
  }
}

class PinnedCommentTag extends StatelessWidget {
  const PinnedCommentTag({
    Key key,
    @required Brightness platformBrightness,
  })  : _platformBrightness = platformBrightness,
        super(key: key);

  final Brightness _platformBrightness;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 12.0,
        right: 12.0,
        bottom: 4.0,
        top: 4.0,
      ),
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: getColor(
          _platformBrightness,
          ColorObjects.TagColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.label_outline,
            color: Theme.of(context).textTheme.subtitle.color,
            size: Theme.of(context).textTheme.subtitle.fontSize,
          ),
          SizedBox(
            width: 4.0,
          ),
          Text(
            "Pinned",
            style: Theme.of(context).textTheme.subtitle,
          ),
        ],
      ),
    );
  }
}

class MoreCommentKind extends StatelessWidget {
  final CommentPojo.Child comment;
  final String postFullName;
  final String id;

  MoreCommentKind({this.comment, this.postFullName, this.id});
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, CommentsProvider model, _) {
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: InkWell(
                enableFeedback: true,
                splashColor: Theme.of(context).accentColor.withOpacity(0.2),
                onTap: () {
                  model.fetchChildren(
                    children: comment.data.children,
                    postId: id,
                    postFullName: postFullName,
                    moreParentId: comment.data.id,
                  );
                },
                child: Row(
                  children: <Widget>[
                    // only change the state of the widget to loading only if
                    // this comment matches the id to the loading comment
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'More',
                        style: TextStyle(
                          color: Theme.of(context).accentColor,
                        ),
                      ),
                    ),
                    model.commentsMoreLoadingState == ViewState.Busy &&
                            model.moreParentLoadingId != "" &&
                            model.moreParentLoadingId == comment.data.id
                        ? Row(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(),
                              ),
                              SizedBox(
                                width: 16,
                              ),
                            ],
                          )
                        : Container(),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
