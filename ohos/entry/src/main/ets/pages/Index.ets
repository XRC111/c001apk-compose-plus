import { HomeTab } from '../view/HomeTab';
import { MessageTab } from '../view/MessageTab';
import { SettingsTab } from '../view/SettingsTab';

/**
 * 应用外壳：底部三栏（首页 / 消息 / 设置）。
 *
 * 用 Tabs + 自定义 tabBar 实现（官方底部页签示例的做法），
 * 相比 if 切换内容能保留各 Tab 的状态与滚动位置。
 */
@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  private tabsController: TabsController = new TabsController();

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentTab, controller: this.tabsController }) {
      TabContent() {
        HomeTab()
      }
      .tabBar(this.TabItem('首页', 0, $r('app.media.ic_home')))

      TabContent() {
        MessageTab()
      }
      .tabBar(this.TabItem('消息', 1, $r('app.media.ic_message')))

      TabContent() {
        SettingsTab()
      }
      .tabBar(this.TabItem('设置', 2, $r('app.media.ic_settings')))
    }
    .barHeight(58)
    .barBackgroundColor($r('app.color.card_bg'))
    .barMode(BarMode.Fixed)
    .scrollable(false)
    .animationDuration(200)
    .onChange((index: number) => {
      this.currentTab = index;
    })
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  @Builder
  TabItem(label: string, idx: number, icon: Resource) {
    Column() {
      Image(icon)
        .width(23)
        .height(23)
        .fillColor(this.currentTab === idx ? $r('app.color.accent') : $r('app.color.text_secondary'))
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === idx ? $r('app.color.accent') : $r('app.color.text_secondary'))
        .fontWeight(this.currentTab === idx ? FontWeight.Medium : FontWeight.Normal)
        .margin({ top: 3 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
