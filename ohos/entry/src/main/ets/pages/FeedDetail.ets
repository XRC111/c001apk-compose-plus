import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import {
  getPendingDetailId,
  parseDetail,
  parseReplies,
  ParsedDetail,
  ParsedReplies,
  ReplyItem,
  richSegments,
  RichSeg,
  setPendingUid,
  str,
  timeAgo,
} from '../common/Feed';
import { setPendingCaptchaId } from '../common/CaptchaBridge';
import { setPendingImages } from './ImageViewer';

@Entry
@Component
struct FeedDetail {
  @State feedId: string = '';
  @State loading: boolean = false;
  @State status: string = '';
  @State user: string = '';
  @State time: string = '';
  @State feedTitle: string = '';
  @State message: string = '';
  @State pics: string[] = [];
  @State likes: string = '';
  @State replies: ReplyItem[] = [];
  @State replyStatus: string = '';
  @State captchaId: string = '';
  @State authorUid: string = '';
  @State segs: RichSeg[] = [];
  @State liked: boolean = false;
  @State likeCount: string = '';
  @State liking: boolean = false;

  aboutToAppear(): void {
    this.feedId = getPendingDetailId();
    if (this.feedId.length === 0) {
      this.status = '缺少动态 ID';
      return;
    }
    this.load();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.status = '加载中…';

    const detailRes: CoolapkResponse = await CoolapkApi.fetchFeedDetail(this.feedId);
    const parsed: ParsedDetail = parseDetail(detailRes.body);
    if (parsed.detail !== null) {
      const d = parsed.detail;
      this.user = str(d.username);
      this.time = timeAgo(d.dateline);
      this.feedTitle = str(d.title);
      this.message = str(d.message);
      this.segs = richSegments(this.message);
      this.authorUid = str(d.uid);
      this.likes = str(d.likes);
      this.likeCount = str(d.likes);
      const ua = d.userAction;
      if (ua !== undefined && ua !== null && ua.like === 1) {
        this.liked = true;
      }
      const arr = d.picArr;
      this.pics = arr !== undefined && arr !== null ? arr : [];
    }

    if (detailRes.needCaptcha) {
      this.captchaId = detailRes.captchaId;
      this.status = this.captchaId.length > 0
        ? '命中风控验证码，可点「去验证」完成人机验证'
        : '命中风控验证码：建议先导入 ShuzlmID 免验';
    } else if (detailRes.status === 200 && parsed.detail !== null) {
      this.status = '';
    } else if (parsed.error.length > 0) {
      this.status = `加载失败：${parsed.error}（HTTP ${detailRes.status}）`;
    } else {
      this.status = `加载失败 HTTP ${detailRes.status}`;
    }

    const replyRes: CoolapkResponse = await CoolapkApi.fetchReplies(this.feedId, 1);
    const parsedReplies: ParsedReplies = parseReplies(replyRes.body);
    this.replies = parsedReplies.replies;
    if (parsedReplies.error.length > 0) {
      this.replyStatus = parsedReplies.error;
    } else {
      this.replyStatus = `${parsedReplies.replies.length} 条评论`;
    }

    this.loading = false;
  }

  /** 点赞 / 取消点赞。 */
  private async toggleLike(): Promise<void> {
    if (this.liking) {
      return;
    }
    this.liking = true;
    const action = this.liked ? 'unlike' : 'like';
    const res: CoolapkResponse = await CoolapkApi.postLike(action, this.feedId);
    this.liking = false;

    if (res.needCaptcha) {
      this.captchaId = res.captchaId;
      this.status = '操作被风控拦截，需先完成人机验证';
      return;
    }
    if (res.status !== 200) {
      this.status = res.status < 0 ? '操作失败：网络错误' : `操作失败 HTTP ${res.status}`;
      return;
    }
    // 服务端返回最新计数
    const m = /"count"\s*:\s*"?(\d+)"?/.exec(res.body);
    this.liked = !this.liked;
    if (m !== null) {
      this.likeCount = m[1];
    }
  }

  @StorageProp('captchaDoneTick') @Watch('onCaptchaDone') captchaDoneTick: number = 0;

  /** 易盾验证完成后自动重放刚才被拦的请求。 */
  private onCaptchaDone(): void {
    this.load();
  }

  build() {
    Column() {
      // 顶栏
      Row() {
        Row() {
          Image($r('app.media.ic_back'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.text_body'))
        }
        .width(34)
        .height(34)
        .borderRadius(17)
        .backgroundColor($r('app.color.card_bg'))
        .justifyContent(FlexAlign.Center)
        .onClick(() => router.back())

        Text('动态详情')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_title'))
          .margin({ left: 12 })

        Blank()
      }
      .width('100%')
      .height(52)
      .padding({ left: 12, right: 12 })

      if (this.loading) {
        Column() {
          LoadingProgress().width(32).height(32).color($r('app.color.accent'))
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
      }

      if (this.status.length > 0) {
        Text(this.status)
          .fontSize(12)
          .fontColor(this.status.indexOf('风控') >= 0 ? $r('app.color.danger') : $r('app.color.text_secondary'))
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      if (this.captchaId.length > 0) {
        Row() {
          Text('需要人机验证才能查看')
            .fontSize(12)
            .fontColor($r('app.color.danger'))
            .layoutWeight(1)
          Button('去验证', { type: ButtonType.Capsule })
            .fontSize(12)
            .height(30)
            .backgroundColor($r('app.color.accent'))
            .onClick(() => {
              setPendingCaptchaId(this.captchaId);
              router.pushUrl({ url: 'pages/CaptchaPage' });
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 8 })
      }

      Scroll() {
        Column() {
          // ===== 正文卡 =====
          Column() {
            Row() {
              Text(this.user.length > 0 ? this.user.substring(0, 1) : '?')
                .width(40)
                .height(40)
                .borderRadius(20)
                .backgroundColor($r('app.color.accent_soft'))
                .textAlign(TextAlign.Center)
                .fontSize(16)
                .fontColor($r('app.color.accent'))
                .margin({ right: 10 })

              Column() {
                Text(this.user.length > 0 ? this.user : '匿名用户')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.accent'))
                  .onClick(() => {
                    if (this.authorUid.length > 0) {
                      setPendingUid(this.authorUid);
                      router.pushUrl({ url: 'pages/UserPage' });
                    }
                  })
                Text(this.time)
                  .fontSize(11)
                  .fontColor($r('app.color.text_secondary'))
                  .margin({ top: 3 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              if (this.likes.length > 0) {
                Text(`赞 ${this.likes}`)
                  .fontSize(11)
                  .fontColor($r('app.color.text_secondary'))
              }
            }
            .width('100%')

            if (this.feedTitle.length > 0) {
              Text(this.feedTitle)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_title'))
                .width('100%')
                .margin({ top: 12 })
            }

            Text() {
              ForEach(this.segs, (s: RichSeg) => {
                Span(s.text)
                  .fontColor(s.kind === 0 ? $r('app.color.text_body') : $r('app.color.accent'))
              }, (s: RichSeg) => s.kind.toString() + ':' + s.text)
            }
            .fontSize(15)
            .width('100%')
            .margin({ top: 10 })
            .lineHeight(24)

            // 图片：单图大图，多图九宫格
            if (this.pics.length === 1) {
              Image(this.pics[0])
                .width('100%')
                .constraintSize({ maxHeight: 360 })
                .objectFit(ImageFit.Cover)
                .alt($r('app.media.ic_image_placeholder'))
                .borderRadius(10)
                .margin({ top: 12 })
                .onClick(() => {
                  setPendingImages(this.pics, 0);
                  router.pushUrl({ url: 'pages/ImageViewer' });
                })
            } else if (this.pics.length > 1) {
              Grid() {
                ForEach(this.pics, (p: string) => {
                  GridItem() {
                    Image(p)
                      .width('100%')
                      .height(104)
                      .objectFit(ImageFit.Cover)
                      .alt($r('app.media.ic_image_placeholder'))
                      .borderRadius(8)
                  }
                  .onClick(() => {
                    setPendingImages(this.pics, this.pics.indexOf(p));
                    router.pushUrl({ url: 'pages/ImageViewer' });
                  })
                }, (p: string) => p)
              }
              .columnsTemplate('1fr 1fr 1fr')
              .columnsGap(6)
              .rowsGap(6)
              .height(this.gridHeight(this.pics.length, 104))
              .width('100%')
              .margin({ top: 12 })
            }
            Row() {
              Blank()
              Row() {
                Image($r('app.media.ic_like'))
                  .width(16)
                  .height(16)
                  .fillColor(this.liked ? $r('app.color.accent') : $r('app.color.text_secondary'))
                Text((this.liked ? '已赞 ' : '赞 ') + this.likeCount)
                  .fontSize(12)
                  .fontColor(this.liked ? $r('app.color.accent') : $r('app.color.text_secondary'))
                  .margin({ left: 5 })
              }
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(14)
              .backgroundColor(this.liked ? $r('app.color.accent_soft') : $r('app.color.page_bg'))
              .onClick(() => this.toggleLike())
            }
            .width('100%')
            .margin({ top: 12 })

          }
          .width('100%')
          .padding(14)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(14)
          .alignItems(HorizontalAlign.Start)
          .shadow({ radius: 10, color: $r('app.color.shadow'), offsetX: 0, offsetY: 2 })
          .margin({ bottom: 10 })

          // ===== 评论区标题 =====
          Row() {
            Text('评论')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_title'))
            Text(this.replyStatus)
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
              .margin({ left: 8 })
            Blank()
          }
          .width('100%')
          .padding({ left: 4, top: 6, bottom: 8 })

          // ===== 评论列表 =====
          if (this.replies.length === 0) {
            Column() {
              Text('还没有评论')
                .fontSize(12)
                .fontColor($r('app.color.text_tertiary'))
            }
            .width('100%')
            .height(100)
            .justifyContent(FlexAlign.Center)
          } else {
            ForEach(this.replies, (r: ReplyItem) => {
              Column() {
                Row() {
                  Text(str(r.username).length > 0 ? str(r.username).substring(0, 1) : '?')
                    .width(30)
                    .height(30)
                    .borderRadius(15)
                    .backgroundColor($r('app.color.avatar_bg'))
                    .textAlign(TextAlign.Center)
                    .fontSize(13)
                    .fontColor($r('app.color.chip_blue'))
                    .margin({ right: 8 })

                  Column() {
                    Row() {
                      Text(str(r.username))
                        .fontSize(12)
                        .fontColor($r('app.color.chip_blue'))
                      Blank()
                      Text(timeAgo(r.dateline))
                        .fontSize(10)
                        .fontColor($r('app.color.text_tertiary'))
                    }
                    .width('100%')

                    Text(str(r.message))
                      .fontSize(14)
                      .fontColor($r('app.color.text_body'))
                      .width('100%')
                      .margin({ top: 5 })
                      .lineHeight(21)
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .alignItems(VerticalAlign.Top)
              }
              .width('100%')
              .padding(12)
              .backgroundColor($r('app.color.card_bg'))
              .borderRadius(12)
              .margin({ bottom: 8 })
            }, (r: ReplyItem) => str(r.id))
          }
        }
        .width('100%')
        .padding({ left: 12, right: 12, bottom: 16 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  /** 九宫格高度：3 列，单元格 cell 高，行间距 6。 */
  private gridHeight(n: number, cell: number): number {
    const rows = Math.ceil(n / 3);
    if (rows <= 0) {
      return 0;
    }
    return rows * cell + (rows - 1) * 6;
  }
}
