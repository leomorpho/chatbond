import argparse
import os

from PIL import Image


def generate_images(src_image, dest_dir):
    im = Image.open(src_image)
    base_size = (512, 512)
    name = os.path.join(dest_dir, os.path.basename(src_image).split(".")[0])

    # Generate square base image
    im = im.resize(base_size, Image.ANTIALIAS)
    im.save(f"{name}-512x512.png")

    sizes = ["16x16", "32x32", "64x64", "96x96", "128x128", "256x256"]
    generated = []
    for size in sizes:
        width, height = map(int, size.split("x"))
        im_resized = im.resize((width, height), Image.ANTIALIAS)
        file_name = f"{name}-{size}.png"
        im_resized.save(file_name)
        generated.append(file_name)

    # Generate ico
    im.save(
        f"{dest_dir}/favicon.ico",
        format="ICO",
        sizes=[(16, 16), (32, 32), (64, 64), (96, 96)],
    )

    sizes_apple = ["152x152", "167x167", "180x180"]
    generated_apple = []
    for size in sizes_apple:
        width, height = map(int, size.split("x"))
        im_resized = im.resize((width, height), Image.ANTIALIAS)
        file_name = f"{name}-apple-{size}.png"
        im_resized.save(file_name)
        generated_apple.append(file_name)

    return generated, generated_apple


def generate_tags(generated, generated_apple, dest_dir):
    with open(os.path.join(dest_dir, "favicons.txt"), "w") as f:
        for icon in generated:
            size = os.path.basename(icon).split("-")[-1].split(".png")[0]
            f.write(
                f'<link rel="shortcut icon" type="image/png" sizes="{size}" href="{icon}" />\n'
            )

        for icon in generated_apple:
            size = os.path.basename(icon).split("-")[-1].split(".png")[0]
            f.write(
                f'<link rel="apple-touch-icon" type="image/png" sizes="{size}" href="{icon}" />\n'
            )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate favicons.")
    parser.add_argument("src_image", type=str, help="Source image.")
    parser.add_argument("dest_dir", type=str, help="Destination directory.")
    parser.add_argument(
        "-x", "--generate_tags", action="store_true", help="Generate HTML tags."
    )

    args = parser.parse_args()

    # Create the destination directory if it doesn't exist
    os.makedirs(args.dest_dir, exist_ok=True)

    generated, generated_apple = generate_images(args.src_image, args.dest_dir)

    if args.generate_tags:
        generate_tags(generated, generated_apple, args.dest_dir)
