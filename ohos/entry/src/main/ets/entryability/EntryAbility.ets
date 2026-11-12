import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { getString, initSettings, KEY_SZLM_ID } from '../common/SettingsStore';
import { setDeviceCode } from '../common/DeviceCode';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'c001apk', 'EntryAbility onCreate');
    // 冷启动时把已保存的 ShuzlmID 应用到设备码，保证与设置页一致
    initSettings(this.context).then(() => {
      getString(KEY_SZLM_ID, '').then((v: string) => {
        if (v.length > 0) {
          setDeviceCode({ szlmId: v });
          hilog.info(DOMAIN, 'c001apk', 'applied saved szlmId');
        }
      });
    });
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
