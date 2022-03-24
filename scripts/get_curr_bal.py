with open('curr_utxo.txt', 'r') as f:
    txt = f.read()

bal = txt.split(' ')
bal = [bal[i] for i in range(len(bal)-1, -1, -1) if len(bal[i])>0]
curr_bal = float(bal[3])

with open('curr_bal.txt', 'w') as f:
  f.write(str(curr_bal))