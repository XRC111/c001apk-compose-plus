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
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_title'))
        Blank()
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })

      List() {
        // ===== 账号 =====
        ListItemGroup({ header: this.groupHeader('账号') }) {
          ListItem() {
            Row() {
              Text('当前账号')
                .fontSize(14)
                .fontColor($r('app.color.text_title'))
              Blank()
              Text(this.loginName.length > 0 ? this.loginName : '未登录')
                .fontSize(13)
                .fontColor(this.loginName.length > 0
                  ? $r('app.color.text_secondary')
                  : $r('app.color.text_tertiary'))
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)
          }

          ListItem() {
            Row() {
              Text(this.loginName.length > 0 ? '退出登录' : '登录酷安')
                .fontSize(14)
                .fontColor(this.loginName.length > 0
                  ? $r('app.color.danger')
                  : $r('app.color.accent'))
              Blank()
              Image($r('app.media.ic_chevron'))
                .width(18)
                .height(18)
                .fillColor($r('app.color.text_tertiary'))
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)
            .margin({ top: 8 })
            .onClick(() => {
              if (this.loginName.length > 0) {
                this.logout();
              } else {
                router.pushUrl({ url: 'pages/LoginPage' });
              }
            })
          }
        }

        // ===== 设备 =====
        ListItemGroup({ header: this.groupHeader('设备') }) {
          ListItem() {
            Column() {
              Text('数字联盟 ID (ShuzlmID)')
                .fontSize(14)
                .fontColor($r('app.color.text_title'))
                .width('100%')
              Text('导入官方设备标识可免除大部分人机验证')
                .fontSize(11)
                .fontColor($r('app.color.text_tertiary'))
                .width('100%')
                .margin({ top: 4, bottom: 10 })

              TextInput({
                placeholder: '粘贴官方酷安连点 5 次「复制 OAID」的日志',
                text: this.szlmId,
              })
                .width('100%')
                .height(72)
                .onChange((v: string) => {
                  this.szlmId = v;
                  this.saved = false;
                })

              Button('保存', { type: ButtonType.Capsule })
                .width('100%')
                .height(38)
                .margin({ top: 10 })
                .backgroundColor($r('app.color.accent'))
                .enabled(this.ready)
                .onClick(() => this.save())

              if (!this.ready) {
                Text('本地存储初始化失败，本次修改仅在当前会话生效')
                  .fontSize(11)
                  .fontColor($r('app.color.danger'))
                  .margin({ top: 8 })
              } else if (this.saved) {
                Text('已保存到本地')
                  .fontSize(11)
                  .fontColor($r('app.color.success'))
                  .margin({ top: 8 })
              }
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
          }

          ListItem() {
            Column() {
              Text('当前设备码 (X-App-Device)')
                .fontSize(13)
                .fontColor($r('app.color.text_title'))
                .width('100%')
              Text(this.devicePreview)
                .fontSize(11)
                .fontColor($r('app.color.text_secondary'))
                .width('100%')
                .margin({ top: 6 })
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)
            .margin({ top: 8 })
          }
        }

        // ===== 其他 =====
        ListItemGroup({ header: this.groupHeader('其他') }) {
          ListItem() {
            Row() {
              Text('关于本应用')
                .fontSize(14)
                .fontColor($r('app.color.text_title'))
              Blank()
              Image($r('app.media.ic_chevron'))
                .width(18)
                .height(18)
                .fillColor($r('app.color.text_tertiary'))
            }
            .width('100%')
            .padding(14)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)
            .onClick(() => router.pushUrl({ url: 'pages/About' }))
          }

          ListItem() {
            Text('非官方客户端 · AGPL-3.0')
              .fontSize(10)
              .fontColor($r('app.color.text_tertiary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding({ top: 9, bottom: 9 })
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12 })
      .scrollBar(BarState.Off)
      .sticky(StickyStyle.Header)
      .contentEndOffset(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  groupHeader(title: string) {
    Text(title)
      .fontSize(12)
      .fontColor($r('app.color.text_secondary'))
      .width('100%')
      .padding({ left: 4, top: 14, bottom: 8 })
      .backgroundColor($r('app.color.page_bg'))
  }
}
