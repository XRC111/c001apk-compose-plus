import { ConfigurationConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { CoolapkApi, CoolapkResponse } from '../common/CoolapkApi';
import { isLoggedIn } from '../common/CookieStore';
import { HomeTab } from '../view/HomeTab';
import { MessageTab } from '../view/MessageTab';
import { SettingsTab } from '../view/SettingsTab';

const DOMAIN = 0xD0001;

/**
 * 应用外壳：底部三栏（首页 / 消息 / 设置）。
 *
 * 用 Tabs + 自定义 tabBar 实现（官方底部页签示例的做法），
 * 相比 if 切换内容能保留各 Tab 的状态与滚动位置。
 *
 * 另外承担状态栏适配：页面背景取自 base/dark 两套资源，
 * 但状态栏文字颜色需要按当前深浅色手动设置（官方「深色模式适配」文档）。
 */
@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State unread: number = 0;
  @StorageProp('currentColorMode')
  @Watch('onColorModeChange')
  currentColorMode: ConfigurationConstant.ColorMode =
    ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

  private tabsController: TabsController = new TabsController();
  private windowObj: window.Window | null = null;

  aboutToAppear(): void {
    this.loadUnread();
    try {
      window.getLastWindow(this.getUIContext().getHostContext(),
        (err: BusinessError, data: window.Window) => {
          if (err.code) {
            hilog.error(DOMAIN, 'c001apk', 'getLastWindow failed: %{public}d', err.code);
            return;
          }
          this.windowObj = data;
          this.applyStatusBar();
        });
    } catch (e) {
      hilog.error(DOMAIN, 'c001apk', 'getLastWindow threw: %{public}s', JSON.stringify(e));
    }
  }

  /** 深浅色切换时重新设置状态栏文字颜色。 */
  onColorModeChange(): void {
    this.applyStatusBar();
  }

  /** 拉未读数，给「消息」Tab 加红点。 */
  private async loadUnread(): Promise<void> {
    const logged = await isLoggedIn();
    if (!logged) {
      return;
    }
    const res: CoolapkResponse = await CoolapkApi.fetchCheckCount();
    const m = /"badge"\s*:\s*(\d+)/.exec(res.body);
    if (m !== null) {
      this.unread = parseInt(m[1], 10);
    }
  }

  private applyStatusBar(): void {
    const win = this.windowObj;
    if (win === null) {
      return;
    }
    try {
      if (this.currentColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
        win.setWindowSystemBarProperties({ statusBarContentColor: '#FFFFFF' });
      } else {
        win.setWindowSystemBarProperties({ statusBarContentColor: '#000000' });
      }
    } catch (e) {
      hilog.error(DOMAIN, 'c001apk', 'setWindowSystemBarProperties failed: %{public}s',
        JSON.stringify(e));
    }
  }

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
      if (idx === 1 && this.unread > 0) {
        Badge({
          count: this.unread,
          position: BadgePosition.RightTop,
          style: { badgeSize: 14, badgeColor: $r('app.color.accent') },
        }) {
          Image(icon)
            .width(23)
            .height(23)
            .fillColor(this.currentTab === idx
              ? $r('app.color.accent')
              : $r('app.color.text_secondary'))
        }
      } else {
        Image(icon)
          .width(23)
          .height(23)
          .fillColor(this.currentTab === idx
            ? $r('app.color.accent')
            : $r('app.color.text_secondary'))
      }
      Text(label)
        .fontSize(10)
        .fontColor(this.currentTab === idx
          ? $r('app.color.accent')
          : $r('app.color.text_secondary'))
        .fontWeight(this.currentTab === idx ? FontWeight.Medium : FontWeight.Normal)
        .margin({ top: 3 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
