"""SI figure: Nebraska (a) and Ohio (b) Delphi panels, stacked, in the Fig. 5 format.
Run figures/fig5_state_delphi.py NE and OH first."""
import os as _os, sys as _sys; _sys.path.insert(0, _os.path.join(_os.path.dirname(_os.path.dirname(_os.path.abspath(__file__))), "src"))
from config import FIGS
from PIL import Image, ImageDraw, ImageFont
ims = [Image.open(f"{FIGS}/fig5_state_delphi_{s}.png").convert("RGB") for s in ("NE", "OH")]
W = max(i.width for i in ims); pad = 60
out = Image.new("RGB", (W, sum(i.height for i in ims) + pad * 2), "white")
try: font = ImageFont.truetype("DejaVuSans-Bold.ttf", 64)
except OSError: font = ImageFont.load_default()
y = 0
for lab, im in zip("ab", ims):
    out.paste(im, (0, y + pad)); ImageDraw.Draw(out).text((10, y + 4), lab, fill="black", font=font); y += im.height + pad
out.save(f"{FIGS}/si_fig_state_delphi_NE_OH.png")
print(out.size)
