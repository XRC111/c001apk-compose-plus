import { router } from '@kit.ArkUI';
import { currentUsername, isLoggedIn } from '../common/CookieStore';

@Component
export struct MessageTab {
  @State loginName: string = '';

  aboutToAppear(): void {
    this.refresh();
  }

  private async refresh(): Promise<void> {
    const logged = await isLoggedIn();
    if (logged) {
      this.loginName = await currentUsername();
    } else {
      this.loginName = '';
    }
  }

  build() {
    Column() {
      Row() {
        Text('消息')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_title'))
        Blank()
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 12 })

      if (this.loginName.length === 0) {
        Column() {
          Text('登录后查看消息')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Text('登录后可接收回复、@ 与私信通知')
            .fontSize(11)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ top: 8 })
          Button('登录酷安', { type: ButtonType.Capsule })
            .fontSize(14)
            .width(160)
            .height(42)
            .margin({ top: 20 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/LoginPage' }).then(() => {
                setTimeout(() => this.refresh(), 500);
              });
            })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Column() {
          Text(`已登录：${this.loginName}`)
            .fontSize(13)
            .fontColor($r('app.color.success'))
          Text('消息列表待接入')
            .fontSize(12)
            .fontColor($r('app.color.text_tertiary'))
            .margin({ top: 10 })
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
