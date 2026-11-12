import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { getString, initSettings, isSettingsReady, KEY_SZLM_ID, putString } from '../common/SettingsStore';
import { getDeviceCode, setDeviceCode } from '../common/DeviceCode';
import { clearLogin, currentUsername, isLoggedIn } from '../common/CookieStore';

@Component
export struct SettingsTab {
  @State szlmId: string = '';
  @State saved: boolean = false;
  @State ready: boolean = false;
  @State devicePreview: string = '';
  @State loginName: string = '';

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await initSettings(ctx);
    this.ready = isSettingsReady();
    this.szlmId = await getString(KEY_SZLM_ID, '');
    this.refreshDevice();
    const logged = await isLoggedIn();
    this.loginName = logged ? await currentUsername() : '';
  }

  private refreshDevice(): void {
    const dev = getDeviceCode();
    this.devicePreview = dev.length > 30 ? dev.substring(0, 30) + '…' : dev;
  }

  private async save(): Promise<void> {
    await putString(KEY_SZLM_ID, this.szlmId);
    setDeviceCode({ szlmId: this.szlmId });
    this.refreshDevice();
    this.saved = true;
  }

  private async logout(): Promise<void> {
    await clearLogin();
    this.loginName = '';
  }

  build() {
    Column() {
      Row() {
        Text('设置')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#111111')
        Blank()
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 12 })

      Scroll() {
        Column() {
          // 账号
          Column() {
            Row() {
              Text('账号')
                .fontSize(13)
                .fontColor('#8A8A8E')
              Blank()
              if (this.loginName.length > 0) {
                Text(this.loginName)
                  .fontSize(13)
                  .fontColor('#222222')
              } else {
                Text('未登录')
                  .fontSize(13)
                  .fontColor('#A0A0A6')
              }
            }
            .width('100%')

            Row() {
              if (this.loginName.length > 0) {
                Button('退出登录', { type: ButtonType.Normal })
                  .fontSize(13)
                  .layoutWeight(1)
                  .onClick(() => this.logout())
              } else {
                Button('登录酷安', { type: ButtonType.Normal })
                  .fontSize(13)
                  .layoutWeight(1)
                  .onClick(() => router.pushUrl({ url: 'pages/LoginPage' }))
              }
            }
            .width('100%')
            .margin({ top: 10 })
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .margin({ bottom: 10 })

          // ShuzlmID
          Column() {
            Text('数字联盟 ID (ShuzlmID)')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .width('100%')
            Text('导入官方设备标识可免除大部分人机验证')
              .fontSize(11)
              .fontColor('#A0A0A6')
              .width('100%')
              .margin({ top: 4, bottom: 10 })

            TextInput({ placeholder: '粘贴官方酷安连点 5 次「复制 OAID」的日志', text: this.szlmId })
              .width('100%')
              .height(76)
              .onChange((v: string) => {
                this.szlmId = v;
                this.saved = false;
              })

            Button('保存', { type: ButtonType.Capsule })
              .width('100%')
              .height(40)
              .margin({ top: 12 })
              .enabled(this.ready)
              .onClick(() => this.save())

            if (!this.ready) {
              Text('本地存储初始化失败，本次修改仅在当前会话生效')
                .fontSize(11)
                .fontColor('#E06030')
                .margin({ top: 8 })
            } else if (this.saved) {
              Text('已保存到本地')
                .fontSize(11)
                .fontColor('#2E7D32')
                .margin({ top: 8 })
            }
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 10 })

          // 设备码
          Column() {
            Text('当前设备码 (X-App-Device)')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .width('100%')
            Text(this.devicePreview)
              .fontSize(11)
              .fontColor('#8A8A8E')
              .width('100%')
              .margin({ top: 6 })
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .alignItems(HorizontalAlign.Start)
          .margin({ bottom: 10 })

          // 关于
          Row() {
            Text('关于本应用')
              .fontSize(14)
              .fontColor('#222222')
            Blank()
            Text('>')
              .fontSize(14)
              .fontColor('#C0C0C6')
          }
          .width('100%')
          .padding(14)
          .backgroundColor('#FFFFFF')
          .borderRadius(12)
          .onClick(() => router.pushUrl({ url: 'pages/About' }))

          Text('非官方客户端 · AGPL-3.0')
            .fontSize(10)
            .fontColor('#C0C0C6')
            .margin({ top: 16, bottom: 12 })
        }
        .width('100%')
        .padding({ left: 12, right: 12 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F7')
  }
}
