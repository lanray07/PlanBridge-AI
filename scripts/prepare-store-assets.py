"""Create exact App Store image sizes; preserve every generated master."""
from pathlib import Path
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'marketing' / 'app-store-drafts'
for name in ['iphone-65', 'ipad-13', 'subscriptions']:
    (OUT / name).mkdir(parents=True, exist_ok=True)

for source in sorted((ROOT / 'marketing' / 'concepts').glob('*.png')):
    with Image.open(source) as image:
        image = image.convert('RGB')
        for folder, size in [('iphone-65', (1242, 2688)), ('ipad-13', (2048, 2732))]:
            fitted = ImageOps.contain(image, size, Image.Resampling.LANCZOS)
            canvas = Image.new('RGB', size, '#F6F4EE')
            canvas.paste(fitted, ((size[0]-fitted.width)//2, (size[1]-fitted.height)//2))
            canvas.save(OUT / folder / source.name, optimize=True)

with Image.open(ROOT / 'marketing' / 'subscriptions' / 'planbridge-pro-master.png') as image:
    image.convert('RGB').resize((1024,1024), Image.Resampling.LANCZOS).save(
        OUT / 'subscriptions' / 'planbridge-pro-1024.png', optimize=True)

for file in OUT.rglob('*.png'):
    with Image.open(file) as image:
        print(file.relative_to(ROOT), image.size, image.mode)
