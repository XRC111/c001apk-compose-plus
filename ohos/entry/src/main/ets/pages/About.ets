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

      Text('c001apk')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
      Text('HarmonyOS 原生版 · 268-harmony')
        .fontSize(13)
        .fontColor('#8A8A8E')
        .margin({ top: 8 })
      Text('ArkTS + ArkUI · Stage 模型 · HAP')
        .fontSize(13)
        .fontColor('#8A8A8E')
        .margin({ top: 4 })

      Column() {
        Text('已实现')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 6 })

        Text('· X-App-Token v3 全链路（纯 ArkTS 的 bcrypt / MD5 / base64）\n'
          + '· 首页信息流（含分页）、动态详情与评论\n'
          + '· 应用详情（图标 / 版本 / 大小 / 下载量 / 更新日志）\n'
          + '· 关键词搜索\n'
          + '· 账号登录（内置网页登录并提取 Cookie）\n'
          + '· 新版风控验证（易盾滑块，验证后自动写回 validate）\n'
          + '· ShuzlmID / 设备码本地持久化\n'
          + '· SESSID 自动回写')
          .fontSize(12)
          .fontColor('#555555')
          .alignSelf(ItemAlign.Start)
          .lineHeight(20)

        Text('暂未实现')
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ top: 14, bottom: 6 })

        Text('· 用户主页\n'
          + '· 点赞、收藏、评论等写操作\n'
          + '· 消息通知、发现页\n'
          + '· 图片缓存与预加载')
          .fontSize(12)
          .fontColor('#555555')
          .alignSelf(ItemAlign.Start)
          .lineHeight(20)
      }
      .width('100%')
      .padding(14)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .margin({ top: 24 })

      Blank()

      Text('非官方客户端，与酷安官方无关。AGPL-3.0。')
        .fontSize(11)
        .fontColor('#A0A0A6')
        .margin({ bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .padding({ top: 48, left: 20, right: 20 })
    .backgroundColor($r('app.color.page_background'))
  }
}
