import { router } from '@kit.ArkUI';

@Entry
@Component
struct About {
  build() {
    Column() {
      Row() {
        Button('<', { type: ButtonType.Normal }).onClick(() => router.back())
        Text('关于').fontSize(20).fontWeight(FontWeight.Bold).margin({ left: 12 })
      }
      .width('100%')
      .margin({ bottom: 32 })

      Text('c001apk').fontSize(28).fontWeight(FontWeight.Bold)
      Text('HarmonyOS 原生骨架 · 268-harmony').fontSize(13).fontColor('#8A8A8E').margin({ top: 8 })
      Text('ArkTS + ArkUI · Stage 模型 · HAP').fontSize(13).fontColor('#8A8A8E').margin({ top: 4 })
      Text('本骨架平移了 Android 版的酷安 v3 签名常量与风控识别协议；'
        + '完整业务 UI 与易盾滑块闭环待后续迭代。')
        .fontSize(13)
        .textAlign(TextAlign.Center)
        .margin({ top: 24 })
        .padding({ left: 12, right: 12 })
    }
    .width('100%')
    .height('100%')
    .padding({ top: 48, left: 20, right: 20 })
    .backgroundColor($r('app.color.page_background'))
  }
}
