with open('curr_utxo.txt', 'r') as f:
    txt = f.read()

data = txt.split(' ')
data = [data[i] for i in range(len(data)-1, -1, -1) if len(data[i])>0]
utxo = data[5].split('\n')[-1]
ix = data[4]
utxo_ix = utxo + "#" + ix

with open('curr_utxo_ix.txt', 'w') as f:
  f.write(str(utxo_ix))