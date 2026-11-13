import { router } from '@kit.ArkUI';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import {
  getPendingUid,
  parseProfile,
  ParsedProfile,
  str,
  UserProfileData,
  userAvatar,
} from '../common/Feed';
import { setPendingCaptchaId } from '../common/CaptchaBridge';

@Entry
@Component
struct UserPage {
  @State uid: string = '';
  @State loading: boolean = false;
  @State status: string = '';
  @State username: string = '';
  @State avatar: string = '';
  @State bio: string = '';
  @State level: string = '';
  @State fans: string = '';
  @State follow: string = '';
  @State experience: string = '';
  @State captchaId: string = '';

  aboutToAppear(): void {
    this.uid = getPendingUid();
    if (this.uid.length === 0) {
      this.status = '缺少用户 ID';
      return;
    }
    this.load();
  }

  private async load(): Promise<void> {
    this.loading = true;
    this.status = '加载中…';
    const res: CoolapkResponse = await CoolapkApi.fetchUserProfile(this.uid);
    const parsed: ParsedProfile = parseProfile(res.body);
    if (parsed.profile !== null) {
      const d: UserProfileData = parsed.profile;
      this.username = str(d.username);
      this.avatar = userAvatar(d);
      this.bio = str(d.bio);
      this.level = str(d.level);
      this.fans = str(d.fans);
      this.follow = str(d.follow);
      this.experience = str(d.experience);
    }

    if (res.needCaptcha) {
      this.captchaId = res.captchaId;
      this.status = '命中风控验证码，可点「去验证」继续';
    } else if (res.status === 200 && parsed.profile !== null) {
      this.status = '';
    } else if (parsed.error.length > 0) {
      this.status = `加载失败：${parsed.error}（HTTP ${res.status}）`;
    } else {
      this.status = `加载失败 HTTP ${res.status}`;
    }
    this.loading = false;
  }

  @StorageProp('captchaDoneTick') @Watch('onCaptchaDone') captchaDoneTick: number = 0;

  /** 易盾验证完成后自动重放刚才被拦的请求。 */
  private onCaptchaDone(): void {
    this.load();
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
        Text('用户主页').fontSize(18).fontWeight(FontWeight.Bold).margin({ left: 12 })
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
            if (this.avatar.length > 0) {
              Image(this.avatar)
                .width(64)
                .height(64)
                .objectFit(ImageFit.Cover)
              .alt($r('app.media.ic_image_placeholder'))
                .borderRadius(32)
                .margin({ right: 12 })
            }
            Column() {
              Row() {
                Text(this.username.length > 0 ? this.username : this.uid)
                  .fontSize(17)
                  .fontWeight(FontWeight.Bold)
                if (this.level.length > 0) {
                  Text(`Lv.${this.level}`)
                    .fontSize(10)
                    .fontColor('#FFFFFF')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .backgroundColor($r('app.color.level_badge'))
                    .borderRadius(4)
                    .margin({ left: 8 })
                }
              }
              .width('100%')

              Text(this.bio.length > 0 ? this.bio : '这个人很懒，什么都没写')
                .fontSize(12)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ top: 6 })
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
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
              Text(this.follow.length > 0 ? this.follow : '-').fontSize(15).fontWeight(FontWeight.Medium)
              Text('关注').fontSize(10).fontColor($r('app.color.text_tertiary'))
            }
            .layoutWeight(1)

            Column() {
              Text(this.fans.length > 0 ? this.fans : '-').fontSize(15).fontWeight(FontWeight.Medium)
              Text('粉丝').fontSize(10).fontColor($r('app.color.text_tertiary'))
            }
            .layoutWeight(1)

            Column() {
              Text(this.experience.length > 0 ? this.experience : '-').fontSize(15).fontWeight(FontWeight.Medium)
              Text('经验').fontSize(10).fontColor($r('app.color.text_tertiary'))
            }
            .layoutWeight(1)
          }
          .width('100%')
          .padding(12)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(12)
          .margin({ bottom: 10 })

          Text('UID: ' + this.uid)
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
            .width('100%')
            .margin({ bottom: 12 })
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
