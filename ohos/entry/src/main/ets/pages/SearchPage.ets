import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import {
  feedAvatar,
  feedPics,
  feedSummary,
  feedTypeLabel,
  FeedItem,
  parseFeed,
  ParsedFeed,
  setPendingAppId,
  setPendingDetailId,
  str,
  timeAgo,
} from '../common/Feed';
import { setPendingCaptchaId } from '../common/CaptchaBridge';

@Entry
@Component
struct SearchPage {
  @State keyword: string = '';
  @State loading: boolean = false;
  @State status: string = '';
  @State items: FeedItem[] = [];
  @State captchaId: string = '';

  build() {
    Column() {
      // 顶部搜索栏
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

        Row() {
          Image($r('app.media.ic_search'))
            .width(16)
            .height(16)
            .fillColor('#B0B0B6')
            .margin({ left: 12, right: 6 })
          TextInput({ placeholder: '搜索动态 / 关键词', text: this.keyword })
            .layoutWeight(1)
            .height(36)
            .backgroundColor(Color.Transparent)
            .fontSize(14)
            .onChange((v: string) => {
              this.keyword = v;
            })
            .onSubmit(() => this.doSearch())
        }
        .layoutWeight(1)
        .height(36)
        .borderRadius(18)
        .backgroundColor('#FFFFFF')
        .margin({ left: 10, right: 8 })

        Text('搜索')
          .fontSize(14)
          .fontColor('#FB7299')
          .fontWeight(FontWeight.Medium)
          .onClick(() => this.doSearch())
      }
      .width('100%')
      .height(56)
      .padding({ left: 12, right: 14 })

      if (this.status.length > 0) {
        Text(this.status)
          .fontSize(12)
          .fontColor(this.status.indexOf('风控') >= 0 ? '#D1532F' : '#9A9AA0')
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })
      }

      if (this.captchaId.length > 0) {
        Row() {
          Text('需要人机验证才能继续')
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

      if (this.loading) {
        Column() {
          LoadingProgress().width(30).height(30).color('#FB7299')
        }
        .width('100%')
        .height(90)
        .justifyContent(FlexAlign.Center)
      }

      List({ space: 10 }) {
        if (!this.loading && this.items.length === 0) {
          ListItem() {
            Column() {
              Text(this.status.length > 0 ? '' : '输入关键词开始搜索')
                .fontSize(13)
                .fontColor('#B0B0B6')
            }
            .width('100%')
            .height(280)
            .justifyContent(FlexAlign.Center)
          }
        }

        ForEach(this.items, (item: FeedItem) => {
          ListItem() {
            this.ResultCard(item)
          }
        }, (item: FeedItem) => str(item.id))
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12 })
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F6')
  }

  @Builder
  ResultCard(item: FeedItem) {
    Column() {
      Row() {
        if (feedAvatar(item).length > 0) {
          Image(feedAvatar(item))
            .width(34)
            .height(34)
            .borderRadius(17)
            .objectFit(ImageFit.Cover)
            .margin({ right: 8 })
        } else {
          Text(str(item.username).length > 0 ? str(item.username).substring(0, 1) : '?')
            .width(34)
            .height(34)
            .borderRadius(17)
            .backgroundColor('#F2E8EC')
            .textAlign(TextAlign.Center)
            .fontSize(14)
            .fontColor('#FB7299')
            .margin({ right: 8 })
        }

        Column() {
          Text(str(item.username).length > 0 ? str(item.username) : '匿名用户')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#111111')
          Text(`${feedTypeLabel(item)} · ${timeAgo(item.dateline)}`)
            .fontSize(10)
            .fontColor('#9A9AA0')
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      Text(feedSummary(item))
        .fontSize(14)
        .fontColor('#222222')
        .width('100%')
        .margin({ top: 9 })
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .lineHeight(21)

      if (feedPics(item).length === 1) {
        Image(feedPics(item)[0])
          .width('100%')
          .constraintSize({ maxHeight: 200 })
          .objectFit(ImageFit.Cover)
          .borderRadius(10)
          .margin({ top: 10 })
      } else if (feedPics(item).length > 1) {
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(feedPics(item), (p: string) => {
            Image(p)
              .width(92)
              .height(92)
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
              .margin({ right: 6, bottom: 6 })
          }, (p: string) => p)
        }
        .width('100%')
        .margin({ top: 10 })
      }
    }
    .width('100%')
    .padding(13)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .alignItems(HorizontalAlign.Start)
    .shadow({ radius: 10, color: '#0D000000', offsetX: 0, offsetY: 2 })
    .onClick(() => this.openItem(item))
  }

  private openItem(item: FeedItem): void {
    const id = item.id;
    if (id === undefined || id.length === 0) {
      return;
    }
    const et = item.entityType;
    if (et === 'product' || et === 'apk') {
      setPendingAppId(id);
      router.pushUrl({ url: 'pages/AppDetail' });
    } else {
      setPendingDetailId(id);
      router.pushUrl({ url: 'pages/FeedDetail' });
    }
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
