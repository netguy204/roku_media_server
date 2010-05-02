import Image, ImageDraw, ImageFont

font = ImageFont.truetype("Consolas.ttf", 24)

def compose(input, text, output, format = None):
  SD_DIM = (223,200)
  HD_DIM = (300,300)

  dim = SD_DIM
  im = Image.open(input)
  im.thumbnail(dim)

  draw = ImageDraw.ImageDraw(im)

  (tw, th) = font.getsize(text)
  start = (dim[0] - tw - 20) / 2, (dim[1] * 3 / 4)
  draw.text(start, text, font=font)

  if format:
    im.save(output, format)
  else:
    im.save(output)


if __name__ == "__main__":
  import sys
  import tempfile
  tf = tempfile.TemporaryFile()
  compose(sys.argv[1], u"Hannah", tf, "jpeg")
  f = open("test.jpg", "wb")
  tf.seek(0)
  f.write(tf.read())
  f.close()


