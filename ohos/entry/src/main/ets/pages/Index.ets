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

      Divider().strokeWidth(0.5).color('#EAEAEA')

      Row() {
        this.BottomItem('首页', 0)
        this.BottomItem('消息', 1)
        this.BottomItem('设置', 2)
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F7')
  }

  @Builder
  BottomItem(label: string, idx: number) {
    Column() {
      Text(label)
        .fontSize(this.currentTab === idx ? 13 : 12)
        .fontWeight(this.currentTab === idx ? FontWeight.Bold : FontWeight.Normal)
        .fontColor(this.currentTab === idx ? '#FB7299' : '#8A8A8E')
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentTab = idx;
    })
  }
}

