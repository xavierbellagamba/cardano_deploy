with open('service_status_raw.txt', 'r') as f:
    srv_txt = f.read()

srv_ln = srv_txt.split("\n")

status_ln = ""
for ln in srv_ln:
    if "Active" in ln:
        status_ln = ln
        break

status_ln = status_ln.split("Active: ")[-1]
status = status_ln.split(" ")[0]

with open('service_status.txt', 'w') as f:
  f.write(status)
