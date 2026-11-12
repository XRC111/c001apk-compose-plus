import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'c001apk', 'EntryAbility onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'c001apk', 'loadContent failed: %{public}d', err.code);
        return;
      }
      hilog.info(DOMAIN, 'c001apk', 'loadContent succeeded');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'c001apk', 'onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'c001apk', 'onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'c001apk', 'onBackground');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'c001apk', 'onDestroy');
  }
}
