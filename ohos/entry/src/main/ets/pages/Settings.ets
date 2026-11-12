import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { getString, initSettings, isSettingsReady, KEY_SZLM_ID, putString } from '../common/SettingsStore';
import { getDeviceCode, setDeviceCode } from '../common/DeviceCode';

@Entry
@Component
struct Settings {
  @State szlmId: string = '';
  @State saved: boolean = false;
  @State ready: boolean = false;
  @State devicePreview: string = '';

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext;
    await initSettings(ctx);
    this.ready = isSettingsReady();
    this.szlmId = await getString(KEY_SZLM_ID, '');
    this.refreshDevice();
  }

  private refreshDevice(): void {
    const dev = getDeviceCode();
    this.devicePreview = dev.length > 28 ? dev.substring(0, 28) + '…' : dev;
  }

  private async save(): Promise<void> {
    await putString(KEY_SZLM_ID, this.szlmId);
    // 重新生成设备码，后续请求即带上新的 ShuzlmID
    setDeviceCode({ szlmId: this.szlmId });
    this.refreshDevice();
    this.saved = true;
  }

  build() {
    Column() {
      Row() {
        Button('<', { type: ButtonType.Normal }).onClick(() => router.back())
        Text('设置').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 12 })
      }
      .width('100%')
      .margin({ bottom: 24 })

      Text('数字联盟 ID (ShuzlmID)')
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
      Text('导入官方设备标识可免除大部分人机验证')
        .fontSize(12)
        .fontColor('#8A8A8E')
        .alignSelf(ItemAlign.Start)
        .margin({ top: 4, bottom: 10 })

      TextInput({ placeholder: '粘贴官方酷安连点 5 次「复制 OAID」的日志', text: this.szlmId })
        .width('100%')
        .height(80)
        .onChange((v: string) => {
          this.szlmId = v;
          this.saved = false;
        })

      Button('保存', { type: ButtonType.Capsule })
        .width('100%')
        .margin({ top: 14 })
        .enabled(this.ready)
        .onClick(() => this.save())

      if (!this.ready) {
        Text('本地存储初始化失败，本次修改仅在当前会话生效')
          .fontSize(12)
          .fontColor('#E06030')
          .margin({ top: 10 })
      } else if (this.saved) {
        Text('已保存到本地（Preferences）')
          .fontSize(12)
          .fontColor('#2E7D32')
          .margin({ top: 10 })
      }

      Divider().margin({ top: 20, bottom: 16 })

      Text('当前设备码 (X-App-Device)')
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
      Text(this.devicePreview)
        .fontSize(11)
        .fontColor('#8A8A8E')
        .alignSelf(ItemAlign.Start)
        .margin({ top: 4 })

      Text('说明：设备码由「ShuzlmID; ; ; MAC; 厂商; 品牌; 型号; 构建号; null」'
        + '经 base64 后反转并去掉 = 得到，与酷安官方格式一致。')
        .fontSize(11)
        .fontColor('#A0A0A6')
        .alignSelf(ItemAlign.Start)
        .margin({ top: 10 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .padding({ top: 48, left: 20, right: 20 })
    .backgroundColor($r('app.color.page_background'))
  }
}
