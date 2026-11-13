import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import {
  appIcon,
  appName,
  AppDetailData,
  getPendingAppId,
  parseAppDetail,
  ParsedAppDetail,
  str,
  timeAgo,
} from '../common/Feed';
import { setPendingCaptchaId } from '../common/CaptchaBridge';

@Entry
@Component
struct AppDetail {
  @State packageName: string = '';
  @State loading: boolean = false;
  @State status: string = '';
  @State name: string = '';
  @State icon: string = '';
  @State versionName: string = '';
  @State apkSize: string = '';
  @State downloads: string = '';
  @State comments: string = '';
  @State updated: string = '';
  @State changelog: string = '';
  @State description: string = '';
  @State captchaId: string = '';

  aboutToAppear(): void {
    this.packageName = getPendingAppId();
    if (this.packageName.length === 0) {
      this.status = '缺少应用包名';
      return;
    }
    this.load();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.status = '加载中…';
    const res: CoolapkResponse = await CoolapkApi.fetchAppDetail(this.packageName);
    const parsed: ParsedAppDetail = parseAppDetail(res.body);
    if (parsed.app !== null) {
      const d: AppDetailData = parsed.app;
      this.name = appName(d);
      this.icon = appIcon(d);
      this.versionName = str(d.apkversionname);
      this.apkSize = str(d.apksize);
      const down = d.downCount;
      const downNum = d.downnum;
      this.downloads = down !== undefined && down.length > 0 ? down : str(downNum);
      const c1 = d.commentnum;
      const c2 = d.commentNum;
      this.comments = c1 !== undefined && c1.length > 0 ? c1 : str(c2);
      this.updated = timeAgo(d.lastupdate);
      this.changelog = str(d.changelog);
      const msg = d.message;
      const intro = d.intro;
      this.description = msg !== undefined && msg.length > 0 ? msg : str(intro);
    }

    if (res.needCaptcha) {
      this.captchaId = res.captchaId;
      this.status = '命中风控验证码，可点「去验证」继续';
    } else if (res.status === 200 && parsed.app !== null) {
      this.status = '';
    } else if (parsed.error.length > 0) {
      this.status = `加载失败：${parsed.error}（HTTP ${res.status}）`;
    } else {
      this.status = `加载失败 HTTP ${res.status}`;
    }
    this.loading = false;
  }

  build() {
    Column() {
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
        Text('应用详情').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 12 })
        Blank()
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.loading) {
        LoadingProgress().width(32).height(32).margin({ top: 20, bottom: 8 })
      }

      if (this.status.length > 0) {
        Text(this.status)
          .fontSize(12)
          .fontColor(this.status.indexOf('风控') >= 0 ? $r('app.color.danger') : $r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: 8 })
      }

      if (this.captchaId.length > 0) {
        Row() {
          Text('需要人机验证才能查看')
            .fontSize(12)
            .fontColor($r('app.color.danger'))
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
        .backgroundColor($r('app.color.danger_soft'))
        .borderRadius(10)
        .margin({ bottom: 8 })
      }

      Scroll() {
        Column() {
          Row() {
            if (this.icon.length > 0) {
              Image(this.icon)
                .width(64)
                .height(64)
                .objectFit(ImageFit.Cover)
              .alt($r('app.media.ic_image_placeholder'))
                .borderRadius(14)
                .margin({ right: 12 })
            }
            Column() {
              Text(this.name.length > 0 ? this.name : this.packageName)
                .fontSize(17)
                .fontWeight(FontWeight.Bold)
                .width('100%')
              Text(this.packageName)
                .fontSize(11)
                .fontColor($r('app.color.text_tertiary'))
                .width('100%')
                .margin({ top: 4 })
              Text(this.versionName.length > 0 ? `版本 ${this.versionName}` : '')
                .fontSize(11)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ top: 2 })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(12)
          .alignItems(VerticalAlign.Top)
          .margin({ bottom: 10 })

          Row() {
            Column() {
              Text(this.downloads.length > 0 ? this.downloads : '-').fontSize(15).fontWeight(FontWeight.Medium)
              Text('下载').fontSize(10).fontColor($r('app.color.text_tertiary'))
            }
            .layoutWeight(1)

            Column() {
              Text(this.comments.length > 0 ? this.comments : '-').fontSize(15).fontWeight(FontWeight.Medium)
              Text('评论').fontSize(10).fontColor($r('app.color.text_tertiary'))
            }
            .layoutWeight(1)

            Column() {
              Text(this.apkSize.length > 0 ? this.apkSize : '-').fontSize(15).fontWeight(FontWeight.Medium)
              Text('大小').fontSize(10).fontColor($r('app.color.text_tertiary'))
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(12)
          .margin({ bottom: 10 })

          if (this.changelog.length > 0) {
            Column() {
              Text('更新日志')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .width('100%')
              Text(this.changelog)
                .fontSize(12)
                .fontColor($r('app.color.text_body'))
                .width('100%')
                .margin({ top: 6 })
                .lineHeight(19)
            }
            .width('100%')
            .padding(12)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 10 })
          }

          if (this.description.length > 0) {
            Column() {
              Text('应用介绍')
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .width('100%')
              Text(this.description)
                .fontSize(12)
                .fontColor($r('app.color.text_body'))
                .width('100%')
                .margin({ top: 6 })
                .lineHeight(19)
            }
            .width('100%')
            .padding(12)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 10 })
          }

          if (this.updated.length > 0) {
            Text(`更新于 ${this.updated}`)
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .margin({ bottom: 12 })
          }
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
    .backgroundColor($r('app.color.page_bg'))
  }
}

