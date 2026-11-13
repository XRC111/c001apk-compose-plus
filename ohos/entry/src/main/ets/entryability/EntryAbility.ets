import {
  AbilityConstant,
  Configuration,
  ConfigurationConstant,
  UIAbility,
  Want,
} from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { getString, initSettings, KEY_SZLM_ID } from '../common/SettingsStore';
import { setDeviceCode } from '../common/DeviceCode';

const DOMAIN = 0xD0001;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'c001apk', 'EntryAbility onCreate');

    // 深色模式适配（参考官方「深色模式适配」文档）：
    // 1) 设为「未指定」，让应用跟随系统深浅色
    // 2) 把当前 colorMode 放进 AppStorage，页面侧据此调整状态栏文字颜色
    try {
      this.context.getApplicationContext()
        .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (e) {
      hilog.error(DOMAIN, 'c001apk', 'setColorMode failed: %{public}s', JSON.stringify(e));
    }
    AppStorage.setOrCreate('currentColorMode', this.context.config.colorMode);

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

  /** 系统深浅色切换时同步到 AppStorage。 */
  onConfigurationUpdate(newConfig: Configuration): void {
    const current: ConfigurationConstant.ColorMode | undefined =
      AppStorage.get<ConfigurationConstant.ColorMode>('currentColorMode');
    if (current !== newConfig.colorMode) {
      AppStorage.setOrCreate('currentColorMode', newConfig.colorMode);
      hilog.info(DOMAIN, 'c001apk', 'colorMode changed to %{public}d', newConfig.colorMode);
    }
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
