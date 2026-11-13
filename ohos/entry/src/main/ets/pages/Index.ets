import { HomeTab } from '../view/HomeTab';
import { MessageTab } from '../view/MessageTab';
import { SettingsTab } from '../view/SettingsTab';

/**
 * 应用外壳：底部三栏（首页 / 消息 / 设置），与 Android 版
 * MainScreen 的 NavigationSuiteScaffold 结构一致。
 */
@Entry
@Component
struct Index {
  @State currentTab: number = 0;

  build() {
    Column() {
      Column() {
        if (this.currentTab === 0) {
          HomeTab()
        } else if (this.currentTab === 1) {
          MessageTab()
        } else {
          SettingsTab()
        }
      }
      .layoutWeight(1)
      .width('100%')

      Divider().strokeWidth(0.5).color('#E6E6EA')

      Row() {
        this.BottomItem('首页', 0, $r('app.media.ic_home'))
        this.BottomItem('消息', 1, $r('app.media.ic_message'))
        this.BottomItem('设置', 2, $r('app.media.ic_settings'))
      }
      .width('100%')
      .height(58)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F2F2F6')
  }

  @Builder
  BottomItem(label: string, idx: number, icon: Resource) {
    Column() {
      Image(icon)
        .width(23)
        .height(23)
        .fillColor(this.currentTab === idx ? '#FB7299' : '#9A9AA0')
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === idx ? '#FB7299' : '#9A9AA0')
        .fontWeight(this.currentTab === idx ? FontWeight.Medium : FontWeight.Normal)
        .margin({ top: 3 })
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentTab = idx;
    })
  }
}
