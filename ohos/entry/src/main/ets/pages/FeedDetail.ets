import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import {
  getPendingDetailId,
  parseDetail,
  parseReplies,
  ParsedDetail,
  ParsedReplies,
  ReplyItem,
  setPendingUid,
  str,
  timeAgo,
} from '../common/Feed';
import { setPendingCaptchaId } from '../common/CaptchaBridge';

@Entry
@Component
struct FeedDetail {
  @State feedId: string = '';
  @State loading: boolean = false;
  @State status: string = '';
  @State user: string = '';
  @State time: string = '';
  @State title: string = '';
  @State message: string = '';
  @State pics: string[] = [];
  @State likes: string = '';
  @State replies: ReplyItem[] = [];
  @State replyStatus: string = '';
  @State captchaId: string = '';
  @State authorUid: string = '';

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
      this.title = str(d.title);
      this.message = str(d.message);
      this.authorUid = str(d.uid);
      this.likes = str(d.likes);
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

  build() {
    Column() {
      // 顶栏
      Row() {
        Row() {
          Image($r('app.media.ic_back'))
            .width(20)
            .height(20)
            .fillColor('#222222')
        }
        .width(34)
        .height(34)
        .borderRadius(17)
        .backgroundColor('#FFFFFF')
        .justifyContent(FlexAlign.Center)
        .onClick(() => router.back())

        Text('动态详情')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')
          .margin({ left: 12 })

        Blank()
      }
      .width('100%')
      .height(52)
      .padding({ left: 12, right: 12 })

      if (this.loading) {
        Column() {
          LoadingProgress().width(32).height(32).color('#FB7299')
        }
        .width('100%')
        .height(120)
        .justifyContent(FlexAlign.Center)
      }

      if (this.status.length > 0) {
        Text(this.status)
          .fontSize(12)
          .fontColor(this.status.indexOf('风控') >= 0 ? '#D1532F' : '#9A9AA0')
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      if (this.captchaId.length > 0) {
        Row() {
          Text('需要人机验证才能查看')
            .fontSize(12)
            .fontColor('#D1532F')
            .layoutWeight(1)
          Button('去验证', { type: ButtonType.Capsule })
            .fontSize(12)
            .height(30)
            .backgroundColor('#FB7299')
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
                .backgroundColor('#F2E8EC')
                .textAlign(TextAlign.Center)
                .fontSize(16)
                .fontColor('#FB7299')
                .margin({ right: 10 })

              Column() {
                Text(this.user.length > 0 ? this.user : '匿名用户')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#FB7299')
                  .onClick(() => {
                    if (this.authorUid.length > 0) {
                      setPendingUid(this.authorUid);
                      router.pushUrl({ url: 'pages/UserPage' });
                    }
                  })
                Text(this.time)
                  .fontSize(11)
                  .fontColor('#9A9AA0')
                  .margin({ top: 3 })
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              if (this.likes.length > 0) {
                Text(`赞 ${this.likes}`)
                  .fontSize(11)
                  .fontColor('#9A9AA0')
              }
            }
            .width('100%')

            if (this.title.length > 0) {
              Text(this.title)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .fontColor('#111111')
                .width('100%')
                .margin({ top: 12 })
            }

            Text(this.message)
              .fontSize(15)
              .fontColor('#222222')
              .width('100%')
              .margin({ top: 10 })
              .lineHeight(24)
              .textAlign(TextAlign.Start)

            // 图片：单图大图，多图九宫格
            if (this.pics.length === 1) {
              Image(this.pics[0])
                .width('100%')
                .constraintSize({ maxHeight: 360 })
                .objectFit(ImageFit.Cover)
                .borderRadius(10)
                .margin({ top: 12 })
            } else if (this.pics.length > 1) {
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.pics, (p: string) => {
                  Image(p)
                    .width(104)
                    .height(104)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(8)
                    .margin({ right: 6, bottom: 6 })
                }, (p: string) => p)
              }
              .width('100%')
              .margin({ top: 12 })
            }
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .alignItems(HorizontalAlign.Start)
          .shadow({ radius: 10, color: '#0D000000', offsetX: 0, offsetY: 2 })
          .margin({ bottom: 10 })

          // ===== 评论区标题 =====
          Row() {
            Text('评论')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#111111')
            Text(this.replyStatus)
              .fontSize(11)
              .fontColor('#9A9AA0')
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
                .fontColor('#B0B0B6')
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
                    .backgroundColor('#EDEDF2')
                    .textAlign(TextAlign.Center)
                    .fontSize(13)
                    .fontColor('#7A8CD0')
                    .margin({ right: 8 })

                  Column() {
                    Row() {
                      Text(str(r.username))
                        .fontSize(12)
                        .fontColor('#7A8CD0')
                      Blank()
                      Text(timeAgo(r.dateline))
                        .fontSize(10)
                        .fontColor('#B0B0B6')
                    }
                    .width('100%')

                    Text(str(r.message))
                      .fontSize(14)
                      .fontColor('#333333')
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
              .backgroundColor('#FFFFFF')
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
    .backgroundColor('#F2F2F6')
  }
}
