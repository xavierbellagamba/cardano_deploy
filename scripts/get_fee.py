with open('fee_raw.txt', 'r') as f:
    txt = f.read()

fee = txt.split(' ')[0]

with open('fee.txt', 'w') as f:
  f.write(str(fee))