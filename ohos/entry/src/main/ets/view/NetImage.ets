/**
 * 远程图片组件：自动带 UA/Referer 下载，解码后渲染。
 *
 * 用法与 Image 类似：
 *   NetImage({ url: item.pic, width: '100%', height: 104, radius: 8 })
 *
 * 为什么要自己实现：酷安图床要求 UA + Referer 同时存在（否则 567），
 * 而 ArkUI Image() 不能自定义请求头，只能自己下载 + 解码成 PixelMap。
 */
import { image } from '@kit.ImageKit';
import { loadImage, getCachedImage } from './RemoteImage';
import { httpsUrl } from './Feed';

@Component
export struct NetImage {
  /** 原始 URL（http 会被自动升级为 https）。 */
  url: string = '';
  /** 显示宽度，支持 '100%' 这类百分比。 */
  imgWidth: Length = '100%';
  /** 显示高度。 */
  imgHeight: Length = 104;
  /** 圆角。 */
  radius: number = 8;
  /** 裁剪方式。 */
  fit: ImageFit = ImageFit.Cover;

  @State private pixel: image.PixelMap | undefined = undefined;
  @State private failed: boolean = false;

  aboutToAppear(): void {
    this.resolve();
  }

  /** 外部 url 变化时重新加载（ForEach 复用组件会走到这里）。 */
  private resolve(): void {
    const key = httpsUrl(this.url);
    const cached = getCachedImage(key);
    if (cached !== undefined) {
      this.pixel = cached;
      this.failed = false;
      return;
    }
    this.pixel = undefined;
    this.failed = false;
    loadImage(this.url).then((pm: image.PixelMap | null) => {
      if (pm !== null) {
        this.pixel = pm;
        this.failed = false;
      } else {
        this.failed = true;
      }
    });
  }

  build() {
    Stack() {
      if (this.pixel !== undefined) {
        Image(this.pixel)
          .width(this.imgWidth)
          .height(this.imgHeight)
          .objectFit(this.fit)
          .borderRadius(this.radius)
      } else if (this.failed) {
        // 加载失败：显示占位图标，不留白
        Column() {
          Image($r('app.media.ic_image_placeholder'))
            .width(26)
            .height(26)
            .fillColor($r('app.color.text_tertiary'))
        }
        .width(this.imgWidth)
        .height(this.imgHeight)
        .borderRadius(this.radius)
        .backgroundColor($r('app.color.divider'))
        .justifyContent(FlexAlign.Center)
      } else {
        // 加载中：浅色占位
        Column()
          .width(this.imgWidth)
          .height(this.imgHeight)
          .borderRadius(this.radius)
          .backgroundColor($r('app.color.divider'))
      }
    }
    .width(this.imgWidth)
    .height(this.imgHeight)
  }
}
