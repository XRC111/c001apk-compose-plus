import { router } from '@kit.ArkUI';

/**
 * 图片查看器。
 *
 * 用 Swiper 左右翻页，点击图片返回。图片地址通过模块级变量传入
 * （与项目里其它页面一致，避免 router 参数的类型转换问题）。
 */

let pendingImages: string[] = [];
let pendingIndex: number = 0;

export function setPendingImages(images: string[], index: number): void {
  pendingImages = images;
  pendingIndex = index;
}

export function getPendingImages(): string[] {
  return pendingImages;
}

export function getPendingImageIndex(): number {
  return pendingIndex;
}

@Entry
@Component
struct ImageViewer {
  @State images: string[] = [];
  @State current: number = 0;
  private swiperController: SwiperController = new SwiperController();

  aboutToAppear(): void {
    this.images = getPendingImages();
    this.current = getPendingImageIndex();
    if (this.current < 0 || this.current >= this.images.length) {
      this.current = 0;
    }
  }

  build() {
    Stack() {
      // 背景：纯黑，看图时最不干扰
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#000000')

      if (this.images.length === 0) {
        Column() {
          Text('没有可显示的图片')
            .fontSize(14)
            .fontColor('#8E8E93')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Swiper(this.swiperController) {
          ForEach(this.images, (url: string) => {
            // 每页都占满，图片 contain 显示完整内容
            Image(url)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
              .alt($r('app.media.ic_image_placeholder'))
              .onClick(() => {
                router.back();
              })
          }, (url: string, idx: number) => url + '_' + idx.toString())
        }
        .index(this.current)
        .loop(false)
        .indicator(this.images.length > 1)
        .width('100%')
        .height('100%')
        .onChange((index: number) => {
          this.current = index;
        })

        // 顶部：页码 + 关闭按钮
        Row() {
          Blank()
          Text(this.images.length > 1
            ? `${this.current + 1} / ${this.images.length}`
            : '')
            .fontSize(14)
            .fontColor('#FFFFFF')
            .padding({ left: 12, right: 12 })
          Button('关闭', { type: ButtonType.Capsule })
            .fontSize(13)
            .height(32)
            .backgroundColor('#33FFFFFF')
            .fontColor('#FFFFFF')
            .margin({ left: 8 })
            .onClick(() => router.back())
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12 })
        .position({ x: 0, y: 0 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
