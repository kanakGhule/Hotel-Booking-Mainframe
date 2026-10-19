import random, datetime
random.seed(2026)
FIRST=["AARAV","VIHAAN","ANANYA","ISHITA","ROHAN","MEERA","KABIR","SANYA","ADITYA","DIYA","ARJUN","NEHA","KARAN","PRIYA","RAHUL","SNEHA","VIKRAM","POOJA","AMIT","RIYA"]
LAST=["SHARMA","PATIL","DESAI","KULKARNI","JOSHI","MEHTA","NAIK","GUPTA","IYER","REDDY","SHAH","KHAN"]
TYPES=[("STD",3500),("DLX",5200),("STE",8800)]
def name(): 
    return (random.choice(FIRST)+" "+random.choice(LAST))[:20]
def f(s,n): 
    s=str(s); assert len(s)<=n,(s,n); return s.ljust(n)
def num(v,n): return str(v).zfill(n)
def reservation(i):
    rt,rate=random.choice(TYPES)
    ci=datetime.date(2026,11,1)+datetime.timedelta(days=random.randint(0,60))
    co=ci+datetime.timedelta(days=random.randint(1,7))
    bd=datetime.date(2026,10,1)+datetime.timedelta(days=random.randint(0,4))
    r=("RSV"+"PUN"+bd.strftime("%y%m%d")+"RS"+num(i,6)+f(name(),20)
       +num(random.randint(101,520),4)+f(rt,4)+ci.strftime("%Y%m%d")+co.strftime("%Y%m%d")
       +num(random.randint(1,4),2)+num(rate,6)+"C"+" "*7)
    assert len(r)==80,len(r); return r
def payment(pid,resid,nm):
    mode=random.choice(["CSH","CRD","UPI"])
    r=("PAY"+"PY"+num(pid,6)+"26"+str(random.randint(10,12))+num(random.randint(1,28),2)+mode
       +resid+num(random.randint(2000,40000)*100,10)+f(nm,20)+" "*22)
    assert len(r)==80,len(r); return r
def invoice(i,rid,nm,gid):
    n=random.randint(1,7); rate=random.choice([3500,5200,8800])
    room=n*rate*100; svc=random.randint(0,3000)*100
    tax=int((room+svc)*(0.05 if rate<=7500 else 0.18)); tot=room+svc+tax
    d=datetime.date(2026,11,1)+datetime.timedelta(days=random.randint(1,70))
    r=("INV"+"PUN"+d.strftime("%Y%m%d")+"G"+num(gid,9)+"IN"+num(i,6)+rid+f(nm,20)
       +num(n,3)+num(room,8)+num(svc,8)+num(tax,8)+num(tot,10)+"P"+"  ")
    assert len(r)==100,len(r); return r
# A1: 90 unique + 10 dup, random order
ids=random.sample(range(1,9000),90)
u=[reservation(i) for i in ids]
recs=u+random.sample(u,10); random.shuffle(recs)
assert len(recs)==100 and len(set(r[12:20] for r in recs))==90
open("data/RESERV.dat","w").write("\n".join(recs)+"\n")
# A2: 50 / 50 with 35 matches
ids=random.sample(range(1,9000),65)
common=ids[:35]; only1=ids[35:50]; only2=ids[50:65]
f1=[reservation(i) for i in common+only1]; random.shuffle(f1)
nm={}
for r in f1: nm[r[12:20]]=r[20:40].strip()
f2=[payment(k+1,"RS"+num(i,6),nm.get("RS"+num(i,6),name())) for k,i in enumerate(common+only2)]
random.shuffle(f2)
assert len(f1)==50 and len(f2)==50
open("data/FILE1.dat","w").write("\n".join(f1)+"\n")
open("data/FILE2.dat","w").write("\n".join(f2)+"\n")
# A3: 105 unique + 15 dup
ids=random.sample(range(1,9000),105)
u=[invoice(i,"RS"+num(random.randint(1,8999),6),name(),random.randint(1,999999)) for i in ids]
recs=u+random.sample(u,15); random.shuffle(recs)
assert len(recs)==120 and len(set(r[24:32] for r in recs))==105
open("data/INVOICE.dat","w").write("\n".join(recs)+"\n")
# expected outputs for verification
open("data/EXPECTED_A1.dat","w").write("\n".join(sorted(set(open("data/RESERV.dat").read().split("\n"))-{""}, key=lambda r:r[12:20]))+"\n")
open("data/EXPECTED_A3.dat","w").write("\n".join(sorted(set(open("data/INVOICE.dat").read().split("\n"))-{""}, key=lambda r:r[24:32]))+"\n")
k1={r[12:20] for r in f1}; k2={r[20:28] for r in f2}
print("A1 unique",len(open('data/EXPECTED_A1.dat').read().split('\n'))-1,"A2 matches",len(k1&k2),"A3 unique",len(open('data/EXPECTED_A3.dat').read().split('\n'))-1)
