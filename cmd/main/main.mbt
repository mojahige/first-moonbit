///|
async fn main {
  let stdin = @stdio.stdin
  let text = stdin.read_all().text()
  let builder = StringBuilder::new()
  let (base_hue, base_saturation, base_lightness) = random_hsl()
  let regex = @regexp.compile("\\s+")
  for row_i, r in text.split("\r|\n|\r\n") {
    for col_i, c in r.iter2() {
      match regex.execute(c.to_string()).matched() {
        true => builder.write_string("\{c}")
        _ =>
          builder.write_string(
            "\{fill(c, row_i, col_i, hue=base_hue, saturation=base_saturation, lightness=base_lightness)}",
          )
      }
    }
    builder.write_string("\n")
  }
  @stdio.stdout.write(builder.to_string())
}

///|
fn fill(
  c : Char,
  row_i : Int,
  col_i : Int,
  spread? : Int = 3,
  hue? : Double = 0.0,
  saturation? : Double = 1.0,
  lightness? : Double = 0.5,
) -> String {
  let (r, g, b) = rainbow_color(
    col_i + row_i * spread,
    freq=0.1,
    base_hue=hue,
    saturation~,
    lightness~,
  )
  "\u001b[38;2;\{r};\{g};\{b}m\{c}\u001b[0m"
}

///|
fn rainbow_color(
  i : Int,
  freq? : Double = 3.0,
  base_hue? : Double = 0.0,
  saturation? : Double = 1.0,
  lightness? : Double = 0.5,
) -> (Int, Int, Int) {
  let hue = (i.to_double() * freq + base_hue) % 360.0
  hsl_to_rgb(hue, saturation, lightness)
}

///|
fn random_hsl() -> (Double, Double, Double) {
  let now = @async.now()
  let buf = @buffer.new()
  buf.write_int64_le(now)
  buf.write_int64_le(now * 31)
  buf.write_int64_le(now * 37)
  buf.write_int64_le(now * 41)
  let rand = @random.Rand::chacha8(seed=buf.to_bytes())
  let hue = rand.double() * 360.0
  let saturation = rand.double() * 0.5 + 0.5
  let lightness = rand.double() * 0.3 + 0.4
  (hue, saturation, lightness)
}

///|
fn hsl_to_rgb(h : Double, s : Double, l : Double) -> (Int, Int, Int) {
  // h: 0-360, s: 0-1, l: 0-1                 
  let c = (1.0 - (2.0 * l - 1.0).abs()) * s
  let x = c * (1.0 - (h / 60.0 % 2.0 - 1.0).abs())
  let m = l - c / 2.0
  let (r1, g1, b1) = if h < 60.0 {
    (c, x, 0.0)
  } else if h < 120.0 {
    (x, c, 0.0)
  } else if h < 180.0 {
    (0.0, c, x)
  } else if h < 240.0 {
    (0.0, x, c)
  } else if h < 300.0 {
    (x, 0.0, c)
  } else {
    (c, 0.0, x)
  }
  (
    ((r1 + m) * 255.0).to_int(),
    ((g1 + m) * 255.0).to_int(),
    ((b1 + m) * 255.0).to_int(),
  )
}
