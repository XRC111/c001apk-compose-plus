import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import {
  getPendingDetailId,
  parseDetail,
  parseReplies,
  ParsedDetail,
  ParsedReplies,
  ReplyItem,
  str,
  timeAgo,
} from '../common/Feed';

@Entry
@Component
struct FeedDetail {
  @State id: string = '';
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

  aboutToAppear(): void {
    this.id = getPendingDetailId();
    if (this.id.length === 0) {
      this.status = '缺少动态 ID';
      return;
    }
    this.load();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.status = '加载中…';

    // 详情与评论并行，评论失败不影响正文
    const detailRes: CoolapkResponse = await CoolapkApi.fetchFeedDetail(this.id);
    const parsed: ParsedDetail = parseDetail(detailRes.body);
    if (parsed.detail !== null) {
      const d = parsed.detail;
      this.user = str(d.username);
      this.time = timeAgo(d.dateline);
      this.title = str(d.title);
      this.message = str(d.message);
      this.likes = str(d.likes);
      const arr = d.picArr;
      this.pics = arr !== undefined && arr !== null ? arr : [];
    }

    if (detailRes.needCaptcha) {
      this.status = '命中风控验证码：需完成人机验证（或先导入 ShuzlmID 免验）';
    } else if (detailRes.status === 200 && parsed.detail !== null) {
      this.status = '';
    } else if (parsed.error.length > 0) {
      this.status = `加载失败：${parsed.error}（HTTP ${detailRes.status}）`;
    } else {
      this.status = `加载失败 HTTP ${detailRes.status}`;
    }

    const replyRes: CoolapkResponse = await CoolapkApi.fetchReplies(this.id, 1);
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
      Row() {
        Button('<', { type: ButtonType.Normal }).onClick(() => router.back())
        Text('动态详情').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 12 })
        Blank()
        if (this.likes.length > 0) {
          Text(`赞 ${this.likes}`).fontSize(12).fontColor('#8A8A8E')
        }
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.loading) {
        LoadingProgress().width(32).height(32).margin({ top: 20, bottom: 8 })
      }

      if (this.status.length > 0) {
        Text(this.status)
          .fontSize(12)
          .fontColor(this.status.indexOf('风控') >= 0 ? '#E06030' : '#8A8A8E')
          .width('100%')
          .margin({ bottom: 8 })
      }

      Scroll() {
        Column() {
          // 正文
          if (this.user.length > 0 || this.message.length > 0) {
            Column() {
              Row() {
                Text(this.user).fontSize(12).fontColor('#7A8CD0')
                Blank()
                Text(this.time).fontSize(11).fontColor('#A0A0A6')
              }
              .width('100%')

              if (this.title.length > 0) {
                Text(this.title)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .width('100%')
                  .margin({ top: 6 })
              }

              Text(this.message)
                .fontSize(14)
                .width('100%')
                .margin({ top: 8 })
                .lineHeight(22)
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 10 })
          }

          // 图片
          ForEach(this.pics, (pic: string) => {
            Image(pic)
              .width('100%')
              .constraintSize({ maxHeight: 420 })
              .objectFit(ImageFit.Contain)
              .borderRadius(10)
              .margin({ bottom: 8 })
          }, (pic: string) => pic)

          // 评论
          Row() {
            Text('评论').fontSize(14).fontWeight(FontWeight.Medium)
            Blank()
            Text(this.replyStatus).fontSize(11).fontColor('#A0A0A6')
          }
          .width('100%')
          .margin({ top: 4, bottom: 8 })

          ForEach(this.replies, (r: ReplyItem) => {
            Column() {
              Row() {
                Text(str(r.username)).fontSize(12).fontColor('#7A8CD0')
                Blank()
                Text(timeAgo(r.dateline)).fontSize(10).fontColor('#A0A0A6')
              }
              .width('100%')

              Text(str(r.message))
                .fontSize(13)
                .width('100%')
                .margin({ top: 4 })
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 8 })
          }, (r: ReplyItem) => str(r.id))
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 40, bottom: 12 })
    .backgroundColor($r('app.color.page_background'))
  }
}
