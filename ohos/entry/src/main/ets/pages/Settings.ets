import { router } from '@kit.ArkUI';

@Entry
@Component
struct Settings {
  @State szlmId: string = '';
  @State saved: boolean = false;

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

      TextInput({ placeholder: '粘贴官方酷安连点 5 次「复制 OAID」的日志' })
        .width('100%')
        .height(80)
        .onChange((v: string) => { this.szlmId = v; this.saved = false; })

      Button('保存', { type: ButtonType.Capsule })
        .width('100%')
        .margin({ top: 14 })
        .onClick(() => { this.saved = true; })

      if (this.saved) {
        Text('已保存（本地会话；持久化待接入 Preferences）')
          .fontSize(12)
          .fontColor('#2E7D32')
          .margin({ top: 10 })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: 48, left: 20, right: 20 })
    .backgroundColor($r('app.color.page_background'))
  }
}
