import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import {
  feedSummary,
  feedTypeLabel,
  FeedItem,
  parseFeed,
  ParsedFeed,
  setPendingAppId,
  setPendingDetailId,
} from '../common/Feed';
import { setPendingCaptchaId } from '../common/CaptchaBridge';

@Entry
@Component
struct SearchPage {
  @State keyword: string = '';
  @State loading: boolean = false;
  @State status: string = '输入关键词后搜索';
  @State items: FeedItem[] = [];
  @State captchaId: string = '';
  @State searched: boolean = false;

  build() {
    Column() {
      Row() {
        Button('<', { type: ButtonType.Normal }).onClick(() => router.back())
        Text('搜索').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .margin({ bottom: 10 })

      Row() {
        TextInput({ placeholder: '搜索动态 / 关键词', text: this.keyword })
          .layoutWeight(1)
          .height(38)
          .onChange((v: string) => {
            this.keyword = v;
          })
          .onSubmit(() => this.doSearch())
        Button('搜索', { type: ButtonType.Capsule })
          .fontSize(13)
          .height(38)
          .margin({ left: 8 })
          .enabled(!this.loading)
          .onClick(() => this.doSearch())
      }
      .width('100%')
      .margin({ bottom: 8 })

      Text(this.status)
        .fontSize(12)
        .fontColor(this.status.indexOf('风控') >= 0 ? '#E06030' : '#8A8A8E')
        .width('100%')
        .margin({ bottom: 6 })

      if (this.captchaId.length > 0) {
        Row() {
          Text('需要人机验证才能继续')
            .fontSize(12)
            .fontColor('#E06030')
            .layoutWeight(1)
          Button('去验证', { type: ButtonType.Capsule })
            .fontSize(12)
            .height(32)
            .onClick(() => {
              setPendingCaptchaId(this.captchaId);
              router.pushUrl({ url: 'pages/CaptchaPage' });
            })
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#FFF3EF')
        .borderRadius(10)
        .margin({ bottom: 8 })
      }

      if (this.loading) {
        LoadingProgress().width(30).height(30).margin({ top: 12, bottom: 8 })
      }

      List({ space: 8 }) {
        ForEach(this.items, (item: FeedItem) => {
          ListItem() {
            Row() {
              Column() {
                Row() {
                  Text(feedTypeLabel(item))
                    .fontSize(10)
                    .fontColor('#FFFFFF')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .backgroundColor('#7A8CD0')
                    .borderRadius(4)
                  Blank()
                  Text(item.username !== undefined ? item.username : '')
                    .fontSize(10)
                    .fontColor('#8A8A8E')
                }
                .width('100%')

                Text(feedSummary(item))
                  .fontSize(13)
                  .width('100%')
                  .margin({ top: 6 })
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              if (item.pic !== undefined && item.pic.length > 0) {
                Image(item.pic)
                  .width(56)
                  .height(56)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .margin({ left: 10 })
              }
            }
            .width('100%')
            .padding(10)
            .backgroundColor('#FFFFFF')
            .borderRadius(10)
            .alignItems(VerticalAlign.Top)
            .onClick(() => {
              const feedId = item.id;
              if (feedId !== undefined && feedId.length > 0) {
                const et = item.entityType;
                if (et === 'product' || et === 'apk') {
                  setPendingAppId(feedId);
                  router.pushUrl({ url: 'pages/AppDetail' });
                } else {
                  setPendingDetailId(feedId);
                  router.pushUrl({ url: 'pages/FeedDetail' });
                }
              }
            })
          }
        }, (item: FeedItem) => item.id !== undefined ? item.id : '')
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 40, bottom: 12 })
    .backgroundColor($r('app.color.page_background'))
  }

  private async doSearch(): Promise<void> {
    const kw = this.keyword.trim();
    if (kw.length === 0) {
      this.status = '请输入关键词';
      return;
    }
    this.loading = true;
    this.captchaId = '';
    this.status = '搜索中…';
    const res: CoolapkResponse = await CoolapkApi.fetchSearch(kw, 'feed', 1);
    const parsed: ParsedFeed = parseFeed(res.body);
    this.items = parsed.items;
    this.searched = true;
    this.loading = false;

    if (res.needCaptcha) {
      this.captchaId = res.captchaId;
      this.status = '命中风控验证码，可点「去验证」继续';
    } else if (res.status === 200) {
      this.status = parsed.items.length > 0
        ? `找到 ${parsed.items.length} 条结果`
        : (parsed.error.length > 0 ? parsed.error : '没有找到结果');
    } else if (res.status < 0) {
      this.status = '网络请求失败';
    } else {
      this.status = `HTTP ${res.status}`;
    }
  }
}
