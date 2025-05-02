import math

N = 256
W = 16
scale = 1 << (W - 1)

for k in range(N // 2):
    angle = -2 * math.pi * k / N
    cos_val = int(round(math.cos(angle) * scale))
    sin_val = int(round(math.sin(angle) * scale))
    negsinstr = ""
    negcosstr = ""
    if sin_val < 0:
      negsinstr = "-"
    if cos_val < 0:
       negcosstr = "-"
    # print(f"            {k}:   begin twiddle_real <= {negcosstr}16'sd{abs(cos_val)}; twiddle_imag <= {negsinstr}16'sd{abs(sin_val)}; end")
    print(f"      twiddle_real[{k}] = {negcosstr}16'sd{abs(cos_val)}; twiddle_imag[{k}] = {negsinstr}16'sd{abs(sin_val)};")

